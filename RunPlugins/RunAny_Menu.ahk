#Requires Autohotkey v2.0
#Warn Unreachable, Off
/*
【RunAny菜单辅助插件（建议自启）】
*/
global RunAny_Plugins_Version:="2.0.5"
; V1toV2: Removed #NoEnv                  ;~不检查空变量为环境变量
#NoTrayIcon             ;~不显示托盘图标
Persistent             ;~让脚本持久运行
#SingleInstance Force   ;~运行替换旧实例
ListLines(false)           ;~不显示最近执行的脚本行
SendMode("Input")          ;~使用更速度和可靠方式发送键鼠点击
DetectHiddenWindows(true)

;[RunAny菜单透明化]
GroupAdd("menuApp", "ahk_exe RunAny.exe")
;[桌面右键菜单透明化]
GroupAdd("menuApp", "ahk_exe explorer.exe")
GroupAdd("menuApp", "ahk_exe DesktopMgr64.exe")

;GroupAdd,menuApp,ahk_exe AutoHotkey.exe  ;如果使用AHK运行RunAny 打开此注释

;（0-255）[0全透明-255完全不透明程度]
透明度:=Var_Read("RunAnyMenuTransparent",225)

;[想要关闭菜单透明化，可以注释掉下面这行定时器]
SetTimer(Transparent_Show,10)

return

;循环等待菜单显示
Transparent_Show:
Transparent_Show()
return

#HotIf WinActive("ahk_exe RunAny.exe") ;|| WinActive("ahk_exe AutoHotkey.exe")  ;如果使用AHK运行RunAny 打开此注释

~RButton Up::HK1_RButton_Up()
return

~Space Up::HK2_Space_Up()
return

~MButton Up::HK3_MButton_Up()
return

~XButton1 Up::HK4_XButton1_Up()
return

~XButton2 Up::HK5_XButton2_Up()
return

#HotIf

MenuClick(buttonRun){
	HoldKeyList:=map("HoldCtrlRun", 2, "HoldCtrlShiftRun", 3, "HoldCtrlWinRun", 4, "HoldShiftRun", 5, "HoldShiftWinRun", 6, "HoldCtrlShiftWinRun", 7)
	HoldKeyValList:={HoldCtrlRun:2,HoldCtrlShiftRun:3,HoldCtrlWinRun:11,HoldShiftRun:5,HoldShiftWinRun:31,HoldCtrlShiftWinRun:4}
	for k, v in HoldKeyList
	{
		j:=Var_Read(k,HoldKeyValList[k])
		if(j=buttonRun){
			if(v=2){
				SendInput("{Ctrl Down}")
				Click()
				SendInput("{Ctrl Up}")
			}else if(v=3){
				SendInput("{Ctrl Down}{Shift Down}")
				Click()
				SendInput("{Ctrl Up}{Shift Up}")
			}else if(v=4){
				SendInput("{Ctrl Down}{LWin Down}")
				Click()
				SendInput("{Ctrl Up}{LWin Up}")
			}else if(v=5){
				SendInput("{Shift Down}")
				Click()
				SendInput("{Shift Up}")
			}else if(v=6){
				SendInput("{Shift Down}{LWin Down}")
				Click()
				SendInput("{Shift Up}{LWin Up}")
			}else if(v=7){
				SendInput("{Ctrl Down}{Shift Down}{LWin Down}")
				Click()
				SendInput("{Ctrl Up}{Shift Up}{LWin Up}")
			}
		}
	}
}
Var_Read(rValue,defVar:=""){
	if(FileExist(A_ScriptDir "\..\RunAnyConfig.ini")){
		regVar := IniRead(A_ScriptDir "\..\RunAnyConfig.ini", "Config", rValue, defVar ? defVar : A_Space)
	}
	return regVar!="" ? regVar: defVar
}

;###############  V1toV2 FUNCS  ###############
Transparent_Show() { ; V1toV2: Lbl->Func
	global
	if(WinActive("ahk_group menuApp") && A_TimeIdle<1000 && WinExist("ahk_class #32768")){
		try WinSetTransparent(透明度, "ahk_class #32768")
	}
return
}
;##############################################
HK1_RButton_Up() { ; V1toV2: HK->Func
	global
	try WinWait("ahk_class #32768", , 1)
	catch
		return
	MenuClick(Var_Read("RunAnyMenuRButtonRun",5))
return
}
;##############################################
HK2_Space_Up() { ; V1toV2: HK->Func
	global
	try WinWait("ahk_class #32768", , 1)
	catch
		return
	MenuClick(Var_Read("RunAnyMenuSpaceRun",2))
return
}
;##############################################
HK3_MButton_Up() { ; V1toV2: HK->Func
	global
	try WinWait("ahk_class #32768", , 1)
	catch
		return
	MenuClick(Var_Read("RunAnyMenuMButtonRun",0))
return
}
;##############################################
HK4_XButton1_Up() { ; V1toV2: HK->Func
	global
	try WinWait("ahk_class #32768", , 1)
	catch
		return
	MenuClick(Var_Read("RunAnyMenuXButton1Run",0))
return
}
;##############################################
HK5_XButton2_Up() { ; V1toV2: HK->Func
	global
	try WinWait("ahk_class #32768", , 1)
	catch
		return
	MenuClick(Var_Read("RunAnyMenuXButton2Run",0))
return
}