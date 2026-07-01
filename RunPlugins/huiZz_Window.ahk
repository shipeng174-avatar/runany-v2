#Requires Autohotkey v2.0
;************************
;* 【ObjReg窗口操作脚本】 
;*             by hui-Zz 
;************************
global RunAny_Plugins_Name:="ObjReg窗口操作脚本"
global RunAny_Plugins_Version:="1.1.3"
global RunAny_Plugins_Icon:="SHELL32.dll,241"
; V1toV2: Removed #NoEnv                  ;~不检查空变量为环境变量
#NoTrayIcon             ;~不显示托盘图标
Persistent             ;~让脚本持久运行
#SingleInstance Force   ;~运行替换旧实例
ListLines(false)           ;~不显示最近执行的脚本行
SendMode("Input")          ;~使用更速度和可靠方式发送键鼠点击
; V1toV2: Removed SetBatchLines,-1        ;~脚本全速执行(默认10ms)
SetControlDelay(0)       ;~控件修改命令自动延时(默认20)
SetWinDelay(0)           ;~执行窗口命令自动延时(默认100)
SetTitleMatchMode(2)     ;~窗口标题模糊匹配
CoordMode("Menu", "Window")   ;~坐标相对活动窗口
;WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
#Include RunAny_ObjReg.ahk

global winTopList:=[]
global winBottomList:=[]

class RunAnyObj {
	;[窗口居中]
	win_center_zz(){
		zTitle := WinGetTitle("A")
WinGetPos(&var_x, &var_y, &var_width, &var_height, "A")
		WinGetPos(, , , &h, "ahk_class Shell_TrayWnd")
		h:=(h>=A_ScreenHeight) ? 0 : h
		WinMove((A_ScreenWidth-var_width)/2, (A_ScreenHeight-var_height-h)/2, , , zTitle)
	}
	;[窗口移动]
	win_move_zz(var_x,var_y){
		WinMove(var_x, var_y, , , "A")
	}
	;[窗口改变大小]
	win_size_zz(var_width,var_height){
		WinRestore("A")
		WinMove(, , var_width, var_height, "A")
	}
	;[窗口改变大小并移动]
	win_move_size_zz(var_x,var_y,var_width,var_height){
		WinRestore("A")
		WinMove(var_x, var_y, var_width, var_height, "A")
	}
	;[窗口置顶]
	win_top_zz(t:=""){
		global winTopList
		winId:=WinExist("A")
		if(t=1 || !winTopList[winId]){
			if(WinActive("ahk_class CabinetWClass")){
				WinSetAlwaysOnTop(1, "ahk_class CabinetWClass")
			}
			WinSetAlwaysOnTop(1, "ahk_id " winId)
			winTopList[winId]:=True ;  V1toV2: Invalid Index errors?, try 'winTopList.Push(<val>)' ;  V1toV2: Invalid Index errors?, try 'winTopList.Push(<val>)'
		}else if(t=0 || winTopList[winId]){
			WinSetAlwaysOnTop(0, "ahk_id " winId)
			winTopList[winId]:=False ;  V1toV2: Invalid Index errors?, try 'winTopList.Push(<val>)' ;  V1toV2: Invalid Index errors?, try 'winTopList.Push(<val>)'
		}
	}
	;[窗口置底]
	win_bottom_zz(t:="",w:="ahk_class Progman"){
		global winBottomList
		Child_ID:=WinExist("A")
		if(t=1 || !winBottomList[Child_ID]){
			Desktop_ID := WinGetID(w)
			DllCall("SetParent", "uint", Child_ID, "uint", Desktop_ID)
			winBottomList[Child_ID]:=True ;  V1toV2: Invalid Index errors?, try 'winBottomList.Push(<val>)' ;  V1toV2: Invalid Index errors?, try 'winBottomList.Push(<val>)'
		}else if(t=0 || winBottomList[Child_ID]){
			DllCall("User32\SetParent", "Ptr", Child_ID, "Ptr", 0)
			winBottomList[Child_ID]:=False ;  V1toV2: Invalid Index errors?, try 'winBottomList.Push(<val>)' ;  V1toV2: Invalid Index errors?, try 'winBottomList.Push(<val>)'
		}
	}
	;[窗口改变大小移至边角置顶观影] v1.0.9
	;参数说明：
	;mode：1-左上,2-右上,3-左下,4-右下
	;x：正数向左偏移像素，负数向右偏移像素
	;y：正数向下偏移像素，负数向上偏移像素
	;title：0-显示标题栏，1-隐藏标题栏
	;w：改变窗口宽度
	;h：改变窗口高度
	win_movie_zz(mode:=1,x:=0,y:=0,title:=0,w:=0,h:=0){
		WinRestore("A")
		zTitle := WinGetTitle("A")
WinGetPos(&var_x, &var_y, &var_width, &var_height, "A")
		WinSetAlwaysOnTop(1, "A")  ;开启置顶
		if(title)
			WinSetStyle(-12582912, "A")
		else
			WinSetStyle(12582912, "A")
		var_width:=w=0 ? var_width : w
		var_height:=h=0 ? var_height : h
		if(mode=1){
			var_x:=0
			var_y:=0
		}else if(mode=2){
			var_x:=A_ScreenWidth-var_width
			var_y:=0
		}else if(mode=3){
			var_x:=0
			var_y:=A_ScreenHeight-var_height
		}else if(mode=4){
			var_x:=A_ScreenWidth-var_width
			var_y:=A_ScreenHeight-var_height
		}
		WinMove(var_x + x, var_y + y, var_width, var_height, zTitle)
	}
	;[窗口透明度]
	win_transparency_zz(flag := 1,amount := 10)
	{
		ActiveTitle := WinGetTitle("A")
		static t := 255
		If(flag=0)
			tmp := t + amount
		else if(flag=1)
			tmp := t - amount
		If(tmp > 255)
			tmp := 255
		else if(tmp < 0)
			tmp := 0
		WinSetTransparent(tmp, ActiveTitle)
		ToolTip("当前透明度:" tmp)
		Sleep(1000)
		ToolTip()
		t := tmp
	}
	;[窗口置顶时设置透明，第二次还原]
	win_transparent_top_zz(){
		#SuspendExempt
		global nhwnd
		temp := WinGetExStyle("A")
		if(temp & 0x8){  ; 0x8 表示 WS_EX_TOPMOST.
			;这个分支是当前激活窗口是置顶窗口
			SetTimer(transparEnter,0) ;关闭时钟
			WinSetAlwaysOnTop(0, "A") ;关闭置顶
			;关闭窗口置顶后取消窗口透明
			WinSetTransparent(255, "A") ;帮助中说,先设置255会让透明关闭的比较稳定
			WinSetTransparent("off", "A")
			nhwnd:=""
		}else{
			;这个分支是当前激活窗口不是置顶窗口,这时什么也不做
			WinSetAlwaysOnTop(1, "A")  ;开启置顶
			SetTimer(transparEnter,250)
			MouseGetPos(, , &nhwnd)
		}
		transparEnter: ;当前置顶窗口执行透明子程序
			temp := WinGetExStyle("A") ;获取当前激活窗口是否置顶状态
			if(temp & 0x8){  ; 0x8 表示 WS_EX_TOPMOST.
				;这个分支是当前激活窗口是置顶窗口,如果当前置顶窗口获取焦点了则取消透明
				TransparEnter := WinGetTransparent("A")
				if(TransparEnter != 255){
					WinSetTransparent(255, "A")
				}
			}else{
				;这个分支是当前激活窗口不是置顶窗口,这时设置置顶的那个窗口透明
				WinSetTransparent(128, "ahk_id " nhwnd)
				;MsgBox,%nhwnd%
			}
		return
	}
	;[窗口最大化并隐藏标题栏，第二次还原]
	win_max_zz(){
		MouseGetPos(, , &wh)
		zW := WinGetMinMax("ahk_id " wh)
		if (zW = 1)
		{
			WinRestore("ahk_id " wh)
			WinSetStyle(12582912, "ahk_id " wh)
		}else{
			WinMaximize("ahk_id " wh)
			WinSetStyle(-12582912, "ahk_id " wh)
		}
		return
	}
	;[多屏窗口最大化]
	win_max_max(){
		VirtualWidth := SysGet(78)
		VirtualHeight := SysGet(79)
		WinMove(0, 0, VirtualWidth, VirtualHeight, "A")
	}
	;[当前窗口关闭] v1.0.4
	win_close_zz(){
		WinClose("A")
	}
	;[当前窗口进程结束] v1.0.4
	win_kill_zz(){
		name := WinGetProcessName("A")
		ProcessClose(name)
	}
	;[当前窗口进程pid结束] v1.0.7
	win_kill_pid_zz(){
		pid := WinGetPID("A")
		ProcessClose(pid)
	}
	;[打开当前窗口进程所在目录] v1.0.6
	;openFolder：填写第三方文件管理器全路径打开文件夹，可选填，特殊写法：%"无路径软件"%
	;openParams：第三方文件管理器的打开参数，可选填
	;资源管理器打开当前窗口目录|huiZz_Window[win_folder_zz]()
	;无路径TotalCommander写法示例：
	;当前窗口目录|huiZz_Window[win_folder_zz](%"Totalcmd64.exe"%, /O /S)
	win_folder_zz(openFolder:="",openParams:=""){
		path := WinGetProcessPath("A")
		if(openFolder){
			if(openParams!="")
				openParams:=A_Space openParams
			Run(openFolder "" openParams "" A_Space "`"" path "`"")
		}else{
			Run("explorer.exe /select," path)
		}
	}

;══════════════════════════大括号以上是RunAny菜单调用的函数══════════════════════════

}

;═══════════════════════════以下是脚本自己调用依赖的函数═══════════════════════════

;独立使用方式
;F1::
	;RunAnyObj.win_center_zz()
;return
