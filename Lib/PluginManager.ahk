class PluginManager {
    static objList := Map()
    static pathList := Map()
    static relPathList := Map()
    static nameList := Map()
    static versionList := Map()
    static iconList := Map()
    static regGUID := Map()
    static pluginCount := 0
    static PLUGINS_DIR := "RunPlugins"
    static OBJREG_INI := "RunAny_ObjReg.ini"
    static objRegActive := Map()
    static dirList := []
    static helpList := Map()

    static Init() {
        PluginManager.BuildHelpList()
        PluginManager.ScanPlugins()
        PluginManager.LoadObjReg()
        PluginManager.AutoStart()
    }

    static BuildHelpList() {
        baseUrl := "https://hui-zz.gitee.io/runany/#"
        pagesPlugins := baseUrl . "/plugins-help?id="
        pagesRunCtrl := baseUrl . "/run-ctrl?id="
        h := PluginManager.helpList
        h["huiZz_QRCode.ahk"] := pagesPlugins . "huizz_qrcode二维码脚本使用方法"
        h["huiZz_Window.ahk"] := pagesPlugins . "huizz_window窗口操作插件使用方法"
        h["huiZz_System.ahk"] := pagesPlugins . "huizz_system系统操作插件使用方法"
        h["huiZz_Text.ahk"] := pagesPlugins . "huizz_text文本操作插件使用方法"
        h["RunAny_SearchBar.ahk"] := baseUrl . "/plugins/runany-searchbar"
        h["RunCtrl_Common.ahk"] := pagesRunCtrl . "runctrl_commonahk插件-公共规则函数库"
        h["RunCtrl_Network.ahk"] := pagesRunCtrl . "runctrl_networkahk插件-网络规则函数库"
    }

    static ScanPlugins() {
        PluginManager.objList := Map()
        PluginManager.pathList := Map()
        PluginManager.relPathList := Map()
        PluginManager.nameList := Map()
        PluginManager.versionList := Map()
        PluginManager.iconList := Map()
        PluginManager.pluginCount := 0
        PluginManager.dirList := []

        dirs := [A_ScriptDir "\" PluginManager.PLUGINS_DIR]
        customDir := ConfigReader.ReadSetting("PluginsDirPath", "")
        if customDir != "" {
            Loop Parse customDir, "|" {
                d := ConfigReader.TransformVar(A_LoopField)
                d := RegExReplace(d, "\\$")
                if d != "" && DirExist(d)
                    dirs.Push(d)
            }
        }

        for baseDir in dirs {
            if !DirExist(baseDir)
                continue
            PluginManager.dirList.Push(baseDir)
            Loop Files baseDir "\*.ahk", "F" {
                PluginManager._RegisterFile(A_LoopFilePath, A_LoopFileName, baseDir)
            }
            Loop Files baseDir "\*", "D" {
                subAhk := A_LoopFilePath "\" A_LoopFileName ".ahk"
                if FileExist(subAhk)
                    PluginManager._RegisterFile(subAhk, A_LoopFileName ".ahk", baseDir)
            }
        }
        PluginManager.LoadConfig()
    }

    static _RegisterFile(filePath, fileName, baseDir) {
        if PluginManager.pathList.Has(fileName)
            return
        meta := PluginManager.ReadMeta(filePath)
        PluginManager.pathList[fileName] := filePath
        PluginManager.relPathList[fileName] := StrReplace(filePath, A_ScriptDir "\")
        PluginManager.nameList[fileName] := meta.name
        PluginManager.versionList[fileName] := meta.version
        PluginManager.iconList[fileName] := meta.icon
        if PluginManager.iconList[fileName] = "" {
            noExt := RegExReplace(filePath, "i)\.ahk$")
            for ext in [".ico", ".exe", ".png"] {
                if FileExist(noExt ext) {
                    PluginManager.iconList[fileName] := noExt ext ",1"
                    break
                }
            }
        }
    }

    static LoadConfig() {
        if !FileExist(CONFIG_PATH)
            return
        try {
            plugins := IniRead(CONFIG_PATH, "Plugins")
            Loop Parse plugins, "`n", "`r" {
                eq := InStr(A_LoopField, "=")
                if eq = 0
                    continue
                key := SubStr(A_LoopField, 1, eq - 1)
                val := SubStr(A_LoopField, eq + 1)
                PluginManager.objList[key] := val
                for d in PluginManager.dirList {
                    if FileExist(d "\" key)
                        PluginManager.pathList[key] := d "\" key
                    noExt := RegExReplace(key, "i)\.ahk$")
                    if FileExist(d "\" noExt "\" key)
                        PluginManager.pathList[key] := d "\" noExt "\" key
                }
                if val
                    PluginManager.pluginCount++
            }
        } catch {
        }
    }

    static ReadMeta(filePath) {
        namePat := 'i)^\s*global\s+RunAny_Plugins_Name\s*:=\s*"(.+?)"'
        verPat := 'i)^\s*global\s+RunAny_Plugins_Version\s*:=\s*"([\d.]*)"'
        iconPat := 'i)^\s*global\s+RunAny_Plugins_Icon\s*:=\s*"(.+?)"'
        oldPattern := "i).*?[\x{3010}\x{300A}\x{FE40}\x{FF08}](.+?)[\x{3011}\x{300B}\x{FE41}\x{FF09}].*"
        result := { name: "", version: "", icon: "" }
        try {
            Loop Read filePath {
                line := A_LoopReadLine
                if result.name = "" && RegExMatch(line, namePat, &m)
                    result.name := m[1]
                if result.name = "" && RegExMatch(line, oldPattern, &m2)
                    result.name := m2[1]
                if result.version = "" && RegExMatch(line, verPat, &m)
                    result.version := m[1]
                if result.icon = "" && RegExMatch(line, iconPat, &m)
                    result.icon := m[1]
                if result.name != "" && result.version != "" && result.icon != ""
                    break
            }
        }
        return result
    }

    static LoadObjReg() {
        PluginManager.regGUID := Map()
        iniPath := A_ScriptDir "\" PluginManager.PLUGINS_DIR "\" PluginManager.OBJREG_INI
        if !FileExist(iniPath)
            return
        try {
            sections := IniRead(iniPath, "objreg")
            Loop Parse sections, "`n", "`r" {
                eq := InStr(A_LoopField, "=")
                if eq = 0
                    continue
                key := SubStr(A_LoopField, 1, eq - 1)
                val := SubStr(A_LoopField, eq + 1)
                PluginManager.regGUID[key] := val
            }
        } catch {
        }
    }

    static AutoStart() {
        for fileName, enabled in PluginManager.objList {
            if !enabled
                continue
            if PluginManager.IsRunning(fileName)
                continue
            path := PluginManager.GetPath(fileName)
            if path = "" || !FileExist(path)
                continue
            PluginManager.LaunchPlugin(fileName)
        }
    }

    static AutoClose() {
        for fileName, enabled in PluginManager.objList {
            if !enabled
                continue
            PluginManager.StopPlugin(fileName)
        }
    }

    static GetPath(fileName) {
        if PluginManager.pathList.Has(fileName)
            return PluginManager.pathList[fileName]
        return ""
    }

    static ToggleAutoStart(fileName) {
        current := PluginManager.objList.Has(fileName) ? PluginManager.objList[fileName] : 0
        newVal := current ? 0 : 1
        PluginManager.objList[fileName] := newVal
        try IniWrite(newVal, CONFIG_PATH, "Plugins", fileName)
        if newVal
            PluginManager.pluginCount++
        else
            PluginManager.pluginCount--
    }

    static IsRunning(fileName) {
        path := PluginManager.GetPath(fileName)
        if path = ""
            return false
        SplitPath(path, &fName, &fDir, &fExt)
        if fExt = "ahk" {
            DetectHiddenWindows(true)
            found := WinExist(path " ahk_class AutoHotkey")
            DetectHiddenWindows(false)
            return found != 0
        }
        if fName
            return ProcessExist(fName) != 0
        return false
    }

    static LaunchPlugin(fileName) {
        if PluginManager.IsRunning(fileName)
            return
        path := PluginManager.GetPath(fileName)
        if path = ""
            return
        SplitPath(path, &fName, &fDir, &fExt)
        try {
            if fDir && DirExist(fDir)
                SetWorkingDir(fDir)
            if fExt = "ahk"
                Run('"' A_AhkPath '" "' path '"')
            else
                Run(path)
        } catch as e {
            TrayTip("插件启动失败: " fileName, e.Message, 3)
        } finally {
            SetWorkingDir(A_ScriptDir)
        }
    }

    static StopPlugin(fileName) {
        path := PluginManager.GetPath(fileName)
        if path = ""
            return
        SplitPath(path, &fName, &fDir, &fExt)
        
        DetectHiddenWindows(true)
        
        if fExt = "ahk" {
            ; WinClose 触发正常关闭流程（异步，不等待）
            try WinClose(path " ahk_class AutoHotkey")
            try WinClose(fName " ahk_class AutoHotkey")
        } else if fName {
            try ProcessClose(fName)
        }
        
        DetectHiddenWindows(false)
    }

    static SuspendPlugin(fileName) {
        path := PluginManager.GetPath(fileName)
        if path = ""
            return
        DetectHiddenWindows(true)
        try PostMessage(0x111, 65404, 0, 0, path " ahk_class AutoHotkey")
        DetectHiddenWindows(false)
    }

    static PausePlugin(fileName) {
        path := PluginManager.GetPath(fileName)
        if path = ""
            return
        DetectHiddenWindows(true)
        try PostMessage(0x111, 65403, 0, 0, path " ahk_class AutoHotkey")
        DetectHiddenWindows(false)
    }

    static EditPlugin(fileName) {
        path := PluginManager.GetPath(fileName)
        if path = ""
            return
        editor := ConfigReader.ReadSetting("PluginsEditor", "")
        if editor != "" {
            editor := ConfigReader.TransformVar(editor)
            try Run(editor ' "' path '"')
            return
        }
        try PostMessage(0x111, 65401, 0, 0, path " ahk_class AutoHotkey")
        catch {
            try Run("edit " path)
            catch
                Run("notepad.exe " path)
        }
    }

    static RemovePlugin(fileName) {
        if PluginManager.objList.Has(fileName)
            PluginManager.objList.Delete(fileName)
        try IniDelete(CONFIG_PATH, "Plugins", fileName)
        noExt := RegExReplace(fileName, "i)\.ahk$")
        iniPath := A_ScriptDir "\" PluginManager.PLUGINS_DIR "\" PluginManager.OBJREG_INI
        try IniDelete(iniPath, "objreg", noExt)
    }

    static IsObjReg(fileName) {
        noExt := RegExReplace(fileName, "i)\.ahk$")
        return PluginManager.regGUID.Has(noExt) || noExt = "RunAny_Menu" || noExt = "RunAny_ObjReg"
    }

    static PauseAll() {
        for fileName, enabled in PluginManager.objList {
            if !enabled
                continue
            PluginManager.PausePlugin(fileName)
        }
    }

    static SuspendAll() {
        for fileName, enabled in PluginManager.objList {
            if !enabled
                continue
            PluginManager.SuspendPlugin(fileName)
        }
    }

    static CloseAll() {
        for fileName, enabled in PluginManager.objList {
            if !enabled
                continue
            PluginManager.StopPlugin(fileName)
        }
    }

    static ShowGui() {
        PluginGui.Show()
    }
}

class PluginGui {
    static guiObj := ""
    static lv1 := ""
    static lv2 := ""
    static lvNum := 1
    static swapMode := false
    static ImageListID := 0
    static tab := ""

    static SetImageList() {
        PluginGui.ImageListID := IL_Create(1, 1)
        IL_Add(PluginGui.ImageListID, A_AhkPath, 2)    ; 统一运行图标
    }

    ; 统一使用启动图标（不做状态区分）
    static GetPluginIcon(fileName) {
        return 1
    }

    static Show() {
        try {
            if PluginGui.guiObj && PluginGui.guiObj.Hwnd && WinExist("ahk_id " PluginGui.guiObj.Hwnd) {
                PluginGui.guiObj.Show()
                return
            }
        } catch {
            PluginGui.guiObj := ""
        }

        PluginManager.ScanPlugins()
        PluginGui.swapMode := ConfigReader.ReadSetting("PluginsListViewSwap", "0") = "1"
        PluginGui.SetImageList()

        g := Gui("+Resize", APP_NAME " 插件管理 - 支持拖放")
        g.SetFont("s10", "Microsoft YaHei")
        PluginGui.guiObj := g

        g.AddText("xm w730 cGray", "💡 请右键进行脚本的相关操作（F1~F11 快捷键可用）")

        tab1Name := !PluginGui.swapMode ? "独立插件" : APP_NAME "插件"
        tab2Name := !PluginGui.swapMode ? APP_NAME "插件" : "独立插件"
        tab := g.AddTab3("xm w740 h530 -Wrap", [tab1Name, tab2Name])
        PluginGui.tab := tab

        tab.UseTab(1)
        lv1 := g.AddListView("x10 y+5 w720 r25 grid HScroll AltSubmit Checked vRunAnyPluginsLV1", [(!PluginGui.swapMode ? "独立" : APP_NAME) "插件脚本", "运行状态", "自动启动", "插件描述", "插件说明地址"])
        DllCall("User32\SendMessageW", "Ptr", lv1.Hwnd, "UInt", 0x1003, "Ptr", 1, "Ptr", PluginGui.ImageListID)  ; LVSIL_SMALL
        PluginGui.lv1 := lv1
        PluginGui.FillLV(lv1, PluginGui.swapMode)

        tab.UseTab(2)
        lv2 := g.AddListView("x10 y+5 w720 r25 grid HScroll AltSubmit Checked vRunAnyPluginsLV2", [(!PluginGui.swapMode ? APP_NAME : "独立") "插件脚本", "运行状态", "自动启动", "插件描述", "插件说明地址"])
        DllCall("User32\SendMessageW", "Ptr", lv2.Hwnd, "UInt", 0x1003, "Ptr", 1, "Ptr", PluginGui.ImageListID)  ; LVSIL_SMALL
        PluginGui.lv2 := lv2
        PluginGui.FillLV(lv2, !PluginGui.swapMode)

        tab.UseTab(0)

        lv1.OnEvent("ContextMenu", (lv, item, isRight, x, y) => PluginGui.ShowContextMenu())
        lv2.OnEvent("ContextMenu", (lv, item, isRight, x, y) => PluginGui.ShowContextMenu())

        g.OnEvent("Close", (*) => (g.Destroy(), PluginGui.guiObj := ""))
        g.OnEvent("Escape", (*) => (g.Destroy(), PluginGui.guiObj := ""))
        g.OnEvent("Size", (guiObj, minMax, w, h) => PluginGui.OnSize(guiObj, minMax, w, h))
        g.Show("w750 h580")
        PluginGui.RegisterHK()
    }

    ; 拖放文件到插件目录（复刻 V1）
    ; AHK v2 不支持 +DropFiles 选项，改用 OnMessage WM_DROPFILES 实现
    static FillLV(lv, wantObjReg) {
        lv.Opt("-Redraw")
        lv.Delete()
        for fileName, path in PluginManager.pathList {
            isObjReg := PluginManager.IsObjReg(fileName)
            if wantObjReg != isObjReg
                continue
            noExt := RegExReplace(fileName, "i)\.ahk$")
            if noExt = "RunAny_ObjReg"
                continue
            running := PluginManager.IsRunning(fileName) ? "启动" : ""
            autoVal := PluginManager.objList.Has(fileName) ? PluginManager.objList[fileName] : 0
            if !path || path = ""
                autoStr := "未找到"
            else
                autoStr := autoVal ? "自启" : "禁用"
            check := autoStr = "自启" ? "Check" : ""
            iconNum := PluginGui.GetPluginIcon(fileName)
            helpUrl := PluginManager.helpList.Has(fileName) ? PluginManager.helpList[fileName] : ""
            desc := PluginManager.nameList.Has(fileName) ? PluginManager.nameList[fileName] : ""
            lv.Add("Icon" iconNum " " check, fileName, running, autoStr, desc, helpUrl)
        }
        lv.ModifyCol(2, "SortDesc")
        lv.ModifyCol(2, 65 " Center")
        lv.ModifyCol(3, 65 " Center")
        lv.ModifyCol(4, 250)
        lv.ModifyCol(5, 200)
        lv.ModifyCol(1, "AutoHdr")
        lv.Opt("+Redraw")
    }

    static GetActiveLV() {
        if !PluginGui.tab
            return ""
        return PluginGui.tab.Value = 1 ? PluginGui.lv1 : PluginGui.lv2
    }

    static ShowContextMenu() {
        cm := Menu()
        cm.Add("启动`tF1", (*) => PluginGui.DoAction("启动"))
        try cm.SetIcon("启动`tF1", A_AhkPath, 2)
        cm.Add("编辑`tF2", (*) => PluginGui.DoAction("编辑"))
        try cm.SetIcon("编辑`tF2", "shell32.dll", 134)
        cm.Add("自启`tF3", (*) => PluginGui.DoAction("自启"))
        try cm.SetIcon("自启`tF3", "shell32.dll", 166)
        cm.Add("关闭`tF4", (*) => PluginGui.DoAction("关闭"))
        try cm.SetIcon("关闭`tF4", "shell32.dll", 28)
        cm.Add("挂起`tF5", (*) => PluginGui.DoAction("挂起"))
        try cm.SetIcon("挂起`tF5", A_AhkPath, 3)
        cm.Add("暂停`tF6", (*) => PluginGui.DoAction("暂停"))
        try cm.SetIcon("暂停`tF6", A_AhkPath, 4)
        cm.Add("移除`tF7", (*) => PluginGui.DoAction("移除"))
        try cm.SetIcon("移除`tF7", "shell32.dll", 132)
        cm.Add()
        cm.Add("下载插件`tF8", (*) => PluginGui.ShowDownloadGui())
        try cm.SetIcon("下载插件`tF8", "shell32.dll", 123)
        cm.Add("插件说明`tF9", (*) => PluginGui.DoAction("帮助"))
        try cm.SetIcon("插件说明`tF9", "shell32.dll", 92)
        cm.Add("插件库`tF10", (*) => PluginGui.ShowLibGui())
        try cm.SetIcon("插件库`tF10", "shell32.dll", 42)
        cm.Add("新建插件`tF11", (*) => PluginGui.CreateNewPlugin())
        try cm.SetIcon("新建插件`tF11", "shell32.dll", 1)
        cm.Add()
        cm.Add("上下交换", (*) => PluginGui.SwapLists())
        cm.Show()
    }

    static SwapLists() {
        if !PluginGui.tab
            return
        PluginGui.tab.Value := PluginGui.tab.Value = 1 ? 2 : 1
    }

    static DoAction(action) {
        lv := PluginGui.GetActiveLV()
        if !lv
            return
        row := lv.GetNext(0, "F")
        if !row && action != "帮助"
            return

        if action = "移除" {
            result := MsgBox("确定移除选中的插件配置？(不会删除文件)", "确认移除？(Esc取消)", 0x23)
            if result != "Yes"
                return
            delRows := []
            r := 0
            Loop {
                r := lv.GetNext(r)
                if !r
                    break
                delRows.Push(r)
            }
            for i in delRows {
                fn := lv.GetText(i, 1)
                PluginManager.RemovePlugin(fn)
                lv.Delete(i)
            }
            return
        }

        row := 0
        Loop {
            row := lv.GetNext(row)
            if !row
                break
            fileName := lv.GetText(row, 1)
            curStatus := lv.GetText(row, 2)
            curAuto := lv.GetText(row, 3)

            switch action {
                case "启动":
                    PluginManager.LaunchPlugin(fileName)
                    lv.Modify(row, "", , "启动")
                case "编辑":
                    PluginManager.EditPlugin(fileName)
                case "自启":
                    if curAuto != "未找到" && curAuto != "自启" {
                        PluginManager.ToggleAutoStart(fileName)
                        lv.Modify(row, "", , , "自启")
                        lv.Modify(row, "Check")
                    } else if curAuto = "自启" {
                        PluginManager.ToggleAutoStart(fileName)
                        lv.Modify(row, "", , , "禁用")
                        lv.Modify(row, "-Check")
                    }
                case "关闭":
                    PluginManager.StopPlugin(fileName)
                    lv.Modify(row, "", , "")
                case "挂起":
                    PluginManager.SuspendPlugin(fileName)
                    PluginGui.UpdateStatusCol(lv, row, curStatus, "挂起", fileName)
                case "暂停":
                    PluginManager.PausePlugin(fileName)
                    PluginGui.UpdateStatusCol(lv, row, curStatus, "暂停", fileName)
                case "帮助":
                    if PluginManager.helpList.Has(fileName) && PluginManager.helpList[fileName] != "" {
                        try Run(PluginManager.helpList[fileName])
                    } else {
                        PluginManager.EditPlugin(fileName)
                    }
            }
        }
    }

    static UpdateStatusCol(lv, row, curStatus, action, fileName) {
        if curStatus = "挂起" && action = "暂停" {
            lv.Modify(row, "", , "挂起暂停")
            return
        }
        if curStatus = "暂停" && action = "挂起" {
            lv.Modify(row, "", , "暂停挂起")
            return
        }
        if curStatus != "启动" && curStatus != "" {
            newStatus := StrReplace(curStatus, action)
            if newStatus = ""
                newStatus := "启动"
            lv.Modify(row, "", , newStatus)
            return
        }
        lv.Modify(row, "", , action)
    }

    static _IsPluginWin(*) {
        return WinActive(APP_NAME " 插件管理")
    }

    static RegisterHK() {
        HotIf(PluginGui._IsPluginWin)
        Hotkey("F1", (*) => PluginGui.DoAction("启动"), "On")
        Hotkey("F2", (*) => PluginGui.DoAction("编辑"), "On")
        Hotkey("F3", (*) => PluginGui.DoAction("自启"), "On")
        Hotkey("F4", (*) => PluginGui.DoAction("关闭"), "On")
        Hotkey("F5", (*) => PluginGui.DoAction("挂起"), "On")
        Hotkey("F6", (*) => PluginGui.DoAction("暂停"), "On")
        Hotkey("F7", (*) => PluginGui.DoAction("移除"), "On")
        Hotkey("F8", (*) => PluginGui.ShowDownloadGui(), "On")
        Hotkey("F9", (*) => PluginGui.DoAction("帮助"), "On")
        Hotkey("F10", (*) => PluginGui.ShowLibGui(), "On")
        Hotkey("F11", (*) => PluginGui.CreateNewPlugin(), "On")
        HotIf
    }

    static ShowLibGui() {
        libGui := Gui(, APP_NAME " - 插件脚本库")
        libGui.SetFont(, "Microsoft YaHei")
        libGui.MarginX := 20
        libGui.MarginY := 20
        libGui.Owner := PluginGui.guiObj

        libGui.AddGroupBox("xm y+10 w460 h220")
        libGui.AddText("xm+5 y35 w80", A_Space "默认插件库：")
        libGui.AddText("x+5 yp", A_ScriptDir "\" PluginManager.PLUGINS_DIR)

        libGui.AddButton("xm+10 y+15 w80", "其他插件库：`n支持多行`n支持变量").OnEvent("Click", (*) => PluginGui.BrowsePluginDir(libEdtDir))
        libEdtDir := libGui.AddEdit("x+5 yp w350 r5", StrReplace(ConfigReader.ReadSetting("PluginsDirPath", ""), "|", "`n"))

        libGui.AddButton("xm+10 y+10 w80", "插件编辑器：`n支持无路径" A_Tab).OnEvent("Click", (*) => PluginGui.BrowsePluginEditor(libEdtEditor))
        libEdtEditor := libGui.AddEdit("x+5 yp w350 r2", ConfigReader.ReadSetting("PluginsEditor", ""))

        libGui.AddButton("Default xm+130 y+35 w75", "保存(&S)").OnEvent("Click", (*) => PluginGui.SaveLibSettings(libGui, libEdtDir, libEdtEditor))
        libGui.AddButton("x+20 w75", "取消(&C)").OnEvent("Click", (*) => libGui.Destroy())
        libGui.OnEvent("Escape", (*) => libGui.Destroy())
        libGui.Show("w480")
    }

    static BrowsePluginDir(edt) {
        folder := DirSelect()
        if folder != "" {
            current := edt.Value
            edt.Value := current = "" ? folder : current "`n" folder
        }
    }

    static BrowsePluginEditor(edt) {
        file := FileSelect(1, , "插件编辑器路径")
        if file != ""
            edt.Value := file
    }

    static SaveLibSettings(libGui, edtDir, edtEditor) {
        dirVal := RegExReplace(edtDir.Value, "S)[\n]+", "|")
        try IniWrite(dirVal, CONFIG_PATH, "Config", "PluginsDirPath")
        try IniWrite(edtEditor.Value, CONFIG_PATH, "Config", "PluginsEditor")
        libGui.Destroy()
        try PluginGui.guiObj.Destroy()
        PluginGui.guiObj := ""
        PluginGui.Show()
    }

    static CreateNewPlugin() {
        count := 1
        Loop Files A_ScriptDir "\RunPlugins\RunAny_NewObjReg_*.ahk"
            count++
        defaultName := "RunAny_NewObjReg_" count ".ahk"

        ib := InputBox("新插件脚本名称`n`n  名称建议为: 作者名_功能.ahk", "ObjReg新建插件脚本",, defaultName)
        if ib.Result = "Cancel"
            return
        newName := ib.Value
        if newName = ""
            return
        fullPath := A_ScriptDir "\RunPlugins\" newName
        if FileExist(fullPath) {
            MsgBox("已有同名的脚本存在: " newName, "文件重名", 48)
            return
        }

        noExt := RegExReplace(newName, "i)\.ahk$")
        lines := []
        lines.Push("#Requires AutoHotkey v2.0")
        lines.Push(";************************")
        lines.Push(";* 【ObjReg插件脚本 " count "】")
        lines.Push(";************************")
        lines.Push('global RunAny_Plugins_Name := "ObjReg插件脚本' count '"')
        lines.Push('global RunAny_Plugins_Version := "1.0.0"')
        lines.Push("#NoTrayIcon")
        lines.Push("Persistent")
        lines.Push("#SingleInstance Force")
        lines.Push("")
        lines.Push(";********************************************************************************")
        lines.Push("")
        lines.Push("#Include RunAny_ObjReg.ahk")
        lines.Push("")
        lines.Push("class RunAnyObj {")
        indent := "    "
        lines.Push(indent ";[新建：你自己的函数]")
        lines.Push(indent ";保存到RunAny.ini为：菜单项名|" noExt "[你的函数名](参数1,参数2)")
        lines.Push(indent ";你的函数名(参数1, 参数2) {")
        lines.Push("        " ";函数内容写在这里")
        lines.Push(indent ";}")
        lines.Push("")
        lines.Push(";══════════════════════════大括号以上是RunAny菜单调用的函数══════════════════════════")
        lines.Push("")
        lines.Push("}")
        lines.Push("")
        lines.Push(";═══════════════════════════以下是脚本自己调用依赖的函数═══════════════════════════")
        lines.Push("")
        lines.Push(";独立使用方式")
        lines.Push(";F1:: {")
        lines.Push(indent ";RunAnyObj.你的函数名(参数1, 参数2)")
        lines.Push(";}")
        tpl := ""
        for l in lines
            tpl .= l "`n"

        try {
            FileAppend(tpl, fullPath, "UTF-8")
            try IniWrite(1, CONFIG_PATH, "Plugins", newName)
            try PluginGui.guiObj.Destroy()
            PluginGui.guiObj := ""
            PluginGui.Show()
            Run("notepad.exe " fullPath)
        } catch as e {
            MsgBox("创建插件失败: " e.Message, APP_NAME, 48)
        }
    }

    static ShowDownloadGui() {
        PluginManager.ScanPlugins()
        dlGui := Gui("+Resize", APP_NAME " 插件下载")
        dlGui.SetFont("s10", "Microsoft YaHei")

        lvDl := dlGui.AddListView("xm w620 r17 grid AltSubmit Checked BackgroundF6F6E8", ["插件文件", "状态", "版本号", "最新版本", "插件描述"])
        lvDl.Opt("-Redraw")

        for fileName, path in PluginManager.pathList {
            noExt := RegExReplace(fileName, "i)\.ahk$")
            status := path && FileExist(path) ? "已下载" : "未下载"
            lvDl.Add("", fileName, status, PluginManager.versionList[fileName], "", PluginManager.nameList[fileName])
        }
        lvDl.ModifyCol(2, 65 " Center")
        lvDl.ModifyCol(3, 65 " Center")
        lvDl.ModifyCol(4, 65 " Center")
        lvDl.Opt("+Redraw")

        dlGui.OnEvent("Close", (*) => dlGui.Destroy())
        dlGui.OnEvent("Escape", (*) => dlGui.Destroy())
        dlGui.Show("w640")
    }

    static OnSize(guiObj, minMax, width, height) {
        if minMax = -1
            return
        try {
            PluginGui.tab.Move(, , width - 10, height - 30)
            PluginGui.lv1.Move(, , width - 30, height - 70)
            PluginGui.lv2.Move(, , width - 30, height - 70)
        }
    }
}
