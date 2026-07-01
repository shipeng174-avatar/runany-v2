#Requires AutoHotkey v2.0
#Include <v2DynGui> ; V1toV2: v2DynGui.ahk in library folder
iniGuiCtrlVars() ; V1toV2: initialize gui ctrl vars
#Warn Unreachable, Off
;*************************************************
;* 【RA搜索框：搜索菜单项，后缀菜单、自定义搜索等】
;*************************************************
global RunAny_Plugins_Name := "RA搜索框：搜索菜单项，后缀菜单、自定义搜索等"
;【使用说明地址】：https://hui-zz.gitee.io/runany/#/plugins/runany-searchbar
;tong
/*1.使用方法：
	1.下载安装【RunAny】 https://hui-zz.gitee.io/runany/#/
	2.在插件管理中将本插件设置为自启，并重启RA，完成第一次使用的初始化
	3.打开RunAny.ini或RunAny2.ini文件，添加以下内容，可自定义快捷键，下列是shift+D开启
		RA搜索框	+d|RunAny_SearchBar[toggle_searchBar]()
		RA搜索框	+d|RunAny_SearchBar[toggle_searchBar](%getZz%)
		上面两个任选一个添加，第二个菜单项可以实现划词搜索
	4.使用3中快捷键开启

  2.使用说明：
	1.加号可移动搜索框
	2.双击候选项可执行
	3.可以选择输入框是否自动填充
	4.可以选择自动填充后禁用输入时间，0代表不禁用
	5.可以选择是否回车自动执行第一个候选项
	6.可以选择是否自动开启大写
	7.可以选择是否记住上次执行内容
	8.可以选择插件配置更改自动重启时间，0代表更改后不重启
	9.可设置输入框出现的位置模式，0代表上次位置，1代表固定位置，2代表鼠标位置
	-----插件配置可通过右键加号打开进行设置-----

  3.快捷键说明：
	1.tab键正序切换功能，右shift逆序切换功能
	2.alt快速选择第1个候选项，alt+1、2、3。。。9分别快速选择第1-9对应候选项
	3.Delete快速清空输入框
	4.上下键快速选择候选项

  4.添加自定义搜索说明：
	1.【RunAny_SearchBar_Custom.ahk】中【Radio_names】添加对应功能名称
	2.【RunAny_SearchBar_Custom.ahk】中【RA_suffix】、【RA_menu】与步骤1中【后缀菜单】、【菜单项】位置对应
	3.【RunAny_SearchBar_Custom.ahk】中【单选框对应功能】中按序号添加对应功能
	-----【RunAny_SearchBar_Custom.ahk】将在第一次运行后自动生成-----
	-----【RunAny_SearchBar_Custom.ahk】可通过右键输入框上方搜索功能项打开-----
	重要：事先声明没有AHK基础不建议自行修改，如出现错误无法解决，请删除RunAny_SearchBar_Custom.ahk，将会自动初始化
  
  5.文件说明
	1.【RunAny_SearchBar.ahk】搜索框主文件，一般下载后会更新此文件
	2.【RunAny_SearchBar.ini】搜索框配置文件，修改搜索框样式，第一次运行后自动生成，可自行备份
	3.【RunAny_SearchBar_Custom.ahk】自定义搜索功能文件，无此需求请勿乱改，可自定义添加不同的搜索功能（可以与别人分享的自己写的搜索功能），第一次运行后自动生成，可自行备份，【不用自启】
	4.【RunAny_SearchBar.ini】和【RunAny_SearchBar_Custom.ahk】文件删除后自动生成
;-----------------------------------------【更新说明】-----------------------------------------
v1.1.1: 2021年12月29日
	1.修复由于v1.1.0自定义搜索功能产生的搜索（例如百度）无内容BUG
v1.1.2: 2021年1月6日
	1.优化选择搜索功能代码
	2.优化有搜索结果的搜索功能无匹配时不再执行，避免报错
	3.新增快捷键F1-8快速切换搜索功能
	4.优化配置项无当前分辨率屏幕的设置时，默认使用1080P下的设置
	5.新增设置候选框搜索结果和加号字体颜色，【候选框字体颜色=black】、【加号颜色=black】如需要请自行添加至配置项，或删除配置文件后自动生成
v1.1.3: 2021年1月13日
	1.修复菜单值中包含=出错情况
*/

global RunAny_Plugins_Version:="1.1.3"
global RunAny_Plugins_Icon:="shell32.dll,23"
;WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
#Include ..\RunAny_ObjReg.ahk
;https://www.autoahk.com/archives/37300 汉字转拼音，不需要则删除下面两行
#Include ..\Lib\ChToPy.ahk
ChToPy.log4ahk_load_all_dll_path()

;----------------------------------------【RA插件功能】----------------------------------------
class RunAnyObj {
	;RA搜索框	+d|RunAny_SearchBar[toggle_searchBar]()
	;RA搜索框	+d|RunAny_SearchBar[toggle_searchBar](%getZz%)
	toggle_searchBar(getZz:=""){
		toggleSearchBar(getZz)
	}
}
;----------------------------------------【自定义样式】----------------------------------------
Label_Custom:
Label_Custom()
return

;----------------------------------------【初始化】----------------------------------------
Label_ScriptSetting: ;脚本前参数设置
Label_ScriptSetting()
return

Label_ReadINI:	;读取INI文件配置收缩框
Label_ReadINI()
return

Label_ReadRAINI:	;读取RAINI文件生成菜单项
Label_ReadRAINI()
return

Label_Init: ;搜索框GUI初始化
Label_Init()
Return

Label_Submit: ;确认提交
Label_Submit()
return

;单选框对应功能
suffix_fun:	;后缀菜单功能
suffix_fun()
Return

menu_fun:	;菜单项功能
menu_fun()
Return

V1toV2_GblCode_001:
V1toV2_GblCode_001()
return

Label_Submit_Before: ;提交之前的操作
Label_Submit_Before()
Return

GuiEscape:	;ESC关闭窗口
GuiEscape()
Return

showSwitchToolTip(Msg:="", ShowTime:=1000, is_input:=0) { ;ToolTip形式显示
	If (is_input=1){
		CoordMode("Caret", "Window")
		CaretGetPos(&A_CaretX, &A_CaretY), ToolTip(Msg, A_CaretX, A_CaretY+60)
	}Else{
		MouseGetPos(&xpos, &ypos)
		ToolTip(Msg, xpos, ypos-30)
		SetTimer(Timer_Remove_ToolTip,ShowTime)
	}
	Return
	
	Timer_Remove_ToolTip:  ;移除ToolTip
		SetTimer(Timer_Remove_ToolTip,0)
		ToolTip()
	Return
}

ChangeRadio(GuiEvent:="", CtrlHwnd:="", EventInfo:="", *){	(IsSet(CtrlHwnd)) && SetDefaultGui(CtrlHwnd)
;单选框改变时的样式改变
	; OutputVar := ControlGetFocus() ; V1toV2: Not really the same, this returns the HWND...
	SelectWhichRadio( SubStr(OutputVar, -1, 1))
}

SelectWhichRadio(index){	;改变搜索功能
	index := index<=len_Radio ? index : len_Radio
	ControlFocus(, "ahk_id " My_Edit_Hwnd)
	Label_Font_Radio_un() ; V1toV2: Gosub
	hwnd := Search_Hwnd_%index_temp%
	fcV2GC("",hwnd).SetFont("s" . ListView_text_size . " c" . Candidates_font_color,"Segoe UI") ; V1toV2: Verify that control [%hwnd%] is accurate
	Label_Font_Radio() ; V1toV2: Gosub
	hwnd := Search_Hwnd_%index%
	fcV2GC("",hwnd).Value := 1 ; V1toV2: Verify that control [%hwnd%] is accurate
	fcV2GC("",hwnd).SetFont("s" . ListView_text_size . " c" . Candidates_font_color,"Segoe UI") ; V1toV2: Verify that control [%hwnd%] is accurate
	index_temp := index
	changeCapsLockState() ; V1toV2: Gosub
	ChangeEdit()
}
;----------------------------------------【单选框对应触发提示对应】----------------------------------------

ChangeEdit(A_GuiEvent:="", A_GuiControl:="", Info:="", *){	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
;输入框改变时触发
	gV2CurLV.Delete()							;删除提示框内容以刷新
	IL_Destroy(ImageListID)				;删除图像列表，降低内存
	match_flag := 1	;用于那些功能出发下方提示框
	Edit_OutputVar := mV2GC[["","Content"]].Value
	If (index_temp=RA_suffix){			;激活指定后缀的菜单触发
		CandidateList:=getCandidateCommon(MenuObjExt,3,MenuObjIcon,3)
		gV2CurLV.ModifyCol(2, , "后缀名")
		gV2CurLV.ModifyCol(3, , "菜单名称")
	}Else If (index_temp=RA_menu){		;打开指定菜单
		CandidateList:=getCandidateCommon(MenuObj,4,MenuObjIcon)
		gV2CurLV.ModifyCol(2, , "菜单名称")
		gV2CurLV.ModifyCol(3, , "菜单值")
	}Else{
		temp := "Show"
		try %("Label_Custom_ListView_" temp)%()
		catch
			match_flag := 0
	}
	column := gV2CurLV.GetCount("Column")
	ListCount := CandidateList.Length/column	;数组对应的3元组数量（key、val、ico_path）
	GuiControl, Move, CommandChoice, % "h" ListView_H1 + ListView_h * ((ListCount > (Candidates_show_num_max-1) ? Candidates_show_num_max : ListCount)-1) ; V1toV2: Ternary not yet supported (coming soon) ;设置对应的提示框高度
	ImageListID := IL_Create(ListCount)	;创建对应图片
	gV2CurLV.SetImageList(ImageListID)
	Loop ListCount{					;ListView插入对应值
		key := CandidateList[3*A_Index-2]
		val := CandidateList[3*A_Index-1]
		ico := StrSplit(CandidateList[3*A_Index], ",")
		IL_Add(ImageListID, ico[1], ico[2])
		gV2CurLV.Add("Icon" . A_Index, "-" . A_Index, key, val)
	}
	width_remainder := 1
	Loop column{
		If (A_Index=column)
			gV2CurLV.ModifyCol(A_Index, Edit_width*width_remainder)
		Else{
			width := width_%A_Index%
			gV2CurLV.ModifyCol(A_Index, Edit_width*width)
			width_remainder -= width
		}
	}
	GuiControl, % ListCount ? "Show" : "Hide", CommandChoice ; V1toV2: Ternary not yet supported (coming soon) 	;根据数量是否显示提示框
	If (is_hide = 0)
		mV2Gui[""].Show("AutoSize")
	If ( match_flag && ListCount=0 && Edit_OutputVar){		;无匹配时提醒
		is_can_run_fun := False
		showSwitchToolTip("无匹配项！",0,1)
	}else if(is_auto_fill && Candidates_num=2){	;剩下一个选项自动填充
		is_can_run_fun := True
		Candidates_num := -1
		Autocomplete(1)
		if (Edit_stop_time){
			mV2GC[["","Content"]].Opt("+ReadOnly")
			Sleep(Edit_stop_time)
			mV2GC[["","Content"]].Opt("-ReadOnly")
		}
	}Else{
		is_can_run_fun := True
		ToolTip()
	}
	CandidateList := ""
	SetTimer(close_ListView,100)
}

close_ListView:	;如果为空则关闭候选框
close_ListView()
Return


GiveEdit:	;在提示框内输入按键自动跳转到输入框，双击执行对应功能
GiveEdit()
Return

;------------------------------------------------------------------------------------------------------
Autocomplete(index:=1){	;自动补全
	OutputVar := mV2GC[["","Content"]].Value
	item := gV2CurLV.GetText(index)
	If (item!=""){
		mV2GC[["","Content"]].Text := item
		SendInput("{End}")
	}
}

Timer_Remove_check: ;鼠标点击其他区域自动隐藏
Timer_Remove_check()
Return

toggleSearchBar(getZz:=""){	;激活或关闭RA搜索框
	if WinActive("ahk_id" WinID){
		SetTimer(Timer_Remove_check,0)
		hide_searchBar() ; V1toV2: Gosub
	}
	Else{
		is_hide := 0
		changeCapsLockState() ; V1toV2: Gosub
		If (pos_mode=0){
			mV2Gui[""].Show()
		}Else If (pos_mode=1){
			mV2Gui[""].Show("x" . x_pos . " y" . y_pos)
		}Else If (pos_mode=2){
			CoordMode("Mouse", "Screen")
			MouseGetPos(&xMouse, &yMouse)
			xMouse -= (ListBox_width/2)
			yMouse -= (Radio_H_ALL+Edit_H/2)
			mV2Gui[""].Show("x" . xMouse . " y" . yMouse)
		}
		WinActivate("ahk_id " WinID)
		ControlFocus(, "ahk_id " My_Edit_Hwnd)
		SendInput(ChangeIMEHotKey)
		If (getZz)
			mV2GC[["","Content"]].Text := getZz
		Else If (is_remember_content)
			mV2GC[["","Content"]].Text := Content
		SendInput("{End}")
		SetTimer(Timer_Remove_check,25)
	}
}

hide_searchBar:	;隐藏搜索框
hide_searchBar()
Return

move_Win(wParam, lParam, msg, hwnd){ ;左键移动窗口
    PostMessage(0xA1, 2)
}

;----------------------------------------【字体样式Lable】----------------------------------------
Label_Font_Radio_un: ;Radio未选中字体样式
Label_Font_Radio_un()
Return

Label_Font_Radio: ;Radio选中字体样式
Label_Font_Radio()
Return
;----------------------------------------------------------------------------------------------

;进程间传递消息
Send_WM_COPYDATA(StringToSend, TargetScriptTitle)
{
    CopyDataStruct := Buffer(3*A_PtrSize, 0)  ; 分配结构的内存区域.
    ; 首先设置结构的 cbData 成员为字符串的大小, 包括它的零终止符:
    SizeInBytes := (StrLen(StringToSend) + 1) * 2
    NumPut("ptr", SizeInBytes, CopyDataStruct, A_PtrSize)  ; cbData
    NumPut("ptr", StrPtr(StringToSend), CopyDataStruct, 2*A_PtrSize)  ; lpData
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    TimeOutTime := 4000  ; 可选的. 等待 receiver.ahk 响应的毫秒数. 默认是 5000
    ; 必须使用发送 SendMessage 而不是投递 PostMessage.
    result := 0
    try result := SendMessage(0x004A, 0, CopyDataStruct.Ptr, , TargetScriptTitle)  ; WM_COPYDATA
    if !result && !InStr(TargetScriptTitle, "RunAny_v2.ahk")
        try result := SendMessage(0x004A, 0, CopyDataStruct.Ptr, , "RunAny_v2.ahk ahk_class AutoHotkey")
    DetectHiddenWindows(Prev_DetectHiddenWindows)  ; 恢复调用者原来的设置.
    SetTitleMatchMode(Prev_TitleMatchMode)         ; 同样.
    return result  ; 返回 SendMessage 的回复给我们的调用者.
}

GuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y){	;右键功能
	If (Move_Hwnd=CtrlHwnd) {
		EditFile(INI,INI_Open_Exe)
	}
	CtrlClass := WinGetClass("ahk_id " CtrlHwnd)
	If (CtrlClass="Button"){
		EditFile(A_ScriptDir "\RunAny_SearchBar_Custom.ahk",AHK_Open_Exe)
	}
}

getCandidateCommon(Obj,default_Icon_number:=4,ObjIcon:="",WhichToExe:=2){	;获取搜索结果
	If (Edit_OutputVar="")
		Return
	CandidateList := Object()
	full_match := 0	;有完全匹配项则不会重复搜索，消除自动补全BUG
	Candidates_num := 1
	temp_kv := ""	;消除临近重复选项，，例如快捷键的
    For ki, kv in Obj
	{
		If (kv="")
			Continue
		a := InStr(ki, Edit_OutputVar) || InStr(ChToPy.allspell(ki), Edit_OutputVar) || InStr(ChToPy.initials(ki), Edit_OutputVar)
		If (a!=0){
			If (kv=temp_kv){
				Continue
			}Else{
				temp_kv := kv
			}
			ico_path := WhichToExe=2?ObjIcon[ki]:ObjIcon[kv]
			If (ico_path="")
				ico_path := "shell32.dll," default_Icon_number
			CandidateList.push(ki,kv,ico_path)
			Candidates_num +=1
		}
		If (ki=Edit_OutputVar){
			full_match := 1
		}
		If ( Candidates_num > Candidates_num_max){
			break
		}
    }
    Candidates_num := Candidates_num=1 ? 0 : Candidates_num
    Candidates_num := full_match ? 1 : Candidates_num
    Return CandidateList
}

executeCandidateWhich(whichColumn:=2){	;执行搜索结果的哪一列
	RowNumber := gV2CurLV.GetNext()
		If (RowNumber!=0){
			Content := gV2CurLV.GetText(gV2CurLV.GetNext())
		}Else If (gV2CurLV.GetCount()!=0 && is_run_first){
			Content := gV2CurLV.GetText(1)
		}Else
			Content := mV2GC[["","Content"]].Value
}

initResetINI() { ;定时重新加载配置文件
	mtime_ini_path := FileGetTime(INI, "M")  ; 获取修改时间.
	mtime_CustomAHK_path := FileGetTime(A_ScriptDir "\RunAny_SearchBar_Custom.ahk", "M")  ; 获取修改时间.
	RegWrite(mtime_ini_path, "REG_SZ", "HKEY_CURRENT_USER\Software\RunAny", INI)
	RegWrite(mtime_CustomAHK_path, "REG_SZ", "HKEY_CURRENT_USER\Software\RunAny", A_ScriptDir "\RunAny_SearchBar_Custom.ahk")
	if (Auto_Reload_MTime>0)
	{
		SetTimer(Auto_Reload_MTime,Auto_Reload_MTime)
	}
}

Auto_Reload_MTime: ;定时重新加载脚本
Auto_Reload_MTime()
Return

Init_Custom_Fun:  ;执行自定义功能标签
Init_Custom_Fun()
Return

changeCapsLockState:	;改变大小写状态
changeCapsLockState()
Return

initCustomAHK(){	;初始化自定义搜索功能的AHK
	FileAppend(
(
";*************************************************
;* 【RA搜索框自定义功能（不用自启）】
;*************************************************
;tong
;【重要】：事先声明没有AHK基础不建议自行修改本文件，如出现错误无法解决，请关闭RA后删除本文件，将会自动初始化本文件
;【说明】：如果改动了本文件，请自行备份，避免丢失，重新下载RunAny_SearchBar.ahk不会覆盖本文件
;【建议】：自定义的变量和辅助函数加上建议使用 SearchCustom_ 前缀避免重名冲突
;【添加自定义搜索功能步骤】：【百度一下】为参考案例
	;1.【Radio_names】添加对应功能名称
	;2.【RA_suffix】、【RA_menu】与步骤1中【后缀菜单】、【菜单项】位置对应，请务必一一对应
	;3.【单选框对应功能】中按序号添加与【Radio_names】对应的功能

;------------------------------------------【自定义变量】-----------------------------------------
Label_Custom_Fun:
	global Radio_names := [`"后缀菜单`",`"菜单项`",`"百度一下`"]
	global RA_suffix := 1		;后缀菜单对应位置
	global RA_menu := 2			;菜单项对应位置
	global Radio_Default := 2	;默认搜索对应位置，默认为菜单项
Return

;----------------------------------------【单选框对应功能】----------------------------------------
fun_1:	;后缀菜单
	Gosub, suffix_fun
Return

fun_2:	;菜单项
	Gosub, menu_fun
Return

fun_3:	;百度一下
	URIContent:=URIEncode(Content)	;网页搜索时内容进行URI转义
	Run https://www.baidu.com/s?wd=`%URIContent`%
Return

";----------------------------------------【辅助函数位置】----------------------------------------
	), A_ScriptDir "\RunAny_SearchBar_Custom.ahk", "UTF-8")
}

EditFile(filePath,openExe:="notepad.exe") { ;打开指定文件
	openExe := openExe ? openExe : "notepad.exe"
	try{
		if(!FileExist(ini)){
			MsgBox("没有找到配置文件：" ini, ini, 16)
		}Else{
			Run(openExe " `"" filePath "`"")
		}
	}catch{
		MsgBox("无法打开配置文件：" filePath, ini, 16)
	}
}

URIEncode(str, encoding := "UTF-8")  {	;URI转义
   VarSetStrCapacity(&var, StrPut(str, encoding)) ; V1toV2: if 'var' is NOT a UTF-16 string, use 'var := Buffer(StrPut(str, encoding))' and replace all instances of 'StrPtr(var)' with 'var.Ptr'
   StrPut(str, StrPtr(var), encoding)

   While code := NumGet(Var, A_Index - 1, "UChar")  {
      bool := (code > 0x7F || code < 0x30 || code = 0x3D)
      UrlStr .= bool ? "%" . Format("{:02X}", code) : Chr(code)
   }
   Return UrlStr
}

initINI() { ;初始化INI
	FileAppend(";【RA搜索框配置文件】`n", INI)
	FileAppend(";【说明】：后续版本如有新的配置项，请对比后自行修改添加`n", INI)
	FileAppend("[基础配置]`n", INI)
	FileAppend("配置版本=" SearchBar_Version "`n", INI)
	FileAppend(";【说明】：本配置文件可针对不同分辨率显示器分别设置，请自行添加，默认为【1080P】的设置，详细参数说明请看RA官网说明或入群自问`n", INI)
	FileAppend("[1920*1080]`n", INI)
	FileAppend("搜索框x轴位置=0.5`n", INI)
	FileAppend("搜索框y轴位置=0.25`n", INI)
	FileAppend("搜索框位置模式=1`n", INI)

	FileAppend("输入框字体颜色=black`n", INI)
	FileAppend("输入框字体大小=25`n", INI)
	FileAppend("输入框透明度=220`n", INI)
	FileAppend("输入框宽度=800`n", INI)
	
	FileAppend("加号颜色=black`n", INI)

	FileAppend("上方搜索选项未选中时字体颜色=black`n", INI)
	FileAppend("上方搜索选项选中时字体颜色=1e90ff`n", INI)

	FileAppend("候选框字体颜色=black`n", INI)
	FileAppend("候选框内最大行数=50`n", INI)
	FileAppend("候选框显示最大行数=10`n", INI)
	FileAppend("候选框内三列比例=0.08:0.28:0.64`n", INI)

	FileAppend("输入框是否自动填充=1`n", INI)
	FileAppend("自动填充后禁用输入时间=500`n", INI)
	FileAppend("是否回车自动执行第一个候选项=1`n", INI)
	FileAppend("是否自动开启大写=1`n", INI)
	FileAppend("对应菜单开启大写=1|2`n", INI)
	FileAppend("切换输入法快捷键=`n", INI)
	FileAppend("是否记住上次执行内容=0`n", INI)

	FileAppend("配置更改自动重启时间=2000`n", INI)
}

;----------------------------------------------------------------------------------------------

#HotIf WinActive("ahk_id" WinID)	;搜索框的热键，可自行更改，因为要判断是否激活了搜索框，所以不能做成RA插件功能
Tab::HK1_Tab()	;TAB键快速正序切换，loop循环保证意外发生，循环其实不会走完一遍
Return
RShift::HK2_RShift()	;右边shift键快速逆序切换
Return
;左Lat自动补全
LAlt::Autocomplete(1)
LAlt & 1::Autocomplete(1)
LAlt & 2::Autocomplete(2)
LAlt & 3::Autocomplete(3)
LAlt & 4::Autocomplete(4)
LAlt & 5::Autocomplete(5)
LAlt & 6::Autocomplete(6)
LAlt & 7::Autocomplete(7)
LAlt & 8::Autocomplete(8)
LAlt & 9::Autocomplete(9)

F1::SelectWhichRadio(1)
F2::SelectWhichRadio(2)
F3::SelectWhichRadio(3)
F4::SelectWhichRadio(4)
F5::SelectWhichRadio(5)
F6::SelectWhichRadio(6)
F7::SelectWhichRadio(7)
F8::SelectWhichRadio(8)

Delete::HK21_Delete()	;delet自动情况输入框
Return

Up::HK22_Up()		;上下选择
Return

Down::HK23_Down()
Return

;###############  V1toV2 FUNCS  ###############
Label_Custom() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	;上方单选框对应功能
	Init_Custom_Fun() ; V1toV2: Gosub
	;搜索框样式
	global x_pos,y_pos,pos_mode,Edit_color,Edit_text_size,Edit_trans,Edit_width,Radio_un_color,Radio_un_text_size,Radio_color,Radio_text_size
	;提示框样式
	global ListView_text_size,ListView_h,Candidates_num_max,Candidates_show_num_max,width_1,width_2,width_3
	;特色功能
	global Edit_stop_time,is_auto_fill,is_run_first,is_auto_CapsLock,CapsLock_List,is_remember_content,ChangeIMEHotKey
	;辅助功能
	global Auto_Reload_MTime,INI_Open_Exe,AHK_Open_Exe
Label_ScriptSetting()
}
;##############################################
Label_ScriptSetting() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	ProcessSetPriority("High")						;脚本高优先级
	A_MenuMaskKey := "vkE8"
	#NoTrayIcon             						;~不显示托盘图标
	Persistent										;让脚本持久运行(关闭或ExitApp)
	#SingleInstance Force							;单例运行
	#WinActivateForce								;强制激活窗口
	A_MaxHotkeysPerInterval := 200						;时间内按热键最大次数
	A_HotkeyModifierTimeout := 100						;按住modifier后(不用释放后再按一次)可隐藏多个当前激活窗口
; V1toV2: Removed 	SetBatchLines, -1								;脚本全速执行
	SetControlDelay(-1)								;控件修改命令自动延时,-1无延时，0最小延时
	CoordMode("Menu Window")							;坐标相对活动窗口
	CoordMode("Mouse Screen")							;鼠标坐标相对于桌面(整个屏幕)
	ListLines(false)									;不显示最近执行的脚本行
	SendMode("Input")									;更速度和可靠方式发送键盘点击
	SetTitleMatchMode(2)								;窗口标题模糊匹配;RegEx正则匹配
	DetectHiddenWindows(true)							;显示隐藏窗口
Label_ReadINI()
}
;##############################################
Label_ReadINI() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	global SearchBar_Version:="1.1.3"
	global INI
	INI := A_ScriptDir . "\RunAny_SearchBar.ini"
	if !FileExist(INI)
		initINI()
	is_exist_Screen := IniRead(INI, A_ScreenWidth "*" A_ScreenHeight, "搜索框x轴位置")
	Screen_Section := is_exist_Screen="ERROR" ? "1920*1080" : A_ScreenWidth "*" A_ScreenHeight
	x_pos := IniRead(INI, Screen_Section, "搜索框x轴位置", 0.5)
	y_pos := IniRead(INI, Screen_Section, "搜索框y轴位置", 0.25)
	pos_mode := IniRead(INI, Screen_Section, "搜索框位置模式", 1)

	Edit_color := IniRead(INI, Screen_Section, "输入框字体颜色", "black")
	Edit_text_size := IniRead(INI, Screen_Section, "输入框字体大小", 25)
	Edit_trans := IniRead(INI, Screen_Section, "输入框透明度", 220)
	Edit_width := IniRead(INI, Screen_Section, "输入框宽度", 800)

	Plus_color := IniRead(INI, Screen_Section, "加号颜色", "black")

	Radio_un_color := IniRead(INI, Screen_Section, "上方搜索选项未选中时字体颜色", "black")
	Radio_un_text_size := Edit_text_size -11
	Radio_text_size := Edit_text_size -10
	Radio_color := IniRead(INI, Screen_Section, "上方搜索选项选中时字体颜色", "1e90ff")

	ListView_text_size := Radio_un_text_size
	Candidates_font_color := IniRead(INI, Screen_Section, "候选框字体颜色", "black")
	Candidates_num_max := IniRead(INI, Screen_Section, "候选框内最大行数", 50)
	Candidates_show_num_max := IniRead(INI, Screen_Section, "候选框显示最大行数", 10)
	ListView_column_ratio := IniRead(INI, Screen_Section, "候选框内三列比例", "0.08:0.28:0.64")
	ListView_column_ratio := StrSplit(ListView_column_ratio, ":")
	width_1 := ListView_column_ratio[1],width_2 := ListView_column_ratio[2],width_3 := ListView_column_ratio[3]

	is_auto_fill := IniRead(INI, Screen_Section, "输入框是否自动填充", 1)
	Edit_stop_time := IniRead(INI, Screen_Section, "自动填充后禁用输入时间", 500)
	is_run_first := IniRead(INI, Screen_Section, "是否回车自动执行第一个候选项", 1)
	is_auto_CapsLock := IniRead(INI, Screen_Section, "是否自动开启大写", 1)
	CapsLock_List1 := IniRead(INI, Screen_Section, "对应菜单开启大写", "1|2")
	ChangeIMEHotKey := IniRead(INI, Screen_Section, "切换输入法快捷键", A_Space)
	CapsLock_List := Object() 
	Loop Parse, CapsLock_List1, "|"
    	CapsLock_List[A_LoopField] := A_LoopField  ;  V1toV2: Invalid Index errors?, try 'CapsLock_List.Push(<val>)'
	is_remember_content := IniRead(INI, Screen_Section, "是否记住上次执行内容", 0)

	Auto_Reload_MTime := IniRead(INI, Screen_Section, "配置更改自动重启时间", 2000)
	If (A_ScreenDPI=96){
		
	}Else If (A_ScreenDPI=120){
		Edit_width *= 1.25*0.9
		ListView_h *= 1.25
		Candidates_show_num_max := Format("{:d}", Candidates_show_num_max/1.25+1)
	}Else If (A_ScreenDPI=144){
		Edit_width *= 1.5*0.9
		ListView_h *= 1.5
		Candidates_show_num_max := Format("{:d}", Candidates_show_num_max/1.5+2)
	}Else{
		Edit_width *= A_ScreenDPI/100*0.9
		ListView_h *= A_ScreenDPI/100
		Candidates_show_num_max := Format("{:d}", Candidates_show_num_max/A_ScreenDPI*100+3)
	}
	initResetINI()
Label_ReadRAINI()
}
;##############################################
Label_ReadRAINI() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	global rAAhkMatch  := "RunAny.ahk ahk_class AutoHotkey"		;RA ahk路径
	;从RA配置文件中读取无路径缓存路径
	SplitPath(A_AhkPath, , &RunAnyConfigDir)
	RunAEvFullPathIniDir := IniRead(RunAnyConfigDir "\RunAnyConfig.ini", "Config", "RunAEvFullPathIniDir", A_Space)
	If (RunAEvFullPathIniDir="")
		INI_Path := A_AppData "\RunAny"
	Else
		; V1toV2: Removed : Transform(INI_Path, Deref, RunAEvFullPathIniDir, )
	;从RA配置文件中ini、ahk后缀关联程序
	openExtVar := IniRead(RunAnyConfigDir "\RunAnyConfig.ini", "OpenExt")
	Loop Parse, openExtVar, "`n", "`r"
	{
		itemList:=StrSplit(A_LoopField,"=",,2)
		openExtIniList[itemList[1]]:=itemList[2]
		Loop Parse, itemList[2], A_Space
		{
			ExtVar := StrLower(A_LoopField)
			if (ExtVar="ini")
				; V1toV2: Removed : Transform(INI_Open_Exe, Deref, itemList[1], )
			Else if(ExtVar="ahk")
				; V1toV2: Removed : Transform(AHK_Open_Exe, Deref, itemList[1], )
		}
	}
	If !FileExist(INI_Open_Exe){
		INI_Open_Exe := IniRead(INI_Path "\RunAnyEvFullPath.ini", "FullPath", INI_Open_Exe, A_Space)
		If !FileExist(INI_Open_Exe)
			INI_Open_Exe := ""
	}
	If !FileExist(AHK_Open_Exe){
		AHK_Open_Exe := IniRead(INI_Path "\RunAnyEvFullPath.ini", "FullPath", AHK_Open_Exe, A_Space)
		If !FileExist(AHK_Open_Exe)
			AHK_Open_Exe := ""
	}
	;读取菜单项配置文件
	INI_EvFullPath := INI_Path "\RunAnyEvFullPath.ini"	
	INI_MenuObj := INI_Path "\RunAnyMenuObj.ini"
	INI_MenuObjIcon := INI_Path "\RunAnyMenuObjIcon.ini"
	INI_MenuObjExt := INI_Path "\RunAnyMenuObjExt.ini"
	If (!FileExist(INI_MenuObj) || !FileExist(INI_MenuObjIcon) || !FileExist(INI_MenuObjExt)){
		Send_WM_COPYDATA("runany[ShowTrayTip](RA搜索框插件,首次运行无法读取RA菜单信息，请将本插件设置为【自启】后重启RA！如已设置为【自启】，请耐心等待【RA】启动初始化，将自动重启生效！,20,17)", rAAhkMatch)
	}
	global EvFullPath := Object()                   ;~无路径缓存
	global MenuObj := Object()                    	;~程序全路径
	global MenuObjIcon := Object()                  ;~程序对应图标路径
	global MenuObjExt := Object()					;~对应后缀菜单
	Loop read, INI_EvFullPath
	{
		If (A_Index!=1){
			equalPos := InStr(A_LoopReadLine, "=")
			EvFullPath[SubStr(A_LoopReadLine, 1, equalPos-1)] := SubStr(A_LoopReadLine, (equalPos+1)<1 ? (equalPos+1)-1 : (equalPos+1)) ;  V1toV2: Invalid Index errors?, try 'EvFullPath.Push(<val>)'
		}
	}
	Loop read, INI_MenuObjIcon
	{
		If (A_Index!=1){
			equalPos := InStr(A_LoopReadLine, "=")
			MenuObjIcon[SubStr(A_LoopReadLine, 1, equalPos-1)] := SubStr(A_LoopReadLine, (equalPos+1)<1 ? (equalPos+1)-1 : (equalPos+1)) ;  V1toV2: Invalid Index errors?, try 'MenuObjIcon.Push(<val>)'
		}
	}
	Loop read, INI_MenuObj
	{
		If (A_Index!=1){
			equalPos := InStr(A_LoopReadLine, "=")
			If (MenuObjIcon.Has(SubStr(A_LoopReadLine, 1, equalPos-1)) || !EvFullPath.Has(SubStr(A_LoopReadLine, 1, equalPos-1) ".exe"))
				MenuObj[SubStr(A_LoopReadLine, 1, equalPos-1)] := SubStr(A_LoopReadLine, (equalPos+1)<1 ? (equalPos+1)-1 : (equalPos+1)) ;  V1toV2: Invalid Index errors?, try 'MenuObj.Push(<val>)'
		}
	}
	Loop read, INI_MenuObjExt
	{
		If (A_Index!=1){
			equalPos := InStr(A_LoopReadLine, "=")
			MenuObjExt[SubStr(A_LoopReadLine, 1, equalPos-1)] := SubStr(A_LoopReadLine, (equalPos+1)<1 ? (equalPos+1)-1 : (equalPos+1)) ;  V1toV2: Invalid Index errors?, try 'MenuObjExt.Push(<val>)'
		}
	}
Label_Init()
}
;##############################################
Label_Init() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	global index_temp := Radio_Default							;临时变量，用于tab切换减少时间复杂度
	global WinID := ""											;窗口ID
	global My_Edit_Hwnd := ""									;输入框ID
	global Content := ""										;输入框内容
	global Move_Hwnd := ""										;加号对应的Hwnd
	global ListView_Hwnd := ""									;候选项对应的Hwnd
	global len_Radio := Radio_names.Length					;上方选项的单选框控件数量
	global Candidates_num := -1									;候选项个数
	global is_hide := 0											;表示是否是隐藏效果
	global Radio_H_ALL,Edit_H,ListBox_width,ListView_H1,ImageListID			;辅助变量
	global CandidateList,Edit_OutputVar							;候选框、输入框内容
	global is_can_run_fun
	OnMessage(0x201, move_Win)								;用于拖拽移动

	CustomColor := "6b9ac9"										;用于背景透明的颜色
	If (!HasV2Gui("")) {
		mV2Gui[""] := NewV2Gui("")
		mV2Gui[""].OnEvent("Escape",GuiEscape)
	}
	mV2Gui[""].Opt("+LastFound +ToolWindow +AlwaysOnTop -Caption -DPIScale")
	WinID := mV2Gui[""].Hwnd
	mV2Gui[""].BackColor := CustomColor
	Label_Font_Radio_un() ; V1toV2: Gosub

;----------------------------------------【自定义功能区】----------------------------------------
	For ki, kv in Radio_names
	{
		If (ki=1)
		{
			mV2GC[["","Search_Hwnd_"]] := mV2Gui[""].Add("Radio","-Background  x0 y0  " . ki,kv)
			Search_Hwnd_ := mV2GC[["","Search_Hwnd_"]].hwnd
			mV2GC[["","Search_Hwnd_"]].OnEvent("Click",ChangeRadio.Bind("Normal"))
		}
		Else
		{
			mV2GC[["","Search_Hwnd_"]] := mV2Gui[""].Add("Radio","-Background x" . Radio_X . " y" . Radio_Y . " " . ki,kv)
			Search_Hwnd_ := mV2GC[["","Search_Hwnd_"]].hwnd
			mV2GC[["","Search_Hwnd_"]].OnEvent("Click",ChangeRadio.Bind("Normal"))
		}
		tmp := Search_Hwnd_%ki%
		ControlGetPos(&Radio_X, &Radio_Y, &Radio_W, &Radio_H, , "ahk_id " tmp)
		If ((Radio_X+Radio_W)>Edit_width){
			Radio_X := Radio_W + 15
			Radio_Y += Radio_H + 15
			Radio_H_ALL += Radio_H +15
			ControlMove(0, Radio_Y, Radio_W*1.05, "Radio_H*1.2", , "ahk_id " tmp)
		}Else{
			Radio_X += Radio_W + 15
			ControlMove(, , Radio_W*1.05, "Radio_H*1.2", , "ahk_id " tmp)
		}
	}
;--------------------------------------------------------------------------------------------

	mV2Gui[""].SetFont("s" . Edit_text_size . " c" . Edit_color,"Segoe UI")
	ControlGetPos(, , , &Radio_H, , "ahk_id " Search_Hwnd_1)
	Radio_H_ALL += Radio_H + 10
	mV2GC[["","Content"]] := mV2Gui[""].Add("Edit","x0 y" . Radio_H_ALL . " w" . Edit_width . " vContent")
	My_Edit_Hwnd := mV2GC[["","Content"]].hwnd
	mV2GC[["","Content"]].OnEvent("Change",ChangeEdit.Bind("Normal"))
	ControlGetPos(, , , &Edit_H, , "ahk_id " My_Edit_Hwnd)
	mV2Gui[""].SetFont("s" . Edit_text_size . " c" . Plus_color,"Segoe UI")
	mV2GC[["","Move_Hwnd"]] := mV2Gui[""].Add("Text","+Border -Background x" . Edit_width . " y" . Radio_H_ALL . " h" . Edit_H,"+")
	Move_Hwnd := mV2GC[["","Move_Hwnd"]].hwnd
	ControlGetPos(, , &Move_W, , , "ahk_id " Move_Hwnd)
	ListBox_width := Edit_width + Move_W
	mV2Gui[""].SetFont("s" . ListView_text_size . " c" . Candidates_font_color,"Segoe UI")
	mV2GC[["","CommandChoice"]] := mV2Gui[""].Add("ListView","xs w" . ListBox_width . " vCommandChoice R2 -Multi +AltSubmit -HScroll",["序号","菜单名称","菜单值"])
	ListView_Hwnd := mV2GC[["","CommandChoice"]].hwnd
	mV2GC[["","CommandChoice"]].OnEvent("DoubleClick",GiveEdit.Bind("DoubleClick"))
	;mV2GC[["","CommandChoice"]].OnEvent("Click",GiveEdit.Bind("Click")) ; V1toV2: enable as needed
	;mV2GC[["","CommandChoice"]].OnEvent("ItemSelect",GiveEdit.Bind("Select")) ; V1toV2: enable as needed
	global gV2CurLV := mV2GC[["","CommandChoice"]]
	mV2GC[["","ListView_temp_Hwnd"]] := mV2Gui[""].Add("ListView","xs w" . ListBox_width . " R1 -Multi +AltSubmit -HScroll",["序号","菜单名称","菜单值"])
	ListView_temp_Hwnd := mV2GC[["","ListView_temp_Hwnd"]].hwnd
	global gV2CurLV := mV2GC[["","ListView_temp_Hwnd"]]
	global gV2CurLV := mV2GC[["","CommandChoice"]]
	ControlGetPos(, , , &ListView_H1, , "ahk_id " ListView_temp_Hwnd)
	ControlGetPos(, , , &ListView_H2, , "ahk_id " ListView_Hwnd)
	ListView_h := ListView_H2 - ListView_H1
	mV2GC[["","ListView_temp_Hwnd"]].Enabled := false
	mV2GC[["","ListView_temp_Hwnd"]].Visible := false
	mV2GC[["","Y"]] := mV2Gui[""].Add("Button","x39 y69 w75 h23 Hidden Default","确定(&Y)")
	mV2GC[["","Y"]].OnEvent("Click",Label_Submit.Bind("Normal"))
	WinSetTransColor(CustomColor " " Edit_trans)

	;开启时的默认单选框设置
	DefaultHwnd := Search_Hwnd_%Radio_Default%
	fcV2GC("",DefaultHwnd).Value := 1 ; V1toV2: Verify that control [%DefaultHwnd%] is accurate
	Label_Font_Radio() ; V1toV2: Gosub
	fcV2GC("",DefaultHwnd).SetFont("s" . ListView_text_size . " c" . Candidates_font_color,"Segoe UI") ; V1toV2: Verify that control [%DefaultHwnd%] is accurate
	mV2GC[["","CommandChoice"]].Visible := false
	x_pos := A_ScreenWidth*x_pos - (ListBox_width/2)
	y_pos := A_ScreenHeight*y_pos - (Radio_H_ALL+Edit_H/2)
	mV2Gui[""].Show("x" . x_pos . " y" . y_pos . " Hide")
Return
}
;##############################################
Label_Submit(A_GuiEvent:="", A_GuiControl:="", Info:="", *) { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	If (!is_can_run_fun)
		Return
	Label_Submit_Before() ; V1toV2: Gosub
	toggleSearchBar("")
	try %("fun_" index_temp)%()
	catch
		Send_WM_COPYDATA("runany[ShowTrayTip](RA搜索框插件,对应功能未定义，请在【RunAny_SearchBar_Custom.ahk】中添加后重启插件，可以通过右键点击功能项快速打开,20,17)", rAAhkMatch)
return
}
;##############################################
suffix_fun() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	If (Content!="")
		showSwitchToolTip("后缀: " . Content,2500)
	Else
		showSwitchToolTip("输入空",2500)
	result := Send_WM_COPYDATA("runany[Remote_Menu_Ext_Show](" Content ")", rAAhkMatch)
Return
}
;##############################################
menu_fun() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	if(RegExMatch(MenuObj[Content], "S).+?\[.+?\]%?\(.*?\)")){
		result := Send_WM_COPYDATA(MenuObj[Content], rAAhkMatch)
	}else{
		result := Send_WM_COPYDATA("runany[Remote_Menu_Run](" Content ")", rAAhkMatch)
	}
Return
}
;##############################################
V1toV2_GblCode_001() { ; V1toV2: Lbl->Func
global
(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
;加载用户自定义功能
#Include RunAny_SearchBar_Custom.ahk
Label_Submit_Before()
}
;##############################################
Label_Submit_Before() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	Content := mV2GC[["","Content"]].Value
	If (index_temp=RA_suffix || index_temp=RA_menu){
		executeCandidateWhich(2)
	}Else{
		temp := "Execute"
		try %("Label_Custom_ListView_" temp)%()
	}
Return
}
;##############################################
GuiEscape(*) { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	hide_searchBar() ; V1toV2: Gosub
Return
}
;##############################################
close_ListView() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	OutputVar := mV2GC[["","Content"]].Value
	If (!OutputVar){
		gV2CurLV.Delete()							;删除提示框内容以刷新
		IL_Destroy(ImageListID)				;删除图像列表，降低内存
		mV2GC[["","CommandChoice"]].Visible := false
	}
	SetTimer(close_ListView,0)
Return
}
;##############################################
GiveEdit(A_GuiEvent:="", A_GuiControl:="", Info:="", *) { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	If (A_GuiEvent = "K"){
		ControlFocus(, "ahk_id " My_Edit_Hwnd)
	}Else If (A_GuiEvent = "DoubleClick"){
		Label_Submit() ; V1toV2: Gosub
	}
Return
}
;##############################################
Timer_Remove_check() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	if !WinActive("ahk_id" WinID){
		hide_searchBar() ; V1toV2: Gosub
		SetTimer(Timer_Remove_check,0)
	}
Return
}
;##############################################
hide_searchBar() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	ToolTip()
	If (is_auto_CapsLock)
		SetCapsLockState("Off")
	is_hide := 1
	mV2GC[["","Content"]].Text := ""
	mV2GC[["","CommandChoice"]].Visible := false
	mV2Gui[""].Hide()
Return
}
;##############################################
Label_Font_Radio_un() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	mV2Gui[""].SetFont("c" . Radio_un_color . " s" . Radio_un_text_size,"Segoe UI")
Return
}
;##############################################
Label_Font_Radio() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	mV2Gui[""].SetFont("c" . Radio_color . " s" . Radio_text_size,"Segoe UI")
Return
}
;##############################################
Auto_Reload_MTime() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	mtime_ini_path_reg := RegRead("HKEY_CURRENT_USER\Software\RunAny", INI)
	mtime_CustomAHK_path_reg := RegRead("HKEY_CURRENT_USER\Software\RunAny", A_ScriptDir "\RunAny_SearchBar_Custom.ahk")
	mtime_ini_path := FileGetTime(INI, "M")  ; 获取修改时间.
	mtime_CustomAHK_path := FileGetTime(A_ScriptDir "\RunAny_SearchBar_Custom.ahk", "M")  ; 获取修改时间.
	if (mtime_ini_path_reg != mtime_ini_path || mtime_CustomAHK_path_reg != mtime_CustomAHK_path)
	{
				{
 try SafeReload()
		}
	}
Return
}
;##############################################
Init_Custom_Fun() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	mtime_CustomAHK_path := FileGetTime(A_ScriptDir "\RunAny_SearchBar_Custom.ahk", "M")  ; 获取修改时间.
	if !mtime_CustomAHK_path{
		initCustomAHK()
		SafeReload()
	}
	temp := "Fun"
	try %("Label_Custom_" temp)%()
Return
}
;##############################################
changeCapsLockState() { ; V1toV2: Lbl->Func
	global
	(IsSet(A_GuiControl)) && SetDefaultGui(A_GuiControl)
	If (is_auto_CapsLock){
		If CapsLock_List.Has(index_temp)
			SetCapsLockState("On")
		Else
			SetCapsLockState("Off")
	}
Return
}
;##############################################
HK1_Tab() { ; V1toV2: HK->Func
	global
	SelectWhichRadio(Mod(index_temp+1, len_Radio+1)=0 ? 1 : Mod(index_temp+1, len_Radio+1))
Return
}
;##############################################
HK2_RShift() { ; V1toV2: HK->Func
	global
	SelectWhichRadio(Mod(index_temp-1, len_Radio+1)=0 ? len_Radio : Mod(index_temp-1, len_Radio+1))
Return
}
;##############################################
HK21_Delete() { ; V1toV2: HK->Func
	global
	ControlFocus(, "ahk_id " My_Edit_Hwnd)
	mV2GC[["","Content"]].Text := ""
	mV2GC[["","CommandChoice"]].Visible := false
Return
}
;##############################################
HK22_Up() { ; V1toV2: HK->Func
	global
	ControlFocus(, "ahk_id " ListView_Hwnd)
	RowNumber := gV2CurLV.GetNext(0)
	If (RowNumber = 0){
		gV2CurLV.Modify(1, "+Focus +Select +Vis")
	}Else If (RowNumber = 1){
		gV2CurLV.Modify(gV2CurLV.GetCount(), "+Focus +Select +Vis")
	}
	Else{
		gV2CurLV.Modify(RowNumber-1, "+Focus +Select +Vis")
	}
Return
}
;##############################################
HK23_Down() { ; V1toV2: HK->Func
	global
	ControlFocus(, "ahk_id " ListView_Hwnd)
	RowNumber := gV2CurLV.GetNext(0)
	If (RowNumber = 0 || RowNumber=gV2CurLV.GetCount()){
		gV2CurLV.Modify(1, "+Focus +Select +Vis")
	}Else{
		gV2CurLV.Modify(RowNumber+1, "+Focus +Select +Vis")
	}
Return
}
;##############################################
iniGuiCtrlVars() { ; V1toV2: initializes gui control variables
    global
    CommandChoice := ""
    Content := ""
}
