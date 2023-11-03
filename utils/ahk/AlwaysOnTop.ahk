#Requires AutoHotkey v2.0
; Allows toggling the always-on-top state of the active window.

; Hotkeys
;   Win + A - Enable always on top for the active window
;   Win + Shift + A - Disable always on top for the active window

; Enable warnings to assist with detecting common errors.
#Warn
; Prevent multiple instances of the script from running
#SingleInstance force
; https://www.autohotkey.com/docs/v1/lib/SendMode.htm
SendMode("Input")
; Ensures a consistent starting directory.
SetWorkingDir(A_ScriptDir)

; Options

; the duration of tooltips displaying always on top status
TooltipDuration := 800

#A::
{
    ; enable always on top
    WinId := WinGetId("A")
    WinSetAlwaysOnTop(1, WinId)
    CoordMode("Tooltip", "Window")
    ToolTip("Always On Top", 4, 4)
    SetTimer(ClearTooltip, TooltipDuration)
}

#+A::
{
    ; disable always on top
    WinId := WinGetId("A")
    WinSetAlwaysOnTop(0, WinId)
    ToolTip("Normal", 4, 4)
    SetTimer(ClearTooltip, TooltipDuration)
}

ClearTooltip()
{
    Tooltip()
}
