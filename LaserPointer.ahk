#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#include %A_ScriptDir%/data/AHKHID.ahk
global WaitLength := 100
global Strokes := 0
Menu, Tray, Icon, %A_ScriptDir%/data/lasrp.ico
Gui,+AlwaysOnTop
Gui, 1:Add, Text, x2 y3 w60 h20 , Laserpointer
Gui, 1:Add, Text, x107 y3 w20 h20 , ms
Gui, 1:Add, Button, x127 y1 w50 h20 , ON
Gui, 1:Add, Button, x127 y1 w50 h20 Hidden, OFF
Gui, 1:Add, Edit, x62 y1 w40 h20 vWaitLength gWaitLengthOK, %WaitLength%
Gui, 1:Show, x467 y368 h22 w180, LaserPointer
GuiControl, Hide, ButtonOFF


	global isOn := 0
	global PEN_NOT_HOVERING := 0x0 ; Pen is moved away from screen.
	global PEN_HOVERING := 0x1 ; Pen is hovering above screen.
	global PEN_TOUCHING := 0x3 ; Pen is touching screen.
	global PEN_2ND_BTN_HOVERING := 0x5 ; 2nd button is pressed.
	
	PenCallback(input, lastInput) {
		if (input = PEN_HOVERING And lastInput = PEN_TOUCHING And isOn) {
			Strokes ++
			SetTimer, Undo, %WaitLength%, On
		}
		
		if (input = PEN_TOUCHING And lastInput = PEN_HOVERING And isOn) {
			SetTimer, Undo, Off
		}
	}
	

	
	WM_INPUT := 0xFF
	USAGE_PAGE := 13
	USAGE := 2
	
	AHKHID_UseConstants()
	AHKHID_AddRegister(1)
	AHKHID_AddRegister(USAGE_PAGE, USAGE, A_ScriptHwnd, RIDEV_INPUTSINK)
	AHKHID_Register()
	
	OnMessage(WM_INPUT, "InputMsg")
	
	InputMsg(wParam, lParam) {
		Local type, inputInfo, inputData, raw, proc
		static lastInput := PEN_NOT_HOVERING
		
		Critical
		
		type := AHKHID_GetInputInfo(lParam, II_DEVTYPE)
		if (type = RIM_TYPEHID) {
			inputData := AHKHID_GetInputData(lParam, uData)
			
			raw := NumGet(uData, 0, "UInt")
			proc := (raw >> 8) & 0x1F
			
			if (proc <> lastInput) {
				PenCallback(proc, lastInput)
				lastInput := proc
			}
		}
	}
	
	return
	
Undo:
	while(Strokes > 0)
	{
		SetTimer, Undo, Off
		MouseGetPos, posX, posY
		ImageSearch, foundX, foundY, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %A_ScriptDir%/data/undo.png
		If(ErrorLevel == 0){
			click, %foundX%, %foundY%
			MouseMove, %posX%, %posY%, 50
		}else{
		;MsgBox, Image not found.
		}
	Strokes --
	Sleep, 50
	}
return


WaitLengthOK:
GuiControlGet, WaitLength
if(Waitlength = "")
{
	Waitlength = 50
}
return


ButtonON:
GuiControl, Hide, ON
GuiControl, Show, OFF
isOn := 1
return

ButtonOFF:
GuiControl, Hide, OFF
GuiControl, Show, ON
isOn := 0
return


GuiClose:
ExitApp
