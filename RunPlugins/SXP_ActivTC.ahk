;************************
;* 【启动、激活TC窗口】 *
;************************
global RunAny_Plugins_Version:="1.0.0"
#NoTrayIcon             ;~不显示托盘图标
Persistent             ;~让脚本持久运行
#SingleInstance Force   ;~运行替换旧实例
;WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
#Include RunAny_ObjReg.ahk

!f1::
{ ; V1toV2: Added opening brace for [!f1]
global ; V1toV2: Made function global
    DetectHiddenWindows(true)

    if !WinExist("ahk_class TTOTAL_CMD")

Run("D:\TotalCommander64\TOTALCMD64.EXE")

    Else

if !WinActive("ahk_class TTOTAL_CMD")

WinActivate()

    Else

WinMinimize()

Return
} ; V1toV2: Added closing brace for [!f1]


