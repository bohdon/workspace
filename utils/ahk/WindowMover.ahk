; Util for easily moving and resizing windows by holding the Win key

; Hotkeys
;   Win-LMB: Move the mouse-active window. Drag anywhere in the window.
;   Win-RMB: Change the size of the mouse-active window. Drag anywhere in the window.
;   Win-MMB: Maximize / restore the mouse-active window.
;   Win-Alt-RMB: Minimize the mouse-active window
;   Win-Ctrl-RMB: Close the mouse-active window



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
; Set filename that holds options
optsFile = WindowMover.ini


; Setup Options File
; ------------------
IniRead, SnapDistance, %optsFile%, Options, SnapDistance, 100
IniWrite, %SnapDistance%, %optsFile%, Options, SnapDistance

IniRead, WinDelay, %optsFile%, Options, WinDelay, 10
IniWrite, %WinDelay%, %optsFile%, Options, WinDelay

SetWinDelay, %WinDelay%

; End of Initial Setup
return




; Globally Used Functions
; -----------------------
Min(A, B)
{
    return A <= B ? A : B
}

Max(A, B)
{
    return A >= B ? A : B
}

GetCurrentScreenBorders(ByRef CurrentScreenLeft, ByRef CurrentScreenRight, ByRef CurrentScreenTop, ByRef CurrentScreenBottom)
{
    ; get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
    MouseGetPos,Mouse_X,Mouse_Y
    SysGet, MonitorCount, MonitorCount
    Loop,  %MonitorCount%
    {
        SysGet, MonitorWorkArea, MonitorWorkArea, %A_Index%
        if (Mouse_X >= MonitorWorkAreaLeft) and (Mouse_X <= MonitorWorkAreaRight) and (Mouse_Y >= MonitorWorkAreaTop) and (Mouse_Y <= MonitorWorkAreaBottom)
        {
            CurrentScreenLeft   := MonitorWorkAreaLeft
            CurrentScreenRight  := MonitorWorkAreaRight
            CurrentScreenTop    := MonitorWorkAreaTop
            CurrentScreenBottom := MonitorWorkAreaBottom
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
return

#MButton::
MouseGetPos,,,mxw_id
IfWinNotActive, ahk_id %mxw_id%
{
    WinActivate, ahk_id %mxw_id%
}
WinGet, mxw_isMax, MinMax, ahk_id %mxw_id%
if mxw_isMax
    WinRestore, ahk_id %mxw_id%
else
    WinMaximize, ahk_id %mxw_id%
return


; Minimize Window
; ---------------
#!RButton Up::
return

#!RButton::
MouseGetPos,,, mnw_id
WinGetClass, mnw_class, ahk_id %mnw_id%
; don't run this on Desktop
if mnw_class not in Progman
    WinMinimize, ahk_id %mnw_id%
return



; Close Window
; ------------
#^RButton Up::
return

#^RButton::
MouseGetPos,,, clw_id
WinGetClass, clw_class, ahk_id %clw_id%
; don't run this on Desktop
if clw_class not in Progman
    WinClose, ahk_id %clw_id%
return



; Move Window
; -----------
#LButton Up::
#+LButton Up::
return

#LButton::
#+LButton::
CoordMode,Mouse,Screen
IfWinActive ahk_class TaskSwitcherWnd
{
    Send {Blind}{LButton}
    return
}

MouseGetPos, mvw_stX, mvw_stY, mvw_id

IfWinNotActive, ahk_id %mvw_id%
{
    WinActivate, ahk_id %mvw_id%
}

WinGetClass, mvw_class, ahk_id %mvw_id%
; don't run this on Desktop
if mvw_class in Progman
    return


WinGet, mvw_isMax, MinMax, ahk_id %mvw_id%
if mvw_isMax
{
    WinRestore, ahk_id %mvw_id%
    ; move start position so that window dragging is centered
    WinGetPos, mvw_stX, mvw_stY, mvw_sizeW, mvw_sizeH, ahk_id %mvw_id%
    mvw_stX := mvw_stX + mvw_sizeW * 0.5
    mvw_stY := mvw_stY + mvw_sizeH * 0.5
}


WinGetPos, mvw_origWinX, mvw_origWinY, mvw_sizeW, mvw_sizeH, ahk_id %mvw_id%
while (GetKeyState("LButton", "P"))
{
    MouseGetPos, mvw_curX, mvw_curY
    mvw_deltaX := mvw_curX - mvw_stX
    mvw_deltaY := mvw_curY - mvw_stY
    mvw_targetX := (mvw_origWinX + mvw_deltaX)
    mvw_targetY := (mvw_origWinY + mvw_deltaY)

    GetCurrentScreenBorders(scrnLeft, scrnRight, scrnTop, scrnBot)
    if (GetShouldSnap())
    {
        ; keep track of actual distance so we can compare
        ; top to bottom or left to right if they are both
        ; within snap tolerance to determine which is better
        mvw_leftDist := mvw_targetX - scrnLeft
        mvw_topDist := mvw_targetY - scrnTop
        mvw_rightDist := scrnRight - (mvw_targetX + mvw_sizeW)
        mvw_botDist := scrnBot - (mvw_targetY + mvw_sizeH)
        if (mvw_leftDist < SnapDistance)
            mvw_targetX := scrnLeft
        if (mvw_topDist < SnapDistance)
            mvw_targetY := scrnTop
        if (mvw_rightDist < SnapDistance and Abs(mvw_rightDist) < Abs(mvw_leftDist))
            mvw_targetX := scrnRight - mvw_sizeW
        if (mvw_botDist < SnapDistance and Abs(mvw_botDist) < Abs(mvw_topDist))
            mvw_targetY := scrnBot - mvw_sizeH
    }
    WinMove, ahk_id %mvw_id%,, mvw_targetX, mvw_targetY, mvw_sizeW, mvw_sizeH
}
return






; Resize Window
; -------------
#RButton Up::
#+RButton Up::
return

#RButton::
#+RButton::
CoordMode,Mouse,Screen
MouseGetPos, rsw_stX, rsw_stY, rsw_id

WinGetClass, rsw_class, ahk_id %rsw_id%
; don't run this on Desktop
if rsw_class in Progman
    return

WinGet, rsw_isMax, MinMax, ahk_id %rsw_id%
if rsw_isMax
{
    GetCurrentScreenBorders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom)
    WinRestore, ahk_id %rsw_id%
    WinMove, ahk_id %rsw_id%,, CurrentScreenLeft, CurrentScreenTop, CurrentScreenRight - CurrentScreenLeft, CurrentScreenBottom - CurrentScreenTop
}

WinGetPos, rsw_stWinX, rsw_stWinY, rsw_stWinW, rsw_stWinH, ahk_id %rsw_id%

; Get the mouse quadrant within the window
if (rsw_stX < rsw_stWinX + rsw_stWinW / 2)
   rsw_LeftFactor := 1
else
   rsw_LeftFactor := -1
if (rsw_stY < rsw_stWinY + rsw_stWinH / 2)
   rsw_TopFactor := 1
else
   rsw_TopFactor := -1

while (GetKeyState("RButton", "P"))
{
    MouseGetPos, rsw_curX, rsw_curY
    rsw_deltaX := rsw_curX - rsw_stX
    rsw_deltaY := rsw_curY - rsw_stY

    GetCurrentScreenBorders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom)
    
    if (GetShouldSnap())
    {
        rsw_targetX := (rsw_stWinX + (rsw_LeftFactor+1)/2*rsw_deltaX)
        rsw_targetY := (rsw_stWinY + (rsw_TopFactor+1)/2*rsw_deltaY)
        rsw_targetW := (rsw_stWinW - rsw_LeftFactor  *rsw_deltaX)
        rsw_targetH := (rsw_stWinH - rsw_TopFactor  *rsw_deltaY)

        if ((rsw_LeftFactor > 0) and (rsw_targetX < CurrentScreenLeft + SnapDistance)) {
            rsw_targetW := rsw_stWinW + rsw_stWinX - CurrentScreenLeft
            rsw_targetX := CurrentScreenLeft
        }
        if ((rsw_TopFactor > 0) and (rsw_targetY < CurrentScreenTop + SnapDistance)) {
            rsw_targetH := rsw_stWinH + rsw_stWinY - CurrentScreenTop
            rsw_targetY := CurrentScreenTop
        }
        if ((rsw_LeftFactor < 0) and (rsw_targetX + rsw_targetW > CurrentScreenRight - SnapDistance))
            rsw_targetW := - rsw_stWinX + CurrentScreenRight
        if ((rsw_TopFactor < 0) and (rsw_targetY + rsw_targetH > CurrentScreenBottom - SnapDistance))
            rsw_targetH := - rsw_stWinY + CurrentScreenBottom
    }
    else
    {
        rsw_targetX := (rsw_stWinX + (rsw_LeftFactor+1)/2*rsw_deltaX)
        rsw_targetY := (rsw_stWinY + (rsw_TopFactor+1)/2*rsw_deltaY)
        rsw_targetW := (rsw_stWinW - rsw_LeftFactor  *rsw_deltaX)
        rsw_targetH := (rsw_stWinH - rsw_TopFactor  *rsw_deltaY)
    }
    
    WinMove, ahk_id %rsw_id%,, rsw_targetX, rsw_targetY, rsw_targetW, rsw_targetH
}
return

