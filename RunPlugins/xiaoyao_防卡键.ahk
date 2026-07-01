#Requires AutoHotkey v2.0
#Warn Unreachable, Off
;************************
;* 【开启后，即可防止ctrl、Alt、Shift出现后台卡键的情况】
;************************
global RunAny_Plugins_Name := "防止Ctrl/Alt/Shift后台卡键"
#NoTrayIcon ;不显示托盘图标
Persistent ;让脚本持久运行
#SingleInstance Force ;运行替换旧实例
SetTimer(fangkajian,1000)
return
fangkajian:
fangkajian()
return

;###############  V1toV2 FUNCS  ###############
fangkajian() { ; V1toV2: Lbl->Func
    global
    StartTime := A_TickCount
    While GetKeyState("ctrl", "P") or GetKeyState("Shift", "P") or GetKeyState("Alt", "P"){
        If (A_TickCount - StartTime >10000){	;判定超过10秒以上为卡键
            StartTime := A_TickCount
            ;MsgBox, 卡键了！
            SendInput("{Shift up}{Ctrl Up}{Alt up}")
        }
        Sleep(10)
    }
return
}