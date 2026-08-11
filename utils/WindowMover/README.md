# WindowMover

A native C# app that lets you move, resize, maximize, minimize, or close any window with the mouse, using the Win key as
a modifier.

## Hotkeys

| Combo                        | Action                    |
|------------------------------|---------------------------|
| `Win` + Left-drag            | Move window               |
| `Win` + Right-drag           | Resize window             |
| `Win` + Middle-click         | Maximize / restore window |
| `Win` + `Alt` + Right-click  | Minimize window           |
| `Win` + `Ctrl` + Right-click | Close window              |
| Hold `Shift` while moving    | Snap to screen edges      |

## Requirements

- Windows 10 or later
- .NET 8 Desktop Runtime (`net8.0-windows`)

## Running

```
WindowMover.exe [--log <path>]
```

Runs headless in the system tray.

## How it works

- Detection happens in a low-level mouse hook (`WH_MOUSE_LL`)
- Move/resize is handled by Windows' native drag loop - this ensures size restrictions (like Terminal snapping to cell
  sizes) is respected.
- `PostMessage`, never `SendMessage`, for cross-process calls. The target window's drag loop (or a "save changes?"
  dialog on close) blocks _its own_ thread until the user finishes. `SendMessage` blocks the _caller_ as well, which
  would stall the whole system for a global input hook.
- Successful actions swallow the triggering click so the window under the cursor doesn't also receive the raw click.
  Failed detections (`Win`+click on the desktop) pass the click through untouched.
- Some windows are excluded from all actions (`Progman`, `WorkerW`, `XamlExplorerHostIslandWindow`) to avoid grabbing
  desktop/shell surfaces.
- Use `--log <path>` for file logging (off by default)

## Build

```bash
cd utils/ahk/WindowMover
dotnet publish -c Release --self-contained false
```
