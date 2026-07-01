#Requires AutoHotkey v2.0
#Warn Unreachable, Off
;************************
;* 【文件分类，解散文件夹，ImageMagick功能，ffmpeg功能等，以及可以直接在runany.ini中使用更多的变量】
;************************
global RunAny_Plugins_Name := "文件分类/ffmpeg/ImageMagick增强工具"
;使用文档:https://hui-zz.github.io/RunAny/#/plugins/xiaoyao-plus

global RunAny_Plugins_Version:="1.9.0"
#NoTrayIcon ;~不显示托盘图标
Persistent ;~让脚本持久运行
#SingleInstance Force ;~运行替换旧实例
;********************************************************************************
#Include A_ScriptDir "\RunAny_ObjReg.ahk"

global winTopList:=[]

Label_Return: ;结束标志
Label_Return()
Return

class RunAnyObj {

    ;══════════════════════获取选中文件的更多变量(多个选中)════════════════════════════════════════════════════
    RA_plus(getZz,plusxy_Path,func){
        getZz := Sort(getZz)
        ;完整路径
        filebatch5:= Explorer_GetPath()								;当前资源管理器打开的窗口的路径, 不支持win11多标签
        ;已废弃	filebatch6:= getfiles4()                            ;当前资源管理器打开的窗口的路径, 支持win11多标签，但需要设置，文件夹选项-查看-勾选"在标题栏中显示完整路径 
        filebatch := getfiles(getZz)								;完整路径，(多选文件时，自动加上双引号""并空格隔开，  	示例："Path1" "Path2" "Path3")
        filebatch2 := getfiles2(getZz)								;完整路径，(多选文件时，自动加上双引号""并逗号,隔开，  	示例："Path1","Path2","Path3")
        filebatch3 := getfiles3(getZz)								;完整路径，(多选文件时，逗号,加空格隔开  	示例：Path1, Path2, Path3)

        fileName2 := system_file_path_zz(getZz,"name")				;名称[换行输出选中的多个文件]
        fileNameNoExt2 := system_file_path_zz(getZz,"NameNoExt")	;无后缀名称[换行输出选中的多个文件]

        filetest :=StrSplit(getZz, "\")
        filebatch4 := filetest[filetest.Length - 1] 			;获取选中文件的目录的名称 示例：C:\win10\娱乐 获取的是 win10	 ; V1toV2: Verify V2 Length value = V1 MaxIndex
        ;══════════════════════获取选中文件的更多变量(单个选中)════════════════════════════════════════════════════
        filedir :=""					; %filedir%				目录
        fileExt :=""					; %fileExt%				后缀
        fileNameNoExt :=""				; %fileNameNoExt%		无后缀名称
        fileDrive :=""					; %fileDrive%			盘符
        filelnkTarget :=""				; %filelnkTarget%		lnk指向路径
        filelnkDir :=""					; %filelnkDir%			lnk指向目录
        filelnkArgs :=""				; %filelnkArgs%			lnk参数
        filelnkDesc :=""				; %filelnkDesc%			lnk注释
        filelnkIcon :=""				; %filelnkIcon%			lnk图标文件名
        filelnkIconNum :=""				; %filelnkIconNum%		lnk图标编号
        filedirlnkRunState :=""			; %filedirlnkRunState%	lnk初始运行方式
        Loop Parse, getZz, "`n", "`r, " A_Space "" A_Tab
        {
            if(!A_LoopField)
                continue
            SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
            if(ext="lnk")
                FileGetShortcut(A_LoopField, &lnkTarget, &lnkDir, &lnkArgs, &lnkDesc, &lnkIcon, &lnkIconNum, &lnkRunState)
            fileName:=name
            filedir:=dir
            fileExt:=ext
            fileNameNoExt:=nameNoExt
            fileDrive:=drive
            filelnkTarget:=lnkTarget
            filelnkDir:=lnkDir
            filelnkArgs:=lnkArgs
            filelnkDesc:=lnkDesc
            filelnkIcon:=lnkIcon
            filelnkIconNum:=lnkIconNum
            filedirlnkRunState:=lnkRunState
        }

        switch func
        {

        case 1:
            SendInput("^a")
            RunAny_Send_WM_COPYDATA("Menu_Show", "RunAny.ahk ahk_class AutoHotkey")
        case 2:		;保存到RunAny.ini为：百度搜索选中文件|XiaoYao_plus[RA_plus](%getZz%,,2)				
            Loop Parse, fileNameNoExt2, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                Run("https://www.baidu.com/s?wd=" xiaoyaoStr)
            }
        case 3:		;保存到RunAny.ini为：添加到开机自启|XiaoYao_plus[RA_plus](%getZz%,,3)		
            RunWait("reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v `"" fileNameNoExt "`" /t REG_SZ /d " filebatch " /f")
            ttip("添加成功",1500)		
        case 4:	
            时间日期跨度计算器() ; V1toV2: Gosub
        case 5:		;新建TXT	文本文档		
            if FileExist(filebatch5) ;判断填写的目录是否真实存在
            { 
                FileAppend(, filebatch5 "\新建文本_" A_Now "." plusxy_Path)
            }
            else
            {
                MsgBox("出错了！请在资源管理器窗口为当前激活时使用。")
            }

        case 6:		;合并文件夹
  Loop Parse, getZz, "`n", "`r"
{ 
    SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
    合并文件夹名称路径:= dir
    if InStr(FileExist(A_LoopField), "D") ;判断指定的文件路径是否为文件夹
        合并文件夹名称合集 := 合并文件夹名称合集 name "|" 
}
合并文件夹名称合集 := SubStr(合并文件夹名称合集, 1, StrLen(合并文件夹名称合集) - 1) ;删除字符串的最后一个字符
;MsgBox,%合并文件夹名称合集%



global hbgetZz := getZz
global hb合并文件夹名称路径 := 合并文件夹名称路径
global hb合并文件夹名称合集 := 合并文件夹名称合集
合并文件夹功能() ; V1toV2: Gosub

        case 7:		;保存到RunAny.ini为：解散文件夹|XiaoYao_plus[RA_plus](%getZz%,,7)		
            Filename :=""
            Loop Parse, getZz, "`n", "`r"
            { 
                Loop Files, A_LoopField "\*.*", "R" ; 递归子文件夹.
                {
                    Filename :=Filename A_LoopFilePath "`n" 
                }
            }
            Filename := SubStr(Filename, 1, StrLen(Filename) - 1) ;删除字符串的最后一个字符
            ;MsgBox,%Filename%
            ;clipboard = %Filename%
            filemove1(Filename, filedir)
            Loop 8
            {
                Loop Parse, getZz, "`n", "`r"
                { 
                    Loop Files, A_LoopField "\*.*", "DR" ; 包括子文件夹.
                    {
                        DirDelete(A_LoopFilePath) ;删除目录, 但仅限于空目录          
                        ;MsgBox, %A_LoopFileFullPath%
                    }
                }
            }
            Loop Parse, getZz, "`n", "`r"
            { 
                DirDelete(A_LoopField) ;删除目录, 但仅限于空目录.        
            } 
        case 8:	;起始(删除一整行);
            Send("{Home}")
            Send("+{End}")
            Send("{delete}")
        case 9:	;复制一整行
            Send("{home}")
            Send("+{end}")
            Send("^c")
        case 10:	;保存到RunAny.ini为：当前目录打开CMD|XiaoYao_plus[RA_plus](,,10)	
            Run(A_ComSpec " /k pushd `"" filebatch5 "`"")
        case 11:	;保存到RunAny.ini为：ev搜当前目录|XiaoYao_plus[RA_plus](,%"Everything.exe"%,11)
            Run(plusxy_Path " -p `"" filebatch5 "`"")
            ;ev搜当前目录		
        case 13:	;创建日期文件夹
            if FileExist(filebatch5) ;判断填写的目录是否真实存在
            { 
                DirCreate(filebatch5 "\" A_YYYY "" A_MM "" A_DD)
            }
            else
            {
                MsgBox("出错了！请在资源管理器窗口为当前激活时使用。")
            }	
        case 14:	;文件分类
            filemove2(getZz)
        case 15:	;颜色神偷
            MouseGetPos(&mouseX, &mouseY)
            ; 获得鼠标所在坐标，把鼠标的 X 坐标赋值给变量 mouseX ，同理 mouseY
            color := PixelGetColor(mouseX, mouseY)
            ; 调用 PixelGetColor 函数，获得鼠标所在坐标的 RGB 值，并赋值给 color
            color := SubStr(color, -1*(6))
            ; 截取 color（第二个 color）右边的6个字符，因为获得的值是这样的：#RRGGBB，一般我们只需要 RRGGBB 部分。把截取到的值再赋给 color（第一个 color）。
            A_Clipboard := color
            ; 把 color 的值发送到剪贴板
            ToolTip("当前鼠标所指位置`n颜色已复制：`n" color) ; 显示提示信息
            Sleep(1500) ; 延时1秒
            ToolTip() ; 关闭提示信息
        case 16:	
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext

                suffix := ""
                if (A_Index > 1)
                    suffix := A_Index
                RunWait(A_ComSpec " /c pushd `"" redir "`" && rename `"" rename1 "`" `"" A_Clipboard "" suffix "." ext "`"", , "Hide")

            }
            ttip("重命名成功",1500)
        case 17:	
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext

                suffix := ""
                if (A_Index > 1)
                    suffix := A_Index
                RunWait(A_ComSpec " /c pushd `"" redir "`" && rename `"" rename1 "`" `"" A_Clipboard "" suffix "`"", , "Hide")

            }
            ttip("重命名成功",1500)
        case 18:	;移动到新建文件夹[弹框版]

            IB := InputBox("请输入新建文件夹的名称：", "", "w300 h123", fileNameNoExt), 文件夹名称1 := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if (ErrorLevel || StrLen(文件夹名称1) == 0) {
                Return
            }
            DirCreate(filedir "\" 文件夹名称1)
            FolderPath1 := filedir . "\" 文件夹名称1 . "\"
            ;MsgBox, %FolderPath1%
            filemove1(getZz, FolderPath1)
        case 19:	;v2rayN快捷开启代理【热键映射，加一键两用】
            detectApp("v2rayN.exe",plusxy_Path)
            v2rayN一键两用()

        case 20:	;给选中的路径格式换成双反斜杠，并用双引号括住
            getZz10 := StrReplace(getZz, "\\", "\")
            getZz10 := StrReplace(getZz10, "`"", "")
            getZz20 := StrReplace(getZz10, "\", "\\")

            Loop Parse, getZz20, "`n", "`r"
            {
                files := files "`"" A_LoopField "`"`n"
            }
            if(StrLen(files) < 1) {
                Return
            }
            files := SubStr(files, 1, StrLen(files) - 1) ;删除字符串的最后一个字符
            A_Clipboard := files
            SendInput("^v")
        case 21:	
            RunAny_Send_WM_COPYDATA("runany[Remote_Menu_Run](腾讯, getZz)", "RunAny.ahk ahk_class AutoHotkey")
        case 22:	;颜色神偷[GUI版]
            lx := A_ScreenWidth - 110
            ly := 60
            yanse := Gui()
            yanse.Opt("+AlwaysOnTop +ToolWindow -caption")
            yanse.Add("Text", "x1 y10 w60", "按ESC退出")
            yanse.Add("Text", "x1 y25 w60", "按Alt复制")
            ;Gui, Add, Text, x1 y25 w35,

            yanse.Show("NoActivate W69 H55 X" . lx . " Y" . ly)
            Gosub color ; V1toV2: Gosub (Manual edit required)
        return
        color:
            Loop
            {
                MouseGetPos(&x, &y)
                c := PixelGetColor(x, y)
                c := SubStr(c, -1*(6))
                yanse.Add("Text", "x1 y40 w60", c)
                if (c != c2)
                {
                    c2 := c
                    yanse.BackColor := c

                    ; GUICONTROL,,Static1,%c%
                    ;traytip,,WIN+C复制 `n %c%
                }
                Sleep(100)
                if GetKeyState("Esc")	;判断是否按下 Esc 键
                {
                    Try yanse.Destroy() ; 关闭 GUI 窗口
                    Break ; 结束循环

                }
                if GetKeyState("Alt") ; 判断是否按下 Alt 键
                {
                    A_Clipboard := c ; 复制颜色值到剪切板
                    ToolTip("颜色已复制：`n" c) ; 显示提示信息
                    Sleep(1000) ; 延时1秒
                    ToolTip() ; 关闭提示信息
                }
            }		
        case 23:	;设置桌面背景
            DllCall("SystemParametersInfo", "UInt", 0x14, "UInt", 0, "Str", "" getZz "", "UInt", 2)
        case 24:	;交换文件名称：选中两个文件，然后把这两个文件的名字互换，它节省了两个文件名互换至少需要的三个步骤，直接简化成一个步骤
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                xiaoyaoStr1:=xiaoyaoStr "`n" xiaoyaoStr1
                renameNoExt:=nameNoExt "`n" renameNoExt
                redir:=dir "`n" redir
                reext:=ext "`n" reext
                rename1:=name "`n" rename1
            }				
            result := StrSplit(renameNoExt, "`n")
            number3 := result[1]
            number4 := result[2]

            result := StrSplit(redir, "`n")
            number5 := result[1]
            number6 := result[2]

            result := StrSplit(reext, "`n")
            number7 := result[1]
            number8 := result[2]

            result := StrSplit(rename1, "`n")
            number9 := result[1]
            number10 := result[2]

            RunWait(A_ComSpec " /c pushd `"" number5 "`" && rename `"" number9 "`" `"xiaoyao_plus正在改." number7 "`"", , "Hide")
            Sleep(400)
            RunWait(A_ComSpec " /c pushd `"" number6 "`" && rename `"" number10 "`" `"" number3 "." number8 "`"", , "Hide")
            Sleep(400)
            RunWait(A_ComSpec " /c pushd `"" number5 "`" && rename `"xiaoyao_plus正在改." number7 "`" `"" number4 "." number7 "`"", , "Hide")
        case 25:	
            IB := InputBox("请输入重命名后的名称：", "", "w300 h123", "xiaoyaoplus"), 重命名后的名称 := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(重命名后的名称) == 0) {
                Return
            }
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext

                suffix := ""
                if (A_Index > 1)
                    suffix := A_Index
                RunWait(A_ComSpec " /c pushd `"" redir "`" && rename `"" rename1 "`" `"" 重命名后的名称 "" suffix "." ext "`"", , "Hide")

            }
            ttip("重命名成功",1500)
        case 26:	
            IB := InputBox("请输入后缀格式：", "", "w300 h123", "mp4"), 只改后缀 := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(只改后缀) == 0) {
                Return
            }
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext

                suffix := ""
                if (A_Index > 1)
                    suffix := A_Index
                RunWait(A_ComSpec " /c pushd `"" redir "`" && rename `"" rename1 "`" `"" rename1 "." 只改后缀 "`"", , "Hide")
            }
            ttip("改后缀成功",1500)
        case 27:	;移动/复制到[标准对话框版]
            global MoveButtongetZz := getZz
            MoveCopyGui() ; V1toV2: Gosub
        case 28:	;移到上层文件夹
            ;获取目录的上一层目录
            result := RegExReplace(filedir, "\\[^\\]*$", "")
            result := result . "\"
            ;MsgBox % result
            filemove1(getZz, result)	
        case 29:	;移到上上层文件夹
            result := RegExReplace(filedir, "\\[^\\]*\\[^\\]*$", "")
            result := result . "\"
            ;MsgBox % result
            filemove1(getZz, result)	
        case 30:	;复制到上层文件夹
            ;获取目录的上一层目录
            result := RegExReplace(filedir, "\\[^\\]*$", "")
            result := result . "\"
            ;MsgBox % result
            filecopy1(getZz, result)	
        case 31:	;复制上上层文件夹
            result := RegExReplace(filedir, "\\[^\\]*\\[^\\]*$", "")
            result := result . "\"
            ;MsgBox % result
            filecopy1(getZz, result)
        case 32:	;一级解散
            Filename :=""
            Loop Parse, getZz, "`n", "`r"
            { 
                Loop Files, A_LoopField "\*.*", "FD" ; 包括子文件夹.
                {
                    Filename :=Filename A_LoopFilePath "`n" 
                }
            }
            Filename := SubStr(Filename, 1, StrLen(Filename) - 1) ;删除字符串的最后一个字符
            ;MsgBox,%Filename%
            ;clipboard = %Filename%
            filemove1(Filename, filedir)
            Loop 8
            {
                Loop Parse, getZz, "`n", "`r"
                { 
                    Loop Files, A_LoopField "\*.*", "DR" ; 包括子文件夹.
                    {
                        DirDelete(A_LoopFilePath) ;删除目录, 但仅限于空目录          
                        ;MsgBox, %A_LoopFileFullPath%
                    }
                }
            }
            Loop Parse, getZz, "`n", "`r"
            { 
                DirDelete(A_LoopField) ;删除目录, 但仅限于空目录.        
            } 
        case 33:	;创建副本：选中文件快速创建文件副本
            Loop Parse, getZz, "`n", "`r"
            { 
                SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
                Loop 400
                {
                    Try {
                        DirCopy(A_LoopField, dir "\" nameNoExt "" A_Now)
                        ErrorLevel := 0
                    } Catch {
                        ErrorLevel := 1
                    }
                    if(ErrorLevel){ 	 	
                        Try {
                            FileCopy(A_LoopField, dir "\" nameNoExt "" A_index "." ext)
                            ErrorLevel := 0
                        } Catch as Err {
                            ErrorLevel := Err.Extra
                        }
                        if(ErrorLevel){
                        }
                        else
                        {
                            break	
                        }
                    }
                    else
                    {
                        break	
                    } 		
                } 
            } 
        case 34:	;文件分类[按年分类]   
            Loop Parse, getZz, "`n", "`r"
            { 
                ModifyTime := FileGetTime(A_LoopField)
                Year := FormatTime(ModifyTime, "yyyy")
                DirCreate(filedir "\" Year)
                FolderPath1 := filedir . "\" Year . "\"
                ;MsgBox, %FolderPath1%
                filemove1(A_LoopField, FolderPath1)	
            }
        case 35:	;文件分类[按月份分类]   
            Loop Parse, getZz, "`n", "`r"
            { 
                SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
                ModifyTime := FileGetTime(A_LoopField)
                Year := FormatTime(ModifyTime, "yyyy-MM")
                DirCreate(filedir "\" Year)
                FolderPath1 := filedir . "\" Year . "\"
                ;MsgBox, %FolderPath1%
                filemove1(A_LoopField, FolderPath1)	
            } 
        case 36:	;文件分类[按日分类]   
            Loop Parse, getZz, "`n", "`r"
            { 
                SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
                ModifyTime := FileGetTime(A_LoopField)
                Year := FormatTime(ModifyTime, "yyyy-MM-dd")
                DirCreate(filedir "\" Year)
                FolderPath1 := filedir . "\" Year . "\"
                ;MsgBox, %FolderPath1%
                filemove1(A_LoopField, FolderPath1)	
            } 
        case 37:	;查看wifi密码   
            所有连过的wifi :=cmdClipReturn("netsh wlan show profiles",1)
            Loop Parse, 所有连过的wifi, "`n"
            {
                if (RegExMatch(A_LoopField, ".*All User Profile.*", &wifi名))
                {
                    wifi名 := StrSplit((wifi名&&wifi名[0]), ":")
                    wifi名 := Trim(wifi名[2])
                    wifi密码 :=cmdClipReturn("netsh wlan show profile name=`"" (wifi名&&wifi名[0]) "`" key=clear",1)

                    Loop Parse, wifi密码, "`n"
                    {
                        if (RegExMatch(A_LoopField, ".*Key Content.*", &wifi密码2))
                        { 
                            wifi密码2 := StrSplit((wifi密码2&&wifi密码2[0]), ":")
                            wifi密码2 := Trim(wifi密码2[2])					
                            wifi组合:="WIFI名称：" (wifi名&&wifi名[0]) "`t 密码：" (wifi密码2&&wifi密码2[0])
                            XiaoYao_plusGUI(wifi组合)
                        }
                    }
                }
            } 
        case 38:	;当前窗口标题获取
            窗口标题 := WinGetTitle("A")
            regex := "(.*)\s-\s.*"
            窗口标题 := RegExReplace(窗口标题, regex, "$1") 
            XiaoYao_plusGUI(窗口标题)
        case 39: ;属性隐藏
            Loop Parse, getZz, "`n", "`r"
            {
                FileExistZ(A_LoopField,,"+=0x2")
            } 
        case 40: ;属性取消隐藏
            Loop Parse, getZz, "`n", "`r"
            {
                FileExistZ(A_LoopField,,":=0x80")
            } 
        case 41: ;属性取消/显示隐藏
            Loop Parse, getZz, "`n", "`r"
            {
                FileExistZ(A_LoopField,,"^=0x2")
            } 
        case 42: ;获取文件的属性信息           
            Loop Parse, getZz, "`n", "`r"
            {
                XiaoYao_plusGUI(FileGetAttrib(A_LoopField))
            } 
        case 43: ;显示活动窗口进程的命令行 
            pid := WinGetPID("A")
            ; 获取 WMI 服务对象.
            wmi := ComObjGet("winmgmts:")
            ; 执行查询以获取匹配进程.
            queryEnum := wmi.ExecQuery(""
            . "Select * from Win32_Process where ProcessId=" . pid)
            ._NewEnum()
            ; 获取首个匹配进程.
            if queryEnum[proc]
                XiaoYao_plusGUI(proc.CommandLine)
            else
                XiaoYao_plusGUI("Process not found!")
            ; 释放所有全局对象(使用局部变量时不需要这么做).
            wmi := queryEnum := proc := ""
        case 44: ;窗口局部置顶工具
            窗口句柄 := WinGetID("A")
            Run(plusxy_Path " --windowId=" 窗口句柄, , "Hide")
        case 45: ; 把任何复制的文件, HTML 或其他格式的文本转换为纯文本.
            ClipSaved := ClipboardAll() ; 保存剪贴板内容
            A_Clipboard := A_Clipboard 
            SendInput("^v")
            Sleep(1000)
            A_Clipboard := ClipSaved ; 还原剪贴板内容
            ClipSaved := "" ; 清空剪贴板保存的内容
        case 46: ; 去除换行、回车和垂直TAB
            ClipSaved := ClipboardAll() ; 保存剪贴板内容
            A_Clipboard := StrReplace(A_Clipboard, "`r`n")
            A_Clipboard := StrReplace(A_Clipboard, "`v")
            A_Clipboard := StrReplace(A_Clipboard, "`t") 
            SendInput("^v")
            Sleep(1000)
            A_Clipboard := ClipSaved ; 还原剪贴板内容
            ClipSaved := "" ; 清空剪贴板保存的内容
        case 47: ;字数统计
            总字符数 := StrLen(getZz) ; 总字符数
            RegExReplace(getZz, "(?<NonAscii>[^\x00-\x7f])|(?<Ascii>[\x21-\x7f]+)", , &所有字符) ; 匹配所有字符
            RegExReplace(getZz, "(?m)^(?>[^\r\n]*\r?$\n?)", , &行数) ; 行数
            RegExReplace(getZz, "[一-龥]", , &中字数) ; 中字数
            RegExReplace(getZz, "\w+", , &英字数) ; 英字数
            ;MsgBox % "总字符数为: " 总字符数 "`n字数: " 所有字符 "`n行数: " 行数 "`n中字数(不含标点): " 中字数 "`n中字数: " 英字数
            XiaoYao_plusGUI("`n字数: " 所有字符 "`n行数: " 行数 "`n中字数(不含标点): " 中字数 "`n英字数: " 英字数 "`n总字符数为: " 总字符数 )
        case 48: ;插入千位分隔符
            千分位加逗号 := RegExReplace(getZz, "(\d{1,3})(?=(\d{3})+(?:$|\.))", "$1,")
            A_Clipboard := 千分位加逗号
            SendInput("^v")
            Sleep(1000)
        case 49: ;用来删除行首行尾的空白字符(包括空格、制表符、换页符等等)
            删除首尾空白 := RegExReplace(getZz, "m)^\s*|\s*$") ;首尾空白字符的正则表达式
            ClipSaved := ClipboardAll() ; 保存剪贴板内容
            A_Clipboard := 删除首尾空白 
            SendInput("^v")
            Sleep(1000)
            A_Clipboard := ClipSaved ; 还原剪贴板内容
            ClipSaved := "" ; 清空剪贴板保存的内容
        case 50: ;记录鼠标坐标
            global 坐标记录次数 := plusxy_Path
            记录鼠标坐标() ; V1toV2: Gosub
case 51:
Cando_颜色查看() ; V1toV2: Gosub



            ;Bandizip功能-----------------------------------
        case 1001:		
            Run(plusxy_Path " bx -target:auto " filebatch)
        case 1002:		
            Run(plusxy_Path " bx -o:`"" filedir "`" " filebatch)
        case 1003:		
            Run(plusxy_Path " cd `"" filedir "\" fileNameNoExt ".zip`" " filebatch)
        case 1004:		
            Run(plusxy_Path " bc -aoa -o:`"" filedir "`" " filebatch)
            ;保存到RunAny.ini为：		
            ;Bz智能解压|XiaoYao_plus[RA_plus](%getZz%,%"Bandizip.exe"%,1001)
            ;Bz解压(非智能)|XiaoYao_plus[RA_plus](%getZz%,%"Bandizip.exe"%,1002)
            ;Bz压缩|XiaoYao_plus[RA_plus](%getZz%,%"Bandizip.exe"%,1003)
            ;Bz分别压缩|XiaoYao_plus[RA_plus](%getZz%,%"Bandizip.exe"%,1004)

            ;Snipaste功能-----------------------------------
        case 2001:
            detectApp("Snipaste.exe",plusxy_Path)
            Run(plusxy_Path " snip")
        case 2002:
            detectApp("Snipaste.exe",plusxy_Path)
            If (getZz!="")
                Run(plusxy_Path " paste --files " getZz)
            Else
                Run(plusxy_Path " paste")
        case 2003:
            detectApp("Snipaste.exe",plusxy_Path)
            Run(plusxy_Path " snip -o pin")
        case 2004:
            detectApp("Snipaste.exe",plusxy_Path)
            Run(plusxy_Path " snip --full -o clipboard")
            ttip("放入剪切板",500) 
        case 2005:
            detectApp("Snipaste.exe",plusxy_Path)
            Run(plusxy_Path " snip -o quick-save")
            ttip("存入文件夹",500)
        case 2006:
            detectApp("Snipaste.exe",plusxy_Path)
            If (getZz!="")
                Run(plusxy_Path " paste --plain " getZz)
            Else
                Run(plusxy_Path " paste --plain")
        case 2007:
            detectApp("Snipaste.exe",plusxy_Path)
            Run(plusxy_Path " whiteboard")
            ;保存到RunAny.ini为：
            ;sinp截图|XiaoYao_plus[RA_plus]("%getZz%",%"Snipaste.exe"%,2001)
            ;sinp选中图片贴图|XiaoYao_plus[RA_plus]("%getZz%",%"Snipaste.exe"%,2002)
            ;截图后贴图|XiaoYao_plus[RA_plus]("%getZz%",%"Snipaste.exe"%,2003)
            ;全屏截图放剪切板|XiaoYao_plus[RA_plus]("%getZz%",%"Snipaste.exe"%,2004)
            ;截图放快速文件夹|XiaoYao_plus[RA_plus]("%getZz%",%"Snipaste.exe"%,2005)
            ;纯文本贴图|XiaoYao_plus[RA_plus]("%getZz%",%"Snipaste.exe"%,2006)
            ;白板|XiaoYao_plus[RA_plus]("%getZz%",%"Snipaste.exe"%,2007)

            ;7zip功能-----------------------------------
        case 4001:		
            Run(plusxy_Path " x " filebatch)
        case 4002:		
            Run(plusxy_Path " a " filebatch)
        case 4003:			
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir)
                redir:=dir
                Run(plusxy_Path " x `"" xiaoyaoStr "`" -o`"" redir "`" -y -aou")
            }
        case 4004:		
            Run(plusxy_Path " a `"" filedir "\" fileNameNoExt ".zip`" " filebatch)
        case 4005:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                Run(plusxy_Path " a `"" redir "\" reNameNoExt ".zip`" `"" xiaoyaoStr "`"")
            }

            ;保存到RunAny.ini为：
            ;7z解压|XiaoYao_plus[RA_plus](%getZz%,%"SmartZip.exe"%,4001)
            ;7z压缩|XiaoYao_plus[RA_plus](%getZz%,%"SmartZip.exe"%,4002)
            ;7z解压1|XiaoYao_plus[RA_plus](%getZz%,%"SmartZip.exe"%,4003)
            ;7z压缩1|XiaoYao_plus[RA_plus](%getZz%,%"SmartZip.exe"%,4004)
            ;7z分别压缩|XiaoYao_plus[RA_plus](%getZz%,%"SmartZip.exe"%,4005)

            ;IObitUnlocker解除占用功能-----------------------------------
        case 5001:		
            Run(plusxy_Path " /None " filebatch2)
        case 5002:		
            Run(plusxy_Path " /Delete " filebatch2)
        case 5003:		
            Run(plusxy_Path " /Copy " filebatch2 " `"D:\下载`"")
        case 5004:		
            Run(plusxy_Path " /Move " filebatch2 " `"D:\下载`"")
            ;保存到RunAny.ini为：
            ;解锁[#]|XiaoYao_plus[RA_plus](%getZz%,%"IObitUnlocker.exe"%,5001)
            ;删除[#]|XiaoYao_plus[RA_plus](%getZz%,%"IObitUnlocker.exe"%,5002)
            ;复制到D下载[#]|XiaoYao_plus[RA_plus](%getZz%,%"IObitUnlocker.exe"%,5003)
            ;移动到D下载[#]|XiaoYao_plus[RA_plus](%getZz%,%"IObitUnlocker.exe"%,5004)

            ;360极速浏览器功能-----------------------------------
        case 6001:

            if WinActive("ahk_exe 360ChromeX.exe")
            {
                Send("^t")									; 新建标签页并定位到地址栏
                Send("{TEXT}chrome://bookmarks/#q=" getZz)	; 发送地址栏中的网址
                Send("{Enter}")

            }
            else
            {	
                RunWait(plusxy_Path " --new-tab")
                Sleep(1000)
                WinActivate("ahk_exe 360ChromeX.exe")			; 激活浏览器窗口
                ErrorLevel := !WinWaitActive("ahk_exe 360ChromeX.exe")		; 等待浏览器窗口激活	
                Send("^t")									; 新建标签页并定位到地址栏
                Send("{TEXT}chrome://bookmarks/#q=" getZz)	; 发送地址栏中的网址
                Send("{Enter}")
            }
        case 6002:		
            if WinActive("ahk_exe 360ChromeX.exe")
            {
                ; 定位到地址栏
                Send("^l")

                ; 输入 JavaScript 代码
                SendInput("{TEXT}JavaScript:")

                    ; 设置剪贴板内容
                    Clipboard :=
                    (
                "!function(){function t(e){e.stopPropagation(),e.stopImmediatePropagation&&e.stopImmediatePropagation()}document.querySelectorAll(`"*`").forEach(e=>{`"none`"===window.getComputedStyle(e,null).getPropertyValue(`"user-select`")&&e.style.setProperty(`"user-select`",`"text`",`"important`")}),[`"copy`",`"cut`",`"contextmenu`",`"selectstart`",`"mousedown`",`"mouseup`",`"mousemove`",`"keydown`",`"keypress`",`"keyup`"].forEach(function(e){document.documentElement.addEventListener(e,t,{capture:!0})}),alert(`"解除限制成功啦！`")}();"
                )

                ; 发送快捷键 Ctrl + V，将 JavaScript 代码粘贴到地址栏
                Send("^v")

                ; 发送 Enter 键，执行 JavaScript 代码
                Send("{Enter}")
            }	
        case 6003:		
            ClipSaved := ClipboardAll() 	;保存剪贴板内容
            A_Clipboard := getZz 		;将选中文字复制到剪贴板
            Send("^+p")					;按下沙拉查词的快捷键[搜索剪贴板内容] ctrl+shift+P
            Sleep(1000)
            A_Clipboard := ClipSaved 	;还原剪贴板内容	
            ClipSaved := "" 			; 清空剪贴板保存的内容

        case 6004:		

        }
    }

    ;托盘悬浮---------------------------------------------------------------------------
    TaskbarTray2(){
        ;托盘悬浮|XiaoYao_plus[TaskbarTray2]()		
        CoordMode("Mouse", "Screen")
        MouseGetPos(&X, &Y)
        if WinActive("ahk_class NotifyIconOverflowWindow")
            WinHide("ahk_class NotifyIconOverflowWindow")
        Else
        {
            DetectHiddenWindows(true)
            WinGetPos(&X1, &Y1, &W, &H, "ahk_class NotifyIconOverflowWindow")
            if (Y <= A_ScreenHeight / 2)
            Y := Y + 15				
            else
                Y := Y - H - 15
            if (X < W / 2)
            X := 0
            else if (X > A_ScreenWidth - W / 2)
            X := A_ScreenWidth - W
            else
                X := X - W / 2 
            WinMove(X, Y, , , "ahk_class NotifyIconOverflowWindow")
            WinShow("ahk_class NotifyIconOverflowWindow")
            WinActivate("ahk_class NotifyIconOverflowWindow")
            SetTimer(NIOFHide,100)
        }
        Return
        NIOFHide:
            if !WinActive("ahk_class NotifyIconOverflowWindow")
            {
                WinHide("ahk_class NotifyIconOverflowWindow")
                SetTimer(NIOFHide,0)
            }
        Return
    }

    ;生成随机密码---------------------------------------------------------------------------
    ;kind:类型 W大写 w小写 d数字 可以组合 length:长度
    RandomPass2(kind:="Wwd",length:=8){
        A_Clipboard:=	RandomPass(kind,length)
        Send("^v")
        ttip("生成成功并放入剪贴板",1000)
    }

    ;══════════════════════════════════移动选中文件/文件夹到══════════════════════════════════	
    movefile1(getZz,Des_path,func:="1"){	
        switch func
        {
        case 1: 
            filemove1(getZz, Des_path)
        case 2:
            arr := StrSplit(getZz, "\")
            result := arr[1] . "\"
            filemove1(getZz, result)
        }
    }	
    ;══════════════════════════════════复制选中文件/文件夹到══════════════════════════════════	
    copyfile1(getZz,Des_path,func:="1"){	
        switch func
        {
        case 1: 
            filecopy1(getZz, Des_path)
        case 2:
            arr := StrSplit(getZz, "\")
            result := arr[1] . "\"
            filecopy1(getZz, result)
        }
    }
    ;══════════════════════════════════只复制文件夹的骨架══════════════════════════════════	
    copyfile2(getZz,Des_path){	
        Loop Parse, getZz, "`n", "`r"
        {
            xiaoyaoStr:=A_LoopField
            SplitPath(xiaoyaoStr, &name, &dir)
            rename1:=name
            redir:=dir
            RunWait("robocopy `"" xiaoyaoStr "`" `"" Des_path "\" rename1 "`" /e /minage:19000101", , "Hide")
        }
        ttip("复制成功",1000)
    }	

    ;══════════════════════════════════ImageMagick功能══════════════════════════════════	
    ImageMagick(getZz,plusxy_Path,formatExt,func){
        getZz := Sort(getZz)
        filebatch := getfiles(getZz)								;完整路径，(多选文件时，自动加上双引号""并空格隔开，  	示例："Path1" "Path2" "Path3")
        filedir :=""					; %filedir%				目录
        Loop Parse, getZz, "`n", "`r, " A_Space "" A_Tab
        {
            if(!A_LoopField)
                continue
            SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
            if(ext="lnk")
                FileGetShortcut(A_LoopField, &lnkTarget, &lnkDir, &lnkArgs, &lnkDesc, &lnkIcon, &lnkIconNum, &lnkRunState)
            filedir:=dir
        }
        switch func
        {
        case 1:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" `"" redir "\转换_" reNameNoExt "." formatExt "`"", , "Hide")
            }
            ttip("转换成功",1000)		
        case 2:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" -quality " formatExt " -strip `"" redir "\压缩" formatExt "_" reNameNoExt "." renameExt "`"", , "Hide")
            }
            ttip("压缩成功",1000)
        case 3:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" -rotate " formatExt " `"" redir "\旋转" formatExt "_" reNameNoExt "." renameExt "`"", , "Hide")
            }
            ttip("旋转成功",1000)		
        case 4:		
            Run(plusxy_Path " convert " filebatch " " formatExt " `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
            ttip("拼接成功",1000)		
        case 5:		
            Run(plusxy_Path " clipboard: `"" formatExt "\剪贴_" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
            ttip("保存成功",1000)	
        case 6:				
            Run(plusxy_Path " montage " filebatch " -geometry +10+10 -tile " formatExt " `"" filedir "\高级拼接.jpg`"", , "Hide")
            ;Run %plusxy_Path% montage -mode concatenate -tile %formatExt% %filebatch%  -background white -geometry 300x200+10+10 "%filedir%\高级拼接.jpg", , Hide
            ttip("拼接成功",1000)
        case 7:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" -thumbnail " formatExt " `"" redir "\缩略图" formatExt "_" reNameNoExt "." renameExt "`"", , "Hide")
            }
            ttip("生成成功",1000)		
        case 8:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" -resize " formatExt " `"" redir "\尺寸" formatExt "_" reNameNoExt "." renameExt "`"", , "Hide")
            }
            ttip("尺寸调整成功",1000)
        case 9:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" -flatten -background white -alpha remove `"" redir "\白色背景_" reNameNoExt "." formatExt "`"", , "Hide")
            }
            ttip("转换成功",1000)

        case 10:	
            IB := InputBox("如想设置拼接的宽度为800，就输入：800`n`n提示：高度会按比例自动进行缩放，保持纵横比，无需设置", "请输入垂直拼接的统一宽度", "h200"), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }
            msgResult := MsgBox("是否添加文件名水印？", "提示", 4)
            if (msgResult = "Yes")
            {
                RunWait(A_ComSpec " /c pushd `"" filedir "`" && md `"临时存放_xiaoyao`"", , "Hide")
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename11:=name
                    redir:=dir
                    renameNoExt:=nameNoExt
                    output1 := "`"" . dir . "`\临时存放_xiaoyao`\暂时" . name . "`""
                    output2 := "`"" . dir . "`\临时存放_xiaoyao`\" . name . "`""
                    fname_list .= A_Space output2
                    RunWait(plusxy_Path " convert `"" xiaoyaoStr "`" -resize " userInput "x " output1, , "Hide")
                    RunWait(plusxy_Path " convert " output1 " -background white -fill black -font simhei -pointsize 20 -gravity north -splice 0x27 -annotate +0+5 `"" nameNoExt "`" " output2, , "Hide")
                }
                RunWait(plusxy_Path " convert " fname_list " -append `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
                output3 := filedir . "`\临时存放_xiaoyao"
                DirDelete(output3, 1)
                ttip("拼接成功",1000)
            } 
            else
            {
                RunWait(A_ComSpec " /c pushd `"" filedir "`" && md `"临时存放_xiaoyao`"", , "Hide")
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename11:=name
                    redir:=dir
                    renameNoExt:=nameNoExt
                    output1 := "`"" . dir . "`\临时存放_xiaoyao`\" . name . "`""
                    fname_list .= A_Space output1
                    RunWait(plusxy_Path " convert `"" xiaoyaoStr "`" -resize " userInput "x " output1, , "Hide")
                }
                RunWait(plusxy_Path " convert " fname_list " -append `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
                output3 := filedir . "`\临时存放_xiaoyao"
                DirDelete(output3, 1)
                ttip("拼接成功",1000)
            }												

        case 11:	
            IB := InputBox("如想设置拼接的高度为800，就输入：800`n`n提示：宽度会按比例自动进行缩放，保持纵横比，无需设置", "请输入水平拼接的统一高度", "h200"), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }
            msgResult := MsgBox("是否添加文件名水印？", "提示", 4)
            if (msgResult = "Yes")
            {
                RunWait(A_ComSpec " /c pushd `"" filedir "`" && md `"临时存放_xiaoyao`"", , "Hide")
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename11:=name
                    redir:=dir
                    renameNoExt:=nameNoExt
                    output1 := "`"" . dir . "`\临时存放_xiaoyao`\暂时" . name . "`""
                    output2 := "`"" . dir . "`\临时存放_xiaoyao`\" . name . "`""
                    fname_list .= A_Space output2
                    RunWait(plusxy_Path " convert `"" xiaoyaoStr "`" -resize x" userInput " " output1, , "Hide")
                    RunWait(plusxy_Path " convert " output1 " -background white -fill black -font simhei -pointsize 20 -gravity north -splice 0x27 -annotate +0+5 `"" nameNoExt "`" " output2, , "Hide")
                }
                RunWait(plusxy_Path " convert " fname_list " +append `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
                output3 := filedir . "`\临时存放_xiaoyao"
                DirDelete(output3, 1)
                ttip("拼接成功",1000)
            } 
            else 
            {
                RunWait(A_ComSpec " /c pushd `"" filedir "`" && md `"临时存放_xiaoyao`"", , "Hide")
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename11:=name
                    redir:=dir
                    renameNoExt:=nameNoExt
                    output1 := "`"" . dir . "`\临时存放_xiaoyao`\" . name . "`""
                    fname_list .= A_Space output1
                    RunWait(plusxy_Path " convert `"" xiaoyaoStr "`" -resize x" userInput " " output1, , "Hide")
                }
                RunWait(plusxy_Path " convert " fname_list " +append `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
                output3 := filedir . "`\临时存放_xiaoyao"
                DirDelete(output3, 1)
                ttip("拼接成功",1000)

            }
        case 12:
            IB := InputBox("示例：`n800x600`n如只想指定宽度为800像素，而高度则按比例自动调整`n800x`n如只想指定高度为600像素，而宽度则按比例自动调整`nx600`n如果希望强制将图像拉伸到指定尺寸，可以在尺寸参数后添加感叹号`n800x600`!", "请输入需要生成的图片尺寸", "h300", "800x600"), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" -resize " userInput " `"" redir "\尺寸" userInput "_" reNameNoExt "." renameExt "`"", , "Hide")
            }
            ttip("尺寸调整成功",1000)

        case 13:
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                Run(plusxy_Path " convert `"" xiaoyaoStr "`" " formatExt " `"" redir "\镜像旋转" formatExt "_" reNameNoExt "." renameExt "`"", , "Hide")
            }
            ttip("旋转成功",1000)
        case 15:		
            IB := InputBox("如想设置合并pdf的宽度为800，就输入：800`n`n提示：高度会按比例自动进行缩放，保持纵横比，无需设置", "请输入合并pdf的统一宽度", "h200"), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }
            RunWait(A_ComSpec " /c pushd `"" filedir "`" && md `"临时存放_xiaoyao`"", , "Hide")
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename11:=name
                redir:=dir
                renameNoExt:=nameNoExt
                output1 := "`"" . dir . "`\临时存放_xiaoyao`\" . name . "`""
                fname_list .= A_Space output1
                RunWait(plusxy_Path " convert `"" xiaoyaoStr "`" -resize " userInput "x -density 0 " output1, , "Hide")
            }
            RunWait(plusxy_Path " convert " fname_list " `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".pdf`"", , "Hide")
            output3 := filedir . "`\临时存放_xiaoyao"
            DirDelete(output3, 1)
            ttip("合并成功",1000)

        case 17:		
            Run(plusxy_Path " convert -delay " formatExt " -dispose previous -loop 0 " filebatch " `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".gif`"", , "Hide")
                ttip("保存成功",1000)	
        case 18:
            IB := InputBox("示例：3排3列就输入3x3", "请输入高级拼接的格式", , "3x3"), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }
            msgResult := MsgBox("是否添加文件名水印？", "提示", 4)
            if (msgResult = "Yes")
            {
                RunWait(A_ComSpec " /c pushd `"" filedir "`" && md `"临时存放_xiaoyao`"", , "Hide")
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename11:=name
                    redir:=dir
                    renameNoExt:=nameNoExt
                    output1 := "`"" . dir . "`\临时存放_xiaoyao`\暂时" . name . "`""
                    output2 := "`"" . dir . "`\临时存放_xiaoyao`\" . name . "`""
                    fname_list .= A_Space output2
                    RunWait(plusxy_Path " convert `"" xiaoyaoStr "`" -resize 340x313 -background white -gravity center -extent 340x313 " output1, , "Hide")
                    RunWait(plusxy_Path " convert " output1 " -background white -fill black -font simhei -pointsize 20 -gravity south -splice 0x27 -annotate +0+5 `"" nameNoExt "`" " output2, , "Hide")
                }
                RunWait(plusxy_Path " montage " fname_list " -geometry +10+10 -tile " userInput " `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
                output3 := filedir . "`\临时存放_xiaoyao"
                DirDelete(output3, 1)
                ttip("拼接成功",1000)
            } 
            else
            {
                RunWait(A_ComSpec " /c pushd `"" filedir "`" && md `"临时存放_xiaoyao`"", , "Hide")
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename11:=name
                    redir:=dir
                    renameNoExt:=nameNoExt
                    output1 := "`"" . dir . "`\临时存放_xiaoyao`\" . name . "`""
                    fname_list .= A_Space output1
                    RunWait(plusxy_Path " convert `"" xiaoyaoStr "`" -resize 340x313 -background white -gravity center -extent 340x313 " output1, , "Hide")
                }
                RunWait(plusxy_Path " montage " fname_list " -geometry +10+10 -tile " userInput " `"" filedir "\" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".jpg`"", , "Hide")
                output3 := filedir . "`\临时存放_xiaoyao"
                DirDelete(output3, 1)
                ttip("拼接成功",1000)												
            }			
        case 19:
            global zztext := getZz
            global zzplusxy_Path := plusxy_Path
            imagemagick1() ; V1toV2: Gosub

        }
    }	
    ;══════════════════════════════════ffmpeg功能══════════════════════════════════	
    ffmpeg(getZz,plusxy_Path,formatExt,func){
        getZz := Sort(getZz)
        filebatch := getfiles(getZz)								;完整路径，(多选文件时，自动加上双引号""并空格隔开，  	示例："Path1" "Path2" "Path3")
        filedir :=""					; %filedir%				目录
        fileExt :=""					; %fileExt%				后缀
        fileNameNoExt :=""				; %fileNameNoExt%		无后缀名称
        filebatch7 := getfiles7(getZz)
        Loop Parse, getZz, "`n", "`r, " A_Space "" A_Tab
        {
            if(!A_LoopField)
                continue
            SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
            if(ext="lnk")
                FileGetShortcut(A_LoopField, &lnkTarget, &lnkDir, &lnkArgs, &lnkDesc, &lnkIcon, &lnkIconNum, &lnkRunState)
            filedir:=dir
            fileExt:=ext
            fileNameNoExt:=nameNoExt
        }
        switch func
        {
        case 1:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -c:v copy -c:a copy -y `"" redir "\转换_" reNameNoExt "." formatExt "`"")
            }
            ttip("转换成功",1000)
        case 2:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -af `"volume=" formatExt "`" -y `"" redir "\" reNameNoExt "_" formatExt "." renameExt "`"")
            }
            ttip("转换成功",1000)
        case 3:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -y `"" redir "\转换_" reNameNoExt "." formatExt "`"")
            }
            ttip("转换成功",1000)
        case 4:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:a:0 -c:a copy -y `"" redir "\" reNameNoExt "_音频1.wav`"")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:a:1 -c:a copy -y `"" redir "\" reNameNoExt "_音频2.wav`"")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:a:2 -c:a copy -y `"" redir "\" reNameNoExt "_音频3.wav`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:a:3 -c:a copy -y `"" redir "\" reNameNoExt "_音频4.wav`"", , "Hide")
            }
            ttip("提取成功",1000)
        case 5:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:0 -y `"" redir "\" reNameNoExt "_字幕1.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:1 -y `"" redir "\" reNameNoExt "_字幕2.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:2 -y `"" redir "\" reNameNoExt "_字幕3.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:3 -y `"" redir "\" reNameNoExt "_字幕4.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:4 -y `"" redir "\" reNameNoExt "_字幕5.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:5 -y `"" redir "\" reNameNoExt "_字幕6.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:6 -y `"" redir "\" reNameNoExt "_字幕7.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:7 -y `"" redir "\" reNameNoExt "_字幕8.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:8 -y `"" redir "\" reNameNoExt "_字幕9.ass`"", , "Hide")
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -map 0:s:9 -y `"" redir "\" reNameNoExt "_字幕10.ass`"", , "Hide")
            }
            ttip("提取成功",1500)
        case 6:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -c:v libx264 -crf 23 -preset medium -c:a copy `"" redir "\压缩_" reNameNoExt ".mp4`"")
            }
            ttip("转换成功",1000)
        case 7:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                renameExt:=ext
                RunWait(plusxy_Path " -i `"" xiaoyaoStr "`" -c:v copy -an `"" redir "\无声_" reNameNoExt "." renameExt "`"")
            }
            ttip("转换成功",1000)
        case 8:	
            Run(plusxy_Path " " filebatch7 " -c:v copy -c:a copy `"" filedir "\合并" A_Now ".mp4`"")
        case 9:	
            Loop Parse, getZz, "`n", "`r"
            {
                number1 := A_Index
            }
            Run(plusxy_Path " " filebatch7 " -filter_complex concat=n=" number1 ":v=1:a=1 -vsync vfr `"" filedir "\合并" A_Now ".mp4`"")
        case 10:
            Loop Parse, getZz, "`n", "`r"
            {
                number1 := A_Index
            }
            Run(plusxy_Path " " filebatch7 " -filter_complex concat=n=" number1 ":v=0:a=1 -f mp3 `"" filedir "\合并" A_Now ".mp3`"")
        }
    }
    ;══════════════════════════════════将选中文件内容保存为文本文件══════════════════════════════════
    ;将选中文字保存为文本文件[默认保存到桌面]，自动抓取选中文字的前面5个字符作为文件名。	
    Storetext(getZz,plusxy_Path,formatExt){
        clip:= getZz
        First := StrReplace(clip, "`r`n")	;将剪贴板中的换行符 rn 替换为空，以便生成文件名
        First := SubStr(First, 1, 5)	;将前 5 个字符赋给 First 变量作为文件名的一部分
        FileAppend(clip, formatExt "\" First "_" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".txt")		;将剪贴板的内容追加到指定路径的文本文件中，文件名由 First 和 .txt 组成
        Run(plusxy_Path " `"" formatExt "\" First "_" A_YYYY "" A_MM "" A_DD "_" A_Hour "" A_Min "" A_Sec ".txt`"")
    }	

    ;══════════════════════════════════RA_plus2:直接在ini里可编辑的功能[会弹框版]══════════════════════════════════	
    ;RA_plus2处理
    RA_plus2(getZz:="", RA_Path:="", commond:="", param:="", isBatch := 0){
        getZz := Sort(getZz)
        commond := RA_Path " " commond
        this.dealMyfunc(getZz, commond, param, isBatch)
    }

    ;RA_plus2Box处理【输入框不带有默认词】
    RA_plus2Box(getZz:="", RA_Path:="", commond:="", param:="", MsgTitles :="", MsgKes := "", isBatch := 0){
        getZz := Sort(getZz)
        msgKeyList := StrSplit(MsgKes, "|")
        MsgTitleList := StrSplit(MsgTitles, "|")
        For index, key in msgKeyList {
            IB := InputBox("", MsgTitleList[index]), OutputVar := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(OutputVar) == 0) {
                Return
            }
            commond := StrReplace(commond, key, OutputVar)
            param := StrReplace(param, key, OutputVar)
        }
        ; MsgBox, % commond "`n" param
        commond := RA_Path " " commond
        this.dealMyfunc(getZz, commond, param, isBatch)
    }
    ;RA_plus2Box2处理【输入框带有默认词】
    RA_plus2Box2(getZz:="", RA_Path:="", commond:="", param:="", MsgTitles :="", MsgTitles2 :="", MsgKes := "", isBatch := 0){
        getZz := Sort(getZz)
        msgKeyList := StrSplit(MsgKes, "|")
        MsgTitleList := StrSplit(MsgTitles, "|")
        MsgTitleList2 := StrSplit(MsgTitles2, "|")
        For index, key in msgKeyList {
            IB := InputBox("", MsgTitleList[index], , MsgTitleList2[index]), OutputVar := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(OutputVar) == 0) {
                Return
            }
            commond := StrReplace(commond, key, OutputVar)
            param := StrReplace(param, key, OutputVar)
        }
        ; MsgBox, % commond "`n" param
        commond := RA_Path " " commond
        this.dealMyfunc(getZz, commond, param, isBatch)
    }
    ;RA_plus2Box3处理【输入框带有默认词并带有注释】
    RA_plus2Box3(getZz:="", RA_Path:="", commond:="", param:="", MsgTitles :="", MsgTitles2 :="", MsgKes := "", MsgTitles3 :="", isBatch := 0){
        getZz := Sort(getZz)
        msgKeyList := StrSplit(MsgKes, "|")
        MsgTitleList := StrSplit(MsgTitles, "|")
        MsgTitleList2 := StrSplit(MsgTitles2, "|")
        MsgTitleList3 := StrSplit(MsgTitles3, "|")
        For index, key in msgKeyList {
            IB := InputBox(MsgTitleList3[index], MsgTitleList[index], , MsgTitleList2[index]), OutputVar := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(OutputVar) == 0) {
                Return
            }
            commond := StrReplace(commond, key, OutputVar)
            param := StrReplace(param, key, OutputVar)
        }
        ; MsgBox, % commond "`n" param
        commond := RA_Path " " commond
        this.dealMyfunc(getZz, commond, param, isBatch)
    }
    ;任务处理
    dealMyfunc(path, commond, param, isBatch := 0){
        if(isBatch) {
            textResult:=""
            Loop Parse, path, "`n", "`r, " A_Space "" A_Tab
            {
                if(!A_LoopField)
                    continue
                SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt)
                textResult.= "`"" A_LoopField "`" "
            }
            RunCommond(textResult, name, dir, ext, nameNoExt, param, commond)
        } else {
            Loop Parse, path, "`n", "`r, " A_Space "" A_Tab
            {
                if(!A_LoopField)
                    continue
                SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt)
                textResult := "`"" A_LoopField "`" "
                RunCommond(textResult, name, dir, ext, nameNoExt, param, commond)
            }
        }
    }
    ;══════════════════════════════════RA_plus3:直接在ini里可编辑的功能[不会弹框版]══════════════════════════════════
    ;RA_plus3处理
    RA_plus3(getZz:="", RA_Path:="", commond:="", param:="", isBatch := 0){
        getZz := Sort(getZz)
        commond := RA_Path " " commond
        this.dealMyfunc3(getZz, commond, param, isBatch)
    }

    ;RA_plus3Box处理
    RA_plus3Box(getZz:="", RA_Path:="", commond:="", param:="", MsgTitles :="", MsgKes := "", isBatch := 0){
        getZz := Sort(getZz)
        msgKeyList := StrSplit(MsgKes, "|")
        MsgTitleList := StrSplit(MsgTitles, "|")
        For index, key in msgKeyList {
            IB := InputBox("", MsgTitleList[index]), OutputVar := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(OutputVar) == 0) {
                Return
            }
            commond := StrReplace(commond, key, OutputVar)
            param := StrReplace(param, key, OutputVar)
        }
        ; MsgBox, % commond "`n" param
        commond := RA_Path " " commond
        this.dealMyfunc3(getZz, commond, param, isBatch)
    }
    ;RA_plus3Box3处理【输入框带有默认词】
    RA_plus3Box3(getZz:="", RA_Path:="", commond:="", param:="", MsgTitles :="", MsgTitles2 :="", MsgKes := "", isBatch := 0){
        getZz := Sort(getZz)
        msgKeyList := StrSplit(MsgKes, "|")
        MsgTitleList := StrSplit(MsgTitles, "|")
        MsgTitleList2 := StrSplit(MsgTitles2, "|")
        For index, key in msgKeyList {
            IB := InputBox("", MsgTitleList[index], , MsgTitleList2[index]), OutputVar := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(OutputVar) == 0) {
                Return
            }
            commond := StrReplace(commond, key, OutputVar)
            param := StrReplace(param, key, OutputVar)
        }
        ; MsgBox, % commond "`n" param
        commond := RA_Path " " commond
        this.dealMyfunc3(getZz, commond, param, isBatch)
    }
    ;RA_plus2Box3处理【输入框带有默认词并带有注释】
    RA_plus3Box4(getZz:="", RA_Path:="", commond:="", param:="", MsgTitles :="", MsgTitles2 :="", MsgKes := "", MsgTitles3 :="", isBatch := 0){
        getZz := Sort(getZz)
        msgKeyList := StrSplit(MsgKes, "|")
        MsgTitleList := StrSplit(MsgTitles, "|")
        MsgTitleList2 := StrSplit(MsgTitles2, "|")
        MsgTitleList3 := StrSplit(MsgTitles3, "|")
        For index, key in msgKeyList {
            IB := InputBox(MsgTitleList3[index], MsgTitleList[index], , MsgTitleList2[index]), OutputVar := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(OutputVar) == 0) {
                Return
            }
            commond := StrReplace(commond, key, OutputVar)
            param := StrReplace(param, key, OutputVar)
        }
        ; MsgBox, % commond "`n" param
        commond := RA_Path " " commond
        this.dealMyfunc(getZz, commond, param, isBatch)
    }
    ;任务处理
    dealMyfunc3(path, commond, param, isBatch := 0){
        if(isBatch) {
            textResult:=""
            Loop Parse, path, "`n", "`r, " A_Space "" A_Tab
            {
                if(!A_LoopField)
                    continue
                SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt)
                textResult.= "`"" A_LoopField "`" "
            }
            RunCommond3(textResult, name, dir, ext, nameNoExt, param, commond)
        } else {
            Loop Parse, path, "`n", "`r, " A_Space "" A_Tab
            {
                if(!A_LoopField)
                    continue
                SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt)
                textResult := "`"" A_LoopField "`" "
                RunCommond3(textResult, name, dir, ext, nameNoExt, param, commond)
            }
        }
    }	
    ;══════════════════════════════════RA_plus4:直接在ini里可编辑的功能[不会弹框版，以及可以判断软件是否在运行，以及选中内容是““文本””]══════════════════════════════════	
    ;RA_plus4处理
    ;pot划词翻译[不弹黑窗]|XiaoYao_plus[RA_plus4](%getZz%,%ComSpec%,/c curl -d $1 "127.0.0.1:60828/",$1=#path#,%"pot.exe"%)
    RA_plus4(getZz:="", RA_Path:="", commond:="", param:="",plusxy_Path:="", isBatch := 0){
        Loop Parse, plusxy_Path, "`n", "`r"
        {
            xiaoyaoStr:=A_LoopField
            SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
            rename1:=name
            redir:=dir
            reext:=ext
        }
        detectApp(rename1,plusxy_Path)
        commond := RA_Path " " commond
        this.dealMyfunc4(getZz, commond, param, isBatch)
    }
    ;任务处理
    dealMyfunc4(path, commond, param, isBatch := 0){
        Loop Parse, path, "`n", "`r, " A_Space "" A_Tab
        {
            if(!A_LoopField)
                continue
            SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt)
            textResult.= A_LoopField " "
        }
        textResult := "`"" textResult "`""
        RunCommond3(textResult, name, dir, ext, nameNoExt, param, commond)
    } 
    ;══════════════════════════════════RA_plus5:直接在ini里可编辑的功能[不会弹框版，以及可以判断软件是否在运行，以及选中内容是““文件””]══════════════════════════════════	
    ;RA_plus5处理
    RA_plus5(getZz:="", RA_Path:="", commond:="", param:="",plusxy_Path:="", isBatch := 0){
        getZz := Sort(getZz)
        Loop Parse, plusxy_Path, "`n", "`r"
        {
            xiaoyaoStr:=A_LoopField
            SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
            rename1:=name
            redir:=dir
            reext:=ext
        }
        detectApp(rename1,plusxy_Path)
        commond := RA_Path " " commond
        this.dealMyfunc3(getZz, commond, param, isBatch)
    }

    ;══════════════════════════════════隐藏/显示桌面图标══════════════════════════════════	
    HideOrShowDesktop()
    {
        class := ControlGetHwnd("SysListView321", "ahk_class Progman")
        if (class = "")
            class := ControlGetHwnd("SysListView321", "ahk_class WorkerW")

        If DllCall("IsWindowVisible", "UInt", class)
            WinHide("ahk_id " class)
        Else
            WinShow("ahk_id " class)
    }
    ;══════════════════════════════════隐藏/显示任务栏══════════════════════════════════
    ToggleTaskbar()
    {
        ; 获取任务栏窗口句柄
        taskbarHwnd := WinGetID("ahk_class Shell_TrayWnd")

        ; 判断任务栏可见性
        if DllCall("IsWindowVisible", "UInt", taskbarHwnd)
        {
            ; 隐藏任务栏
            WinHide("ahk_id " taskbarHwnd)
        }
        else
        {
            ; 显示任务栏
            WinShow("ahk_id " taskbarHwnd)
        }
    }
    ;══════════════════════════════════文字竖排══════════════════════════════════
    Texttest1(getZz)
    {
        text := getZz
        verticalText := ""
        Loop Parse, text
        {
            word := Trim(A_LoopField)

            Loop Parse, word
            {
                character := Trim(A_LoopField)
                verticalText .= character . "`n"
            }
        }
        ClipSaved := ClipboardAll() ; 保存剪贴板内容
        A_Clipboard := verticalText 
        SendInput("^v")
        Sleep(1000)
        A_Clipboard := ClipSaved ; 还原剪贴板内容
        ClipSaved := "" ; 清空剪贴板保存的内容
    }
    ;══════════════════════════════════ReNamer功能══════════════════════════════════
    ReNamer(getZz,plusxy_Path,rnp_Path, func){
        getZz := Sort(getZz)
        filebatch := getfiles(getZz)
        switch func
        {
        case 1:
            Run(plusxy_Path " /enqueue " filebatch)
        case 2:
            Run(plusxy_Path " /preset `"" rnp_Path "`" " filebatch)
        case 3:
            Run(plusxy_Path " /preset `"" rnp_Path "`" " filebatch)
        case 4:
            Run(plusxy_Path " /preset `"" rnp_Path "`" " filebatch)
        }
    }
    ;══════════════════════════════════创建新文件夹══════════════════════════════════
    Batch_file1(){
        Batchfile() ; V1toV2: Gosub
    }
    ;══════════════════════════════════文字反转══════════════════════════════════
    ReverseString1(getZz)
    {
        reversedText := ReverseString(getZz)
        ClipSaved := ClipboardAll() ; 保存剪贴板内容
        A_Clipboard := reversedText
        ; 发送快捷键 Ctrl + V，将竖排后的文字粘贴到选中的区域，并替换掉原有的选中文字
        SendInput("^v")
        Sleep(1000)
        A_Clipboard := ClipSaved ; 还原剪贴板内容
        ClipSaved := "" ; 清空剪贴板保存的内容
    }
    ;══════════════════════════════════文档定位══════════════════════════════════
    locationpath(plusxy_Path){
        str := WinGetTitle("A")
        if (SubStr(str, 1, 1) = "*")
            str := SubStr(str, 2)
        str := StrReplace(str, "[只读]", "")
        str := StrReplace(str, "[兼容模式]", "")
        ;MsgBox % str

        if WinActive("ahk_exe Notepad2.exe")
        {
            result := RegExMatch(str, ".*(?=\s\[.*\])", &match)
            ;MsgBox % match
            Run(plusxy_Path " -s `"wfn:ww:`"`"`"" (match&&match[0]) "`"`"`"")
        }
        else if WinActive("ahk_exe Notepad3.exe")
        {
            result := RegExMatch(str, ".*(?=\s\[.*\])", &match)
            ;MsgBox % match
            Run(plusxy_Path " -s `"wfn:ww:`"`"`"" (match&&match[0]) "`"`"`"")
        }
        else
        {
            regex := "(.*)\s-\s.*"
            result := RegExReplace(str, regex, "$1")
            ;MsgBox % result

            Run(plusxy_Path " -s `"wfn:ww:`"`"`"" result "`"`"`"")
        }
    }
    ;══════════════════════════════════BCompare比较选中文字和剪贴板文字══════════════════════════════════
    bcompare(getZz,plusxy_Path,func){
        filebatch := getfiles(getZz)

        switch func
        {
        case 1:	
            FileAppend(getZz, A_Temp "\选中文字" A_Now ".txt")		;将选中文字的内容追加到指定路径的文本文件中
            FileAppend(A_Clipboard, A_Temp "\剪贴板文字" A_Now ".txt")		;将剪贴板的内容追加到指定路径的文本文件中
            Run(plusxy_Path " `"" A_Temp "\选中文字" A_Now ".txt`" `"" A_Temp "\剪贴板文字" A_Now ".txt`"") ;执行比较命令
        case 2:
            Run(plusxy_Path " " filebatch)
        }	
    }
    ;══════════════════════════════════cpdf功能══════════════════════════════════	
    ;[获取cmd的值]
    ;参数说明：output：1-输出test1；0-显示test1并复制到剪贴板
    cpdf(getZz,plusxy_Path,output:=0){
        getZz := Sort(getZz)
        Loop Parse, getZz, "`n", "`r"
        {
            xiaoyaoStr:=A_LoopField
            SplitPath(xiaoyaoStr, &name, &dir)
            rename1:=name
            redir1:=dir
            test1 :=cmdClipReturn(plusxy_Path " -pages `"" xiaoyaoStr "`"",%output%)
            test1 := StrReplace(test1, "This demo is for evaluation only. http://www.coherentpdf.com/", "")
            test1 := StrReplace(test1, "`r`n")
            test1 := StrReplace(test1, " ")		
            files1 := files1 "+" test1
            files2 := files2 rename1 " 页数为" test1 "`n"
        }
        ;test2 := """" plusxy_Path """" " -pages """ getZz """"
        files1 := SubStr(files1, 2)
        arr := StrSplit(files1, "+")
        ; 遍历数组并计算总和
        for i, value in arr
        {
            sum += value
        }
        ; 显示总和
        ;MsgBox % files2
        files3 :=	files2 "`n总页数为" files1 "=" sum
        XiaoYao_plusGUI(files3)

    }
    ;══════════════════════════════════xpdf功能══════════════════════════════════
    xpdf(getZz,plusxy_Path,formatExt,func){
        getZz := Sort(getZz)
        switch func
        {
        case 1:		
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                DirCreate(redir "\" nameNoExt)
                RunWait(plusxy_Path " " formatExt " `"" xiaoyaoStr "`" `"" redir "\" nameNoExt "\" nameNoExt "`"", , "Hide")
            }
        case 2:		
            IB := InputBox("", "请指定页码进行转换", , 1), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                DirCreate(redir "\" nameNoExt)
                RunWait(plusxy_Path " -f " userInput " -l " userInput " `"" xiaoyaoStr "`" `"" redir "\" nameNoExt "\" nameNoExt "`"", , "Hide")
            }	
        case 3:		
            IB := InputBox("", "指定分辨率，单位为DPI", , 150), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                redir:=dir
                renameNoExt:=nameNoExt
                DirCreate(redir "\" nameNoExt)
                RunWait(plusxy_Path " -r " userInput " `"" xiaoyaoStr "`" `"" redir "\" nameNoExt "\" nameNoExt "`"", , "Hide")
            }	

        }
    }
    ;══════════════════════════════════数字转大写金额══════════════════════════════════
    DXmoney(getZz){
        A_Clipboard:=dmoney(getZz)
        SendInput("^v")
    }
    ;══════════════════════════════════目录生成菜单══════════════════════════════════
    XY_DrawMenu(MyAppsDir1:="",MyAppstype1:="0",MenuIconSize1:="24",MyAppsext1:=""){	
        global MyAppsDir:= MyAppsDir1
        global MyAppsMenuIconSize:= MenuIconSize1
        global MyAppstype:= MyAppstype1
        global MyAppsext:= MyAppsext1

        if FileExist(MyAppsDir1) ;判断文件夹是否存在
        { 
            Label_My_global_and_PreDefined_Var() ; V1toV2: Gosub
        }else{
            MsgBox("目标文件夹不存在！`n请检查菜单项的文件夹是否填写正确，是否存在该文件夹")
        }

    }
    ;══════════════════════════════════取时间戳函数[毫秒级]及时间戳转正常时间格式══════════════════════════════════
    ;获取时间戳
    timestamp() { ;
        时间戳 := A_NowUTC
        时间戳 -= 19700101000000, s
        时间戳 := 时间戳 * 1000 + A_MSec
        A_Clipboard:= 时间戳
        SendInput("^v")
        ttip(时间戳 "`n已放入剪贴板",2000)
    }

    ;时间戳转日期格式by@灼伤眼眸 https://www.autoahk.com/archives/44829
    normalTime(timestamp) {
        ;可以自行添加一下格式校验
        len := StrLen(timestamp)
        ;毫秒转秒
        if(len == 13) {
            timestamp := (timestamp - A_MSec)// 1000
        }
        startTime := "19700101000000"
        ;时区换算
        difTime := A_Now
        difTime := DateDiff((difTime != "" ? difTime : A_Now), (A_NowUTC != "" ? A_NowUTC : A_Now), "Seconds")
        startTime := DateAdd((startTime != "" ? startTime : A_Now), timestamp, "Seconds")
        startTime := DateAdd((startTime != "" ? startTime : A_Now), difTime, "Seconds")
        ;格式化
        time := FormatTime(startTime, "yyyy-MM-dd HH:mm:ss")
        A_Clipboard:= time
        SendInput("^v")
        ttip(time "`n已放入剪贴板",2000)
    }
    ;══════════════════════════════════按 年、月 范围输出全部日期══════════════════════════════════
    AutoDate(getZz, DateFormat := "yyyy年MM月dd日-dddd",func:="1") {
        switch func
        {
        case 1:
            If (RegExMatch(getZz, "[^\d]")){
                MsgBox("请输入正确的待格式化日期格式：`n2000/200010/20001010")
                Return 
            }
            XiaoYao_plusGUI("范围日期如下：`n" AutoDate(getZz, DateFormat))
        case 2:
            IB := InputBox("当前格式为： " DateFormat "`n输入2023：按格式输出2022年所有天数`n输入202310：按格式输出2022年1月所有天数`n输入20231010：为当前日期", "请输入正确的待格式化日期格式", , A_YYYY "" A_MM), userInput := IB.Value, ErrorLevel := IB.Result="OK" ? 0 : IB.Result="CANCEL" ? 1 : IB.Result="Timeout" ? 2 : "ERROR"
            if(ErrorLevel || StrLen(userInput) == 0) {
                Return
            }

            If (RegExMatch(userInput, "[^\d]")){
                MsgBox("请输入正确的待格式化日期格式：`n2000/200010/20001010")
                Return 
            }
            XiaoYao_plusGUI("范围日期如下：`n" AutoDate(userInput, DateFormat))
        }			
    }
    ;══════════════════════════════════简繁转换══════════════════════════════════
    ;語言填1或2，1是繁體、2是简体。
    简繁转换(getZz, 翻译前语言:="1", 翻译后语言:="2",func:="1"){
        switch func
        {
        case 1:	
            语言转化后 := 繁簡轉換(getZz, 翻译前语言, 翻译后语言)
            ClipSaved := ClipboardAll() ; 保存剪贴板内容
            A_Clipboard := 语言转化后 
            SendInput("^v")
            Sleep(1000)
            A_Clipboard := ClipSaved ; 还原剪贴板内容
            ClipSaved := "" ; 清空剪贴板保存的内容
        case 2:	
            语言转化后 := 繁簡轉換(getZz, 翻译前语言, 翻译后语言)
            XiaoYao_plusGUI("转化后：`n" 语言转化后)
        }	
    }
    ;══════════════════════════════════中英符号替换══════════════════════════════════
    ;;将中文符号替换成英文符号,满足不同的需求或规范，符号填1或2，1是中文符号、2是英文符号。
    中英符号互替(getZz, 替换前:="1", 替换后:="2",func:="1"){
        switch func
        {
        case 1:	
            符号替换后 := 中英符号替换(getZz, 替换前, 替换后)
            ClipSaved := ClipboardAll() ; 保存剪贴板内容
            A_Clipboard := 符号替换后 
            SendInput("^v")
            Sleep(1000)
            A_Clipboard := ClipSaved ; 还原剪贴板内容
            ClipSaved := "" ; 清空剪贴板保存的内容
        case 2:	
            符号替换后 := 中英符号替换(getZz, 替换前, 替换后)
            XiaoYao_plusGUI("替换后：`n" 符号替换后)
        }	
    }
    ;══════════════════════════════════获取网址上一级══════════════════════════════════
    UrlUpLevel(url) { ;获取网址上一级
        url := Trim(url, " `t`r`n/\")
        url := !(url ~= "\w/\w") ? RegExReplace(url, "\w+\.(?=.*\.)", , , 1) : RegExReplace(url, "\w\K/[^/]+$")
        url := (url ~= "i)^(ftp|https?)://") ? url : "http://" url
        XiaoYao_plusGUI(url)
    }
    ;══════════════════════════════════窗口进程暂停══════════════════════════════════
    pssuspend(plusxy_Path,func:="1") {
        switch func
        {
        case 1:
            global psplusxy_Path := plusxy_Path
            窗口进程暂停1() ; V1toV2: Gosub
        case 2:
            pid := WinGetPID("A")
            activeWindowClass := WinGetClass("A")
            窗口标题 := WinGetTitle("A")
            regex := "(.*)\s-\s.*"
            窗口标题1 := RegExReplace(窗口标题, regex, "$1")
            窗口标题 := SubStr(窗口标题1, 1, 15)
            窗口进程名 := WinGetProcessName("A")
            if (activeWindowClass = "Shell_TrayWnd"|| activeWindowClass = "WorkerW" || activeWindowClass = "CabinetWClass" || activeWindowClass = "Progman"){
                窗口标题 = 当前窗口为系统窗口！
                pid := "不存在"
            }
            if (pid = "不存在"){
                return 
            }
            Run(psplusxy_Path " " pid, , "Hide")
            OutputVar1 :=""
            lastLine:=""
            OutputVar1 := FileRead(A_Temp "\xiaoyaoCache.txt")
            lines := StrSplit(OutputVar1,"`n")
            lastLine := lines[lines.Length] ;获取最后一行
            if (pid = lastLine){
                return 
            }
            FileAppend("`n" pid, A_Temp "\xiaoyaoCache.txt")
            FileAppend("`n" 窗口进程名 "-" 窗口标题 " pid值为：" pid, A_Temp "\xiaoyaoCache2.txt")
        case 3:
            OutputVar1 :=""
            lastLine:=""
            OutputVar1 := FileRead(A_Temp "\xiaoyaoCache.txt")
            lines := StrSplit(OutputVar1,"`n")
            lastLine := lines[lines.Length] ;获取最后一行
            Run(plusxy_Path " -r " lastLine, , "Hide")
        }
    }
    ;══════════════════════════════════生成随机数══════════════════════════════════
    生成随机数(范围最小值, 范围最大值, 生成多少个)
    {
        Loop 生成多少个
        {
            随机数1 := Random(范围最小值, 范围最大值)
            随机数2 .=随机数1 "`n"
        }

        XiaoYao_plusGUI("生成的" 生成多少个 "个随机数为(" 范围最小值 "-" 范围最大值 ")：`n" 随机数2)
    }
    ;══════════════════════════════════显示\隐藏 文件\扩展名══════════════════════════════════
    system_hidefile(系统模式=0,参数1=1,参数2=1){
        hideFileRegPath:="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (系统模式 = "0"){
            CF_RegWrite("REG_DWORD", hideFileRegPath, "Hidden", 参数1)
            CF_RegWrite("REG_DWORD", hideFileRegPath, "ShowSuperHidden", 参数1)
            RefreshExplorer()
        }
        if (系统模式 = "1"){
            CF_RegWrite("REG_DWORD", hideFileRegPath, "HideFileExt", 参数1)
            RefreshExplorer()
        }
    }
    ;══════════════════════════════════垂直水平最大化══════════════════════════════════
    win_movie(窗口模式){

        DetectHiddenWindows(true)
        h_hwnd := WinGetTitle("获取当前窗口信息")
        Windy_CurWin_id := StrReplace(h_hwnd, "获取当前窗口信息")
        if !Windy_CurWin_id
            Windy_CurWin_id := WinExist("A")
        if !Windy_CurWin_id
        ExitApp()
    MonitorGetWorkArea(, &OutputVarLeft, &OutputVarTop, &OutputVarRight, &OutputVarBottom)

    if (窗口模式 = "0") ;垂直最大化
        CF_WinMove(Windy_CurWin_id,, 0,, OutputVarBottom)
    if (窗口模式 = "1") ;水平最大化
        CF_WinMove(Windy_CurWin_id, 0,, OutputVarRight)

}
;══════════════════════════════════窗口置顶══════════════════════════════════	
win_top_zz(t:="",color_xy:="ffae00"){
    global border_color := color_xy
    global winTopList
    winId:=WinExist("A")
    if(t=1 || !winTopList[winId]){
        if(WinActive("ahk_class CabinetWClass")){
            WinSetAlwaysOnTop(1, "ahk_class CabinetWClass")
        }
        WinSetAlwaysOnTop(1, "ahk_id " winId)
        winTopList[winId]:=True ;  V1toV2: Invalid Index errors?, try 'winTopList.Push(<val>)'
        置顶加边框() ; V1toV2: Gosub
    }else if(t=0 || winTopList[winId]){
        WinSetAlwaysOnTop(0, "ahk_id " winId)
        winTopList[winId]:=False ;  V1toV2: Invalid Index errors?, try 'winTopList.Push(<val>)'
        结束置顶加边框() ; V1toV2: Gosub
    }
}
;══════════════════════════════════倒计时══════════════════════════════════
countdowngui(func:="1"){
    switch func
    {
    case 1:
        倒计时gui() ; V1toV2: Gosub
    case 2:
        SetTimer(倒计时刷新,0)
        WinClose("倒计时xiaoyao")
        Try djs.Destroy()
    case 3:
        djs.Hide()
    case 4:
        hWnd := WinGetID("倒计时xiaoyao")
        if (hWnd){
            PID := WinGetPID("ahk_id " hWnd)
            djs.show()
        }else{
            MsgBox("未设置倒计时")
        }
    }
}

countdown(Xiaoshi:="0",Fenzhong:="0",Miao:="30"){
    xyshijian := Xiaoshi*60*60+Fenzhong*60+Miao
    xyshijian3 := Xiaoshi "时" Fenzhong "分" Miao "秒"
    global shijian := xyshijian
    global shijian3 := xyshijian3
    倒计时() ; V1toV2: Gosub
}
;══════════════════════════════════下一个功能══════════════════════════════════
}

;-----------------------------------【辅助函数】---------------------------------------------------------------------------
return
;检测软件是否开启，如果开启则跳过，否则开启
detectApp(exe:="",path:="",waitTime:=3){
    If (exe!=""){
        ErrorLevel := ProcessExist(exe)
        if(ErrorLevel=0)
        {
            Run(path)
            ToolTip(exe "启动中")
            ErrorLevel := !WinWaitActive("ahk_exe " exe, , waitTime)
        }
    }
    ToolTip()
    Sleep(100)
}

Label_ClearMEM: ;清理内存
Label_ClearMEM()
Return

ttip(text,time){
    ToolTip(text)
    Sleep(time)
    ToolTip()
Return
}

;══════════════════════════多选时，自动加上双引号""并空格隔开，  	示例："Path1" "Path2" "Path3"══════════════════════════════════
getfiles(getZz){
    files := ""
    line := getZz
    Loop Parse, line, "`n", "`r"
    {
        files := files " `"" A_LoopField "`""
    }
    if(StrLen(files) < 1) {
        Return
    }
Return files
}

;══════════════════════════多选时，自动加上双引号""并逗号,隔开  	示例："Path1","Path2","Path3"══════════════════════════════════
getfiles2(getZz){
    files := ""
    line := getZz
    Loop Parse, line, "`n", "`r"
    {
        files := files ",`"" A_LoopField "`""
    }
    if(StrLen(files) < 1) {
        Return
    }
Return files
}

;══════════════════════════多选时，逗号,加空格隔开  	示例：Path1, Path2, Path3══════════════════════════════════
getfiles3(getZz){
    files := ""
    line := getZz
    Loop Parse, line, "`n", "`r"
    {
        files := files ", " A_LoopField
    }
    if(StrLen(files) < 1) {
        Return
    }
Return files
}
;══════════════════════════多选时，逗号,加空格隔开  	示例：-i Path1, Path2, Path3══════════════════════════════════
getfiles7(getZz){
    files := ""
    line := getZz
    Loop Parse, line, "`n", "`r"
    {
        files := files "-i `"" A_LoopField "`"" " "
    }
    if(StrLen(files) < 1) {
        Return
    }
Return files
}

;═════════════════════════资源管理器中获取路径══════════════════════════
Explorer_GetPath(hwnd:="")
{
    hwnd := WinExist("A")
    if !(window := Explorer_GetWindow(hwnd))
        return ErrorLevel := "ERROR"
    WinClass := WinGetClass("ahk_id " hwnd)
    if (WinClass = "CabinetWClass") {
        hwnd := WinActive("ahk_class CabinetWClass")
        activeTab := 0
        try activeTab := ControlGetHwnd("ShellTabWindowClass1", "ahk_id" hwnd)
        for w in ComObject("Shell.Application").Windows {
            if (w.hwnd != hwnd)
                continue
            if activeTab {
                static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"
                shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
                DllCall(NumGet(NumGet(shellBrowser+0, "UPtr")+3*A_PtrSize, "UPtr"), "Ptr", shellBrowser, "UInt*", &thisTab)
                if (thisTab != activeTab)
                    continue
                ObjRelease(shellBrowser)
            }
            return w.Document.Folder.Self.Path
        }
    } else if (WinClass = "Progman" || WinClass = "WorkerW") {
        return A_Desktop
    } else
    throw Error("Window must be an Explorer window or the desktop.", -1)
}

Explorer_GetWindow(hwnd:="")
{
    ; thanks to jethrow for some pointers here
    process := WinGetprocessName("ahk_id" hwnd := hwnd? hwnd:WinExist("A"))
    class := WinGetClass("ahk_id " hwnd)

    if (process!="explorer.exe")
        return
    if (class ~= "(Cabinet|Explore)WClass")
    {
        for window in ComObject("Shell.Application").Windows
            if (window.hwnd==hwnd)
            return window
    }
    else if (class ~= "Progman|WorkerW")
        return "desktop" ; desktop found
}

;══════════════════════════════════[复制选中文件路径]HuiZz v1.0.7══════════════════════════════════
;复制文件说明：path路径, name名称, dir目录, ext后缀, nameNoExt无后缀名称, drive盘符
;复制快捷方式说明：lnkTarget指向路径, lnkDir指向目录, lnkArgs参数, lnkDesc注释, lnkIcon图标文件名, lnkIconNum图标编号, lnkRunState初始运行方式
system_file_path_zz(getZz,copy:=""){
    textResult:=""
    Loop Parse, getZz, "`n", "`r, " A_Space "" A_Tab
    {
        if(!A_LoopField)
            continue
        SplitPath(A_LoopField, &name, &dir, &ext, &nameNoExt, &drive)
        if(ext="lnk")
            FileGetShortcut(A_LoopField, &lnkTarget, &lnkDir, &lnkArgs, &lnkDesc, &lnkIcon, &lnkIconNum, &lnkRunState)
        textResult.=(copy="path") ? A_LoopField "`n" : %copy% "`n"
    }
    xiaoyaopath:=Trim(textResult, ",`n ")
return xiaoyaopath
}

;══════════════════════════════════生成随机密码══════════════════════════════════	
RandomPass(kind:="Wwd",length:=8){
    ;类型 W大写 w小写 d数字 可以组合
    char := [1,2,3,4,5,6,7,8,9,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",0,1,2,3,4,5,6,7,8,9]
    char[0] := 0 ;定义数组 ;  V1toV2: Invalid Index errors?, try 'char.Push(<val>)'
    option := kind
    kind := 0 ;必须先赋值  不然后面的加法无效
    kind := InStr(option, "W", 1) ? kind+100 : kind ;InStr区分大小写
    kind := InStr(option, "w", 1) ? kind+10 : kind
    kind := InStr(option, "d") ? kind+1 : kind
    if (kind = 111)
        min:=0,max:=61
    else if (kind = 110)
        min:=10,max:=61
    else if (kind = 11)
        min:=0,max:=35
    else if (kind = 101)
        min:=36,max:=71
    else if (kind = 1)
        min:=0,max=9
    else if (kind = 10)
        min:=10,max=35
    else if (kind = 100)
        min:=36,max=61
    Loop length
    {
        l := Random(min, max)
        str .= char[l]
    }
return str
}
;══════════════════════════════════RA_plus2:直接在ini里可编辑的功能[会弹框版]══════════════════════════════════	
RunCommond(path, name, dir, ext, nameNoExt, param, commond) {
    allValue := { path: path, name: name, dir: dir, ext: ext, nameNoExt: nameNoExt}
    paramList := StrSplit(param, "|")
    for index, pair in paramList
    {
        ; 拆分键值对，获取键和值
        keyValue := StrSplit(pair, "=")
        key := keyValue[1]
        tvalue := keyValue[2]
        paramValue := StrSplit(tvalue, "#")
        facValue := ""
        for idx, pv in paramValue
        {
            remainder := Mod(idx, 2)
            if(remainder == 0) {
                facValue.= allValue[pv]
            } else {
                facValue.= pv
            }
        }
        if(InStr(tvalue, "path") == 0) {
            facValue := "`"" facValue "`""
        }
        ; 输出当前键和值
        ; MsgBox % "Key: " . key . "--Value: " . facValue
        commond := StrReplace(commond, key, facValue)
    }
    ; MsgBox, % commond
    RunWait(commond)
    ; SetTimer, RemoveToolTip, -5000
    ; return
}
;══════════════════════════════════RA_plus3:直接在ini里可编辑的功能══════════════════════════════════	
RunCommond3(path, name, dir, ext, nameNoExt, param, commond) {
    allValue := { path: path, name: name, dir: dir, ext: ext, nameNoExt: nameNoExt}
    paramList := StrSplit(param, "|")
    for index, pair in paramList
    {
        ; 拆分键值对，获取键和值
        keyValue := StrSplit(pair, "=")
        key := keyValue[1]
        tvalue := keyValue[2]
        paramValue := StrSplit(tvalue, "#")
        facValue := ""
        for idx, pv in paramValue
        {
            remainder := Mod(idx, 2)
            if(remainder == 0) {
                facValue.= allValue[pv]
            } else {
                facValue.= pv
            }
        }
        if(InStr(tvalue, "path") == 0) {
            facValue := "`"" facValue "`""
        }
        ; 输出当前键和值
        ; MsgBox % "Key: " . key . "--Value: " . facValue
        commond := StrReplace(commond, key, facValue)
    }
    ; MsgBox, % commond
    RunWait(commond, , "Hide")
    ; SetTimer, RemoveToolTip, -5000
    ; return
}
;══════════════════════════════════选中文字反转══════════════════════════════════	
; 定义一个函数，用于反转字符串
ReverseString(str) {
    reversed := ""
    Loop Parse, str
    {
        reversed := A_LoopField . reversed
    }
return reversed
}

;═════════════════════════════════【隐藏运行cmd命令并将结果存入剪贴板后取回 @hui-Zz】══════════════════════════════════	

cmdClipReturn(command,save:=0){
    cmdInfo:=""
    try{
        if(save)
            Clip_Saved:=ClipboardAll()
        A_Clipboard:=""
        Run(A_ComSpec " /C chcp 65001 && " command " | CLIP", , "Hide")	;使用了chcp 65001命令来设置命令行的输出编码为UTF-8（65001是UTF-8对应的代码页）
        Errorlevel := !ClipWait(2)
        cmdInfo:=A_Clipboard
        if(save)
            A_Clipboard:=Clip_Saved
    }catch{}
return cmdInfo
}
;═════════════════════════════════【数字转大写金额 by 而今迈步从头越】══════════════════════════════════	
dmoney(SmallNum){
    ;从控件中取得数字值
    NumStr:=""
    ;删除回车
    NumStr := StrReplace(SmallNum, "`n`r") ;换行回车
    NumStr := StrReplace(NumStr, "`n") ;换行
    NumStr := StrReplace(NumStr, "`r") ;回车
    ;删除空格
    NumStr := StrReplace(NumStr, "`") ;转义字符+半角空格
    NumStr := StrReplace(NumStr, "`　") ;转义字符+全角空格
    ;删除千位符","
    NumStr := StrReplace(NumStr, ",")
    ;MsgBox %NumStr%

    ;数据是否为数字
    if (RegExMatch(numstr, "^(\-|\+)?\d+(\.\d+)?$")=0)
    {
        MsgBox("要转换的内容不是数值", "提示", 48)
        return
    }

    ;小写转大写的映射数组
    ;NumberArray := Object()
    NumberArray0 := "零"
    NumberArray1 := "壹"
    NumberArray2 := "贰"
    NumberArray3 := "叁"
    NumberArray4 := "肆"
    NumberArray5 := "伍"
    NumberArray6 := "陆"
    NumberArray7 := "柒"
    NumberArray8 := "捌"
    NumberArray9 := "玖"
    ;数位数组
    DigitPlace0 := "元"
    DigitPlace1 := "拾"
    DigitPlace2 := "佰"
    DigitPlace3 := "仟"
    DigitPlace4 := "万"
    DigitPlace5 := "拾"
    DigitPlace6 := "佰"
    DigitPlace7 := "仟"
    DigitPlace8 := "亿"
    DigitPlace9 := "拾"
    DigitPlace10 := "佰"
    DigitPlace12 := "仟"
    DigitPlace13 := "万"
    ;币值
    Valuta0 := "元"
    Valuta1 := "角"
    Valuta2 := "分"
    ;小数点前
    ;StrBeforeRadix :="人民币 "
    StrBeforeRadix :=""
    ;小数点后
    StrAfterRadix :=""
    ;整
    zheng :="整"
    ;需要用到的模式匹配
    StrPattern :=""
    ;临时用变量
    TempStr1 :=""
    TempStr2 :=""
    i :=0
    ;结果字符串
    TransResult :=""

    ;找到小数点位置
    RadixPointLocation:=0
    RadixPointLocation := InStr(Numstr, ".")
    ;开始转换
    ;先转换小数点后的小数
    if (RadixPointLocation = 0)
    {
        ;数为整数
        StrAfterRadix := Valuta0 . zheng
    } Else {
        ;不是整数，先读取小数部分
        TempStr1 := SubStr(Numstr, (RadixPointLocation+1)<1 ? (RadixPointLocation+1)-1 : (RadixPointLocation+1))
        i := 1
        NCount :=strlen(TempStr1)
        Loop NCount
        {
            NewID:=SubStr(TempStr1, (i)<1 ? (i)-1 : (i), 1)
            StrAfterRadix := StrAfterRadix . NumberArray%NewID% . valuta%i%
            i := i + 1
        }
        ;处理小数的各种特殊情况
        StrAfterRadix := StrReplace(StrAfterRadix, "零分", "整")
        StrAfterRadix := StrReplace(StrAfterRadix, "零角", "零")
        StrAfterRadix := StrReplace(StrAfterRadix, "零零")
        StrAfterRadix := StrReplace(StrAfterRadix, "零整", "整")
        If strlen(StrAfterRadix) = 0 Or strlen(StrAfterRadix) = 2 Then
            StrAfterRadix := StrAfterRadix . "整"
    }

    if (RadixPointLocation = 0)
    {
        count1:=strlen(Numstr)
        TempStr1 := SubStr(Numstr, 1, count1)
    }
    else
    {
        TempStr1 := SubStr(Numstr, 1, RadixPointLocation-1)
    }

    ;If strlen(TempStr1) > 13   Return "数字太大，本程序无法转换" . numstr
    i := strlen(TempStr1) - 1
    j :=1
    MCount :=strlen(TempStr1)
    Loop MCount
    {
        NewID:=SubStr(TempStr1, (j)<1 ? (j)-1 : (j), 1)
        StrBeforeRadix := StrBeforeRadix . NumberArray%NewID% . Digitplace%i%
        i := i- 1
        j := j+1
    }
    StrBeforeRadix := StrReplace(StrBeforeRadix, "零拾", "零")
    StrBeforeRadix := StrReplace(StrBeforeRadix, "零佰", "零")
    StrBeforeRadix := StrReplace(StrBeforeRadix, "零仟", "零")
    transresult := StrBeforeRadix . StrAfterradix
    ;MsgBox %transresult%
    ;处理多个0的情况
    findzero := False
    mystr := ""
    TempStr2 := ""
    i :=1
    NNCount :=strlen(transresult)
    Loop NNCount
    {
        TempStr1:=SubStr(transresult, (i)<1 ? (i)-1 : (i), 1)
        If (TempStr1 = "零")
        {
            findzero := True
            mystr := ""
        } Else {
            If findzero
            {
                mystr := "零" . TempStr1
                findzero := False
            } Else {
                mystr := TempStr1
            }
        }
        TempStr2 :=TempStr2 . mystr
        i+=1
    }

    TempStr2 := StrReplace(TempStr2, "零万", "万")
    TempStr2 := StrReplace(TempStr2, "零亿", "亿")
    TempStr2 := StrReplace(TempStr2, "零元", "元")
    TempStr2 := StrReplace(TempStr2, "元元", "元")
    transresult := TempStr2
    ;MsgBox %transresult%
Return transresult
}
;═════════════════════════════════【gui调用imagemagick加水印 by @灼伤眼眸】══════════════════════════════════
imagemagick1:
imagemagick1()
return

Button加水印确认:
Button加水印确认()
return
;═════════════════════════════════【文件夹/文件批量创建1.3】══════════════════════════════════
Batchfile:
Batchfile()
return

创建file:
创建file()
Return

创建file2:
创建file2()
Return

创建file3:
创建file3()
Return
;═════════════════════════════════【gui+移动/复制到[标准对话框版]】══════════════════════════════════
MoveCopyGui:
MoveCopyGui()
return

MoveButton:
MoveButton()
Return

CopyButton: 
CopyButton()
Return
;═════════════════════════════════【配合gui使用的部分】══════════════════════════════════
GuiEscape:
GuiEscape()
return
GuiClose:
GuiClose()
return
;═════════════════════════════════【判断目标路径是否存在同名文件】══════════════════════════════════
;判断目标路径是否存在同名文件, path1是填的目录 存在等于1
determine(getZz:="", path1:=""){
    determinepath := ""
    Loop Parse, getZz, "`n", "`r"
    {
        xiaoyaoStr:=A_LoopField
        SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
        if FileExist(path1 "\" name)
        {
            ;MsgBox,存在
            determinepath:="1"
            break
        }	
    }
    ;MsgBox, %determinepath%
Return determinepath
}
;═════════════════════════════════【文件移动或者复制的函数】════════════════════════════════════════════
;文件移动，可判断目标路径是否存在而进行下一步操作
filemove1(getZz,getZzpath){
    txet3:=""
    txet:=""
    getZzpath2 := getZzpath . "\"
    if FileExist(getZzpath2)
    {	
        txet :=determine(getZz, getZzpath)
        if (txet = 1)
        {	
            ; 弹出提示框，让用户选择操作
            msgResult := MsgBox("选项说明：`n【温馨提示：关闭右上角窗口，不进行移动操作】`n`n取 消：跳过所有重名文件`n重 试：移动并重命名所有重名文件为 原文件名+当前日期+当日秒数 `n继 续：覆盖所有重名文件", "目标目录存在同名文件，请选择", 6)
            if(ErrorLevel){
                Return
            }
            if (msgResult = "Cancel")
            {
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename1:=name
                    redir:=dir
                    reext:=ext
                    DirMove(xiaoyaoStr, getZzpath "\" name)
                    if FileExist(xiaoyaoStr) ;判断文件是否移动成功
                    { 
                        ; 不覆盖文件
                        Try {
                            FileMove(xiaoyaoStr, getZzpath)
                            ErrorLevel := 0
                        } Catch as Err {
                            ErrorLevel := Err.Extra
                        }
                        if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
                        {
                            txet2:="1"
                            txet3:=	txet3 name "`n"
                        }
                    }
                }
                if (txet2 = 1)
                {
                    ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
                    ttip("重名文件移动失败",1500)		
                }		
                else
                {
                    ;ttip("移动成功",1000)
                }
            }
            if (msgResult = "continue")
            {
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename1:=name
                    redir:=dir
                    reext:=ext
                    DirMove(xiaoyaoStr, getZzpath "\" name, 1)
                    if FileExist(xiaoyaoStr) ;判断文件夹是否移动成功
                    { 
                        ; 覆盖目标文件
                        Try {
                            FileMove(xiaoyaoStr, getZzpath, 1)
                            ErrorLevel := 0
                        } Catch as Err {
                            ErrorLevel := Err.Extra
                        }
                        if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
                        {
                            txet2:="1"
                            txet3:=	txet3 name "`n"
                        }
                    }
                }
                if (txet2 = 1)
                {
                    ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
                    ttip("重名文件移动失败",1500)	
                }		
                else
                {
                    ;ttip("移动成功",1000)
                }
            }
            if (msgResult = "TryAgain")
            {
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename1:=name
                    redir:=dir
                    reext:=ext
                    DirMove(xiaoyaoStr, getZzpath "\" name)
                    Try {
                        FileMove(xiaoyaoStr, getZzpath)
                        ErrorLevel := 0
                    } Catch as Err {
                        ErrorLevel := Err.Extra
                    }
                    if FileExist(xiaoyaoStr) ;判断文件夹是否移动成功
                    {
                        ; 生成新的文件名，格式为 原文件名+当前日期+当日秒数
                        DirMove(xiaoyaoStr, getZzpath "\" name "_" A_Now)
                        Try {
                            FileMove(xiaoyaoStr, getZzpath "\" nameNoExt "_" A_Now "." ext)
                            ErrorLevel := 0
                        } Catch as Err {
                            ErrorLevel := Err.Extra
                        }
                        if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
                        {
                            txet2:="1"
                            txet3:=	txet3 name "`n"
                        }
                    }
                }
                if (txet2 = 1)
                {
                    ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
                    ttip("重名文件移动失败",1500)		
                }		
                else
                {
                    ;ttip("移动成功",1000)
                }
            }	
        }		
        else
        {
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext
                DirMove(xiaoyaoStr, getZzpath "\" name)
                Try {
                    FileMove(xiaoyaoStr, getZzpath)
                    ErrorLevel := 0
                } Catch as Err {
                    ErrorLevel := Err.Extra
                }
                if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
                {
                    txet2:="1"
                    txet3:=	txet3 name "`n"
                }
            }
            if (txet2 = 1)
            {
                ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
                ttip("重名文件移动失败",1500)		
            }		
            else
            {
                ;ttip("移动成功",1000)
            }
        }
    }
    Else
    {
        msgResult := MsgBox("目标路径不存在或者文件夹创建失败！`n创建的文件夹和已有的某个文件重名因为（该文件没带后缀）`n请检查文件夹名称是否规范和存在。")
    }
}
;═════════════════════════════════【文件移动或者复制的函数】════════════════════════════════════════════
;文件复制的函数，可判断目标路径是否存在而进行下一步操作
filecopy1(getZz,getZzpath){
    txet3:=""
    getZzpath2 := getZzpath . "\"
    if FileExist(getZzpath2)
    {	
        txet :=determine(getZz, getZzpath)
        if (txet = 1)
        {	
            ; 弹出提示框，让用户选择操作
            msgResult := MsgBox("选项说明：`n【温馨提示：关闭右上角窗口，不进行复制操作】`n`n取 消：跳过所有重名文件`n重 试：复制并重命名所有重名文件为 原文件名+当前日期+当日秒数 `n继 续：覆盖所有重名文件", "目标目录存在同名文件，请选择", 6)
            if(ErrorLevel){
                Return
            }
            if (msgResult = "Cancel")
            {
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename1:=name
                    redir:=dir
                    reext:=ext
                    if FileExist(getZzpath "\" name)
                    {

                    }	 
                    else
                    { 						
                        Try {
                            DirCopy(xiaoyaoStr, getZzpath "\" name)
                            ErrorLevel := 0
                        } Catch {
                            ErrorLevel := 1
                        }
                        if(ErrorLevel){
                            Try {
                                FileCopy(xiaoyaoStr, getZzpath)
                                ErrorLevel := 0
                            } Catch as Err {
                                ErrorLevel := Err.Extra
                            }
                        }
                    }
                }
                ttip("复制成功, 重名文件已跳过",1000)
            }
            if (msgResult = "continue")
            {
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename1:=name
                    redir:=dir
                    reext:=ext
                    Try {
                        DirCopy(xiaoyaoStr, getZzpath "\" name, 1)
                        ErrorLevel := 0
                    } Catch {
                        ErrorLevel := 1
                    }
                    if(ErrorLevel){
                        Try {
                            FileCopy(xiaoyaoStr, getZzpath, 1)
                            ErrorLevel := 0
                        } Catch as Err {
                            ErrorLevel := Err.Extra
                        }
                    }

                }
                ttip("复制成功, 重名文件覆盖",1000)
            }
            if (msgResult = "TryAgain")
            {
                Loop Parse, getZz, "`n", "`r"
                {
                    xiaoyaoStr:=A_LoopField
                    SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                    rename1:=name
                    redir:=dir
                    reext:=ext
                    if FileExist(getZzpath "\" name) ;再次判断目标路径是否存在同名文件
                    {
                        Try {
                            DirCopy(xiaoyaoStr, getZzpath "\" name "_" A_Now)
                            ErrorLevel := 0
                        } Catch {
                            ErrorLevel := 1
                        }
                        if(ErrorLevel){
                            Try {
                                FileCopy(xiaoyaoStr, getZzpath "\" nameNoExt "_" A_Now "." ext)
                                ErrorLevel := 0
                            } Catch as Err {
                                ErrorLevel := Err.Extra
                            }
                        }

                    }
                    else
                    {
                        Try {
                            DirCopy(xiaoyaoStr, getZzpath "\" name)
                            ErrorLevel := 0
                        } Catch {
                            ErrorLevel := 1
                        }
                        if(ErrorLevel){
                            Try {
                                FileCopy(xiaoyaoStr, getZzpath)
                                ErrorLevel := 0
                            } Catch as Err {
                                ErrorLevel := Err.Extra
                            }
                        }

                    }
                }
                ttip("复制成功, 重名文件已修改",1000)
            }	
        }		
        else
        {
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext
                Try {
                    DirCopy(xiaoyaoStr, getZzpath "\" name)
                    ErrorLevel := 0
                } Catch {
                    ErrorLevel := 1
                }
                if(ErrorLevel){
                    Try {
                        FileCopy(xiaoyaoStr, getZzpath)
                        ErrorLevel := 0
                    } Catch as Err {
                        ErrorLevel := Err.Extra
                    }
                }
            }
            ttip("复制成功,",1000)
        }
    }
    Else
    {
        msgResult := MsgBox("目标路径不存在或者文件夹创建失败！`n创建的文件夹和已有的某个文件重名因为（该文件没带后缀）`n请检查文件夹名称是否规范和存在。")
    }
}

;═════════════════════════════════【文件分类特供版】══════════════════════════════════
;文件分类特供版，判断目标路径是否存在同名文件, path1是填的目录 存在等于1
determineext(getZz:=""){
    determinepath := ""
    Loop Parse, getZz, "`n", "`r"
    {
        xiaoyaoStr:=A_LoopField
        SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
        if FileExist(dir "\" ext "\" name)
        {
            determinepath:="1"
            break
        }	
    }
    ;MsgBox, %determinepath%
Return determinepath
}

;文件分类特供版，文件移动，可判断目标路径是否存在而进行下一步操作
filemove2(getZz){
    txet3:=""
    txet :=determineext(getZz)
    if (txet = 1)
    {	
        ; 弹出提示框，让用户选择操作
        msgResult := MsgBox("选项说明：`n【温馨提示：关闭右上角窗口，不进行移动操作】`n`n取 消：跳过所有重名文件`n重 试：移动并重命名所有重名文件为 原文件名+当前日期+当日秒数 `n继 续：覆盖所有重名文件", "已存在后缀文件夹，并且里面有同名文件", 6)
        if(ErrorLevel){
            Return
        }
        if (msgResult = "Cancel")
        {
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext
                DirCreate(dir "\" ext)
                if FileExist(xiaoyaoStr) ;判断文件是否移动成功
                { 
                    ; 不覆盖文件
                    Try {
                        FileMove(xiaoyaoStr, dir "\" ext)
                        ErrorLevel := 0
                    } Catch as Err {
                        ErrorLevel := Err.Extra
                    }
                    if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
                    {
                        txet2:="1"
                        txet3:=	txet3 name "`n"
                    }
                }
            }
            if (txet2 = 1)
            {
                ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
                ttip("重名文件移动失败",1500)		
            }		
            else
            {
                ;ttip("移动成功",1500)
            }
        }
        if (msgResult = "continue")
        {
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext
                DirCreate(dir "\" ext)
                if FileExist(xiaoyaoStr) ;判断文件夹是否移动成功
                { 
                    ; 覆盖目标文件
                    Try {
                        FileMove(xiaoyaoStr, dir "\" ext, 1)
                        ErrorLevel := 0
                    } Catch as Err {
                        ErrorLevel := Err.Extra
                    }
                    if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
                    {
                        txet2:="1"
                        txet3:=	txet3 name "`n"
                    }
                }
            }
            if (txet2 = 1)
            {
                ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
                ttip("重名文件移动失败",1500)	
            }		
            else
            {
                ;ttip("移动成功",1500)
            }
        }
        if (msgResult = "TryAgain")
        {
            Loop Parse, getZz, "`n", "`r"
            {
                xiaoyaoStr:=A_LoopField
                SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
                rename1:=name
                redir:=dir
                reext:=ext
                DirCreate(dir "\" ext)
                Try {
                    FileMove(xiaoyaoStr, dir "\" ext)
                    ErrorLevel := 0
                } Catch as Err {
                    ErrorLevel := Err.Extra
                }
                if FileExist(xiaoyaoStr) ;判断文件夹是否移动成功
                {
                    ; 生成新的文件名，格式为 原文件名+当前日期+当日秒数
                    Try {
                        FileMove(xiaoyaoStr, dir "\" ext "\" nameNoExt "_" A_Now "." ext)
                        ErrorLevel := 0
                    } Catch as Err {
                        ErrorLevel := Err.Extra
                    }
                    if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
                    {
                        txet2:="1"
                        txet3:=	txet3 name "`n"
                    }
                }
            }
            if (txet2 = 1)
            {
                ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
                ttip("重名文件移动失败",1500)		
            }		
            else
            {
                ;ttip("移动成功",1500)
            }
        }	
    }		
    else
    {
        Loop Parse, getZz, "`n", "`r"
        {
            xiaoyaoStr:=A_LoopField
            SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
            rename1:=name
            redir:=dir
            reext:=ext
            DirCreate(dir "\" ext)
            Try {
                FileMove(xiaoyaoStr, dir "\" ext)
                ErrorLevel := 0
            } Catch as Err {
                ErrorLevel := Err.Extra
            }
            if FileExist(xiaoyaoStr) ;最后再判断文件是否移动成功
            {
                txet2:="1"
                txet3:=	txet3 name "`n"
            }
        }
        if (txet2 = 1)
        {
            ;MsgBox, 以下文件移动失败`n%txet3%移动失败！文件正在被占用，或者存在同名文件夹无法覆盖
            ttip("重名文件移动失败",1500)		
        }		
        else
        {
            ;ttip("移动成功",1500)
        }
    }

}

;═════════════════════════════════将指定文件夹生成一个菜单，实时显示文件夹里的内容。by：Kawvin═════════════════════════════════════════════════
;https://www.autoahk.com/archives/9033
Label_My_global_and_PreDefined_Var:
Label_My_global_and_PreDefined_Var()
return
Label_Candy_DrawMenu:
Label_Candy_DrawMenu()
return

;================菜单处理================================
Label_Candy_HandleMenu:
Label_Candy_HandleMenu()
return

;================菜单编辑================================
Label_Kawvin_EditMenu:
Label_Kawvin_EditMenu()
return

/*
╔══════════════════════════════════════╗
║<<<<Fuctions所用到的函数>>>>                                   ║
╚══════════════════════════════════════╝
*/
SkSub_GetMenuItem(IniDir,IniNameNoExt,Sec,TopRootMenuName,Parent:="") ;从一个ini的某个段获取条目，用于生成菜单。
{
    Items:=SkSub_IniRead_Section(MenuLst_ini,"MyMenus") ;本次菜单的发起地
    Items := StrReplace(Items, "△", "`t")
    Loop Parse, Items, "`n"
    {
        Left:=RegExReplace(A_LoopField, "(?<=\/)\s+|\s+(?=\/)|^\s+|(|\s+)=[^!]*[^>]*")
        Right:=RegExReplace(A_LoopField, "^.*?\=\s*(.*)\s*$", "$1")
        if (RegExMatch(left, "^/|//|/$|^$")) ;如果最右端是/，或者最左端是/，或者存在//，则是一个错误的定义，抛弃
            continue
        if RegExMatch(Left, "i)(^|/)\+$") ;如果左边的最末端是仅仅一个"独立的" + 号
        {
            m_Parent := InStr(Left, "/") > 0 ? RegExReplace(Left, "/[^/]*$") "/" : "" ;如果+号前面有存在上级菜单,则有上级菜单，否则没有
                Right:=RegExReplace(Right, "~\|", Chr(3))
                arrRight:=StrSplit(Right,"|"," `t")
                rr1:=arrRight[1]
                rr2:=RegExReplace(arrRight[2], Chr(3), "|")
                rr3:=RegExReplace(arrRight[3], Chr(3), "|")
                rr4:=RegExReplace(arrRight[4], Chr(3), "|")
            }
            else
            {
                szMenuIdx.Insert( Parent "" Left )
                szMenuContent[ TopRootMenuName "/" Parent "" Left] := Right ;  V1toV2: Invalid Index errors?, try 'szMenuContent.Push(<val>)'
                szMenuWhichFile[ TopRootMenuName "/" Parent "" Left] :=IniNameNoExt ;  V1toV2: Invalid Index errors?, try 'szMenuWhichFile.Push(<val>)'
            }
        }
    }
    SkSub_DeleteSubMenus(TopRootMenuName)
    {
        For i,v in szMenuIdx
        {
            if InStr(v, "/")>0
            {
                Item:=RegExReplace(v, "(.*)/.*", "$1")
                %TopRootMenuName%/%Item% := Menu()
                %TopRootMenuName%/%Item%.add()
                %TopRootMenuName%/%Item%.Delete()
            }
        }
    }
    SkSub_CreateMenu(Item,ParentMenuName,label,IconDir,IconSize) ;条目，它所处的父菜单名，菜单处理的目标标签
    { ;送进来的Item已经经过了“去空格处理”，放心使用
        arrS:=StrSplit(Item,"/"," `t")
        _s:=arrS[1]
        if arrS.Length= 1 ;如果里面没有 /，就是最终的”菜单项“。添加到”它的父菜单”上。 ; V1toV2: Verify V2 Length value = V1 MaxIndex
        {
            if InStr(_s, "-") = 1 ;-分割线
                %ParentMenuName% := Menu()
                %ParentMenuName%.Add()
            else if InStr(_s, "*") = 1 ;* 灰菜单
            {
                _s:=LTrim(_s,"*")
                %ParentMenuName%.Add(_s, %Label%)
                %ParentMenuName%.Disable(_s)
            }
            else
            {
                y:=szMenuContent[ ParentMenuName "/" Item]
                z:=SkSub_Get_MenuItem_Icon( y ,IconDir)
                %ParentMenuName%.Add(_s, %Label%)
                %ParentMenuName%.SetIcon(_s, z,, %IconSize%)
            }
        }
        else ;如果有/，说明还不是最终的菜单项，还得一层一层分拨出来。
        {
            _Sub_ParentName:=ParentMenuName . "/" . _s
            _subItem := SubStr(Item, (StrLen(_s)+1)+1)
            SkSub_CreateMenu(_subItem,_Sub_ParentName,label,IconDir,IconSize)
            %ParentMenuName%.add(_s, %_Sub_ParentName%)
            if FileExist(KyMenu_IconDir "\" _s ".ico")
                %ParentMenuName%.SetIcon(_s, KyMenu_IconDir . "\" . _s . ".ico",, %IconSize%)
        }
    }

    SkSub_Get_MenuItem_Icon(item,iconpath) ; item=需要获取图标的条目，iconpath=你定义的图标库文件夹
    {
        if RegExMatch(item, "i)^(ow|openwith|rot|Run|roa|Runp|Rund)\|") ;运行命令类
        {
            cmd_removed:=RegExReplace(item, "^.*?\|") ;里面纯粹的 应用程序 路径
            x:=RegExReplace(cmd_removed, "i)exe[^!]*[^>]*", "exe")
            return x
        }
        else if InStr(item, ".exe") ;省略了指令的openwith|
        {
            x:=RegExReplace(item, "i)\.exe[^!]*[^>]*", ".exe")
            return x
        }
        else
        {
            t:=RegExReplace(item, "\s*\|.*?$") ;去除运行参数，只保留第一个|最前面的部分
            x:=AssocQueryApp(t)
            return x
        }
    }
    AssocQueryApp(sExt)
    {
        sExt :="." . sExt ;ASSOCSTR_EXECUTABLE
        DllCall("shlwapi.dll\AssocQueryString", "uint", 0, "uint", 2, "uint", &sExt, "uint", 0, "uint", 0, "uint*", &iLength)
        sApp := Buffer(2*iLength, 0) ; V1toV2: if 'sApp' is a UTF-16 string, use 'VarSetStrCapacity(&sApp, 2*iLength)' and replace all instances of 'sApp.Ptr' with 'StrPtr(sApp)'
        DllCall("shlwapi.dll\AssocQueryString", "uint", 0, "uint", 2, "uint", &sExt, "uint", 0, "str", sApp, "uint*", &iLength)
        return sApp
    }

    SkSub_IniRead(ini, sec, key:="", default := "") ;iniread的函数化
    {
        v := IniRead(ini, sec, key, Default)
        return v
    }

    SkSub_IniRead_Section(ini,sec)
    { ;返回全部某段的内容，函数化而已
        keylist := IniRead(ini, sec) ;提取[sec]段里面所有的群组
        return keylist
    }
    ;═════════════════════════════════增强版的输出显示;by @荻君═════════════════════════════════════════════════
    XiaoYao_plusGUI(arr*)
    {	
        for i,v in arr{
            XiaoYao_plusGUIvalue.=(A_Index=1 ? "":",") json(v) 
        }
        if(arr.Length=0)
            XiaoYao_plusGUIvalue:=""
        ex := Error("", -1)
        Try {
            Global ErrorLevel := 0, ScriptLine := StrSplit(FileRead(A_ScriptFullPath),"`n","`r")[ex.Line]
        } Catch {
            ScriptLine := "", ErrorLevel := 1
        }
        global guiexist
        global XiaoYao_plusGUItext
        global hEdit
        if(guiexist=""){
            guiexist:=1
            SetTimer(guishow,1)
            Sleep(100)
        }
        XiaoYao_plusGUItext.="[" Format("{:03}",ex.line) "]| " json(XiaoYao_plusGUIvalue) "`n"
        ;XiaoYao_plusGUItext.=json(XiaoYao_plusGUIvalue) "`n"
        ogcXiaoYao_plusGUIt1.Text := XiaoYao_plusGUItext
        ErrorLevel := SendMessage(0xB1, -2, -1, , "ahk_id " hEdit) ; 将光标移动到末尾
        ErrorLevel := SendMessage(0xB7, 0, 0, , "ahk_id " hEdit) ; 滚动到末端
        return
        guishow:
            {
                XiaoYao_plusGUI := Gui("XiaoYao_plusGUI")
                XiaoYao_plusGUI.OnEvent("Close", XiaoYao_plusGUIGuiClose)
                XiaoYao_plusGUI.OnEvent("Size", XiaoYao_plusGUIGuiSize)
                XiaoYao_plusGUI.Opt("+Resize")
                ; gui,XiaoYao_plusGUI:Default
                XiaoYao_plusGUI.SetFont("s10 cdcdcaa", "verdana")
                XiaoYao_plusGUI.BackColor := "2b2b2b"
                ogcEditXiaoYao_plusGUIt1 := XiaoYao_plusGUI.Add("Edit", "vXiaoYao_plusGUIt1 x-2 y-2 w500 h515 ReadOnly"), hEdit := ogcEditXiaoYao_plusGUIt1.hwnd
                XiaoYao_plusGUI.Title := "XiaoYao_plusGUI"
                XiaoYao_plusGUI.Show("w500 h515 y360")
                ; 窗口不在前排
                ;	Gui,XiaoYao_plusGUI:Show,NoActivate w500 h515 y360,XiaoYao_plusGUI 
            }
        return
        XiaoYao_plusGUIGuiClose:
            Reload()
            ;Gui,XiaoYao_plusGUI: Destroy
        return
        XiaoYao_plusGUIGuiSize:
            ogcEditXiaoYao_plusGUIt1.move(, , A_GuiWidth+5, A_GuiHeight+5)
        Return
    }

    json( obj ) {

        If IsObject( obj )
        {
            isarray := 0 ; an empty object could be an array... but it ain't, says I
            for key in obj
                if ( key != ++isarray )
            {
                isarray := 0
                Break
            }

            for key, val in obj
                str .= ( A_Index = 1 ? "" : "," ) ( isarray ? "" : json( key ) ":" ) json( val )

        return isarray ? "[" str "]" : "{" str "}"
    }
    else
        return obj
}
;══════════════════════════════════by僵尸牌木乃伊══════════════════════════════════
; https://www.autoahk.com/archives/42214
; 按 年、月 范围输出全部日期
; AutoDate(2022)--按格式输出2022年所有天数
; AutoDate(20221)--按格式输出2022年1月所有天数
; 第一个参数为日期范围，可以是 年（2022）、月（202211）、日（20221122），也可以留空，为当前日期
; 默认输出格式 ： 年月日-星期。。参二可以自定义格式：同FormatTime相同
AutoDate(LongDate := "", DateFormat := "yyyy年MM月dd日-dddd"){
    If !(LongDate)
        LongDate := A_Now
    If (RegExMatch(LongDate, "[^\d]")){
        MsgBox("请输入正确的待格式化日期格式：`n2000/200010/20001010")
        Return 
    }
    InTime := LongDate
    OutTime := FormatTime(LongDate, "yyyyMMdd")
    Out := OutTime
    LongDate := DateAdd((LongDate != "" ? LongDate : A_Now), -1, 'days')
    Loop{
        LongDate := DateAdd((LongDate != "" ? LongDate : A_Now), 1, 'days')
        AutoTime := FormatTime(LongDate, DateFormat)
        OutTime := FormatTime(LongDate, "yyyyMMdd")
        If (RegExMatch(InTime, "^\d{4}$"))
            If (RegExReplace(Out, "^(\d{4}).+$", "$1") != RegExReplace(OutTime, "^(\d{4}).+$", "$1"))
            Break
        If (RegExMatch(InTime, "^\d{5,6}$"))
            If (RegExReplace(Out, "^\d{4}(\d{2}).+$", "$1") != RegExReplace(OutTime, "^\d{4}(\d{2}).+$", "$1"))
            Break
        If (RegExMatch(InTime, "^\d{7,}$") | !(LongDate))
            If (RegExReplace(Out, "^\d{6}(\d{2}).+$", "$1") != RegExReplace(OutTime, "^\d{6}(\d{2}).+$", "$1"))
            Break
        RDate .= "`n" AutoTime
    }
    Return Trim(RDate,"`n")
}
;═════════════════════════════════简繁互转═════════════════════════════════════════════════
;https://www.autohotkey.com/boards/viewtopic.php?f=28&t=9133
繁簡轉換(內容, 翻譯前語言, 翻譯後語言) ;語言填1或2，1是繁體、2是简体。
{
    ;從Unicode的20902個漢字(0x4E00~0x9fa5)中得到2575個有繁簡差別的字
    繁體字 := "壹贰叁肆伍陆柒捌玖拾丟並亂亙亞伕佇佈佔併來侖侶侷俁係俠倀倆倉個們倖倣倫偉側偵偺偽傑傖傘備傚傢傭傯傳傴債傷傾僂僅僉僑僕僥僨僱價儀儂億儅儈儉儐儔儕儘償優儲儷儸儺儻儼兇兌兒兗內兩冊冑冪凈凍凜凱別刪剄則剋剎剛剝剮剴創剷劃劄劇劉劊劌劍劑勁動勗務勛勝勞勢勣勦勱勳勵勸勻匟匭匯匱區協卹卻厙厤厭厲厴參叢吒吳吶呂咼員哢唄唚唸問啗啞啟啣喒喚喦喪喫喬單喲嗆嗇嗎嗚嗩嗶嘆嘍嘔嘖嘗嘜嘩嘮嘯嘰嘵嘸噁噓噠噥噦噯噲噴噸噹嚀嚇嚌嚐嚕嚙嚥嚦嚨嚮嚳嚴嚶囀囁囂囅囈囉囌囑囓囪圇國圍園圓圖團坰垵埡埰埵執堅堊堝堯報場堿塊塋塏塒塗塚塢塤塴塵塹塼墊墑墜墝墮墳墻墾壇壎壓壘壙壚壞壟壢壩壯壺壽夠夢夾奐奧奩奪奮妝姍姦姪娛婁婦婬婭媧媮媯媼媽嫗嫵嫺嫻嬈嬋嬌嬙嬝嬡嬤嬪嬭嬰嬸嬾孃孌孫學孿宮寢實寧審寫寬寵寶將專尋對導尷屆屍屜屢層屨屬岊岡峴島峽崍崑崗崙崟崠崢崳嵐嶁嶄嶇嶗嶠嶧嶴嶸嶺嶼嶽巋巒巔巖巰巹帥師帳帶幀幃幗幘幟幣幫幬幹幾庫廁廂廄廈廕廚廝廟廠廡廢廣廩廬廳弒弔弳張強彆彈彊彌彎彙彥彫彿徑從徠復徹恆恥悅悵悶悽惡惱惲惻愛愜愨愴愷愾慄慇態慍慘慚慟慣慪慫慮慳慶慼慾憂憊憐憑憒憚憤憫憮憲憶懇應懌懍懞懟懣懨懲懶懷懸懺懼懽懾戀戇戔戧戩戰戲戶扞扠拋挾捨捫捲掃掄掙掛採掽揀揚換揫揮揹搆損搖搗搥搯搶搾摑摜摟摯摳摶摻撈撐撓撚撟撢撣撥撫撲撳撻撾撿擁擄擇擊擋擔據擠擣擬擯擰擱擲擴擷擺擻擼擾攄攆攏攔攖攙攛攜攝攢攣攤攩攪攬攷敗敘敵數敺斂斃斕斬斷旃昇時晉晝暈暉暢暫暱曄曆曇曉曖曠曬書會朧朮東枴柵柺栴桿梔條梟梱棄棖棗棟棧棲椏楊楓楨業極榦榪榮榿槃構槍槓槧槨槳槼樁樂樅樑樓標樞樣樸樹樺橈橋機橢橫檁檉檔檜檢檣檯檳檸檻櫂櫃櫓櫚櫛櫝櫞櫟櫥櫧櫨櫪櫫櫬櫱櫳櫸櫺櫻欄權欏欑欒欖欞欽歎歐歛歟歡歲歷歸歿殀殘殞殤殫殭殮殯殲殺殼毀毆毘毧毬毿氈氌氣氫氬氳氾汎汙決沍沒沖況洩洶浹涇涼淊淒淚淥淨淩淪淵淶淺渙減渦測渮渾湊湞湣湧湯溈準溝溫溼滄滅滌滎滬滯滲滷滸滾滿漁漚漢漣漬漲漵漸漿潁潑潔潛潟潤潯潰潷潿澀澂澆澇澗澠澤澩澮澱濁濃濕濘濛濟濤濫濬濰濱濺濼濾瀅瀆瀉瀋瀏瀕瀘瀝瀟瀠瀦瀧瀨瀰瀲瀾灃灄灑灕灘灝灣灤灨灩災炤為烏烴無煆煇煉煒煖煙煢煥煩煬熒熗熱熾燁燄燈燉燐燒燙燜營燦燬燭燴燻燼燾燿爍爐爛爭爺爾牆牋牘牠牴牽犖犛犢犧狀狹狽猙猶猻獃獄獅獎獨獪獫獰獲獵獷獸獺獻獼玀玆玨珮現琍琯琺琿瑋瑣瑤瑩瑪瑯璉璣璦環璽璿瓊瓏瓔瓚甌甕產甦畝畢畫畬異當畽疇疊痙痠痺痾瘉瘋瘍瘓瘞瘡瘧瘺療癆癇癉癒癘癟癡癢癤癥癩癬癭癮癰癱癲發皁皚皰皸皺盃盜盞盡監盤盧盪眥眾睏睜睞睪瞇瞞瞭瞼矇矚矯砲硃硤硨硯碩碭確碼磚磣磧磯磽礎礙礡礦礪礫礬礱祅祐祕祿禍禎禦禪禮禰禱禿秈稅稈稜稟種稱穀穌積穎穡穢穨穩穫穭窩窪窮窯窶窺竄竅竇竊競筆筍筧箄箇箋箎箏箠節範築篋篛篠篤篩篳簀簍簑簞簡簣簫簷簽簾籃籉籌籐籜籟籠籤籩籪籬籮籲粧粵糝糞糧糰糲糴糶糸糾紀紂約紅紆紇紈紉紋納紐紓純紕紗紙級紛紜紡紮細紱紲紳紹紺紼紿絀終絃組絆絎絏結絕絛絞絡絢給絨統絲絳絹綁綃綆綈綏綑經綜綞綠綢綣綬維綰綱網綴綵綸綹綺綻綽綾綿緄緇緊緋緒緗緘緙線緝緞締緡緣緦編緩緬緯緱緲練緶緹緻縈縉縊縋縐縑縚縛縝縞縟縣縫縭縮縯縱縲縴縵縶縷縹總績繃繅繆繈繐繒織繕繖繙繚繞繡繢繩繪繫繭繯繰繳繹繼繽繾纈纊續纍纏纓纔纖纘纜缽缾罈罋罌罣罰罵罷羅羆羈羋羢羥羨義羶習翹耑耡耬聖聞聯聰聲聳聵聶職聹聽聾肅胊脅脈脕脛脣脩脫脹腎腡腦腫腳腸膃膚膠膩膽膾膿臉臍臏臘臚臟臠臥臨臺臿與興舉舊舖艙艤艦艫艱艷艸芻苃苧茲荊荳莊莖莢莧華菴萇萊萬萵葉葒著葦葯葷蒐蒔蒞蒼蓀蓆蓋蓮蓯蓴蓽蔆蔔蔞蔣蔥蔦蔭蕁蕆蕎蕕蕘蕢蕩蕪蕭蕷薈薊薌薑薔薟薦薩薺藍藎藝藥藪藶藷藹藺蘄蘆蘇蘊蘋蘗蘚蘞蘢蘭蘺蘿處虛虜號虧虯蛺蛻蜆蜋蝕蝟蝦蝨蝸螄螘螞螢螻蟄蟈蟣蟬蟯蟲蟶蟻蠅蠆蠍蠐蠑蠔蠟蠣蠱蠶蠻衊術衚衛衝衹袞裊裌裏補裝裡製複褲褳褸褻襆襉襖襝襠襢襤襪襬襯襲覈見規覓視覘覜覡覦親覬覯覲覷覺覽覿觀觝觴觶觸訂訃計訊訌討訏訐訓訕訖託記訛訝訟訢訣訥訪設許訴訶診註証詁詆詎詐詒詔評詘詛詞詠詡詢詣試詩詫詬詭詮詰話該詳詵詼詿誄誅誆誇誌認誑誒誕誘誚語誠誡誣誤誥誦誨說誰課誶誹誼調諂諄談諉請諍諏諑諒論諗諛諜諞諠諡諢諤諦諧諫諭諮諱諳諶諷諸諺諼諾謀謁謂謄謅謊謎謐謔謖謗謙謚講謝謠謨謫謬謳謹謾譁譆證譎譏譖識譙譚譜譟譫譭譯議譴護譽譾讀變讎讒讓讕讖讚讜讞谿豈豎豐豔豬貍貓貝貞負財貢貧貨販貪貫責貯貰貲貳貴貶買貸貺費貼貽貿賀賁賂賃賄賅資賈賊賑賒賓賕賚賜賞賠賡賢賣賤賦賧質賬賭賴賸賺賻購賽賾贄贅贈贊贍贏贐贓贖贗贛趕趙趨趲跡跼踐踫踴蹌蹕蹟蹣蹤蹧蹺躉躊躋躍躑躒躓躕躚躡躥躦躪軀車軋軌軍軒軔軛軟軫軸軹軺軻軼軾較輅輇載輊輒輓輔輕輛輜輝輞輟輥輦輩輪輯輳輸輻輾輿轂轄轅轆轉轍轎轔轟轡轢轤辦辭辮辯農迆迴迺逕這連週進遊運過達違遙遜遝遞遠適遲遷選遺遼邁還邇邊邏邐郃郟郤郵鄆鄉鄒鄔鄖鄘鄧鄭鄰鄲鄴鄶鄺酈醃醜醞醫醬釀釁釃釅釆釋釐釓釔釕釗釘釙針釣釤釦釧釩釵釷釹鈀鈁鈄鈅鈉鈍鈐鈑鈔鈕鈞鈣鈥鈦鈧鈮鈰鈳鈴鈷鈸鈹鈺鈽鈾鈿鉀鉅鉆鉈鉉鉋鉍鉑鉗鉚鉛鉞鉤鉦鉬鉭鉸鉺鉻鉿銀銃銅銑銓銖銘銚銜銠銣銥銦銨銩銪銫銬銲銳銷銹銻銼鋁鋃鋅鋇鋌鋏鋒鋝鋟鋤鋦鋨鋪鋮鋯鋰鋱鋸鋻鋼錁錄錆錈錐錒錕錘錙錚錛錟錠錢錦錨錫錮錯錳錶錸鍆鍇鍊鍋鍍鍔鍘鍛鍤鍥鍬鍰鍵鍶鍺鍾鎂鎊鎌鎔鎖鎗鎘鎚鎢鎣鎦鎧鎩鎪鎬鎮鎰鎳鎵鏃鏇鏈鏌鏍鏑鏗鏘鏜鏝鏞鏟鏡鏢鏤鏨鏵鏷鏹鏽鐃鐋鐐鐒鐓鐔鐘鐙鐠鐨鐫鐮鐲鐳鐵鐶鐸鐺鐿鑄鑊鑌鑑鑒鑠鑣鑤鑪鑭鑰鑲鑷鑼鑽鑾鑿钁長門閂閃閆閉開閌閎閏閑閒間閔閘閡閣閤閥閨閩閫閬閭閱閶閹閻閼閽閾閿闃闆闈闊闋闌闐闔闕闖關闞闡闢闥阨阬阯陘陝陞陣陰陳陸陽隄隉隊階隕際隨險隱隴隸隻雋雖雙雛雜雞離難雲電霑霤霧霽靂靄靈靚靜靦靨鞏鞦韁韃韆韉韋韌韓韙韜韝韞韻響頁頂頃項順頇須頊頌頎頏預頑頒頓頗領頜頡頤頦頫頭頰頷頸頹頻顆題額顎顏顓願顙顛類顢顥顧顫顯顰顱顳顴風颮颯颱颳颶颺颼飄飆飛飢飩飪飫飭飯飲飴飼飽飾餃餅餉養餌餑餒餓餘餚餛餞餡館餬餱餳餵餼餽餾餿饃饅饈饉饋饌饑饒饗饜饞馬馭馮馱馳馴駁駐駑駒駔駕駘駙駛駝駟駢駭駮駱駿騁騃騅騍騎騏騖騙騣騫騭騮騰騶騷騸騾驀驁驂驃驄驅驊驍驏驕驗驚驛驟驢驤驥驪骯髏髒體髕髖髮鬁鬆鬍鬚鬢鬥鬧鬨鬩鬮鬱魎魘魚魯魴魷鮐鮑鮒鮚鮞鮪鮫鮭鮮鯀鯁鯇鯉鯊鯔鯖鯗鯛鯡鯢鯤鯧鯨鯪鯫鯰鯽鰈鰉鰍鰒鰓鰣鰥鰨鰩鰭鰱鰲鰳鰷鰹鰻鰾鱈鱉鱒鱔鱖鱗鱘鱟鱧鱭鱷鱸鱺鳥鳧鳩鳳鳴鳶鴆鴇鴉鴕鴛鴝鴟鴣鴦鴨鴯鴰鴻鴿鵂鵑鵒鵓鵜鵝鵠鵡鵪鵬鵯鵲鶇鶉鶘鶚鶩鶯鶴鶻鶼鶿鷂鷓鷗鷙鷚鷥鷦鷯鷲鷳鷴鷸鷹鷺鸕鸚鸛鸝鸞鹵鹹鹺鹼鹽麗麥麩麴麵麼黃黌點黨黲黴黷黽黿鼇鼉鼕鼴齊齋齎齏齒齔齙齜齟齠齡出齦齧齪齬齲齷龍龐龔龕龜"
    简体字 := "一二三四五六七八九十丢并乱亘亚夫伫布占并来仑侣局俣系侠伥俩仓个们幸仿伦伟侧侦咱伪杰伧伞备效家佣偬传伛债伤倾偻仅佥侨仆侥偾雇价仪侬亿当侩俭傧俦侪尽偿优储俪罗傩傥俨凶兑儿兖内两册胄幂净冻凛凯别删刭则克刹刚剥剐剀创铲划札剧刘刽刿剑剂劲动勖务勋胜劳势绩剿劢勋励劝匀炕匦汇匮区协恤却厍历厌厉厣参丛咤吴呐吕呙员咔呗吣念问啖哑启衔咱唤岩丧吃乔单哟呛啬吗呜唢哔叹喽呕啧尝唛哗唠啸叽哓呒恶嘘哒哝哕嗳哙喷吨当咛吓哜尝噜啮咽呖咙向喾严嘤啭嗫嚣冁呓罗苏嘱啮囱囵国围园圆图团垧埯垭采陲执坚垩埚尧报场碱块茔垲埘涂冢坞埙堋尘堑砖垫墒坠硗堕坟墙垦坛埙压垒圹垆坏垄坜坝壮壶寿够梦夹奂奥奁夺奋妆姗奸侄娱娄妇淫娅娲偷妫媪妈妪妩娴娴娆婵娇嫱袅嫒嬷嫔奶婴婶懒娘娈孙学孪宫寝实宁审写宽宠宝将专寻对导尴届尸屉屡层屦属岜冈岘岛峡崃昆岗仑金岽峥嵛岚嵝崭岖崂峤峄岙嵘岭屿岳岿峦巅岩巯卺帅师帐带帧帏帼帻帜币帮帱干几库厕厢厩厦荫厨厮庙厂庑废广廪庐厅弑吊弪张强别弹强弥弯汇彦雕佛径从徕复彻恒耻悦怅闷凄恶恼恽恻爱惬悫怆恺忾栗殷态愠惨惭恸惯怄怂虑悭庆戚欲忧惫怜凭愦惮愤悯怃宪忆恳应怿懔蒙怼懑恹惩懒怀悬忏惧欢慑恋戆戋戗戬战戏户擀叉抛挟舍扪卷扫抡挣挂采碰拣扬换揪挥背构损摇捣捶掏抢榨掴掼搂挚抠抟掺捞撑挠拈挢掸掸拨抚扑揿挞挝捡拥掳择击挡担据挤捣拟摈拧搁掷扩撷摆擞撸扰摅撵拢拦撄搀撺携摄攒挛摊挡搅揽考败叙敌数驱敛毙斓斩断毡升时晋昼晕晖畅暂昵晔历昙晓暧旷晒书会胧术东拐栅拐毡杆栀条枭捆弃枨枣栋栈栖桠杨枫桢业极干杩荣桤盘构枪杠椠椁桨规桩乐枞梁楼标枢样朴树桦桡桥机椭横檩柽档桧检樯台槟柠槛棹柜橹榈栉椟橼栎橱槠栌枥橥榇蘖栊榉棂樱栏权椤攒栾榄棂钦叹欧敛欤欢岁历归殁夭残殒殇殚僵殓殡歼杀壳毁殴毗绒球毵毡氇气氢氩氲泛泛污决冱没冲况泄汹浃泾凉淹凄泪渌净凌沦渊涞浅涣减涡测菏浑凑浈愍涌汤沩准沟温湿沧灭涤荥沪滞渗卤浒滚满渔沤汉涟渍涨溆渐浆颍泼洁潜舄润浔溃滗涠涩澄浇涝涧渑泽泶浍淀浊浓湿泞蒙济涛滥浚潍滨溅泺滤滢渎泻渖浏濒泸沥潇潆潴泷濑弥潋澜沣滠洒漓滩灏湾滦赣滟灾照为乌烃无煅辉炼炜暖烟茕焕烦炀荧炝热炽烨焰灯炖磷烧烫焖营灿毁烛烩熏烬焘耀烁炉烂争爷尔墙笺牍它抵牵荦牦犊牺状狭狈狰犹狲呆狱狮奖独狯猃狞获猎犷兽獭献猕猡兹珏佩现璃管珐珲玮琐瑶莹玛琅琏玑瑷环玺璇琼珑璎瓒瓯瓮产苏亩毕画畲异当疃畴叠痉酸痹疴愈疯疡痪瘗疮疟瘘疗痨痫瘅愈疠瘪痴痒疖症癞癣瘿瘾痈瘫癫发皂皑疱皲皱杯盗盏尽监盘卢荡眦众困睁睐睾眯瞒了睑蒙瞩矫炮朱硖砗砚硕砀确码砖碜碛矶硗础碍礴矿砺砾矾砻袄佑秘禄祸祯御禅礼祢祷秃籼税秆棱禀种称谷稣积颖穑秽颓稳获稆窝洼穷窑窭窥窜窍窦窃竞笔笋笕箅个笺篪筝棰节范筑箧箬筱笃筛筚箦篓蓑箪简篑箫檐签帘篮笞筹藤箨籁笼签笾簖篱箩吁妆粤糁粪粮团粝籴粜纟纠纪纣约红纡纥纨纫纹纳纽纾纯纰纱纸级纷纭纺扎细绂绁绅绍绀绋绐绌终弦组绊绗绁结绝绦绞络绚给绒统丝绛绢绑绡绠绨绥捆经综缍绿绸绻绶维绾纲网缀彩纶绺绮绽绰绫绵绲缁紧绯绪缃缄缂线缉缎缔缗缘缌编缓缅纬缑缈练缏缇致萦缙缢缒绉缣绦缚缜缟缛县缝缡缩演纵缧纤缦絷缕缥总绩绷缫缪襁穗缯织缮伞翻缭绕绣缋绳绘系茧缳缲缴绎继缤缱缬纩续累缠缨缠纤缵缆钵瓶坛瓮罂挂罚骂罢罗罴羁芈绒羟羡义膻习翘专锄耧圣闻联聪声耸聩聂职聍听聋肃朐胁脉脘胫唇修脱胀肾脶脑肿脚肠腽肤胶腻胆脍脓脸脐膑腊胪脏脔卧临台锸与兴举旧铺舱舣舰舻艰艳艹刍茇苎兹荆豆庄茎荚苋华庵苌莱万莴叶荭着苇药荤搜莳莅苍荪席盖莲苁莼荜菱卜蒌蒋葱茑荫荨蒇荞莸荛蒉荡芜萧蓣荟蓟芗姜蔷莶荐萨荠蓝荩艺药薮苈薯蔼蔺蕲芦苏蕴苹蘖藓蔹茏兰蓠萝处虚虏号亏虬蛱蜕蚬琅蚀猬虾虱蜗蛳蚁蚂萤蝼蛰蝈虮蝉蛲虫蛏蚁蝇虿蝎蛴蝾蚝蜡蛎蛊蚕蛮蔑术胡卫冲只衮袅夹里补装里制复裤裢褛亵幞裥袄裣裆袒褴袜摆衬袭核见规觅视觇眺觋觎亲觊觏觐觑觉览觌观抵觞觯触订讣计讯讧讨吁讦训讪讫托记讹讶讼欣诀讷访设许诉诃诊注证诂诋讵诈诒诏评诎诅词咏诩询诣试诗诧诟诡诠诘话该详诜诙诖诔诛诓夸志认诳诶诞诱诮语诚诫诬误诰诵诲说谁课谇诽谊调谄谆谈诿请诤诹诼谅论谂谀谍谝喧谥诨谔谛谐谏谕谘讳谙谌讽诸谚谖诺谋谒谓誊诌谎谜谧谑谡谤谦谥讲谢谣谟谪谬讴谨谩哗嘻证谲讥谮识谯谭谱噪谵毁译议谴护誉谫读变雠谗让谰谶赞谠谳溪岂竖丰艳猪狸猫贝贞负财贡贫货贩贪贯责贮贳赀贰贵贬买贷贶费贴贻贸贺贲赂赁贿赅资贾贼赈赊宾赇赉赐赏赔赓贤卖贱赋赕质账赌赖剩赚赙购赛赜贽赘赠赞赡赢赆赃赎赝赣赶赵趋趱迹局践碰踊跄跸迹蹒踪糟跷趸踌跻跃踯跞踬蹰跹蹑蹿躜躏躯车轧轨军轩轫轭软轸轴轵轺轲轶轼较辂辁载轾辄挽辅轻辆辎辉辋辍辊辇辈轮辑辏输辐辗舆毂辖辕辘转辙轿辚轰辔轹轳办辞辫辩农迤回乃径这连周进游运过达违遥逊沓递远适迟迁选遗辽迈还迩边逻逦合郏郄邮郓乡邹邬郧墉邓郑邻郸邺郐邝郦腌丑酝医酱酿衅酾酽采释厘钆钇钌钊钉钋针钓钐扣钏钒钗钍钕钯钫钭钥钠钝钤钣钞钮钧钙钬钛钪铌铈钶铃钴钹铍钰钸铀钿钾巨钻铊铉刨铋铂钳铆铅钺钩钲钼钽铰铒铬铪银铳铜铣铨铢铭铫衔铑铷铱铟铵铥铕铯铐焊锐销锈锑锉铝锒锌钡铤铗锋锊锓锄锔锇铺铖锆锂铽锯鉴钢锞录锖锩锥锕锟锤锱铮锛锬锭钱锦锚锡锢错锰表铼钔锴炼锅镀锷铡锻锸锲锹锾键锶锗锺镁镑镰熔锁枪镉锤钨蓥镏铠铩锼镐镇镒镍镓镞镟链镆镙镝铿锵镗镘镛铲镜镖镂錾铧镤镪锈铙铴镣铹镦镡钟镫镨镄镌镰镯镭铁钚铎铛镱铸镬镔鉴鉴铄镳刨炉镧钥镶镊锣钻銮凿镢长门闩闪闫闭开闶闳闰闲闲间闵闸阂阁阖阀闺闽阃阆闾阅阊阉阎阏阍阈阌阒板闱阔阕阑阗阖阙闯关阚阐辟闼厄坑址陉陕升阵阴陈陆阳堤陧队阶陨际随险隐陇隶只隽虽双雏杂鸡离难云电沾溜雾霁雳霭灵靓静腼靥巩秋缰鞑千鞯韦韧韩韪韬鞴韫韵响页顶顷项顺顸须顼颂颀颃预顽颁顿颇领颌颉颐颏俯头颊颔颈颓频颗题额颚颜颛愿颡颠类颟颢顾颤显颦颅颞颧风飑飒台刮飓扬飕飘飙飞饥饨饪饫饬饭饮饴饲饱饰饺饼饷养饵饽馁饿馀肴馄饯馅馆糊糇饧喂饩馈馏馊馍馒馐馑馈馔饥饶飨餍馋马驭冯驮驰驯驳驻驽驹驵驾骀驸驶驼驷骈骇驳骆骏骋矣骓骒骑骐骛骗鬃骞骘骝腾驺骚骟骡蓦骜骖骠骢驱骅骁骣骄验惊驿骤驴骧骥骊肮髅脏体髌髋发疬松胡须鬓斗闹哄阋阄郁魉魇鱼鲁鲂鱿鲐鲍鲋鲒鲕鲔鲛鲑鲜鲧鲠鲩鲤鲨鲻鲭鲞鲷鲱鲵鲲鲳鲸鲮鲰鲶鲫鲽鳇鳅鳆鳃鲥鳏鳎鳐鳍鲢鳌鳓鲦鲣鳗鳔鳕鳖鳟鳝鳜鳞鲟鲎鳢鲚鳄鲈鲡鸟凫鸠凤鸣鸢鸩鸨鸦鸵鸳鸲鸱鸪鸯鸭鸸鸹鸿鸽鸺鹃鹆鹁鹈鹅鹄鹉鹌鹏鹎鹊鸫鹑鹕鹗鹜莺鹤鹘鹣鹚鹞鹧鸥鸷鹨鸶鹪鹩鹫鹇鹇鹬鹰鹭鸬鹦鹳鹂鸾卤咸鹾硷盐丽麦麸曲面么黄黉点党黪霉黩黾鼋鳌鼍冬鼹齐斋赍齑齿龀龅龇龃龆龄出龈啮龊龉龋龌龙庞龚龛龟" 
    語言 := [繁體字,简体字]
    Loop Parse, 內容
    {
        翻譯前語言位置 := InStr(語言[翻譯前語言], A_LoopField)
        翻譯後的內容 .= 翻譯前語言位置 ? SubStr(語言[翻譯後語言], (翻譯前語言位置)<1 ? (翻譯前語言位置)-1 : (翻譯前語言位置), 1) : A_LoopField 
    } 
    Return 翻譯後的內容
}
;═════════════════════════════════【日期跨度计算器】══════════════════════════════════
时间日期跨度计算器:
时间日期跨度计算器()
return

计算方法1:
计算方法1()
Return

计算方法2:
计算方法2()
Return

多少天后方法:
多少天后方法()
Return

HowLong(Date1,Date2){
    year1 := SubStr(Date1, 1, 4), 	month1 := SubStr(Date1, 5, 2), 	day1 := SubStr(Date1, 7, 2)
    year2 := SubStr(Date2, 1, 4), 	month2 := SubStr(Date2, 5, 2), 	day2 := SubStr(Date2, 7, 2)
    month := leapyear(year1) ? [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] : [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if (day1 > day2)
        day2 := day2 + month[month1], month2 := month2 - 1
    if (month1 > month2) 
        year2 := year2 - 1, month2 := month2 + 12
    D:= day2 - day1, 	M:= month2 - month1, 	Y := year2 - year1
    ;~ MsgBox % Y " Years`n" M " Months`n" D " Days"
return Y " 年`n" M " 月`n" D " 天"
}
leapyear(year){
    if (Mod(year, 100) = 0)
        return (Mod(year, 400) = 0)
return (Mod(year, 4) = 0)
}
;═══════════════════════════════════
max(x, y)	;输出两个变量之间最大的那个
{
return x ^ ((x ^ y) & -(x < y))
}

min(x, y)	;输出两个变量之间最小的那个
{
return y ^ ((x ^ y) & -(x < y))
}
;═════════════════════════════════获取/检查/设置文件属性═════════════════════════════════════════════════
;https://www.autohotkey.com/boards/viewtopic.php?f=6&t=75519
;检查文件或文件夹是否存在: If FileExistZ("D:\")
;使用第二个参数检查文件是否具有特定属性：If FileExistZ("C:\My File.txt", 0x2 )
;检查路径是否为现有文件夹:If FileExistZ("C:\My Folder", 0x10) 
;添加、删除、切换文件属性或完全替换现有属性（如果可能）FileExistZ("C:\MyFiles",,"^=0x2")
FileExistZ(File, C:=0, P*) { 
    Local K,V,N,A, M := A := DllCall("GetFileAttributes", "Str", File, "Int")
    If (P.Count and A != -1 and not C)
        For K,V in P 
        N := StrSplit(V,"="," ",2), K := N[1], V := Round(N[2])
    , M := K="+" ? M|V : K="-" ? M&~V : K="^" ? M^V : K=":" ? V : M|V 
    A := (A != -1 and A != M) ? DllCall("SetFileAttributes", "Str", File, "Int", M)
    ? DllCall("GetFileAttributes", "Str", File, "Int") : -1 : A
Return Format("0x{2:06X}", A := A!=-1 and C ? A & C=C ? A : -1 : A, A=0 ? 8 : A=-1 ? 0 : A)
}
;═════════════════════════════════窗口进程暂停═════════════════════════════════════════════════
窗口进程暂停1:
窗口进程暂停1()
return

窗口进程暂停:
窗口进程暂停()
return

窗口进程恢复:
窗口进程恢复()
return

窗口进程暂停旧:
窗口进程暂停旧()
return

窗口进程恢复旧:
窗口进程恢复旧()
return

全部窗口进程恢复:
全部窗口进程恢复()
return

暂停的窗口:
暂停的窗口()
return

恢复的窗口:
恢复的窗口()
return

查看所有被禁用: 
查看所有被禁用()
return

清除缓存pid:
清除缓存pid()
return

UpdateWindowInfo:
UpdateWindowInfo()
return
;═════════════════════════════════获取文件的属性信息═════════════════════════════════════════════════
;传入参数 vPath 是文件的路径
FileGetAttrib(vPath)
{
    if !FileExist(vPath)
        return
    SplitPath(vPath, &vName, &vDir, &vExt, &vNameNoExt, &vDrive)
    oShell := ComObject("Shell.Application")
    oFolder := oShell.NameSpace(vDir "\")
    oFilename := oFolder.Parsename(vName)
    Loop 360
    {
        vAttrib := oFolder.GetDetailsOf(oFolder.Items, A_Index-1)
        if !(vAttrib = "")
        {
            vValue := oFolder.GetDetailsOf(oFilename, A_Index-1)
            if !(vValue = "")
            {
                组合 .= vAttrib "：" vValue "`n"			
            }
        }
    }
return 组合
}
;═════════════════════════════════中英符号替换═════════════════════════════════════════════════
;将中文符号替换成英文符号,满足不同的需求或规范
中英符号替换(內容, 替换前, 替换后) ;符号填1或2，1是中文符号、2是英文符号。
{
    ;列出中英区别的符号
    中文符号 := "！（），。；‘’【】《》？：“”"
    英文符号 := "!(),.;''[]<>?:`"`"`"" 
    符号替换 := [中文符号,英文符号]
    Loop Parse, 內容
    {
        替换前位置 := InStr(符号替换[替换前], A_LoopField)
        替换后的內容 .= 替换前位置 ? SubStr(符号替换[替换后], (替换前位置)<1 ? (替换前位置)-1 : (替换前位置), 1) : A_LoopField 
    } 
Return 替换后的內容
}
;═════════════════════════════════ v2rayN一键两用═════════════════════════════════════════════════
v2rayN一键两用(){
    Static a := False
Send((a := !a) ? "^!+{F11}" : "^!+{F12}")
}
;═════════════════════════════════记录鼠标坐标═════════════════════════════════════════════════
记录鼠标坐标:
记录鼠标坐标()
return

    #HotIf (Clicksn < 坐标记录次数)
        ~LButton::HK1_LButton()
    Return
    #HotIf

    Button记录开始:
Button记录开始()
    Return
    ;═════════════════════════════════判断指定的文件路径是否为文件夹═════════════════════════════════════════════════
    CF_IsFolder(sfile){
        if InStr(FileExist(sfile), "D")
            || (sfile = "`"::{20D04FE0-3AEA-1069-A2D8-08002B30309D}`"")
    return 1
    else
    return 0
}
;══════════════════════════════════显示\隐藏 文件\扩展名══════════════════════════════════
CF_RegWrite(ValueType, KeyName, ValueName:="", Value:="")
{
    RegWrite(Value, ValueType, KeyName, ValueName)
    if ErrorLevel
    Return A_LastError
else
    Return 0
}

RefreshExplorer()
{ ; by teadrinker on D437 @ tiny.cc/refreshexplorer
    local Windows := ComObject("Shell.Application").Windows
    Windows.Item(ComValue(0x13, 8)).Refresh()
    for Window in Windows
        if (Window.Name != "Internet Explorer")
        Window.Refresh()
}
;═════════════════════════════════窗口垂直\水平最大化═════════════════════════════════════════════════
CF_WinMove(Win, x:="", y:="", w:="", h:="")
{
    WinMove(x, y, w, h, "ahk_id " win)
}

;═════════════════════════════════置顶时加外框═════════════════════════════════════════════════
置顶加边框:
置顶加边框()
return
    ;   border_color = ffae00

DrawRect:
DrawRect()
return

结束置顶加边框:
结束置顶加边框()
return
;═════════════════════════════════倒计时═════════════════════════════════════════════════
倒计时gui:
倒计时gui()
Return

倒计时开始:
倒计时开始()
return

倒计时结束:
倒计时结束()
return

daojishiGuiClose:
daojishiGuiClose()
return

显示倒计时窗口:
显示倒计时窗口()
return
隐藏倒计时窗口:
隐藏倒计时窗口()
return
倒计时:
倒计时()
return

倒计时刷新:
倒计时刷新()
return
;═════════════════════════════════合并文件夹═════════════════════════════════════════════════
合并文件夹功能:
合并文件夹功能()
return

合并确认:
合并确认()
return

合并取消:
hebingGuiClose:
hebingGuiClose()
return
;═════════════════════════════════颜色查看═════════════════════════════════════════════════
;by：https://wyagd001.github.io/RuYi-Ahk/
Cando_颜色查看:
Cando_颜色查看()
Return

RGBGuiescape:
RGBGuiClose:
RGBGuiClose()
Return

changcolor:
changcolor()
return

Hex2RGB(_hexRGB, _delimiter:="")
{
	local color, r, g, b, decimalRGB

	if (_delimiter = "")
		_delimiter := ","
	color += "0x" . _hexRGB
	b := color & 0xFF
	g := (color & 0xFF00) >> 8
	r := (color & 0xFF0000) >> 16
	decimalRGB := r _delimiter g _delimiter b
	Return decimalRGB
}

RGB2Hex(_decimalRGB, _delimiter:="")
{
	local weight, color, hexRGB

	if (_delimiter = "")
		_delimiter := ","
	weight := 16
; V1toV2: Removed 	BackUp_FmtInt := A_FormatInteger
; V1toV2: Removed 	SetFormat Integer, Hex
	color := 0x1000000
	Loop Parse, _decimalRGB, _delimiter
	{
		color += A_LoopField << weight
		weight -= 8
	}
	hexRGB := SubStr(color, (3)+1)
; V1toV2: Removed 	SetFormat Integer, %BackUp_FmtInt%
	Return hexRGB
}

;###############  V1toV2 FUNCS  ###############
Label_Return() { ; V1toV2: Lbl->Func
    global
    SetTimer(Label_ClearMEM,-1000) ;清理内存
Return
}
;##############################################
Label_ClearMEM() { ; V1toV2: Lbl->Func
    global
    pid:=() ? DllCall("GetCurrentProcessId") : pid
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
Return
}
;##############################################
imagemagick1() { ; V1toV2: Lbl->Func
    global
    myGui := Gui()
    myGui.OnEvent("Close", GuiClose)
    myGui.OnEvent("Escape", GuiEscape)
    myGui.Opt("+AlwaysOnTop")
    myGui.Add("Text", , "文本内容:自定义")
    myGui.Add("Edit", "w200 v文字内容", "逍遥")
    myGui.Add("Text", , "文本颜色:`n填写的格式支持: 颜色英文(red) 颜色值(#C0C0C0)`n还支持填写 `"rgba(0, 0, 0, 0.5)`" 英文双引号必须带上`n最后一个参数表示透明度为0.5（其中0表示完全透明，1表示完全不透明）")
    myGui.Add("Link", , "在线取色器：<a href=`"https://c.runoob.com/front-end/5449/`">https://c.runoob.com/front-end/5449/</a>")
    myGui.Add("ComboBox", "w200 v文字颜色 Choose1", ["Red", "Green", "Blue", "Black", "White", "Yellow", "Purple", "Pink", "Orange", "Gray"])
    myGui.Add("Text", , "文字大小:填阿拉伯数字`n[请根据图片分辨率进行设置，图片分辨率越大，数字也需相应填大]")
    myGui.Add("ComboBox", "w200 v文字大小 Choose5", ["10", "20", "30", "40", "50", "60", "70", "80", "90", "100", "200", "300", "400", "500", "600", "700", "800"])
    myGui.Add("Text", , "文字位置:`n左上角(NorthWest) 左中间(West) 左下角(SouthEast)`n上中间(North) 正中间(center) 下中间(South)`n右上角(NorthEast) 右中间(East) 右下角(SouthEast)")
    myGui.Add("ComboBox", "w200 v文字位置 Choose9", ["NorthWest", "North", "NorthEast", "West", "center", "East", "SouthWest", "South", "SouthEast"])
    myGui.SetFont("cRed", "Microsoft YaHei")
    myGui.Add("Text", , "文字旋转角度：[范围：-180到180]")
    myGui.SetFont()
    myGui.Add("ComboBox", "w200 v文字旋转角度 Choose3", ["-90", "-45", "0", "45", "90"])
    myGui.SetFont("cRed", "Microsoft YaHei")
    myGui.Add("Text", , "文本具体坐标(偏移量)[一般不更改]：")
    myGui.SetFont()
    ogcEdit2020 := myGui.Add("Edit", "w200 v文字偏移量", "+20+20")
    myGui.SetFont("cRed", "Microsoft YaHei")
    myGui.Add("Text", , "使用的字体[一般不更改]`n[支持中文的字体可以输出中文水印]")
    myGui.SetFont()
    ogcEditsimhei := myGui.Add("Edit", "w200 v文字字体", "simhei")
    ogcButton := myGui.Add("Button", "Default", "加水印确认")

    myGui.Title := "给图片加文字水印[基于imagemagick使用]"
    myGui.Show()
return
}
;##############################################
Button加水印确认() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui.Submit()
    ;FileAppend,%文字内容%, %A_Temp%\xiaoyaoshuiyin.txt,UTF-8-RAW
    Loop Parse, zztext, "`n", "`r"
    {
        xiaoyaoStr:=A_LoopField
        SplitPath(xiaoyaoStr, &name, &dir, &ext, &nameNoExt, &drive)
        redir:=dir
        renameNoExt:=nameNoExt
        renameExt:=ext
        ;Run %zzplusxy_Path% convert "%xiaoyaoStr%" -fill %FirstVar% -pointsize %SecondVar% -gravity %FourthVar% -draw "text 10`,10 '%ThirdVar%'" "%redir%\%reNameNoExt%_文字水印.%renameExt%", , Hide
        ;Runwait %zzplusxy_Path% "%xiaoyaoStr%" -pointsize %文字大小% -fill %文字颜色% -font %文字字体% -gravity %文字位置% -annotate %文字偏移量% @"%A_Temp%\xiaoyaoshuiyin.txt" "%redir%\%reNameNoExt%_文字水印.%renameExt%", , Hide
        RunWait(zzplusxy_Path " `"" xiaoyaoStr "`" -pointsize " 文字大小 " -fill " 文字颜色 " -font " 文字字体 " -gravity " 文字位置 " -draw `"rotate " 文字旋转角度 " text " 文字偏移量 " '" 文字内容 "'`" `"" redir "\" reNameNoExt "_水印" A_Hour "" A_Min "." renameExt "`"", , "Hide")
    }
    Try FileDelete(A_Temp "\xiaoyaoshuiyin.txt")
    Try myGui.Destroy()
return
}
;##############################################
Batchfile() { ; V1toV2: Lbl->Func
    global
    filebatch5:= Explorer_GetPath()	
    myGui2 := Gui()
    myGui2.OnEvent("Close", GuiClose)
    myGui2.OnEvent("Escape", GuiEscape)
    myGui2.Opt("+Resize")
    myGui2.Opt("+AlwaysOnTop")
    myGui2.SetFont("s10 Bold cBlue", "Microsoft YaHei")
    Tab := myGui2.Add("Tab3", , ["新建文件夹", "新建文件", "新建文件[多行]", "关于"])

    myGui2.SetFont()
    Tab.UseTab("新建文件夹")
    myGui2.Add("Text", , "1.新建文件夹的名称：[自定义]")
    ogcEditFirstVar := myGui2.Add("Edit", "w200 vFirstVar", "新建文件夹")
    myGui2.Add("Text", , "2.需要创建的文件夹个数：[填写阿拉伯数字]")
    ogcEditSecondVar := myGui2.Add("Edit", "w200 vSecondVar", "5")
    myGui2.Add("Text", , "3.创建到哪个目录路径下：[填写格式如 D:\下载]")
    myGui2.SetFont("cRed", "Microsoft YaHei")
    myGui2.Add("Text", , "【已自动获取当前路径】")
    myGui2.SetFont()
    ogcEditThirdVar := myGui2.Add("Edit", "w400 vThirdVar", filebatch5)
    myGui2.Add("Text", , "`n`n")
    ogcButton1 := myGui2.Add("Button", "Default", "确认(&1)")

    Tab.UseTab("新建文件")
    myGui2.Add("Text", , "1.新建文件的类型：[填类型后缀名]")
    ogcEditFirstVar11 := myGui2.Add("Edit", "w200 vFirstVar11", "txt")
    myGui2.Add("Text", , "2.新建文件的名称：[自定义]")
    ogcEditFirstVar1 := myGui2.Add("Edit", "w200 vFirstVar1", "新建 文本文档")
    myGui2.Add("Text", , "3.需要创建的文件个数：[填写阿拉伯数字]")
    ogcEditSecondVar1 := myGui2.Add("Edit", "w200 vSecondVar1", "5")
    myGui2.Add("Text", , "4.创建到哪个目录路径下：[填写格式如 D:\下载]")
    myGui2.SetFont("cRed", "Microsoft YaHei")
    myGui2.Add("Text", , "【已自动获取当前路径】")
    myGui2.SetFont()
    ogcEditThirdVar1 := myGui2.Add("Edit", "w400 vThirdVar1", filebatch5)
    ogcButton1 := myGui2.Add("Button", "Default", "确认(&1)")

    Tab.UseTab("新建文件[多行]")
    myGui2.Add("Text", , "输入新建文件的名称[一行一个]")
    ogcMyEdit2 := myGui2.Add("Edit", "r9 vMyEdit2 w400", "例1`n例2")
    myGui2.Add("Text", , "新建文件的类型：[填类型后缀名]")
    ogcEditFirstVar12 := myGui2.Add("Edit", "w200 vFirstVar12", "txt")
    myGui2.SetFont("cRed", "Microsoft YaHei")
    myGui2.Add("Text", , "【已自动获取当前路径】")
    ogcEditThirdVar2 := myGui2.Add("Edit", "w400 vThirdVar2", filebatch5)
    myGui2.SetFont()
    ogcButton1 := myGui2.Add("Button", "Default", "确认(&1)")

    Tab.UseTab("关于")
    myGui2.SetFont("s10 Bold cBlack", "Microsoft YaHei")
    myGui2.Add("Link", "xm+18 y+10", "当前版本：1.4")
    myGui2.Add("Link", "xm+18 y+10", "讨论QQ群：<a href=`"https://jq.qq.com/?_wv=1027&k=445Ug7u`">246308937【RunAny快速启动一劳永逸】</a>`n")
    myGui2.Add("Text", , "感谢 @hui-Zz、@灼傷眼眸、@而今迈步从头越 的帮助")
    myGui2.Add("Link", "xm+18 y+10", "RunAny_Github文档：<a href=`"https://hui-zz.github.io/RunAny`">https://hui-zz.github.io/RunAny</a>")
    myGui2.Add("Link", "xm+18 y+10", "RunAny_Github地址：<a href=`"https://github.com/hui-Zz/RunAny`">https://github.com/hui-Zz/RunAny</a>")
    myGui2.SetFont()

    myGui2.Title := "文件夹/文件批量创建1.4 [逍遥-2024.02.28]"
    myGui2.Show()
return
}
;##############################################
创建file() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui2.Submit()
    Try FirstVar := oSaved.FirstVar
    Try FirstVar1 := oSaved.FirstVar1
    Try FirstVar11 := oSaved.FirstVar11
    Try FirstVar12 := oSaved.FirstVar12
    Try SecondVar := oSaved.SecondVar
    Try SecondVar1 := oSaved.SecondVar1
    Try ThirdVar := oSaved.ThirdVar
    Try ThirdVar1 := oSaved.ThirdVar1
    Try ThirdVar2 := oSaved.ThirdVar2
    Try MyEdit2 := oSaved.MyEdit2
    if FileExist(ThirdVar) ;判断填写的目录是否真实存在
    { 
        Loop SecondVar
        {
            DirCreate(ThirdVar "\" FirstVar A_index)
        }
        Run(ThirdVar)
    }
    else
    {
        MsgBox("创建失败！`n填写的目录路径格式不正确或者目录路径不存在，请检查")
    }
    myGui2.Title := "文件夹\文件批量创建1.1 [逍遥-2023.11.09]"
    myGui2.Show()
Return 
}
;##############################################
创建file2() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui2.Submit()
    Try FirstVar := oSaved.FirstVar
    Try FirstVar1 := oSaved.FirstVar1
    Try FirstVar11 := oSaved.FirstVar11
    Try FirstVar12 := oSaved.FirstVar12
    Try SecondVar := oSaved.SecondVar
    Try SecondVar1 := oSaved.SecondVar1
    Try ThirdVar := oSaved.ThirdVar
    Try ThirdVar1 := oSaved.ThirdVar1
    Try ThirdVar2 := oSaved.ThirdVar2
    Try MyEdit2 := oSaved.MyEdit2
    if FileExist(ThirdVar1) ;判断填写的目录是否真实存在
    { 
        Loop SecondVar1
        {
            FileAppend(, ThirdVar1 "\" FirstVar1 A_index "." FirstVar11)
        }
        Run(ThirdVar)
    }
    else
    {
        MsgBox("创建失败！`n填写的目录路径格式不正确或者目录路径不存在，请检查")
    }
    myGui2.Title := "文件夹\文件批量创建1.1 [逍遥-2023.11.09]"
    myGui2.Show()
Return 
}
;##############################################
创建file3() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui2.Submit()
    Try FirstVar := oSaved.FirstVar
    Try FirstVar1 := oSaved.FirstVar1
    Try FirstVar11 := oSaved.FirstVar11
    Try FirstVar12 := oSaved.FirstVar12
    Try SecondVar := oSaved.SecondVar
    Try SecondVar1 := oSaved.SecondVar1
    Try ThirdVar := oSaved.ThirdVar
    Try ThirdVar1 := oSaved.ThirdVar1
    Try ThirdVar2 := oSaved.ThirdVar2
    Try MyEdit2 := oSaved.MyEdit2
    if FileExist(ThirdVar2) ;判断填写的目录是否真实存在
    { 
        Loop Parse, MyEdit2, "`n", "`r"
        {
            FileAppend(, ThirdVar2 "\" A_LoopField "." FirstVar12)
        }
        Run(ThirdVar2)
    }
    else
    {
        MsgBox("创建失败！`n填写的目录路径格式不正确或者目录路径不存在，请检查")
    }
    myGui2.Title := "文件夹\文件批量创建1.1 [逍遥-2023.11.09]"
    myGui2.Show()

Return
}
;##############################################
MoveCopyGui() { ; V1toV2: Lbl->Func
    global
    myGui3 := Gui()
    myGui3.OnEvent("Close", GuiClose)
    myGui3.OnEvent("Escape", GuiEscape)
    myGui3.SetFont("s11") ; 设置字体大小为 12 磅
    myGui3.Add("Text", , "选择你要将“选中内容”进行移动还是复制")
    ogcButton1 := myGui3.Add("Button", "Default x20", "移动到(&1)")
    ogcButton1.OnEvent("Click", MoveButton.Bind("Normal"))
    ogcButton2 := myGui3.Add("Button", "Default x+25", "复制到(&2)")
    ogcButton2.OnEvent("Click", CopyButton.Bind("Normal"))
    myGui3.Title := "请选择操作"
    myGui3.Show()
return
}
;##############################################
MoveButton(A_GuiEvent:="", A_GuiControl:="", Info:="", *) { ; V1toV2: Lbl->Func
    global
    Try myGui3.Destroy()
    OutputVar := DirSelect(, 3, "选择你要将“选中文件”移动到哪个位置，然后单击“确定”按钮`n[支持ra的快速定位目录功能]")
    if (ErrorLevel || StrLen(OutputVar) == 0) {
        ;MsgBox, 你没选择任何文件夹
        Return
    } 
    filemove1(MoveButtongetZz, OutputVar)
Return 
}
;##############################################
CopyButton(A_GuiEvent:="", A_GuiControl:="", Info:="", *) { ; V1toV2: Lbl->Func
    global
    Try myGui3.Destroy()
    OutputVar := DirSelect(, 3, "选择你要将”选中文件”复制到哪个位置，然后单击”确定“按钮[支持ra的快速定位目录功能]")
    if (ErrorLevel || StrLen(OutputVar) == 0) {
        ;MsgBox, 你没选择任何文件夹
        Return
    } 
    filecopy1(MoveButtongetZz, OutputVar)
Return 
}
;##############################################
GuiEscape(*) { ; V1toV2: Lbl->Func
global
GuiClose()
}
;##############################################
GuiClose(*) { ; V1toV2: Lbl->Func
    global
    Try myGui3.Destroy()
return
}
;##############################################
Label_My_global_and_PreDefined_Var() { ; V1toV2: Lbl->Func
    global
    global szMenuIdx:={} ;菜单用1
    global szMenuContent:={} ;菜单用2
    global szMenuWhichFile:={} ;菜单用3
    SplitPath(A_ScriptFullPath, , , , &MyOutNameNoExt)
    global MenuLst_ini := MyOutNameNoExt . ".ini"
    global KyMenu_IconSize:=""
    global KyMenu_IconDir:=""

    ;选择要生成菜单的文件夹
    if (MyAppsDir = "")
        return
    ;遍历exe文件
    Try FileDelete(MenuLst_ini)
    FileAppend("[General_Settings]`n", MenuLst_ini)
    FileAppend("AppsDir=" MyAppsDir "`n", MenuLst_ini)
    FileAppend("MenuIconSize=" MyAppsMenuIconSize "`n", MenuLst_ini)
    FileAppend("MenuIconDir=图标库`n", MenuLst_ini)
    FileAppend("随系统启动=0`n`n", MenuLst_ini)
    FileAppend("[MyMenus]`n", MenuLst_ini)

    if(MyAppstype = 2) {
        Loop Files, MyAppsDir "\*" MyAppsext, "R"
        {
            MyMenuName:=A_LoopFilePath
            MyMenuName:=StrReplace(MyMenuName, "[", "(")
            MyMenuName:=StrReplace(MyMenuName, "]", ")")
            if (InStr(MyMenuName, "[") > 0 or InStr(MyMenuName, "]") > 0)
                continue
            MyMenuName := StrReplace(MyMenuName, MyAppsDir "\")
            MyMenuName := StrReplace(MyMenuName, "`\", "`/")
            ;MyMenuPath:=A_LoopFileFullPath
            FileAppend(MyMenuName "`=" A_LoopFilePath "`n", MenuLst_ini)
        }
    }else if(MyAppstype = 1){
        Loop Files, MyAppsDir "\*" MyAppsext, "F"
        {
            MyMenuName:=A_LoopFilePath
            MyMenuName:=StrReplace(MyMenuName, "[", "(")
            MyMenuName:=StrReplace(MyMenuName, "]", ")")
            if (InStr(MyMenuName, "[") > 0 or InStr(MyMenuName, "]") > 0)
                continue
            MyMenuName := StrReplace(MyMenuName, MyAppsDir "\")
            MyMenuName := StrReplace(MyMenuName, "`\", "`/")
            ;MyMenuPath:=A_LoopFileFullPath
            FileAppend(MyMenuName "`=" A_LoopFilePath "`n", MenuLst_ini)
        }
    }else {
        Loop Files, MyAppsDir "\*" MyAppsext, "D"
        {
            MyMenuName:=A_LoopFilePath
            MyMenuName:=StrReplace(MyMenuName, "[", "(")
            MyMenuName:=StrReplace(MyMenuName, "]", ")")
            if (InStr(MyMenuName, "[") > 0 or InStr(MyMenuName, "]") > 0)
                continue
            MyMenuName := StrReplace(MyMenuName, MyAppsDir "\")
            MyMenuName := StrReplace(MyMenuName, "`\", "`/")
            ;MyMenuPath:=A_LoopFileFullPath
            FileAppend(MyMenuName "`=" A_LoopFilePath "`n", MenuLst_ini)
        }
        Loop Files, MyAppsDir "\*" MyAppsext, "F"
        {
            MyMenuName:=A_LoopFilePath
            MyMenuName:=StrReplace(MyMenuName, "[", "(")
            MyMenuName:=StrReplace(MyMenuName, "]", ")")
            if (InStr(MyMenuName, "[") > 0 or InStr(MyMenuName, "]") > 0)
                continue
            MyMenuName := StrReplace(MyMenuName, MyAppsDir "\")
            MyMenuName := StrReplace(MyMenuName, "`\", "`/")
            ;MyMenuPath:=A_LoopFileFullPath
            FileAppend(MyMenuName "`=" A_LoopFilePath "`n", MenuLst_ini)
        }
    }
Label_Candy_DrawMenu()
}
;##############################################
Label_Candy_DrawMenu() { ; V1toV2: Lbl->Func
    global

    KyTopLevelMenu := Menu()
    KyTopLevelMenu.add()
    KyTopLevelMenu.Delete()
    KyMenu_IconSize:=SkSub_IniRead(MenuLst_ini, "General_Settings", "MenuIconSize",16)
    KyMenu_IconDir:=SkSub_IniRead(MenuLst_ini, "General_Settings", "MenuIconDir") ;菜单图标位置

    ;加菜单
    szMenuIdx:={}
    szMenuContent:={}
    szMenuWhichFile:={}
    SkSub_GetMenuItem(Candy_Profile_Dir,CandyMenu_ini,CandyMenu_sec,"KyTopLevelMenu","")
    SkSub_DeleteSubMenus("KyTopLevelMenu")

    For k,v in szMenuIdx
    {
        SkSub_CreateMenu(v,"KyTopLevelMenu","Label_Candy_HandleMenu",KyMenu_IconDir,KyMenu_IconSize)
    }
    KyTopLevelMenu.add()

    KyTopLevelMenu.add("资源管理器打开目录", Label_Kawvin_EditMenu)

    MouseGetPos(&CandyMenu_X, &CandyMenu_Y)
    MouseMove(CandyMenu_X, CandyMenu_Y, 0)
    MouseMove(CandyMenu_X, CandyMenu_Y, 0)
    KyTopLevelMenu.shOW()
return
}
;##############################################
Label_Candy_HandleMenu() { ; V1toV2: Lbl->Func
    global
    MyArray_Memu:=StrSplit( szMenuContent[ A_thisMenu "/" A_ThisMenuItem], ";")
    CmdStr1:=MyArray_Memu[1]
    CmdStr2:=MyArray_Memu[2]
    CmdStr3:=MyArray_Memu[3]
    CmdStr4:=MyArray_Memu[4]
    ;msgbox %CmdStr1% %CmdStr2%,%CmdStr3%,%CmdStr4%
    {   ErrorLevel := "ERROR"
       Try ErrorLevel := Run(CmdStr1 " " CmdStr2, CmdStr3, CmdStr4 "", )
    }
return
}
;##############################################
Label_Kawvin_EditMenu(A_ThisMenuItem:="", A_ThisMenuItemPos:="", MyMenu:="", *) { ; V1toV2: Lbl->Func
    global
    Run(MyAppsDir)
return
}
;##############################################
时间日期跨度计算器() { ; V1toV2: Lbl->Func
    global
    ;https://www.autohotkey.com/boards/viewtopic.php?f=6&t=54796
    myGui4 := Gui()
    myGui4.OnEvent("Close", GuiClose)
    myGui4.OnEvent("Escape", GuiEscape)
    myGui4.Opt("+Resize")
    myGui4.Opt("+AlwaysOnTop")
    myGui4.SetFont("s10 Bold cBlue", "Microsoft YaHei")
    Tab := myGui4.Add("Tab3", , ["跨度1", "跨度2", "多少天前后"])

    myGui4.SetFont()
    Tab.UseTab("跨度1")
    myGui4.Add("Text", , "日期1")
    ogcDateTimeFirstVar := myGui4.Add("DateTime", "vFirstVar", "LongDate")
    myGui4.Add("Text", , "日期2")
    ogcDateTimeSecondVar := myGui4.Add("DateTime", "vSecondVar", "LongDate")
    ogcButton1 := myGui4.Add("Button", "Default", "确认(&1)")

    Tab.UseTab("跨度2")
    myGui4.Add("Text", , "手动输入, 填写格式是：20231122")
    myGui4.Add("Text", , "日期1")
    ogcEditFirstVar1 := myGui4.Add("Edit", "w200 vFirstVar1")
    myGui4.Add("Text", , "日期2")
    ogcEditSecondVar1 := myGui4.Add("Edit", "w200 vSecondVar1")
    ogcButton1 := myGui4.Add("Button", "Default", "确认(&1)")

    Tab.UseTab("多少天前后")
    myGui4.Add("Text", , "日期")
    ogcDateTimeFirstVar2 := myGui4.Add("DateTime", "vFirstVar2", "LongDate")
    myGui4.Add("Text", , "填写格式是天数`n多少天之后就填正数：30`n多少天之前就填负数：-30")
    ogcEditSecondVar2 := myGui4.Add("Edit", "w200 vSecondVar2")
    ogcButton1 := myGui4.Add("Button", "Default", "确认(&1)")

    myGui4.Title := "日期跨度计算器-逍遥"
    myGui4.Show()
return
}
;##############################################
计算方法1() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui4.Submit(0)
    Try FirstVar := oSaved.FirstVar
    Try FirstVar2 := oSaved.FirstVar2
    Try SecondVar := oSaved.SecondVar
    Try FirstVar1 := oSaved.FirstVar1
    Try SecondVar1 := oSaved.SecondVar1
    Try SecondVar2 := oSaved.SecondVar2
    year1 := FormatTime(FirstVar, "yyyy")
    month1 := FormatTime(FirstVar, "MM")
    day1 := FormatTime(FirstVar, "dd")
    年月日组合1 := year1 . month1 . day1
    year2 := FormatTime(SecondVar, "yyyy")
    month2 := FormatTime(SecondVar, "MM")
    day2 := FormatTime(SecondVar, "dd")
    年月日组合2 := year2 . month2 . day2
    最大年月日组合:=max(年月日组合1, 年月日组合2)
    最小年月日组合:=min(年月日组合1, 年月日组合2)
    SecondVar := DateDiff((SecondVar != "" ? SecondVar : A_Now), (FirstVar != "" ? FirstVar : A_Now), "days")
    XiaoYao_plusGUI("日期跨度计算器`n" HowLong(最小年月日组合,最大年月日组合) "`n总间隔天：" SecondVar)
Return 
}
;##############################################
计算方法2() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui4.Submit(0)
    Try FirstVar := oSaved.FirstVar
    Try FirstVar2 := oSaved.FirstVar2
    Try SecondVar := oSaved.SecondVar
    Try FirstVar1 := oSaved.FirstVar1
    Try SecondVar1 := oSaved.SecondVar1
    Try SecondVar2 := oSaved.SecondVar2
    最大年月日组合1:=max(FirstVar1, SecondVar1)
    最小年月日组合1:=min(FirstVar1, SecondVar1)
    SecondVar1 := DateDiff((SecondVar1 != "" ? SecondVar1 : A_Now), (FirstVar1 != "" ? FirstVar1 : A_Now), "days")
    XiaoYao_plusGUI("日期跨度计算器`n" HowLong(最小年月日组合1,最大年月日组合1) "`n总间隔天：" SecondVar1)
Return 
}
;##############################################
多少天后方法() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui4.Submit(0)
    Try FirstVar := oSaved.FirstVar
    Try FirstVar2 := oSaved.FirstVar2
    Try SecondVar := oSaved.SecondVar
    Try FirstVar1 := oSaved.FirstVar1
    Try SecondVar1 := oSaved.SecondVar1
    Try SecondVar2 := oSaved.SecondVar2
    FirstVar2 := DateAdd((FirstVar2 != "" ? FirstVar2 : A_Now), SecondVar2, 'days')
    year1 := FormatTime(FirstVar2, "yyyy")
    month1 := FormatTime(FirstVar2, "MM")
    day1 := FormatTime(FirstVar2, "dd")
    年月日组合3 := year1 "年" month1 "月" day1 "日"
    XiaoYao_plusGUI(SecondVar2 "天 的日期是"年月日组合3)
Return
}
;##############################################
窗口进程暂停1() { ; V1toV2: Lbl->Func
    global
    pid1 := WinGetPID("A")
    activeWindowClass1 := WinGetClass("A")
    窗口标题1 := WinGetTitle("A")
    regex := "(.*)\s-\s.*"
    窗口标题11 := RegExReplace(窗口标题1, regex, "$1")
    窗口标题1 := SubStr(窗口标题11, 1, 15)
    窗口进程名1 := WinGetProcessName("A")
    缓存pid组合1 := FileRead(A_Temp "\xiaoyaoCache2.txt")
    缓存pid组合21 :=""
    Loop Parse, 缓存pid组合1, "`n", "`r"
    {
        xiaoyaoStr:=A_LoopField
        缓存pid组合21 :=缓存pid组合21 "|" xiaoyaoStr 
    }
    if (activeWindowClass1 = "Shell_TrayWnd"|| activeWindowClass1 = "WorkerW" || activeWindowClass1 = "CabinetWClass" || activeWindowClass1 = "Progman"){
        窗口标题1 = 当前窗口为系统窗口！
        pid1 := "不存在"
    }

    SetTitleMatchMode(2)
    myGui4.Opt("+AlwaysOnTop")

    myGui4.SetFont("s10 Bold cBlue", "Microsoft YaHei")
    Tab := myGui4.Add("Tab3", , ["自动获取[切换窗口]", "自动获取[旧]", "手动输入暂停", "手动输入恢复", "关于"])
    myGui4.SetFont()
    Tab.UseTab("自动获取[切换窗口]")

    ogcTextWindow := myGui4.Add("Text", "w500 vWindow标题", "窗口标题:")
    ogcTextWindowPID := myGui4.Add("Text", "w150 vWindowPID", "PID:")
    ogcTextWindow := myGui4.Add("Text", "x+5 w300 vWindow进程名", "进程名:")
    ogcButton1 := myGui4.Add("Button", "x20 y120 Default", "窗口进程暂停(&1)")
    ogcButton2 := myGui4.Add("Button", "x+60 y120 Default", "恢复上次禁用(&2)")
    ogcButton3 := myGui4.Add("Button", "x+60 y120 Default", "查看所有被禁用(&3)")
    myGui4.SetFont("cRed", "Microsoft YaHei")
    myGui4.Add("Text", "x20 y160", "将之前暂停的所有窗口全部恢复")
    myGui4.Add("Text", "x+20 y160", "注意：删除缓存后将不能恢复全部进程")
    myGui4.SetFont()
    ogcButton4 := myGui4.Add("Button", "x20 y190 Default", "全部进程恢复(&4)")
    ogcButtonpid5 := myGui4.Add("Button", "x+80 y190 Default", "清除所有缓存pid(&5)")

    Tab.UseTab("自动获取[旧]")
    myGui4.Add("Text", , "第一次打开gui时的窗口：`n`n" . 窗口进程名1 . " " . 窗口标题1 . " pid值为：" . pid1)
    ogcButton1 := myGui4.Add("Button", "x20 y120 Default", "窗口进程暂停(&1)")
    ogcButton2 := myGui4.Add("Button", "x+60 y120 Default", "窗口进程恢复(&2)")
    ogcButton3 := myGui4.Add("Button", "x+60 y120 Default", "查看所有被禁用(&3)")
    myGui4.SetFont("cRed", "Microsoft YaHei")
    myGui4.Add("Text", "x20 y160", "将之前暂停的所有窗口全部恢复")
    myGui4.Add("Text", "x+20 y160", "注意：删除缓存后将不能恢复全部进程")
    myGui4.SetFont()
    ogcButton4 := myGui4.Add("Button", "x20 y190 Default", "全部进程恢复(&4)")
    ogcButtonpid5 := myGui4.Add("Button", "x+80 y190 Default", "清除所有缓存pid(&5)")

    Tab.UseTab("手动输入暂停")
    myGui4.Add("Text", , "请输入要暂停的窗口的pid[填阿拉伯数字]，或者下拉选择之前禁用过的窗口[实时更新]`n`n请重新打开gui，更新缓存。")
    myGui4.SetFont("cRed", "Microsoft YaHei")
    myGui4.Add("Text", , "注意：如果下拉选择没有内容，可能是之前没暂停过任何进程")
    myGui4.SetFont()
    myGui4.Add("ComboBox", "w500 v缓存的pid1", StrSplit(窗口进程名1, "|")) ; V1toV2: Ensure ComboBox has correct choose value
    ogcButton1 := myGui4.Add("Button", "Default", "暂停确认(&1)")

    Tab.UseTab("手动输入恢复")
    myGui4.Add("Text", , "请输入要恢复的窗口的pid[填阿拉伯数字]，或者下拉选择之前禁用过的窗口[实时更新]`n`n请重新打开gui，更新缓存。")
    myGui4.SetFont("cRed", "Microsoft YaHei")
    myGui4.Add("Text", , "注意：如果下拉选择没有内容，可能是之前没暂停过任何进程")
    myGui4.SetFont()
    myGui4.Add("ComboBox", "w500 v缓存的pid2", StrSplit(窗口进程名1, "|")) ; V1toV2: Ensure ComboBox has correct choose value
    ogcButton1 := myGui4.Add("Button", "Default", "恢复确认(&1)")

    Tab.UseTab("关于")
    myGui4.SetFont("s9 Bold cBlack", "Microsoft YaHei")
    myGui4.Add("Link", "xm+18 y+10", "当前版本：1.2-[20231201]")
    myGui4.Add("Link", "xm+18 y+10", "讨论QQ群：<a href=`"https://jq.qq.com/?_wv=1027&k=445Ug7u`">246308937【RunAny快速启动一劳永逸】</a>`n")
    myGui4.Add("Text", , "@久华 提供软件支持")
    myGui4.Add("Link", "xm+18 y+10", "pssuspend官网：<a href=`"https://learn.microsoft.com/zh-cn/sysinternals/downloads/pssuspend`">https://learn.microsoft.com/zh-cn/sysinternals/downloads/pssuspend</a>")
    myGui4.Add("Link", "xm+18 y+10", "RunAny_Github文档：<a href=`"https://hui-zz.github.io/RunAny`">https://hui-zz.github.io/RunAny</a>")
    myGui4.Add("Link", "xm+18 y+10", "RunAny_Github地址：<a href=`"https://github.com/hui-Zz/RunAny`">https://github.com/hui-Zz/RunAny</a>")
    myGui4.SetFont()

    myGui4.Title := "暂停/恢复进程[基于pssuspend.exe使用]"
    myGui4.Show()

    SetTimer(UpdateWindowInfo,250)
return
}
;##############################################
窗口进程暂停() { ; V1toV2: Lbl->Func
    global
    if (pid = "不存在"){
        return 
    }
    Run(psplusxy_Path " " pid, , "Hide")
    OutputVar1 :=""
    lastLine:=""
    OutputVar1 := FileRead(A_Temp "\xiaoyaoCache.txt")
    lines := StrSplit(OutputVar1,"`n")
    lastLine := lines[lines.Length] ;获取最后一行
    if (pid = lastLine){
        return 
    }
    FileAppend("`n" pid, A_Temp "\xiaoyaoCache.txt")
    FileAppend("`n" 窗口进程名 "-" 窗口标题 " pid值为：" pid, A_Temp "\xiaoyaoCache2.txt")
return
}
;##############################################
窗口进程恢复() { ; V1toV2: Lbl->Func
    global
    OutputVar1 :=""
    lastLine:=""
    OutputVar1 := FileRead(A_Temp "\xiaoyaoCache.txt")
    lines := StrSplit(OutputVar1,"`n")
    lastLine := lines[lines.Length] ;获取最后一行
    Run(psplusxy_Path " -r " lastLine, , "Hide")

return
}
;##############################################
窗口进程暂停旧() { ; V1toV2: Lbl->Func
    global
    if (pid1 = "不存在"){
        return 
    }
    Run(psplusxy_Path " " pid1, , "Hide")
    OutputVar1 :=""
    lastLine:=""
    OutputVar1 := FileRead(A_Temp "\xiaoyaoCache.txt")
    lines := StrSplit(OutputVar1,"`n")
    lastLine := lines[lines.Length] ;获取最后一行
    if (pid = lastLine){
        return 
    }
    FileAppend("`n" pid1, A_Temp "\xiaoyaoCache.txt")
    FileAppend("`n" 窗口进程名1 "-" 窗口标题1 " pid值为：" pid1, A_Temp "\xiaoyaoCache2.txt")
return
}
;##############################################
窗口进程恢复旧() { ; V1toV2: Lbl->Func
    global
    Run(psplusxy_Path " -r " pid1, , "Hide")

return
}
;##############################################
全部窗口进程恢复() { ; V1toV2: Lbl->Func
    global
    OutputVar1 := FileRead(A_Temp "\xiaoyaoCache.txt")
    Loop Parse, OutputVar1, "`n", "`r"
    {
        xiaoyaoStr:=A_LoopField
        Run(psplusxy_Path " -r " xiaoyaoStr, , "Hide")
    }
return
}
;##############################################
暂停的窗口() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui4.Submit()
    Try FirstVar := oSaved.FirstVar
    Try FirstVar2 := oSaved.FirstVar2
    Try SecondVar := oSaved.SecondVar
    Try FirstVar1 := oSaved.FirstVar1
    Try SecondVar1 := oSaved.SecondVar1
    Try SecondVar2 := oSaved.SecondVar2
    if (缓存的pid1 = "不存在"){
        myGui4.Title := "暂停/恢复进程[基于pssuspend.exe使用]"
        myGui4.Show()
        return 
    }
    缓存的pid11 := 缓存的pid1
    startIndex := InStr(缓存的pid1, "pid值为：")
    if (startIndex > 0){
        最终缓存的pid1 := SubStr(缓存的pid1, (startIndex + StrLen("pid值为："))<1 ? (startIndex + StrLen("pid值为："))-1 : (startIndex + StrLen("pid值为：")))
    }else{
        最终缓存的pid1 := 缓存的pid11
    }
    Run(psplusxy_Path " " 最终缓存的pid1, , "Hide")
    lines := StrSplit(OutputVar1,"`n")
    lastLine := lines[lines.Length] ;获取最后一行
    if (缓存的pid1 = lastLine){
        myGui4.Title := "暂停/恢复进程[基于pssuspend.exe使用]"
        myGui4.Show()
        return 
    }

    FileAppend("`n" pid, A_Temp "\xiaoyaoCache.txt")
    FileAppend("`n手动输入 pid值为：" 最终缓存的pid1, A_Temp "\xiaoyaoCache2.txt")
    myGui4.Title := "暂停/恢复进程[基于pssuspend.exe使用]"
    myGui4.Show()
return
}
;##############################################
恢复的窗口() { ; V1toV2: Lbl->Func
    global
    oSaved := myGui4.Submit()
    Try FirstVar := oSaved.FirstVar
    Try FirstVar2 := oSaved.FirstVar2
    Try SecondVar := oSaved.SecondVar
    Try FirstVar1 := oSaved.FirstVar1
    Try SecondVar1 := oSaved.SecondVar1
    Try SecondVar2 := oSaved.SecondVar2
    缓存的pid21 := 缓存的pid2
    startIndex := InStr(缓存的pid2, "pid值为：")
    if (startIndex > 0){
        最终缓存的pid2 := SubStr(缓存的pid2, (startIndex + StrLen("pid值为："))<1 ? (startIndex + StrLen("pid值为："))-1 : (startIndex + StrLen("pid值为：")))
    }else{
        最终缓存的pid2 := 缓存的pid21
    }
    Run(psplusxy_Path " -r " 最终缓存的pid2, , "Hide")
    myGui4.Title := "暂停/恢复进程[基于pssuspend.exe使用]"
    myGui4.Show()
return
}
;##############################################
查看所有被禁用() { ; V1toV2: Lbl->Func
    global
    MyAppsDir1 := A_Temp "\xiaoyaoCache2.txt"
    if FileExist(MyAppsDir1) ;判断文件夹是否存在
    { 
        Run("`"" A_Temp "\xiaoyaoCache2.txt`"")
    }else{
        MsgBox("没有被禁用的窗口进程")
    }
return
}
;##############################################
清除缓存pid() { ; V1toV2: Lbl->Func
    global
    Try FileDelete(A_Temp "\xiaoyaoCache.txt")
    Try FileDelete(A_Temp "\xiaoyaoCache2.txt")
    myGui4.Title := "暂停/恢复进程[基于pssuspend.exe使用]"
    myGui4.Show()
return
}
;##############################################
UpdateWindowInfo() { ; V1toV2: Lbl->Func
    global
    activeWindowTitle := WinGetTitle("A")
    activeWindowClass := WinGetClass("A")

    If (activeWindowTitle = "暂停/恢复进程[基于pssuspend.exe使用]" && activeWindowClass = "AutoHotkeyGUI") {
        pauseUpdate := 1
    } Else {
        pauseUpdate := 0
    }

    if (pauseUpdate = 0) {
        pid := WinGetPID("A")
        activeWindowClass := WinGetClass("A")
        窗口标题 := WinGetTitle("A")
        regex := "(.*)\s-\s.*"
        窗口标题1 := RegExReplace(窗口标题, regex, "$1")
        窗口标题 := SubStr(窗口标题1, 1, 15)
        窗口进程名 := WinGetProcessName("A")
        缓存pid组合 := FileRead(A_Temp "\xiaoyaoCache2.txt")
        缓存pid组合2 :=""
        Loop Parse, 缓存pid组合, "`n", "`r"
        {
            xiaoyaoStr:=A_LoopField
            缓存pid组合2 :=缓存pid组合2 "|" xiaoyaoStr 
        }

        if (activeWindowClass = "Shell_TrayWnd"|| activeWindowClass = "WorkerW" || activeWindowClass = "CabinetWClass" || activeWindowClass = "Progman"){
            窗口标题 = 当前窗口为系统窗口！
            pid := "不存在"
        }

        ogcWindow标题.Value := "窗口标题：" 窗口标题
        ogcTextWindowPID.Value := "PID：" pid
        ogcWindow进程名.Value := "窗口进程名：" 窗口进程名
        ogc缓存的pid2.Value := 缓存pid组合2
        ogc缓存的pid1.Value := 缓存pid组合2
    }
return
}
;##############################################
记录鼠标坐标() { ; V1toV2: Lbl->Func
    global
    myGui4.Opt("+AlwaysOnTop")
    myGui4.SetFont("s10")
    ogcButton := myGui4.Add("Button", "w300 Default", "记录开始")
    myGui4.Add("Edit", "wp r10 -VScroll v鼠标点击位置")

    myGui4.Title := "记录鼠标点击位置的坐标"
    myGui4.Show()
    Clicksn := 坐标记录次数
HK1_LButton()
}
;##############################################
HK1_LButton() { ; V1toV2: HK->Func
        global
        CoordMode("Mouse")
        MouseGetPos(&x, &y)
        ogc鼠标点击位置.Value := 鼠标点击位置 .= x ", " y "`n"
        If (++Clicksn = 坐标记录次数)
            ogc记录开始.Enabled := true
    Return
}
;##############################################
Button记录开始() { ; V1toV2: Lbl->Func
        global
        Clicksn := 0
        ogc鼠标点击位置.Value := 鼠标点击位置 := ""
        ogc记录开始.Enabled := false
    Return
}
;##############################################
置顶加边框() { ; V1toV2: Lbl->Func
    global
    active_id := WinGetID("A")
    SetTimer(DrawRect,20)
    border_thickness := 4
DrawRect()
}
;##############################################
DrawRect() { ; V1toV2: Lbl->Func
    global
    active_id2 := WinGetID("A")

    notMedium1 := WinGetMinMax("ahk_id " active_id)
    if(notMedium1 != 0)
    {
        WinClose("GUI4Boarder")
        return
    }

    if (active_id2 = active_id)
    {
        WinGetPos(&x, &y, &w, &h, "A")
        if (x="")
            return
        myGui4.Opt("+Lastfound +AlwaysOnTop")
        myGui4.BackColor := border_color
        myGui4.Opt("-Caption")
        notMedium := WinGetMinMax("A")

        if (notMedium==0){
            offset:=0
            outerX:=offset
            outerY:=offset
            outerX2:=w-offset
            outerY2:=h-offset
            innerX:=border_thickness+offset
            innerY:=border_thickness+offset
            innerX2:=w-border_thickness-offset
            innerY2:=h-border_thickness-offset
            newX:=x
            newY:=y
            newW:=w
            newH:=h
            WinSetRegion(outerX "-" outerY " " outerX2 "-" outerY " " outerX2 "-" outerY2 " " outerX "-" outerY2 " " outerX "-" outerY " " innerX "-" innerY " " innerX2 "-" innerY " " innerX2 "-" innerY2 " " innerX "-" innerY2 " " innerX "-" innerY)
            myGui4.Title := "GUI4Boarder"
            myGui4.Show("w" . newW . " h" . newH . " x" . newX . " y" . newY . " NoActivate")
            return
        }else
        {
            WinSetRegion("0-0 w0 h0")
            return
        }
    }
return
}
;##############################################
结束置顶加边框() { ; V1toV2: Lbl->Func
    global
    SetTimer(DrawRect,0)
    WinClose("GUI4Boarder")
    Try myGui4.Destroy()
return
}
;##############################################
倒计时gui() { ; V1toV2: Lbl->Func
global
hWnd2 := WinGetID("倒计时[20240224]")
if (hWnd2){
    PID := WinGetPID("ahk_id " hWnd2)
    WinActivate("ahk_pid " PID)
}else{
    daojishi.SetFont("s10 Bold cBlue", "Microsoft YaHei")
    Tab := daojishi.Add("Tab3", , ["设置倒计时时间", "关于"])
    daojishi.SetFont()
    Tab.UseTab("设置倒计时时间")
    daojishi.SetFont("s20")
    ogcEditXiaoshi1 := daojishi.Add("Edit", "vXiaoshi1 h30", "00")
    daojishi.add("Text", "x+5", "时")
    ogcEditFenzhong1 := daojishi.Add("Edit", "vFenzhong1 x+5 h30", "00")
    daojishi.add("Text", "x+2", "分")
    ogcEditMiao1 := daojishi.Add("Edit", "vMiao1 x+5 h30", "30")
    daojishi.add("Text", "x+5", "秒")
    daojishi.SetFont("s12")
    ogcButton1 := daojishi.Add("Button", "x50 y+15 Default", "开始(&1)")
    ogcButton2 := daojishi.Add("Button", "x+18 Default", "提前结束(&2)")

    daojishi.SetFont()
    daojishi.add("Text", "x20 y+15", "更多设置")
    daojishi.SetFont("s11")
    ogcButton := daojishi.Add("Button", "x20 y+15 Default", "显示倒计时窗口")
    ogcButton := daojishi.Add("Button", "x+18 Default", "隐藏倒计时窗口")
    Tab.UseTab("关于")
    daojishi.SetFont("s10 Bold cBlack", "Microsoft YaHei")
    daojishi.Add("Link", "xm+18 y+10", "当前版本：1.1")
    daojishi.Add("Link", "xm+18 y+10", "讨论QQ群：<a href=`"https://jq.qq.com/?_wv=1027&k=445Ug7u`">246308937</a>")
    daojishi.Add("Link", "xm+18 y+10", "文 档：<a href=`"https://hui-zz.github.io/RunAny`">https://hui-zz.github.io/RunAny</a>")
    daojishi.Add("Link", "xm+18 y+10", "Github：<a href=`"https://github.com/hui-Zz/RunAny`">https://github.com/hui-Zz/RunAny</a>")
    daojishi.SetFont()

    daojishi.Title := "倒计时[20240223]"
    daojishi.Show()
}
Return
}
;##############################################
倒计时开始() { ; V1toV2: Lbl->Func
    global
    oSaved := daojishi.Submit()
    Try Fenzhong1 := oSaved.Fenzhong1
    Try Miao1 := oSaved.Miao1
    Try Xiaoshi1 := oSaved.Xiaoshi1
    kaishishijian := A_Hour ":" A_Min ":" A_Sec
    shijian := Xiaoshi1*60*60+Fenzhong1*60+Miao1
    shijian3 := Xiaoshi1 "时" Fenzhong1 "分" Miao1 "秒"
    倒计时() ; V1toV2: Gosub
    daojishi.Show()
return
}
;##############################################
倒计时结束() { ; V1toV2: Lbl->Func
    global
    SetTimer(倒计时刷新,0)
    WinClose("倒计时xiaoyao")
    Try djs.Destroy()
return
}
;##############################################
daojishiGuiClose() { ; V1toV2: Lbl->Func
    global
    Try daojishi.Destroy()
return
}
;##############################################
显示倒计时窗口() { ; V1toV2: Lbl->Func
    global
    djs.show()
return
}
;##############################################
隐藏倒计时窗口() { ; V1toV2: Lbl->Func
    global
    djs.Hide()
return
}
;##############################################
倒计时() { ; V1toV2: Lbl->Func
    global
    kaishishijian := A_Hour ":" A_Min ":" A_Sec
    hWnd := WinGetID("倒计时xiaoyao")
    if (hWnd){
        PID := WinGetPID("ahk_id " hWnd)
        MsgBox("倒计时正在运行")
    }else{
        djs.Opt("+Disabled +Owner -Caption +LastFound +AlwaysOnTop")
        myGui4.MarginX := 0, myGui4.MarginY := 0
        djs.BackColor := "c000000"
        djs.SetFont("cffffff s20", "Microsoft YaHei")
        ogcTextshijian2 := djs.Add("Text", "Center y+15 w170 h35 vshijian2", "倒计时未开始")
        WinSetTransColor("c000000 255") ;黑色部分透明，文本0-255，150半透明
        djs.Title := "倒计时xiaoyao"
        djs.Show("x1700 y975")
        SetTimer(倒计时刷新,1000)
        倒计时刷新() ; V1toV2: Gosub
    }
return
}
;##############################################
倒计时刷新() { ; V1toV2: Lbl->Func
    global
    shijian -= 1
    If(shijian = 0)
    {	
        ogcTextshijian2.Text := "倒计时结束"
        MsgBox(shijian3 "的倒计时已结束`n`n开始时刻:" kaishishijian "`n结束时刻:" A_Hour ":" A_Min ":" A_Sec)
        SetTimer(倒计时刷新,0)
        Try djs.Destroy()
        Try daojishi.Destroy()
    }Else{
        xs := shijian//3600
        fz := Mod(shijian,3600)//60
        M := Mod(Mod(shijian,3600),60)
        SJ := xs . "时" . fz . "分" . M . "秒"
        ogcTextshijian2.Text := SJ
    }
return
}
;##############################################
合并文件夹功能() { ; V1toV2: Lbl->Func
global
hebing := Gui()
hebing.OnEvent("Close", hebingGuiClose)
hebing.Opt("+AlwaysOnTop")
hebing.SetFont("s12")
hebing.Add("Text", , "请输入文件夹名称:`n[可下拉选择其中之一]")
hebing.Add("ComboBox", "w400 v合并文件夹名称", StrSplit(hb合并文件夹名称合集, "|")) ; V1toV2: Ensure ComboBox has correct choose value
ogcButton1 := hebing.Add("Button", "Default x100 y+30", "确认(&1)")
ogcButton2 := hebing.Add("Button", "Default x+25", "取消(&2)")
hebing.Title := "合并文件夹"
hebing.Show()
return
}
;##############################################
合并确认() { ; V1toV2: Lbl->Func
    global
    oSaved := hebing.Submit()
    DirCreate(hb合并文件夹名称路径 "\" 合并文件夹名称)
    FolderPath1 := hb合并文件夹名称路径 . "\" 合并文件夹名称 . "\"
    FolderPath2 := hb合并文件夹名称路径 . "\" 合并文件夹名称
    ;MsgBox, %FolderPath1%
 
Filename :=""
Loop Parse, hbgetZz, "`n", "`r"
{ 
 if (FolderPath2 !=A_LoopField)
 {
 if InStr(FileExist(A_LoopField), "D") ;判断指定的文件路径是否为文件夹
 {
    Loop Files, A_LoopField "\*.*", "FD" ; 包括子文件夹.
    {
        Filename :=Filename A_LoopFilePath "`n" 
    }
 }Else{
 Filename :=Filename A_LoopField "`n" 
 } 
 }  
}
Filename := SubStr(Filename, 1, StrLen(Filename) - 1) ;删除字符串的最后一个字符
;MsgBox,%Filename%
    filemove1(Filename, FolderPath1)
    Loop 8
    {
        Loop Parse, hbgetZz, "`n", "`r"
        { 
            Loop Files, A_LoopField "\*.*", "DR" ; 包括子文件夹.
            {
                DirDelete(A_LoopFilePath) ;删除目录, 但仅限于空目录          
                ;MsgBox, %A_LoopFileFullPath%
            }
        }
    }
    Loop Parse, hbgetZz, "`n", "`r"
    { 
        DirDelete(A_LoopField) ;删除目录, 但仅限于空目录.        
    } 
Try hebing.Destroy()
return
}
;##############################################
hebingGuiClose(*) { ; V1toV2: Lbl->Func
global
Try hebing.Destroy()
return
}
;##############################################
Cando_颜色查看() { ; V1toV2: Lbl->Func
global
;Gui,RGB: Default ; V1toV2: removed
V1toV2_LineFill := true ; remove me after inspection
Try RGB.Destroy()
RGB.Opt("+Lastfound +AlwaysOnTop")
RGB.add("text", "x7", "输入格式举例：#FF0000 FF0000")
RGB.add("text", "x7", "颜色代码(Hex):")
ogceditcolor_hex := RGB.Add("edit", "x+10 w120 vcolor_hex", Color_Hex)
ogcbuttonOk := RGB.add("button", "x+120 default", "Ok")
ogcbuttonOk.OnEvent("Click", changcolor.Bind("Normal"))
RGB.add("text", "x7", "颜色代码(RGB):")
ogceditColor_RGB := RGB.Add("edit", "x+10 readonly w120 vColor_RGB", Color_RGB)
RGB.add("text", "x7", "颜色:")
ogcProgressprobar := RGB.Add("Progress", "x+10 c" . Color_Hex . " w170 h170 vprobar", "100")
RGB.Title := "颜色查看"
RGB.Show("w230 h230")
Return
}
;##############################################
RGBGuiClose() { ; V1toV2: Lbl->Func
global
Try RGB.Destroy()
Return
}
;##############################################
changcolor(A_GuiEvent:="", A_GuiControl:="", Info:="", *) { ; V1toV2: Lbl->Func
global
;Gui,RGB: Default ; V1toV2: removed, but applied
V1toV2_LineFill := true ; remove me after inspection
oSaved := RGB.Submit(0)
Try Color_RGB := oSaved.Color_RGB
Try color_hex := oSaved.color_hex
Color_Hex := StrReplace(Color_Hex, "#", "")
Color_RGB := Hex2RGB(Color_Hex)
Color_RGB := "RGB(" Color_RGB ")"
ogceditColor_RGB.Value := Color_RGB
ogcProgressprobar.Opt("+c" Color_Hex)
return
}
;═════════════════════════════════下一功能═════════════════════════════════════════════════