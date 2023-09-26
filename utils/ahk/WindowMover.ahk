; Utils for moving and resizing windows by holding the Win key
; Author: Bohdon Sayre
; https://github.com/bohdon/workspace

; Hotkeys
;   Win-LMB: Move the mouse-active window. Drag anywhere in the window.
;   Win-RMB: Change the size of the mouse-active window. Drag anywhere in the window.
;   Win-MMB: Maximize / restore the mouse-active window.
;   Win-Alt-RMB: Minimize the mouse-active window
;   Win-Ctrl-RMB: Close the mouse-active window

; See the Options section below, as well as the WindowsMover.ini file for additional settings.


; Enable warnings to assist with detecting common errors.
#Warn
; Prevent multiple instances of the script from running
#SingleInstance force
; https://www.autohotkey.com/docs/v1/lib/SendMode.htm
SendMode("Input")
; Ensures a consistent starting directory.
SetWorkingDir(A_ScriptDir)
; Set filename that holds options
OptionsFile := "WindowMover.ini"


; Options
; -------

; the threshold in pixels for snapping to screen edges when resizing while holding shift
SnapDistance := IniRead(OptionsFile, "Options", "SnapDistance", 100)
IniWrite(SnapDistance, OptionsFile, "Options", "SnapDistance")

; win delay effectively determines how quickly to refresh when dragging windows, etc.
; 0ms ensures that window dragging is smooth even on high refresh rate monitors.
WinDelay := IniRead(OptionsFile, "Options", "WinDelay", 0)
IniWrite(WinDelay, OptionsFile, "Options", "WinDelay")

SetWinDelay(WinDelay)

; whether to activate windows when resizing them, off by default
ActivateOnResize := IniRead(OptionsFile, "Options", "ActivateOnResize", false)
IniWrite(ActivateOnResize, OptionsFile, "Options", "ActivateOnResize")


; End of Initial Setup
return




; Globally Used Functions
; -----------------------
CanModifyWin(WinId)
{
    ; return true if a window is allowed to be moved/minimized/maximized, false otherwise.
    ; handles special windows like the desktop and task switcher to prevent accidental input.

    WinClass := WinGetClass("ahk_id " WinId)

    OutputDebug(WinClass)

    if (WinClass ~= "^(?i:Progman)$" or
        WinClass ~= "^(?i:WorkerW)$" or
        WinClass ~= "^(?i:XamlExplorerHostIslandWindow)$")
    {
        return false
    }

    return true
}

Min(A, B)
{
    return A <= B ? A : B
}

Max(A, B)
{
    return A >= B ? A : B
}

GetCurrentScreenBorders(&ScreenLeft, &ScreenRight, &ScreenTop, &ScreenBot)
{
    ; get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
    MouseGetPos(&MouseX, &MouseY)

    MonitorCount := MonitorGetCount()
    Loop (MonitorCount)
    {
        MonitorGetWorkArea(A_Index, &MonitorWorkAreaLeft, &MonitorWorkAreaTop, &MonitorWorkAreaRight, &MonitorWorkAreaBot)
        if (MouseX >= MonitorWorkAreaLeft) and (MouseX <= MonitorWorkAreaRight) and
            (MouseY >= MonitorWorkAreaTop) and (MouseY <= MonitorWorkAreaBot)
        {
            ScreenLeft := MonitorWorkAreaLeft
            ScreenRight := MonitorWorkAreaRight
            ScreenTop := MonitorWorkAreaTop
            ScreenBot := MonitorWorkAreaBot
            break
        }
    }
}

GetShouldSnap()
{
    return GetKeyState("LShift", "P")
}


; Maximize Window
; ---------------
#MButton Up::
{
}

#MButton::
{
    MouseGetPos(, , &WinId)

    if (!CanModifyWin(WinId))
    {
        return
    }

    ; activate the window if not already
    if (!WinActive("ahk_id " WinId))
    {
        WinActivate("ahk_id " WinId)
    }

    ; toggle maximized/restored
    if (WinGetMinMax("ahk_id " WinId))
    {
        WinRestore("ahk_id " WinId)
    }
    else
    {
        WinMaximize("ahk_id " WinId)
    }
}


; Minimize Window
; ---------------
#!RButton Up::
{
}

#!RButton::
{
    MouseGetPos(, , &WinId)

    if (!CanModifyWin(WinId))
    {
        return
    }

    WinMinimize("ahk_id " WinId)
}



; Close Window
; ------------
#^RButton Up::
{
}

#^RButton::
{
    MouseGetPos(, , &WinId)

    if (!CanModifyWin(WinId))
    {
        return
    }

    WinClose("ahk_id " WinId)
}



; Move Window
; -----------
#LButton Up::
#+LButton Up::
{
}

#LButton::
#+LButton::
{
    CoordMode("Mouse", "Screen")

    MouseGetPos(&StartX, &StartY, &WinId)

    if (!CanModifyWin(WinId))
    {
        return
    }

    if (!WinActive("ahk_id " WinId))
    {
        WinActivate("ahk_id " WinId)
    }

    ; restore the window if it's maximized
    if (WinGetMinMax("ahk_id " WinId))
    {
        WinRestore("ahk_id " WinId)
        ; move start position so that window dragging is centered
        WinGetPos(&StartX, &StartY, &WinWidth, &WinHeight, "ahk_id " WinId)
        StartX := StartX + WinWidth * 0.5
        StartY := StartY + WinHeight * 0.5
    }


    WinGetPos(&WinPosX, &WinPosY, &WinWidth, &WinHeight, "ahk_id " WinId)
    while (GetKeyState("LButton", "P"))
    {
        MouseGetPos(&MouseX, &MouseY)
        DeltaX := MouseX - StartX
        DeltaY := MouseY - StartY
        NewPosX := (WinPosX + DeltaX)
        NewPosY := (WinPosY + DeltaY)

        GetCurrentScreenBorders(&ScreenLeft, &ScreenRight, &ScreenTop, &ScreenBot)
        if (GetShouldSnap())
        {
            ; keep track of actual distance so we can compare
            ; top to bottom or left to right if they are both
            ; within snap tolerance to determine which is better
            DistToLeft := NewPosX - ScreenLeft
            DistToTop := NewPosY - ScreenTop
            DistToRight := ScreenRight - (NewPosX + WinWidth)
            DistToBot := ScreenBot - (NewPosY + WinHeight)
            if (DistToLeft < SnapDistance)
                NewPosX := ScreenLeft
            if (DistToTop < SnapDistance)
                NewPosY := ScreenTop
            if (DistToRight < SnapDistance and Abs(DistToRight) < Abs(DistToLeft))
                NewPosX := ScreenRight - WinWidth
            if (DistToBot < SnapDistance and Abs(DistToBot) < Abs(DistToTop))
                NewPosY := ScreenBot - WinHeight
        }
        WinMove(NewPosX, NewPosY, WinWidth, WinHeight, "ahk_id " WinId)
    }
}





; Resize Window
; -------------
#RButton Up::
#+RButton Up::
{
}

#RButton::
#+RButton::
{
    CoordMode("Mouse", "Screen")

    MouseGetPos(&StartX, &StartY, &WinId)

    if (!CanModifyWin(WinId))
    {
        return
    }

    if (ActivateOnResize and !WinActive("ahk_id " WinId))
    {
        WinActivate("ahk_id " WinId)
    }

    ; restore the window if it's maximized
    if (WinGetMinMax("ahk_id " WinId))
    {
        GetCurrentScreenBorders(&ScreenLeft, &ScreenRight, &ScreenTop, &ScreenBot)
        WinRestore("ahk_id " WinId)
        WinMove(ScreenLeft, ScreenTop, ScreenRight - ScreenLeft, ScreenBot - ScreenTop, "ahk_id " WinId)
    }

    WinGetPos(&WinPosX, &WinPosY, &WinWidth, &WinHeight, "ahk_id " WinId)

    ; determine which quadrant the mouse is in, which affects which corner to resize
    if (StartX < WinPosX + WinWidth / 2)
    {
        LeftFactor := 1
    }
    else
    {
        LeftFactor := -1
    }
    if (StartY < WinPosY + WinHeight / 2)
    {
        TopFactor := 1
    }
    else
    {
        TopFactor := -1
    }

    while (GetKeyState("RButton", "P"))
    {
        MouseGetPos(&MouseX, &MouseY)
        DeltaX := MouseX - StartX
        DeltaY := MouseY - StartY

        GetCurrentScreenBorders(&ScreenLeft, &ScreenRight, &ScreenTop, &ScreenBot)

        if (GetShouldSnap())
        {
            NewPosX := (WinPosX + (LeftFactor + 1) / 2 * DeltaX)
            NewPosY := (WinPosY + (TopFactor + 1) / 2 * DeltaY)
            NewWidth := (WinWidth - LeftFactor * DeltaX)
            NewHeight := (WinHeight - TopFactor * DeltaY)

            if ((LeftFactor > 0) and (NewPosX < ScreenLeft + SnapDistance)) {
                NewWidth := WinWidth + WinPosX - ScreenLeft
                NewPosX := ScreenLeft
            }
            if ((TopFactor > 0) and (NewPosY < ScreenTop + SnapDistance)) {
                NewHeight := WinHeight + WinPosY - ScreenTop
                NewPosY := ScreenTop
            }
            if ((LeftFactor < 0) and (NewPosX + NewWidth > ScreenRight - SnapDistance))
                NewWidth := - WinPosX + ScreenRight
            if ((TopFactor < 0) and (NewPosY + NewHeight > ScreenBot - SnapDistance))
                NewHeight := - WinPosY + ScreenBot
        }
        else
        {
            NewPosX := (WinPosX + (LeftFactor + 1) / 2 * DeltaX)
            NewPosY := (WinPosY + (TopFactor + 1) / 2 * DeltaY)
            NewWidth := (WinWidth - LeftFactor * DeltaX)
            NewHeight := (WinHeight - TopFactor * DeltaY)
        }

        WinMove(NewPosX, NewPosY, NewWidth, NewHeight, "ahk_id " WinId)
    }
}
