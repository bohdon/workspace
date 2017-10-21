


; Recommended for performance and compatibility with future AutoHotkey releases.
#NoEnv
; Enable warnings to assist with detecting common errors.
#Warn
; Prevent multiple instances of this script from running
#SingleInstance force
; Recommended for new scripts due to its superior speed and reliability.
SendMode Input
; Ensures a consistent starting directory.
SetWorkingDir %A_ScriptDir%



#Space::
RunOrToggleMinimized("ahk_exe Velocity.exe", "Velocity")
return


; Runs or toggles the minimized state of a window
RunOrToggleMinimized(WinTitle, Target) {
	IfWinExist, %WinTitle%
	{
		IfWinActive, %WinTitle%
		{
			WinMinimize, %WinTitle%
		}
		else
		{
			WinActivate, %WinTitle%
		}
	}
	else
	{
		Run, %Target%
	}
}