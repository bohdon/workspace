#Requires AutoHotkey v2.0
; This disables the alt triggered menubar navigation
; that can get in the way if you press alt accidentally
; without triggering a real hotkey


; Enable warnings to assist with detecting common errors.
#Warn
; Prevent multiple instances of this script from running
#SingleInstance force
; Recommended for new scripts due to its superior speed and reliability.
SendMode("Input")
; Ensures a consistent starting directory.
SetWorkingDir(A_ScriptDir)


~LAlt Up::
{
    OutputDebug("Hello")
    return
}
