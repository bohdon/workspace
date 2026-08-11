// WindowMover - move/resize/edit Windows with Win key and mouse.

// Hotkeys
//   Win-LMB: Move window
//   Win-RMB: Resize window
//   Win-MMB: Maximize / restore window
//   Win-Alt-RMB: Minimize window
//   Win-Ctrl-RMB: Close window

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

namespace WindowMover;

static class DebugLogger
{
    private enum Level
    {
        Info,
        Warn,
        Error
    }

    // Guards both console writes (so colored lines aren't interleaved/torn by other threads) and file appends.
    private static readonly object Sync = new();

    private static string _logPath = "";

    /// <summary>Plain info message - no prefix added.</summary>
    public static void Info(string msg) => Log(Level.Info, msg);

    /// <summary>Warning message, shown in yellow.</summary>
    public static void Warn(string msg) => Log(Level.Warn, msg);

    /// <summary>Error message, shown in red.</summary>
    public static void Error(string msg) => Log(Level.Error, msg);

    /// <summary>Enable file logging to a specific path.</summary>
    public static void SetLogPath(string path)
    {
        lock (Sync)
        {
            _logPath = path;
        }
    }

    private static void Log(Level level, string msg)
    {
        string prefix = level switch
        {
            Level.Warn => "Warning: ",
            Level.Error => "Error: ",
            _ => ""
        };

        string line =
            $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} [{Environment.CurrentManagedThreadId}] {prefix}{msg}";

        Debug.WriteLine(line);

        lock (Sync)
        {
            WriteColored(level, line);

            if (_logPath != "")
            {
                try
                {
                    File.AppendAllText(_logPath, line + Environment.NewLine);
                }
                catch
                {
                    // tried
                }
            }
        }
    }

    private static void WriteColored(Level level, string line)
    {
        // Don't touch ForegroundColor when output isn't an actual console
        if (Console.IsOutputRedirected || level == Level.Info)
        {
            Console.WriteLine(line);
            return;
        }

        ConsoleColor original = Console.ForegroundColor;
        Console.ForegroundColor = level == Level.Error ? ConsoleColor.Red : ConsoleColor.Yellow;
        try
        {
            Console.WriteLine(line);
        }
        finally
        {
            Console.ForegroundColor = original;
        }
    }

    /// <summary>Dump window class name and rectangle for diagnostic purposes.</summary>
    public static void DumpWindow(string prefix, IntPtr hWnd)
    {
        if (hWnd == IntPtr.Zero)
        {
            Warn($"{prefix} - null hWnd");
            return;
        }

        try
        {
            var sb = new StringBuilder(256);
            Win32.GetClassNameW(hWnd, sb, sb.Capacity);
            string className = sb.ToString();
            Win32.GetWindowRect(hWnd, out var rect);
            Info(
                $"{prefix} - class: {className} pos: ({rect.Left},{rect.Top}) size: {rect.Width}x{rect.Height} hwnd: {hWnd:X8}");
        }
        catch (Exception ex)
        {
            Warn($"{prefix} - error: {ex.Message}");
        }
    }
}

static class Program
{
    /// <summary>Special value telling Windows to attach to the parent process</summary>iu
    private const int ATTACH_PARENT_PROCESS = -1;

    [STAThread]
    static void Main()
    {
        // ensure console output goes to the parent process (if started from terminal)
        Win32.AttachConsole(ATTACH_PARENT_PROCESS);

        // Log (rather than silently lose) any exception that would otherwise crash
        // this background/tray app without a trace.
        Application.ThreadException += (_, e) =>
            DebugLogger.Error($"Unhandled UI thread exception: {e.Exception}");
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
            DebugLogger.Error($"Unhandled exception (terminating={e.IsTerminating}): {e.ExceptionObject}");

        // Ctrl+C to shut down the app cleanly (instead of hard-terminating)
        Console.CancelKeyPress += (_, e) =>
        {
            DebugLogger.Info("Ctrl+C received via console");
            e.Cancel = true;
            Application.Exit();
        };

        // Parse --log <path> from command line; file logging is off by default.
        string logPath = "";
        string[] args = Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length; i++)
        {
            if (string.Equals(args[i], "--log", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
            {
                logPath = args[i + 1];
                break;
            }
        }

        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        DebugLogger.SetLogPath(logPath);
        DebugLogger.Info("WindowMover started.");
        Console.WriteLine(logPath != ""
            ? $"WindowMover running in system tray. Log: {logPath}"
            : "WindowMover running in system tray. File logging disabled");
        Application.Run(new WindowMover());
        Console.WriteLine("WindowMover shut down.");
    }
}

enum MouseButton
{
    Left,
    Middle,
    Right,
}

class WindowMover : Form
{
    private const int SNAP_DISTANCE = 100;

    private IntPtr _mouseHookHandle = IntPtr.Zero;
    private IntPtr _keyboardHookHandle = IntPtr.Zero;
    private Win32.HookProc _hookProc;

    /// <summary>Drag session state</summary>
    private DragOperation _drag;

    public enum DragType
    {
        Move,
        Resize,
    }

    public struct DragOperation
    {
        /// <summary>Is a drag currently active?</summary>
        public bool IsActive;

        /// <summary>The type of drag operation.</summary>
        public DragType Type;

        /// <summary>target window during drag.</summary>
        public IntPtr Target;

        /// <summary>Cursor position at drag start.</summary>
        public Win32.POINT StartPos;

        /// <summary>Latest known cursor position from mouse moves.</summary>
        public Win32.POINT CurrentPos;

        /// <summary>window rect at session start.</summary>
        public Rectangle InitRect;

        /// <summary>Should the window be snapped to edges during this drag?</summary>
        public bool ShouldSnap;

        /// <summary>corner/edge hit-test value for resize.</summary>
        public int HitTestVal;

        public void Clear()
        {
            IsActive = false;
            Target = IntPtr.Zero;
            StartPos = default;
            CurrentPos = default;
            InitRect = default;
            ShouldSnap = false;
            HitTestVal = 0;
        }
    }

    /// <summary>
    /// Was the Win key used for any action during the current hold? Determines whether
    /// we've already suppressed the Start Menu trigger for this hold (see MarkWinKeyUsed).
    /// </summary>
    private bool _usedWinKey;

    /// <summary>
    /// Which mouse downs were just swallowed? so we can swallow mouse-up too.
    /// </summary>
    private HashSet<MouseButton> _activeMouseDowns = [];

    /// <summary>System tray icon for visibility / exit.</summary>
    private NotifyIcon _trayIcon;

    public WindowMover()
    {
        ShowInTaskbar = false;
        Opacity = 0;
        VisibleChanged += (_, _) =>
        {
            if (Visible) Hide();
        };

        Win32.SetProcessDpiAwarenessContext(Win32.DPI_PER_MONITOR_AWARE_V2);

        // System tray icon - shows the app is running and provides an Exit option
        _trayIcon = new NotifyIcon
        {
            Icon = LoadAppIcon(),
            Text = "WindowMover - Win+mouse to move/resize windows",
            Visible = true,
            ContextMenuStrip = new ContextMenuStrip
            {
                Items = { new ToolStripMenuItem("Exit", null, (_, _) => Application.Exit()) }
            }
        };

        SetupHook();
    }

    private void SetupHook()
    {
        _hookProc = HookProc;
        var hModule = Win32.GetModuleHandleW(null);
        _mouseHookHandle = Win32.SetWindowsHookExW(Win32.WH_MOUSE_LL, _hookProc, hModule, 0);
        _keyboardHookHandle = Win32.SetWindowsHookExW(Win32.WH_KEYBOARD_LL, _hookProc, hModule, 0);

        if (_mouseHookHandle == IntPtr.Zero || _keyboardHookHandle == IntPtr.Zero)
        {
            DebugLogger.Error(
                $"Failed to install hook(s). mouse: {_mouseHookHandle != IntPtr.Zero} " +
                $"keyboard: {_keyboardHookHandle != IntPtr.Zero} GetLastError: {Marshal.GetLastWin32Error()}");
            MessageBox.Show(
                "Failed to install mouse/keyboard hook.\n\nThis usually means another app has registered the same hook.",
                "WindowMover", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
        else
        {
            DebugLogger.Info(
                $"Hooks installed. mouse: {_mouseHookHandle:X8} keyboard: {_keyboardHookHandle:X8}");
        }
    }

    /// <summary>
    /// Shared low-level hook callback for both WH_MOUSE_LL and WH_KEYBOARD_LL.
    /// Returning a nonzero IntPtr swallows the event.
    /// </summary>
    private IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam)
    {
        int msg = wParam.ToInt32();
        bool isKeyboardMsg = msg is Win32.WM_KEYDOWN or Win32.WM_KEYUP or Win32.WM_SYSKEYDOWN or Win32.WM_SYSKEYUP;
        IntPtr hookHandle = isKeyboardMsg ? _keyboardHookHandle : _mouseHookHandle;

        if (nCode < 0)
            return Win32.CallNextHookEx(hookHandle, nCode, wParam, lParam);

        bool swallow = false;

        switch (msg)
        {
            case Win32.WM_LBUTTONDOWN:
                swallow = OnMouseDown(MouseButton.Left, Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam));
                break;
            case Win32.WM_RBUTTONDOWN:
                swallow = OnMouseDown(MouseButton.Right, Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam));
                break;
            case Win32.WM_MBUTTONDOWN:
                swallow = OnMouseDown(MouseButton.Middle, Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam));
                break;

            case Win32.WM_LBUTTONUP:
                swallow = OnMouseUp(MouseButton.Left, Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam));
                break;
            case Win32.WM_RBUTTONUP:
                swallow = OnMouseUp(MouseButton.Right, Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam));
                break;
            case Win32.WM_MBUTTONUP:
                swallow = OnMouseUp(MouseButton.Middle, Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam));
                break;

            case Win32.WM_MOUSEMOVE:
                OnMouseMove(Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam));
                break;

            case Win32.WM_KEYDOWN:
            case Win32.WM_SYSKEYDOWN:
                swallow = OnKeyDown(Marshal.PtrToStructure<Win32.KBDLLHOOKSTRUCT>(lParam));
                break;

            case Win32.WM_KEYUP:
            case Win32.WM_SYSKEYUP:
                swallow = OnKeyUp(Marshal.PtrToStructure<Win32.KBDLLHOOKSTRUCT>(lParam));
                break;
        }

        if (swallow)
        {
            return (IntPtr)1;
        }

        return Win32.CallNextHookEx(hookHandle, nCode, wParam, lParam);
    }

    /// <summary>
    /// Handle starting move/resize or other actions.
    /// </summary>
    /// <returns>true if the event should be swallowed (an action was actually taken)</returns>
    private bool OnMouseDown(MouseButton button, Win32.MSLLHOOKSTRUCT mouse)
    {
        if (Win32.IsDummyInput(mouse))
        {
            return false;
        }

        if (!IsWinDown() || _drag.IsActive)
            return false;

        bool actionHandled = false;
        if (button == MouseButton.Right && IsKeyDown(Win32.VK_MENU))
        {
            DebugLogger.Info("> Minimizing");
            actionHandled = Minimize();
        }
        else if (button == MouseButton.Right && IsKeyDown(Win32.VK_CONTROL))
        {
            DebugLogger.Info("> Closing");
            actionHandled = CloseWindow();
        }
        else if (button == MouseButton.Middle)
        {
            DebugLogger.Info("> Toggling maximize");
            actionHandled = ToggleMaximize();
        }

        if (actionHandled)
        {
            MarkWinKeyUsed();
            _activeMouseDowns.Add(button);
            return true;
        }

        Win32.GetCursorPos(out var pt);
        IntPtr hWnd = RootWindowFromPoint(pt);
        DebugLogger.DumpWindow("Drag start cursor", hWnd);

        switch (button)
        {
            case MouseButton.Left:
                TryStartMoveDrag(hWnd, pt);
                break;
            case MouseButton.Right:
                TryStartResizeDrag(hWnd, pt);
                break;
        }

        return true;
    }

    private bool OnMouseUp(MouseButton button, Win32.MSLLHOOKSTRUCT mouse)
    {
        if (Win32.IsDummyInput(mouse))
        {
            return false;
        }

        bool handled = false;

        if (_drag.IsActive)
        {
            DebugLogger.Info($"{button} release - ending drag session");

            // We own termination now (see StopNativeDrag) rather than relying on
            // the real physical up-event reaching the target, so it's safe - and
            // necessary for the Win+RMB resize case - to swallow this.
            StopNativeDrag(_drag.Target, _drag.HitTestVal);
            _drag.Clear();

            handled = true;
        }

        // swallow any mouse-ups for matching mouse-downs
        if (_activeMouseDowns.Contains(button))
        {
            DebugLogger.Info($"{button} release - consumed");
            _activeMouseDowns.Remove(button);
            handled = true;
        }

        return handled;
    }

    private bool OnMouseMove(Win32.MSLLHOOKSTRUCT mouse)
    {
        if (!_drag.IsActive || _drag.Target == IntPtr.Zero || _drag.Type != DragType.Move) return false;

        // handle drag moves directly with SetWindowPos
        // (resize is done by handing off input to the window)

        // update current pos so we can toggle snapping even without mouse movement
        _drag.CurrentPos = mouse.pt;

        UpdateDraggedWindowPos();

        return true;
    }

    private bool OnKeyDown(Win32.KBDLLHOOKSTRUCT kb)
    {
        // ignore any synthetic keystrokes we injected
        if (Win32.IsDummyInput(kb)) return false;

        // refresh dragged window pos when shift (snapping) changes
        if (_drag is { IsActive: true, Type: DragType.Move } &&
            kb.vkCode is Win32.VK_LSHIFT or Win32.VK_RSHIFT)
        {
            _drag.ShouldSnap = true;
            UpdateDraggedWindowPos();
        }

        return false;
    }

    private bool OnKeyUp(Win32.KBDLLHOOKSTRUCT kb)
    {
        if (Win32.IsDummyInput(kb)) return false;

        // refresh dragged window pos when shift (snapping) changes
        if (_drag is { IsActive: true, Type: DragType.Move } &&
            kb.vkCode is Win32.VK_LSHIFT or Win32.VK_RSHIFT)
        {
            _drag.ShouldSnap = false;
            UpdateDraggedWindowPos();
        }

        if (kb.vkCode is Win32.VK_LWIN or Win32.VK_RWIN && _usedWinKey)
        {
            if (_usedWinKey)
            {
                // don't swallow Win up (so key state doesn't break), but suppress
                // start menu from showing by injecting a fake tap of the Ctrl key
                Win32.SuppressStartMenu();
            }

            DebugLogger.Info($"Win key release (used: {_usedWinKey})");
            _usedWinKey = false;
        }

        return false;
    }

    /// <summary>
    /// Marks the Win key as "used" for the current hold.
    /// </summary>
    private void MarkWinKeyUsed()
    {
        if (_usedWinKey) return;
        _usedWinKey = true;
        DebugLogger.Info("Win key used for an action - suppressing Start Menu trigger");
    }

    // Move (Win+LButton)
    private bool TryStartMoveDrag(IntPtr hWnd, Win32.POINT pt)
    {
        if (!CanModifyWin(hWnd))
        {
            DebugLogger.Info("TryStartMoveDrag: CanModifyWin = false");
            return false;
        }

        Win32.GetWindowRect(hWnd, out var rect);
        _drag.InitRect = new Rectangle(rect.Left, rect.Top, rect.Width, rect.Height);
        DebugLogger.Info(
            $"TryStartMoveDrag: pt: ({pt.X}, {pt.Y}), rect: ({rect.Left},{rect.Top}) {rect.Width}x{rect.Height}");

        StartMoveDrag(pt);
        return true;
    }

    private void StartMoveDrag(Win32.POINT pt)
    {
        IntPtr hWnd = RootWindowFromPoint(pt);
        DebugLogger.Info($"> Starting move drag: hWnd: {hWnd:X8}");

        _drag.IsActive = true;
        _drag.Type = DragType.Move;
        _drag.Target = hWnd;
        _drag.StartPos = pt;
        _drag.CurrentPos = pt;
        _drag.ShouldSnap = IsKeyDown(Win32.VK_SHIFT);
        MarkWinKeyUsed();

        FocusWindowForDrag(hWnd);

        // use SetWindowPos instead of relying on the target window here,
        // trying to spoof HTCAPTION mouse input is not as reliable as it is for resize.
        // This also lets us move unmovable-windows in rare but useful situations.
    }

    /// <summary>
    /// Update the current position of the dragged window, applying snapping if necessary.
    /// </summary>
    private void UpdateDraggedWindowPos()
    {
        int deltaX = _drag.CurrentPos.X - _drag.StartPos.X;
        int deltaY = _drag.CurrentPos.Y - _drag.StartPos.Y;

        Rectangle newRect = _drag.InitRect with { X = _drag.InitRect.Left + deltaX, Y = _drag.InitRect.Top + deltaY };

        if (_drag.ShouldSnap)
        {
            SnapToEdges(ref newRect);
        }

        Win32.SetWindowPos(_drag.Target, IntPtr.Zero,
            newRect.Left, newRect.Top,
            newRect.Width, newRect.Height,
            Win32.SWP_NOACTIVATE | Win32.SWP_NOZORDER);
    }

    /// <summary>
    /// Start a window resize if possible
    /// </summary>
    private bool TryStartResizeDrag(IntPtr hWnd, Win32.POINT pt)
    {
        if (!CanModifyWin(hWnd))
        {
            DebugLogger.Warn("DetectResize: CanModifyWin returned false");
            return false;
        }

        int style = (int)Win32.GetWindowLongPtrW(hWnd, Win32.GWLP_STYLE).ToInt64();
        bool hasFrame = (style & (int)Win32.WS_THICKFRAME) != 0;
        DebugLogger.Info($"DetectResize: WS_THICKFRAME: {hasFrame} style: 0x{style:X8}");

        Win32.GetWindowRect(hWnd, out var rect);
        _drag.InitRect = new Rectangle(rect.Left, rect.Top, rect.Width, rect.Height);
        DebugLogger.Info($"DetectResize: rect: {rect.Left},{rect.Top}) {rect.Width}x{rect.Height}");

        StartResizeDrag(pt);
        return true;
    }

    private void StartResizeDrag(Win32.POINT pt)
    {
        IntPtr hWnd = RootWindowFromPoint(pt);
        _drag.HitTestVal = ComputeResizeHitTest(hWnd, pt);
        DebugLogger.Info($"> Starting drag resize: quadrant hit-test: HT{Hex8(_drag.HitTestVal)} -> hWnd: {hWnd:X8}");

        _drag.IsActive = true;
        _drag.Type = DragType.Resize;
        _drag.Target = hWnd;
        _drag.StartPos = pt;
        MarkWinKeyUsed();

        StartNativeDrag(hWnd, _drag.HitTestVal, pt);
    }

    private static Win32.POINT SnapToEdge(Rectangle rect, int hitTest)
    {
        int x = hitTest is Win32.HTTOPLEFT or Win32.HTBOTTOMLEFT ? rect.Left + 1
            : hitTest is Win32.HTTOPRIGHT or Win32.HTBOTTOMRIGHT ? rect.Right - 1
            : rect.Left + rect.Width / 2;

        int y = hitTest is Win32.HTTOPLEFT or Win32.HTTOPRIGHT
            ? rect.Top + 1
            : rect.Bottom - 1;

        return new Win32.POINT { X = x, Y = y };
    }

    /// <summary>
    /// Simulate a left-mouse drag on a specific hit area of a window,
    /// to let it handle the input natively and respect any movement or size restrictions.
    /// Releases mouse capture (so the target's DefWindowProc doesn't refuse to start dragging).
    /// Uses PostMessage (not SendMessage) - the target's drag loop blocks ITS OWN
    /// thread until release, and SendMessage would block ours (the global mouse hook)
    /// for that whole time, stalling input system-wide.
    /// </summary>
    private void StartNativeDrag(IntPtr hWnd, int hitTest, Win32.POINT pt)
    {
        FocusWindowForDrag(hWnd);
        Win32.ReleaseCapture();

        // Some apps re-derive their own hit test from these coordinates instead
        // of trusting wParam, so the point needs to genuinely sit on the border for
        // the desired edge/corner - not just "somewhere in the right quadrant".
        var edgePt = SnapToEdge(_drag.InitRect, hitTest);
        DebugLogger.Info($"posting LBUTTONDOWN at {edgePt} (snapped from {pt})");
        int lparam = (edgePt.X & 0xFFFF) | ((edgePt.Y & 0xFFFF) << 16);

        bool posted = Win32.PostMessageW(hWnd, Win32.WM_NCLBUTTONDOWN, (IntPtr)hitTest, (IntPtr)lparam);
        DebugLogger.Info($"native drag posted: {posted} hitTest: HT{hitTest:X} lParam: 0x{lparam:X8}");
    }

    /// <summary>
    /// Restore (if maximized), bring to front, and give keyboard focus to the target window.
    /// </summary>
    public void FocusWindowForDrag(IntPtr hWnd)
    {
        if (IsZoomed(hWnd))
        {
            Win32.ShowWindow(hWnd, Win32.SW_RESTORE);

            // preserve pre-restore size to make the transition feel seamless
            if (_drag.Target == hWnd)
            {
                Win32.SetWindowPos(hWnd, IntPtr.Zero,
                    _drag.InitRect.Left, _drag.InitRect.Top,
                    _drag.InitRect.Width, _drag.InitRect.Height,
                    Win32.SWP_NOACTIVATE | Win32.SWP_NOZORDER);
            }
        }

        if (Win32.SetForegroundWindow(hWnd))
        {
            Win32.SetFocus(hWnd);
        }
    }

    /// <summary>
    /// End the current drag, sending left-mouse-up events as needed (regardless of
    /// whether the left-mouse was the real button that started the drag).
    /// </summary>
    private static void StopNativeDrag(IntPtr hWnd, int hitTest)
    {
        if (hWnd == IntPtr.Zero) return;

        Win32.GetCursorPos(out var pt);
        int lparam = (pt.X & 0xFFFF) | ((pt.Y & 0xFFFF) << 16);

        // Pin the target's last-known tracking position to the release point first,
        // so a straggling real WM_MOUSEMOVE can't land after our up-message and
        // leave the loop waiting on stale position data. Both are PostMessage to a
        // specific HWND - this never touches the low-level hook chain or the RIT,
        // so unlike SendInput it can't deadlock the input subsystem, and unlike
        // SendMessage it can't block us waiting on the target's modal loop.
        Win32.PostMessageW(hWnd, (uint)Win32.WM_MOUSEMOVE, IntPtr.Zero, (IntPtr)lparam);
        Win32.PostMessageW(hWnd, Win32.WM_LBUTTONUP, (IntPtr)hitTest, (IntPtr)lparam);

        // as a fallback, send cancel mode to ensure the drag is abandoned if the
        // above "release mouse button" spoof doesn't work. This can happen rarely when
        // tapping right mouse quickly while moving.
        Win32.PostMessageW(hWnd, Win32.WM_CANCELMODE, IntPtr.Zero, IntPtr.Zero);

        DebugLogger.Info($"native drag stop posted, hitTest: HT{hitTest:X} lParam: 0x{lparam:X8}");
    }

    /// <summary>
    /// Toggle maximize/restore on the target window.
    /// </summary>
    /// <returns>True if the window was toggled</returns>
    private bool ToggleMaximize()
    {
        IntPtr hWnd = GetTargetWindow();
        if (!CanModifyWin(hWnd)) return false;
        DebugLogger.Info($"ToggleMaximize: hWnd: {hWnd:X8} isZoomed: {IsZoomed(hWnd)}");
        Win32.ShowWindow(hWnd, IsZoomed(hWnd) ? Win32.SW_RESTORE : Win32.SW_MAXIMIZE);
        return true;
    }

    /// <summary>
    /// Minimize the target window
    /// </summary>
    /// <returns>True if the window was minimized</returns>
    private bool Minimize()
    {
        IntPtr hWnd = GetTargetWindow();
        if (!CanModifyWin(hWnd)) return false;
        DebugLogger.Info($"Minimize: hWnd: {hWnd:X8}");
        Win32.ShowWindow(hWnd, Win32.SW_MINIMIZE);
        return true;
    }

    /// <summary>
    /// Close the target window
    /// </summary>
    /// <returns>True if the window was closed</returns>
    private bool CloseWindow()
    {
        IntPtr hWnd = GetTargetWindow();
        if (!CanModifyWin(hWnd)) return false;
        DebugLogger.Info($"Close: hWnd: {hWnd:X8}");
        // PostMessage, not SendMessage: closing may pop a "save changes?" dialog,
        // which would otherwise block our hook until the user responds to it.
        Win32.PostMessageW(hWnd, Win32.WM_CLOSE, IntPtr.Zero, IntPtr.Zero);
        return true;
    }

    /// <summary>
    /// Snap a window to the edges of the screen using SetWindowPos
    /// </summary>
    private static void SnapToEdges(ref Rectangle inOutRect)
    {
        Win32.POINT center = new Win32.POINT
        {
            X = inOutRect.Left + inOutRect.Width / 2,
            Y = inOutRect.Top + inOutRect.Height / 2
        };
        IntPtr hMonitor = Win32.MonitorFromPoint(center, Win32.MONITOR_DEFAULTTONEAREST);
        var mi = new Win32.MONITORINFO();
        mi.cbSize = Marshal.SizeOf<Win32.MONITORINFO>();

        if (!Win32.GetMonitorInfoW(hMonitor, ref mi))
        {
            // DebugLogger.Warn($"[SnapToEdges] failed to find monitor for pos: ({center.X},{center.Y}), GetLastError={Marshal.GetLastWin32Error()}");
            return;
        }

        var work = mi.rcWork;
        int snapX = inOutRect.Left, snapY = inOutRect.Top;
        bool hasSnapX = false, hasSnapY = false;

        if (inOutRect.Left - work.Left < SNAP_DISTANCE)
        {
            snapX = work.Left;
            hasSnapX = true;
        }
        else if (work.Right - inOutRect.Right < SNAP_DISTANCE)
        {
            snapX = work.Right - inOutRect.Width;
            hasSnapX = true;
        }

        if (inOutRect.Top - work.Top < SNAP_DISTANCE)
        {
            snapY = work.Top;
            hasSnapY = true;
        }
        else if (work.Bottom - inOutRect.Bottom < SNAP_DISTANCE)
        {
            snapY = work.Bottom - inOutRect.Height;
            hasSnapY = true;
        }

        inOutRect.X = hasSnapX ? snapX : inOutRect.Left;
        inOutRect.Y = hasSnapY ? snapY : inOutRect.Top;
    }

    /// <summary>4-quadrant resize hit-test.</summary>
    private int ComputeResizeHitTest(IntPtr hWnd, Win32.POINT cursorScreen)
    {
        if (!Win32.GetClientRect(hWnd, out var client)) return Win32.HTBOTTOMRIGHT;

        int winLeft = _drag.InitRect.Left;
        int winTop = _drag.InitRect.Top;
        int relX = Math.Max(0, cursorScreen.X - winLeft);
        int relY = Math.Max(0, cursorScreen.Y - winTop);
        int cw = client.Width, ch = client.Height;

        DebugLogger.Info($"resize hit-test: client: ({winLeft},{winTop}) {cw}x{ch} mouseRel: ({relX},{relY})");

        if (cw < 1) cw = 1;
        if (ch < 1) ch = 1;
        int cx = cw / 2, cy = ch / 2;

        bool left = relX < cx;
        bool right = !left;
        bool top = relY < cy;
        bool bottom = !top;

        DebugLogger.Info($"resize hit-test: quadrant L: {left} R: {right} T: {top} B: {bottom}");

        return top
            ? (left ? Win32.HTTOPLEFT : Win32.HTTOPRIGHT)
            : (left ? Win32.HTBOTTOMLEFT : Win32.HTBOTTOMRIGHT);
    }

    // Helpers

    private static bool IsKeyDown(byte vk) => (Win32.GetAsyncKeyState(vk) & 0x8000) != 0;

    private static bool IsWinDown() => IsKeyDown(Win32.VK_LWIN) || IsKeyDown(Win32.VK_RWIN);

    /// <summary>
    /// Walk up to the root from WindowFromPoint to get the real top-level window.
    /// </summary>
    private static IntPtr RootWindowFromPoint(Win32.POINT pt)
    {
        IntPtr hWnd = Win32.WindowFromPoint(pt);
        return hWnd == IntPtr.Zero ? hWnd : Win32.GetAncestor(hWnd, Win32.GA_ROOT);
    }

    private IntPtr GetTargetWindow()
    {
        Win32.GetCursorPos(out var pt);
        IntPtr hWnd = RootWindowFromPoint(pt);
        DebugLogger.Info($"target window: ({pt.X},{pt.Y}) -> hWnd: {hWnd:X8}");
        return hWnd;
    }

    private bool IsZoomed(IntPtr hWnd) => Win32.IsZoomed(hWnd);

    private bool CanModifyWin(IntPtr hWnd)
    {
        if (hWnd == IntPtr.Zero) return false;

        var sb = new StringBuilder(256);
        Win32.GetClassNameW(hWnd, sb, sb.Capacity);
        string winClass = sb.ToString();
        DebugLogger.Info($"can modify: class: \"{winClass}\"");

        if (winClass.Equals("Progman", StringComparison.OrdinalIgnoreCase)) return false;
        if (winClass.Equals("WorkerW", StringComparison.OrdinalIgnoreCase)) return false;
        if (winClass.Equals("XamlExplorerHostIslandWindow", StringComparison.OrdinalIgnoreCase)) return false;
        return true;
    }

    private string Hex8(int val) => $"0x{val:X8}";

    /// <summary>Load app.ico from the output directory next to the exe.</summary>
    private static Icon LoadAppIcon()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "app.ico");
        return File.Exists(path) ? new Icon(path) : SystemIcons.Shield;
    }

    // Cleanup
    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        DebugLogger.Info("shutting down");
        base.OnFormClosing(e);
        if (_mouseHookHandle != IntPtr.Zero) Win32.UnhookWindowsHookEx(_mouseHookHandle);
        if (_keyboardHookHandle != IntPtr.Zero) Win32.UnhookWindowsHookEx(_keyboardHookHandle);
        _trayIcon?.Dispose();
        DebugLogger.Info("WindowMover shut down");
    }
}