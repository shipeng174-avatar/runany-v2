#Requires AutoHotkey v2.0
#SingleInstance Off
if !IsSet(APP_NAME)
    global APP_NAME := "RunAny_v2"
class SettingsGui {
    static guiObj := ""
    static controls := Map()

    static Show() {
        if SettingsGui.guiObj && WinExist("ahk_id " SettingsGui.guiObj.Hwnd) {
            SettingsGui.guiObj.Show()
            return
        }

        g := Gui(, "设置 - " APP_NAME)
        g.SetFont(, "Microsoft YaHei")
        g.MarginX := 30
        g.MarginY := 10
        SettingsGui.guiObj := g

        tabNames := ["RunAny设置", "热键配置", "菜单变量", "无路径缓存", "搜索Everything", "一键直达", "内部关联", "热字符串", "图标设置", "高级配置"]
        tab := g.AddTab3("x10 y10 w680", tabNames)
        SettingsGui.controls["tab"] := tab

        tab.UseTab(1)
        SettingsGui.BuildTab1(g)
        tab.UseTab(2)
        SettingsGui.BuildTab2(g)
        tab.UseTab(3)
        SettingsGui.BuildTab3(g)
        tab.UseTab(4)
        SettingsGui.BuildTab4(g)
        tab.UseTab(5)
        SettingsGui.BuildTab5(g)
        tab.UseTab(6)
        SettingsGui.BuildTab6(g)
        tab.UseTab(7)
        SettingsGui.BuildTab7(g)
        tab.UseTab(8)
        SettingsGui.BuildTab8(g)
        tab.UseTab(9)
        SettingsGui.BuildTab9(g)
        tab.UseTab(10)
        SettingsGui.BuildTab10(g)
        tab.UseTab(0)

        ; 四个按钮居中
        btnW := 75, btnGap := 20, cfgW := 100
        totalW := btnW * 3 + cfgW + btnGap * 3
        centerX := 30 + (640 - totalW) // 2
        g.AddButton("Default w" btnW " x" centerX, "确定").OnEvent("Click", (*) => SettingsGui.OnOK())
        g.AddButton("x+" btnGap " w" btnW, "取消").OnEvent("Click", (*) => g.Hide())
        g.AddButton("x+" btnGap " w" btnW, "重置").OnEvent("Click", (*) => SettingsGui.OnReset())
        g.AddButton("x+" btnGap " w" cfgW, "配置文件").OnEvent("Click", (*) => Run("notepad.exe " CONFIG_PATH))

        g.OnEvent("Close", (*) => g.Hide())
        g.OnEvent("Escape", (*) => g.Hide())
            g.Show("w700")
    }

    static CB(g, key, text, opts := "") {
        c := g.AddCheckBox(opts " Checked" (ConfigReader.ReadSetting(key, "0") = "1" ? 1 : 0) " vv" key, text)
        SettingsGui.controls[key] := c
        return c
    }

    static ED(g, key, text, opts := "") {
        c := g.AddEdit(opts " vv" key, ConfigReader.ReadSetting(key, text))
        SettingsGui.controls[key] := c
        return c
    }

    static HK(g, key, opts := "") {
        c := g.AddHotkey(opts " vv" key, ConfigReader.ReadSetting(key, ""))
        SettingsGui.controls[key] := c
        return c
    }

    static CW(g, key, opts := "") {
        c := g.AddCheckBox(opts " Checked" (ConfigReader.ReadSetting(key, "0") = "1" ? 1 : 0) " vv" key, "Win")
        SettingsGui.controls[key] := c
        return c
    }

    ; ═══════ Tab1: RunAny设置 ═══════
    static BuildTab1(g) {
        ; AutoRun_Reg: 从注册表读取实际状态，而非INI
        autoRunChecked := 0
        try autoRunChecked := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "RunAny") != "" ? 1 : 0
        c := g.AddCheckBox("xm-10 y+12 Checked" autoRunChecked " vAutoRun_Reg", "开机自动启动")
        SettingsGui.controls["AutoRun_Reg"] := c
        SettingsGui.CB(g, "AdminRun", "管理员权限运行所有软件和插件", "x+25 yp")
        g.AddButton("x+20 w280 yp-3", "系统任务计划方式：开机管理员启动" APP_NAME).OnEvent("Click", (*) => SettingsGui.SetScheduledTasks())

        g.AddGroupBox("xm-10 y+2 w660 h110", "RunAny应用菜单")
        SettingsGui.CB(g, "HideFail", "隐藏失效项", "xm yp+20")
        SettingsGui.CB(g, "HideSend", "隐藏短语", "x+180")
        SettingsGui.CB(g, "HideWeb", "隐藏带%s网址", "xm yp+20")
        SettingsGui.CB(g, "HideGetZz", "隐藏带%getZz%插件脚本", "x+163")
        SettingsGui.CB(g, "HideSelectZz", "隐藏选中目标提示", "xm yp+20")
        SettingsGui.CB(g, "HideAddItem", "隐藏【添加到此菜单】", "x+144")
        SettingsGui.CB(g, "HideMenuTray", "隐藏底部" APP_NAME "设置", "xm yp+20")
        SettingsGui.ED(g, "RecentMax", "", "x+101 w30 h20")
        g.AddText("x+5 yp+2", "最近运行项数量 (0为隐藏)")
        g.AddButton("x+5 yp-2 w50 h20", "清理").OnEvent("Click", (*) => SettingsGui.ClearRecentMax())

        g.AddGroupBox("xm-10 y+20 w225 h55", "RunAny菜单热键 " ConfigReader.ReadSetting("MenuKey", ""))
        SettingsGui.HK(g, "MenuKey", "xm yp+20 w150")
        SettingsGui.CW(g, "MenuWinKey", "xm+155 yp+3")

        ; Menu2: 存在RunAny2.ini时显示热键，否则显示开启按钮
        iniPath2 := A_ScriptDir "\RunAny2.ini"
        if FileExist(iniPath2) {
            g.AddGroupBox("x+60 yp-23 w225 h55", "菜单2热键 " ConfigReader.ReadSetting("MenuKey2", ""))
            SettingsGui.HK(g, "MenuKey2", "xp+10 yp+20 w150")
            SettingsGui.CW(g, "MenuWinKey2", "xp+155 yp+3")
        } else {
            g.AddButton("x+60 yp-5 w150", "开启第2个菜单").OnEvent("Click", (*) => SettingsGui.EnableMenu2())
        }

        g.AddGroupBox("xm-10 y+25 w660 h110", "RunAny.ini文件设置")
        SettingsGui.ED(g, "AutoReloadMTime", "3000", "xm yp+20 w50 h20")
        g.AddText("x+5 yp+2", "(毫秒) INI修改后自动重启，0为不自动重启")
        SettingsGui.CB(g, "RunABackupRule", "自动备份", "xm yp+25")
        g.AddText("x+5 yp", "最多备份数量")
        SettingsGui.ED(g, "RunABackupMax", "15", "x+5 yp-2 w70 h20")
        g.AddText("x+5 yp+2", "备份文件名格式")
        SettingsGui.ED(g, "RunABackupFormat", ".%A_Now%.bak", "x+5 yp-2 w236 h20")
        g.AddButton("xm yp+25", "RunAny.ini自动备份目录").OnEvent("Click", (*) => SettingsGui.BrowseFolder("RunABackupDir"))
        SettingsGui.ED(g, "RunABackupDir", "%A_ScriptDir%\RunBackup", "x+11 yp+2 w400 r1")

        g.AddGroupBox("xm-10 y+25 w660 r10 ", "屏蔽RunAny程序列表（英文逗号分隔）")
        g.AddButton("xm yp+25 w140", "从运行中进程选择").OnEvent("Click", (*) => SettingsGui.PickRunningProcess())
        g.SetFont(, "Consolas")
        SettingsGui.ED(g, "DisableApp", "vmware-vmx.exe,TeamViewer.exe", "xm yp+35 w640 r14")
        g.SetFont(, "Microsoft YaHei")
    }

    ; ═══════ Tab2: 热键配置 ═══════
    static BuildTab2(g) {
        g.AddGroupBox("xm-10 y+10 w660 h125", "多种方式启动菜单")
        SettingsGui.CB(g, "MenuDoubleCtrlKey", "双击Ctrl键", "xm yp+20")
        SettingsGui.CB(g, "MenuDoubleAltKey", "双击Alt键", "x+166")
        SettingsGui.CB(g, "MenuDoubleLWinKey", "双击左Win键", "xm y+5")
        SettingsGui.CB(g, "MenuDoubleRWinKey", "双击右Win键", "x+152")
        SettingsGui.CB(g, "MenuCtrlRightKey", "Ctrl+鼠标右键", "xm y+5")
        SettingsGui.CB(g, "MenuShiftRightKey", "Shift+鼠标右键", "x+145")
        SettingsGui.CB(g, "MenuXButton1Key", "鼠标X1键", "xm y+5")
        SettingsGui.CB(g, "MenuXButton2Key", "鼠标X2键", "x+171")
        SettingsGui.CB(g, "MenuMButtonKey", "鼠标中键(需关闭huiZz_MButton)", "xm y+5")

        g.AddLink("xm-10 y+15 w660", APP_NAME '热键配置列表（双击修改，按F2可手写AHK使用特殊热键，<a href="https://wyagd001.github.io/zh-cn/docs/KeyList.htm">如Space、CapsLock、Tab等</a>）')

        hotkeys := [
            ["显示菜单", "MenuKey", "MenuWinKey"],
            ["显示菜单2", "MenuKey2", "MenuWinKey2"],
            ["显示菜单(不获取选中内容)", "MenuNoGetKey", "MenuNoGetWinKey"],
            ["Everything搜索", "EvKey", "EvWinKey"],
            ["一键搜索", "OneKey", "OneWinKey"],
            ["修改菜单(1)", "TreeHotKey1", "TreeWinKey1"],
            ["修改菜单(2)", "TreeHotKey2", "TreeWinKey2"],
            ["修改菜单文件(1)", "TreeIniHotKey1", "TreeIniWinKey1"],
            ["修改菜单文件(2)", "TreeIniHotKey2", "TreeIniWinKey2"],
            ["RunAny托盘菜单", "RunATrayHotKey", "RunATrayWinKey"],
            ["设置", "RunASetHotKey", "RunASetWinKey"],
            ["重载", "RunAReloadHotKey", "RunAReloadWinKey"],
            ["停用", "RunASuspendHotKey", "RunASuspendWinKey"],
            ["退出", "RunAExitHotKey", "RunAExitWinKey"],
            ["插件管理", "PluginsManageHotKey", "PluginsManageWinKey"],
            ["启动管理", "RunCtrlManageHotKey", "RunCtrlManageWinKey"],
            ["独立插件一键暂停", "PluginsAlonePauseHotKey", "PluginsAlonePauseWinKey"],
            ["独立插件挂起", "PluginsAloneSuspendHotKey", "PluginsAloneSuspendWinKey"],
            ["独立插件一键关闭", "PluginsAloneCloseHotKey", "PluginsAloneCloseWinKey"],
        ]
        lv := g.AddListView("xm-10 y+10 w660 r24 grid -Multi", ["热键", "热键说明", "变量名"])
        lv.ModifyCol(1, 120)
        lv.ModifyCol(2, 250)
        lv.ModifyCol(3, 200)
        SettingsGui.controls["HotkeyLV"] := lv
        for hk in hotkeys {
            keyVal := ConfigReader.ReadSetting(hk[2], "")
            winVal := ConfigReader.ReadSetting(hk[3], "0") = "1"
            display := winVal && keyVal ? "#" keyVal : keyVal
            lv.Add("", display, hk[1], hk[2])
        }
        lv.OnEvent("DoubleClick", (lv, item) => SettingsGui.EditHotkeyItem(lv, item))
    }

    static EditHotkeyItem(lv, item) {
        hkDisplay := lv.GetText(item, 1)
        hkName := lv.GetText(item, 3)
        hkKey := ConfigReader.ReadSetting(hkName, "")
        ; Tab2 hotkey list defines [label, keyName, winKeyName]
        ; Win key var is the 3rd column of the hotkeys array, derived from the keyName
        winKeyName := SettingsGui.GetWinKeyName(hkName)
        hkWin := ConfigReader.ReadSetting(winKeyName, "0") = "1"

        eg := Gui(, "配置热键")
        eg.SetFont(, "Microsoft YaHei")
        eg.AddGroupBox("x10 y10 w300 h55", lv.GetText(item, 2) "：" hkDisplay)
        keyCtrl := eg.AddHotkey("x20 yp+20 w180", hkKey)
        winCtrl := eg.AddCheckBox("x+10 yp+3 Checked" (hkWin ? 1 : 0), "Win")
        eg.AddButton("Default x60 y+20 w75", "保存").OnEvent("Click", (*) => (
            SettingsGui.SaveHotkeyItem(hkName, keyCtrl.Value = "vkE5" ? "" : keyCtrl.Value, winCtrl.Value),
            lv.Modify(item, "", (winCtrl.Value && keyCtrl.Value && keyCtrl.Value != "vkE5" ? "#" : "") (keyCtrl.Value = "vkE5" ? "" : keyCtrl.Value), lv.GetText(item, 2), hkName),
            eg.Hide()
        ))
        eg.AddButton("x+20 w75", "取消").OnEvent("Click", (*) => eg.Hide())
        eg.Show("w330")
    }

    static GetWinKeyName(hkName) {
        ; Map each hotkey variable to its corresponding Win key variable
        winKeyMap := Map(
            "MenuKey", "MenuWinKey",
            "MenuKey2", "MenuWinKey2",
            "MenuNoGetKey", "MenuNoGetWinKey",
            "EvKey", "EvWinKey",
            "OneKey", "OneWinKey",
            "TreeHotKey1", "TreeWinKey1",
            "TreeHotKey2", "TreeWinKey2",
            "TreeIniHotKey1", "TreeIniWinKey1",
            "TreeIniHotKey2", "TreeIniWinKey2",
            "RunATrayHotKey", "RunATrayWinKey",
            "PluginsManageHotKey", "PluginsManageWinKey",
            "RunCtrlManageHotKey", "RunCtrlManageWinKey",
            "RunASetHotKey", "RunASetWinKey",
            "RunAReloadHotKey", "RunAReloadWinKey",
            "RunASuspendHotKey", "RunASuspendWinKey",
            "RunAExitHotKey", "RunAExitWinKey",
            "PluginsAlonePauseHotKey", "PluginsAlonePauseWinKey",
            "PluginsAloneSuspendHotKey", "PluginsAloneSuspendWinKey",
            "PluginsAloneCloseHotKey", "PluginsAloneCloseWinKey",
        )
        if winKeyMap.Has(hkName)
            return winKeyMap[hkName]
        return StrReplace(hkName, "Hot", "Win")
    }

    static SaveHotkeyItem(varName, keyVal, winVal) {
        ; Write to INI
        try IniWrite(keyVal, CONFIG_PATH, "Config", varName)
        winName := SettingsGui.GetWinKeyName(varName)
        try IniWrite(winVal ? "1" : "0", CONFIG_PATH, "Config", winName)

        ; Sync to Tab1/Tab5 hotkey controls so OnOK() picks up the change
        c := SettingsGui.controls
        if c.Has(varName)
            c[varName].Value := keyVal
        if c.Has(winName)
            c[winName].Value := winVal
    }

    ; ═══════ Tab3: 菜单变量 ═══════
    static BuildTab3(g) {
        g.AddText("xm-10 y+10 w660", "自定义配置RunAny菜单中可以使用的变量 (%变量名%)")
        g.AddButton("xm-10 y+10 w50", "+ 增加").OnEvent("Click", (*) => SettingsGui.MenuVarEdit("新建"))
        g.AddButton("x+10 w50", "· 修改").OnEvent("Click", (*) => SettingsGui.MenuVarEdit("编辑"))
        g.AddButton("x+10 w50", "- 减少").OnEvent("Click", (*) => SettingsGui.MenuVarRemove())
        g.AddLink("x+15 yp-3 w350", '使用方法：变量两边加百分号如：<a href="https://hui-zz.gitee.io/runany/#/article/built-in-variables">`%变量名`%</a>`n编辑菜单项的启动路径中 或 RunAny.ini文件中使用')

        lv := g.AddListView("xm-10 y+10 w660 r30 grid", ["菜单变量名", "类型", "菜单变量值"])
        lv.ModifyCol(1, 150)
        lv.ModifyCol(2, 180)
        lv.ModifyCol(3, 300)
        SettingsGui.controls["MenuVarLV"] := lv

        ; 默认变量列表（名称 => 类型标记，1=RunAny变量 2=系统环境变量 3=用户变量）
        defaultVars := Map(
            "A_Desktop", 1,
            "A_MyDocuments", 1,
            "A_ScriptDir", 1,
            "A_ScriptDrive", 1,
            "AppData", 2,
            "ComputerName", 2,
            "ComSpec", 2,
            "LocalAppData", 2,
            "OneDrive", 2,
            "ProgramFiles", 2,
            "UserName", 2,
            "UserProfile", 2,
            "WinDir", 2,
        )
        if A_Is64bitOS
            defaultVars["ProgramW6432"] := 2

        ; 合并INI中用户自定义的变量
        try {
            iniVars := IniRead(CONFIG_PATH, "MenuVar")
            Loop Parse iniVars, "`n", "`r" {
                eq := InStr(A_LoopField, "=")
                if eq = 0
                    continue
                k := Trim(SubStr(A_LoopField, 1, eq - 1))
                v := SubStr(A_LoopField, eq + 1)
                defaultVars[k] := 3
            }
        }

        for k, mtypeFlag in defaultVars {
            val := ""
            mtype := "用户变量(固定值)"

            ; 获取变量值
            if mtypeFlag = 1 {
                ; RunAny内置变量
                try val := %k%
                mtype := "RunAny变量(动态)"
            } else if mtypeFlag = 2 {
                ; 系统环境变量
                try val := EnvGet(k)
                mtype := "系统环境变量(动态)"
            } else {
                ; 用户变量，从INI读取值
                try val := IniRead(CONFIG_PATH, "MenuVar", k, "")
                if val = ""
                    try val := EnvGet(k)
            }
            lv.Add("", k, mtype, val)
        }
        lv.OnEvent("DoubleClick", (lv, item) => SettingsGui.MenuVarEdit("编辑"))
    }

    static MenuVarEdit(action) {
        lv := SettingsGui.controls["MenuVarLV"]
        varName := "", varVal := "", varType := "用户变量(固定值)"
        if action = "编辑" {
            row := lv.GetNext(0)
            if !row
                return
            varName := lv.GetText(row, 1)
            varType := lv.GetText(row, 2)
            varVal := lv.GetText(row, 3)
        }
        eg := Gui(, APP_NAME " - " action "菜单变量")
        eg.SetFont(, "Microsoft YaHei")
        eg.AddGroupBox("x10 y10 w450 h130 vvVarType", varType)
        eg.AddText("x20 y40 w60", "变量名")
        nameEdt := eg.AddEdit("x+5 yp w350", varName)
        eg.AddText("x20 y+15 w60", "变量值")
        valEdt := eg.AddEdit("x+5 yp w350 r3", varVal)
        nameEdt.OnEvent("Change", (*) => SettingsGui.CheckVarType(nameEdt.Value, valEdt))
        eg.AddButton("Default x150 y+20 w75", "保存").OnEvent("Click", (*) => SettingsGui.SaveMenuVar(lv, action, nameEdt.Value, valEdt.Value, eg))
        eg.AddButton("x+20 w75", "取消").OnEvent("Click", (*) => eg.Hide())
        eg.Show("w480")
    }

    static CheckVarType(name, valEdt) {
        if name = ""
            return
        try {
            envVal := EnvGet(name)
            if envVal != "" {
                valEdt.Value := envVal
                valEdt.Opt("+ReadOnly")
                return
            }
        }
        try {
            dynVal := %name%
            if dynVal != "" {
                valEdt.Value := dynVal
                valEdt.Opt("+ReadOnly")
                return
            }
        }
        valEdt.Opt("-ReadOnly")
    }

    static SaveMenuVar(lv, action, name, val, eg) {
        if name = "" {
            ToolTip("请填入变量名")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        if !RegExMatch(name, "^[\p{Han}A-Za-z0-9_]+$") {
            ToolTip("变量名只能为中文、数字、字母、下划线")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        if action = "新建" {
            Loop lv.GetCount() {
                if lv.GetText(A_Index, 1) = name {
                    ToolTip("已有相同变量名")
                    SetTimer(() => ToolTip(), -3000)
                    return
                }
            }
            lv.Add("", name, "用户变量(固定值)", val)
        } else {
            row := lv.GetNext(0)
            lv.Modify(row, "", name, lv.GetText(row, 2), val)
        }
        lv.ModifyCol()
        eg.Hide()
    }

    static MenuVarRemove() {
        lv := SettingsGui.controls["MenuVarLV"]
        row := lv.GetNext(0)
        if row
            lv.Delete(row)
    }

    ; ═══════ Tab4: 无路径缓存 ═══════
    static BuildTab4(g) {
        ; Detect Everything status (直接检测进程，不依赖配置路径)
        evRunning := ProcessExist("Everything64.exe") || ProcessExist("Everything.exe")
        emptyReason := evRunning ? "无路径说明" : "Everything未启动"
        if evRunning && !FileExist(PathCache.CACHE_FILE) {
            emptyReason := "自动更新中...可以重新打开设置查看或点击EV更新同步"
        }

        g.AddText("xm-10 y+10", "RunAny菜单中无路径的缓存全路径")
        g.AddButton("x+10 yp-5", "缓存目录").OnEvent("Click", (*) => SettingsGui.BrowseFolder("RunAEvFullPathIniDir"))
        SettingsGui.ED(g, "RunAEvFullPathIniDir", "%AppData%\\RunAny", "x+11 yp+2 w300 r1")
        g.AddButton("xm-10 yp+32 w50", "+ 增加").OnEvent("Click", (*) => SettingsGui.PathCacheEdit("新建"))
        g.AddButton("x+10 yp w50", "· 修改").OnEvent("Click", (*) => SettingsGui.PathCacheEdit("编辑"))
        g.AddButton("x+10 yp w50", "- 减少").OnEvent("Click", (*) => SettingsGui.PathCacheRemove())
        g.AddButton("x+10 yp w50", "A 全选").OnEvent("Click", (*) => SettingsGui.controls["PathCacheLV"].Modify(0, "Select"))
        g.AddButton("x+10 yp w75", "EV更新同步").OnEvent("Click", (*) => SettingsGui.EvSyncPaths())
        g.AddText("x+15 yp-3", "无路径说明：每次新增或移动无路径应用文件后`n会使用Everything获得它最新的运行全路径")

        lv := g.AddListView("xm-10 yp+40 w660 r30 grid", ["无路径应用名(不能有等号=)", "当前电脑运行全路径（来自Everything）", emptyReason])
        SettingsGui.controls["PathCacheLV"] := lv

        ; Create ImageList with DPI-aware icon size (system small icon metric)
        iconCx := DllCall("User32\GetSystemMetrics", "Int", 49, "Int")  ; SM_CXSMICON
        iconCy := DllCall("User32\GetSystemMetrics", "Int", 50, "Int")  ; SM_CYSMICON
        hIL := DllCall("comctl32.dll\ImageList_Create", "Int", iconCx, "Int", iconCy, "UInt", 0x21, "Int", 100, "Int", 10, "Ptr")
        stdExe   := IL_Add(hIL, "shell32.dll", 3)    ; generic exe
        stdFail  := IL_Add(hIL, "shell32.dll", 124)   ; fail/missing
        IL_Add(hIL, "shell32.dll", 2)                  ; idx 3 - typing
        IL_Add(hIL, "shell32.dll", 14)                 ; idx 4 - url
        IL_Add(hIL, "shell32.dll", 5)                  ; idx 5 - folder
        exeIconCache := Map()

        ; Retain ImageList handle (prevent GC) and set on ListView
        SettingsGui.controls["PathCacheIL"] := hIL
        DllCall("User32\SendMessageW", "Ptr", lv.Hwnd, "UInt", 0x1003, "Ptr", 1, "Ptr", hIL)  ; LVSIL_SMALL=1 for report mode

        ; Build merged map: cache file entries + no-path exe items from menu INI
        mergedMap := Map()

        ; 1) Read existing cache file
        try {
            cacheFile := SettingsGui.GetEvFullPathIni()
            if FileExist(cacheFile) {
                sections := IniRead(cacheFile, "FullPath")
                Loop Parse sections, "`n", "`r" {
                    eq := InStr(A_LoopField, "=")
                    if eq = 0
                        continue
                    k := SubStr(A_LoopField, 1, eq - 1)
                    v := SubStr(A_LoopField, eq + 1)
                    mergedMap[k] := v
                }
            }
        }

        ; 2) Scan menu INI for no-path exe items not yet in cache
        try {
            iniFiles := [INI_PATH]
            ini2 := ConfigReader.ReadSetting("IniPath2", "")
            if ini2 != ""
                iniFiles.Push(ConfigReader.TransformVar(ini2))
            for iniFile in iniFiles {
                if !FileExist(iniFile)
                    continue
                content := ConfigReader.ReadINI(iniFile)
                if content = ""
                    continue
                lines := StrSplit(content, "`n", "`r")
                for line in lines {
                    trimmed := Trim(line)
                    if trimmed = "" || InStr(trimmed, ";") = 1
                        continue
                    ; Skip category lines (start with -) and separators
                    if InStr(trimmed, "-") = 1 || trimmed = "|" || trimmed = "||"
                        continue
                    ; Extract run path (after | separator)
                    runPath := trimmed
                    if InStr(trimmed, "|") {
                        parts := StrSplit(trimmed, "|",, 2)
                        runPath := parts.Has(2) && parts[2] != "" ? parts[2] : parts[1]
                    }
                    ; Strip hotkey (tab-separated)
                    if InStr(runPath, "`t")
                        runPath := StrSplit(runPath, "`t",, 2)[1]
                    ; Skip non-exe items (URLs, phrases ending with ;, plugin calls, full paths, hotstrings)
                    if RegExMatch(runPath, "i)^([\w-]+://?|www[.]).*")
                        continue
                    if RegExMatch(runPath, "\.\;{1,2}$")
                        continue
                    if RegExMatch(runPath, "\.\:\:?$")
                        continue
                    if RegExMatch(runPath, ".+?\[.+?\]%?\(.*?\)")
                        continue
                    if RegExMatch(runPath, "^:[*?a-zA-Z0-9]+?:")
                        continue
                    if RegExMatch(runPath, "i)^(\\\\|[A-Za-z]:\\).*?\.exe($| .*)") {
                        ; Full path exe — extract exe name and check if it exists
                        exeName := RegExReplace(runPath, "iS)(.*?\.exe)($| .*)", "$1")
                        SplitPath(exeName, &fName)
                        if !mergedMap.Has(fName) && !mergedMap.Has(RegExReplace(fName, "i)\.exe$"))
                            mergedMap[fName] := runPath
                        continue
                    }
                    if RegExMatch(runPath, "i)^(\\\\|[A-Za-z]:\\)")
                        continue
                    ; No-path exe items
                    if RegExMatch(runPath, "iS)\.exe($| .*)") {
                        exeName := RegExReplace(runPath, "iS)(.*?\.exe)($| .*)", "$1")
                        if !mergedMap.Has(exeName) {
                            mergedMap[exeName] := ""
                        }
                    }
                }
            }
        }

        ; 3) Populate ListView from merged map with icons
        hideFail := ConfigReader.ReadSetting("HideFail", "0") = "1"
        lv.Opt("-Redraw")
        for k, v in mergedMap {
            ; Determine if this entry is a failed/invalid item
            isFail := false
            failReason := ""
            if v = "" {
                ; No path at all — check if it can be resolved
                resolved := ""
                if g_PathCache.Has(k)
                    resolved := g_PathCache[k]
                else if g_PathCache.Has(RegExReplace(k, "i)\.exe$"))
                    resolved := g_PathCache[RegExReplace(k, "i)\.exe$")]
                if resolved = "" {
                    isFail := true
                    failReason := "未找到路径"
                }
            } else {
                ; Has a path — check if file actually exists
                checkPath := v
                if RegExMatch(v, "iS)(.*?\.exe)($| .*)", &em)
                    checkPath := em[1]
                if !FileExist(checkPath) {
                    isFail := true
                    failReason := "路径无效"
                }
            }
            if hideFail && isFail
                continue

            iconIdx := stdFail
            if v != "" && !isFail {
                ; Try to load the actual exe icon
                resolvedPath := v
                ; Strip parameters after exe
                if RegExMatch(v, "iS)(.*?\.exe)($| .*)", &em)
                    resolvedPath := em[1]
                if exeIconCache.Has(resolvedPath) {
                    iconIdx := exeIconCache[resolvedPath]
                } else if FileExist(resolvedPath) {
                    try {
                        added := IL_Add(hIL, resolvedPath, 1)
                        if added > 0 {
                            iconIdx := added
                            exeIconCache[resolvedPath] := iconIdx
                        }
                    } catch {
                        iconIdx := stdExe
                    }
                }
            }
            row := lv.Add("Icon" iconIdx, k, v, failReason)
        }
        lv.ModifyCol()
        lv.ModifyCol(1, 155)
        lv.ModifyCol(2, 350)
        lv.ModifyCol(1, "Sort")
        lv.Opt("+Redraw")

        lv.OnEvent("DoubleClick", (lv, item) => SettingsGui.PathCacheEdit("编辑"))
    }

    static GetEvFullPathIni() {
        dir := ConfigReader.TransformVar(ConfigReader.ReadSetting("RunAEvFullPathIniDir", "%AppData%\\RunAny"))
        return dir "\RunAnyEvFullPath.ini"
    }

    static PathCacheEdit(action) {
        lv := SettingsGui.controls["PathCacheLV"]
        pName := "", pVal := ""
        if action = "编辑" {
            row := lv.GetNext(0)
            if !row
                return
            pName := lv.GetText(row, 1)
            pVal := lv.GetText(row, 2)
        }
        eg := Gui(, "无路径应用缓存")
        eg.SetFont(, "Microsoft YaHei")
        eg.AddGroupBox("x10 y10 w450 h120", action "无路径应用缓存")
        eg.AddText("x20 y35 w60", "无路径名")
        nameEdt := eg.AddEdit("x+5 yp w350", pName)
        eg.AddText("x20 y+15 w60", "运行全路径")
        valEdt := eg.AddEdit("x+5 yp w350 r3", pVal)
        eg.AddButton("Default x150 y+20 w75", "保存").OnEvent("Click", (*) => SettingsGui.SavePathCache(lv, action, nameEdt.Value, valEdt.Value, eg))
        eg.AddButton("x+20 w75", "取消").OnEvent("Click", (*) => eg.Hide())
        eg.Show("w480")
    }

    static SavePathCache(lv, action, name, val, eg) {
        if name = ""
            return
        ; Validate path for column 3 status
        reason := ""
        if val != "" {
            checkPath := val
            if RegExMatch(val, "iS)(.*?\.exe)($| .*)", &em)
                checkPath := em[1]
            if !FileExist(checkPath)
                reason := "路径无效"
        } else
            reason := "未找到路径"
        if action = "新建"
            lv.Add("", name, val, reason)
        else {
            row := lv.GetNext(0)
            lv.Modify(row, "", name, val, reason)
        }
        lv.ModifyCol()
        eg.Hide()
    }

    static PathCacheRemove() {
        lv := SettingsGui.controls["PathCacheLV"]
        row := lv.GetNext(0)
        if row
            lv.Delete(row)
    }

    static EvSyncPaths() {
        if ExeResolver.EvExePath = "" {
            MsgBox("未找到Everything", APP_NAME, 48)
            return
        }
        lv := SettingsGui.controls["PathCacheLV"]
        Loop lv.GetCount() {
            name := lv.GetText(A_Index, 1)
            curPath := lv.GetText(A_Index, 2)
            if curPath != "" && FileExist(curPath)
                continue
            resolved := ExeResolver.Find(name)
            if resolved != ""
                lv.Modify(A_Index, "", name, resolved)
        }
        ToolTip("同步完成")
        SetTimer(() => ToolTip(), -3000)
    }

    ; ═══════ Tab5: 搜索Everything ═══════
    static BuildTab5(g) {
        ; Detect Everything status
        evRunning := ProcessExist("Everything64.exe") || ProcessExist("Everything.exe")
        evStatus := evRunning ? "正在运行" : "未运行"
        ; 获取实际运行的Everything路径（通过进程PID获取）
        evRunPath := ""
        evPid := ProcessExist("Everything64.exe")
        if !evPid
            evPid := ProcessExist("Everything.exe")
        if evPid {
            try evRunPath := ProcessGetPath(evPid)
        }
        evIsAdmin := false
        if evRunning {
            try evIsAdmin := ExeResolver.EvIsAdmin
        }
        evAdminStr := evIsAdmin ? "管理员权限" : "非管理员"

        g.AddText("xm-10 y+10", "Everything当前权限：【" evAdminStr "】 " (evRunning ? "✓" evStatus : "✗ " evStatus))
        SettingsGui.CB(g, "EvAutoClose", "Everything自动关闭(不常驻后台)", "x+20 yp")
        g.AddButton("x+10 yp-6 w80", "重建索引").OnEvent("Click", (*) => SettingsGui.EvReindex())

        g.AddText("xm-10 yp+32", "Everything当前运行路径：" (evRunPath != "" ? evRunPath : "未找到"))

        g.AddGroupBox("xm-10 y+10 w660 h55", "一键Everything [搜索选中文字，支持多选文件、再按为隐藏/激活]")
        SettingsGui.HK(g, "EvKey", "xm yp+20 w130")
        SettingsGui.CW(g, "EvWinKey", "xm+150 yp+3")
        SettingsGui.CB(g, "EvShowExt", "搜索带文件后缀", "x+27")
        SettingsGui.CB(g, "EvShowFolder", "搜索选中文件夹内部", "x+5")

        g.AddGroupBox("xm-10 y+25 w660 h60", "Everything安装路径（支持菜单变量和相对路径 \\..\\ 代表上一级目录）")
        g.AddButton("xm yp+20 w50", "选择").OnEvent("Click", (*) => SettingsGui.BrowseFile("EvPath", "Everything.exe"))
        SettingsGui.ED(g, "EvPath", "", "xm+60 yp+2 w580 r1")

        g.AddGroupBox("xm-10 y+25 w660 h450", "RunAny调用Everything搜索参数（搜索结果可在RunAny无路径运行，Everything异常请尝试重建索引）")
        evDemand := ConfigReader.ReadSetting("EvDemandSearch", "1") = "1"
        g.AddRadio("xm yp+25" (evDemand ? " Checked" : ""), "按需搜索模式（推荐，只搜索RunAny菜单的无路径文件进行匹配路径，速度快）")
        g.AddRadio("xm yp+25" (!evDemand ? " Checked" : ""), "全磁盘搜索模式（搜索全磁盘指定后缀的文件，开机首次加载缓慢）")
        SettingsGui.CB(g, "EvExeVerNew", "搜索结果优先最新版本的同名exe", "xm yp+25")
        SettingsGui.CB(g, "EvExeMTimeNew", "优先最新修改时间的同名文件", "x+23")

        g.AddText("xm y+15", "默认排除搜索参数：")
        g.AddButton("x+5 yp-4 w70 h22", "恢复默认").OnEvent("Click", (*) => SettingsGui.RestoreEvCommandDefault())
        g.AddText("xm y+5 cGray", "说明：排除系统目录、回收站、临时目录、软件数据目录等，注意中间空格间隔")

        g.SetFont(, "Consolas")
        SettingsGui.ED(g, "EvCommand", "", "xm y+5 w650 r5")
        g.SetFont(, "Microsoft YaHei")
        }

        static RestoreEvCommandDefault() {
        if SettingsGui.controls.Has("EvCommand") {
            SettingsGui.controls["EvCommand"].Value := ExeResolver.GetEvCommand()
        }
        }

    ; ═══════ Tab6: 一键直达 ═══════
    static BuildTab6(g) {
        g.AddButton("xm-10 y+10 w50", "@ 在线").OnEvent("Click", (*) => SettingsGui.OneKeyOnline())
        g.AddButton("x+5 yp w50", "+ 增加").OnEvent("Click", (*) => SettingsGui.OneKeyEdit("新建"))
        g.AddButton("x+5 yp w50", "· 修改").OnEvent("Click", (*) => SettingsGui.OneKeyEdit("编辑"))
        g.AddButton("x+5 yp w50", "- 减少").OnEvent("Click", (*) => SettingsGui.OneKeyRemove())
        g.AddLink("x+20 yp-2", '【正则一键直达】（仅菜单1热键触发，不想触发的菜单项放入菜单2中）`n<a href="https://wyagd001.github.io/zh-cn/docs/misc/RegEx-QuickRef.htm">AHK正则选项</a>：i)不区分大小写 m)多行匹配 S)研究模式提高性能')

        lv := g.AddListView("xm-10 y+5 w660 r10 grid Checked", ["选中内容匹配正则", "一键直达说明", "状态", "一键直达运行"])
        lv.ModifyCol(1, 240)
        lv.ModifyCol(2, 120)
        lv.ModifyCol(3, 50)
        lv.ModifyCol(4, 200)
        SettingsGui.controls["OneKeyLV"] := lv

        defaults := [
            ["一键公式计算", 'S)^[\(\)\.\s\d]*\d+\s*[+*/-]+[\(\)\.+*/-\d\s]+($|=$)', "", true],
            ["一键打开文件", "S)^(\\\\|[A-Za-z]:\\).*?\\..+", "", true],
            ["一键打开目录", "S)^(\\\\|[A-Za-z]:\\)", "", true],
            ["一键打开网址", "iS)^([\\w-]+://?|www[.]).*", "", true],
            ["一键磁力链接", "iS)^magnet:\\?xt=urn:btih:.*", "", true],
        ]
        for d in defaults {
            regex := ConfigReader.ReadSetting(d[1] "_Regex", d[2])
            runCmd := ConfigReader.ReadSetting(d[1] "_Run", d[3])
            enabled := runCmd != "" || d[4]
            lv.Add(enabled ? "Check" : "", regex, d[1], enabled ? "启用" : "禁用", d[1] = "一键公式计算" ? "内置功能" : runCmd)
        }
        lv.OnEvent("DoubleClick", (lv, item) => SettingsGui.OneKeyEdit("编辑"))

        g.AddGroupBox("xm-10 y+10 w660 h300", "一键搜索选中文字")
        SettingsGui.HK(g, "OneKey", "xm yp+25 w150")
        SettingsGui.CW(g, "OneWinKey", "xm+155 yp+3")
        SettingsGui.CB(g, "OneKeyMenu", "绑定菜单热键为一键搜索", "x+38")
        g.AddText("xm y+10 w300", "搜索网址(%s为选中文字):")
        SettingsGui.ED(g, "OneKeyUrl", "https://www.baidu.com/s?wd=%s", "xm y+5 w640 r3")
        g.AddText("xm y+10", "非默认浏览器:")
        g.AddButton("x+5 yp-5", "选择").OnEvent("Click", (*) => SettingsGui.BrowseFile("BrowserPath", ""))
        SettingsGui.ED(g, "BrowserPath", "", "xm y+5 w640 r3")
    }

    static OneKeyOnline() {
        try Run("https://hui-zz.gitee.io/runany/#/")
    }

    static OneKeyEdit(action) {
        lv := SettingsGui.controls["OneKeyLV"]
        oRegex := "", oName := "", oRun := ""
        if action = "编辑" {
            row := lv.GetNext(0)
            if !row
                return
            oRegex := lv.GetText(row, 1)
            oName := lv.GetText(row, 2)
            oRun := lv.GetText(row, 4)
        }
        eg := Gui(, "一键直达规则")
        eg.SetFont(, "Microsoft YaHei")
        eg.AddGroupBox("x10 y10 w450 h140", action "一键直达规则")
        eg.AddText("x20 y35 w80", "规则名称:")
        nameEdt := eg.AddEdit("x+5 yp w350", oName)
        eg.AddText("x20 y+15 w80", "正则表达式:")
        regexEdt := eg.AddEdit("x+5 yp w350", oRegex)
        eg.AddText("x20 y+15 w80", "运行命令:")
        runEdt := eg.AddEdit("x+5 yp w350", oRun)
        eg.AddButton("Default x150 y+20 w75", "保存").OnEvent("Click", (*) => SettingsGui.SaveOneKey(lv, action, nameEdt.Value, regexEdt.Value, runEdt.Value, eg))
        eg.AddButton("x+20 w75", "取消").OnEvent("Click", (*) => eg.Hide())
        eg.Show("w480")
    }

    static SaveOneKey(lv, action, name, regex, runCmd, eg) {
        if name = ""
            return
        if action = "新建"
            lv.Add("Check", regex, name, "启用", runCmd)
        else {
            row := lv.GetNext(0)
            lv.Modify(row, "", regex, name, lv.GetText(row, 3), runCmd)
        }
        lv.ModifyCol()
        eg.Hide()
    }

    static OneKeyRemove() {
        lv := SettingsGui.controls["OneKeyLV"]
        row := lv.GetNext(0)
        if row
            lv.Delete(row)
    }

    ; ═══════ Tab7: 内部关联 ═══════
    static BuildTab7(g) {
        g.AddText("Section xm-10 y+10", "内部关联RunAny.ini菜单内不同后缀的文件，使用指定软件打开")
        g.AddText("x+5 ys cRed", "（对资源管理器选中的文件无效！）")
        g.AddButton("xs y+10 w50", "+ 增加").OnEvent("Click", (*) => SettingsGui.OpenExtEdit("新建"))
        g.AddButton("x+10 yp w50", "· 修改").OnEvent("Click", (*) => SettingsGui.OpenExtEdit("编辑"))
        g.AddButton("x+10 yp w50", "- 减少").OnEvent("Click", (*) => SettingsGui.OpenExtRemove())
        g.AddText("x+10 yp+5 w220", "特殊类型：http https www ftp | folder")
        lv := g.AddListView("xs y+15 w660 r30 grid -Multi", ["RunAny菜单内文件后缀(空格分隔)", "打开方式(支持无路径)"])
        lv.ModifyCol(1, 250)
        lv.ModifyCol(2, 380)
        SettingsGui.controls["OpenExtLV"] := lv

        try {
            exts := IniRead(CONFIG_PATH, "OpenExt")
            Loop Parse exts, "`n", "`r" {
                eq := InStr(A_LoopField, "=")
                if eq = 0
                    continue
                k := SubStr(A_LoopField, 1, eq - 1)
                v := SubStr(A_LoopField, eq + 1)
                lv.Add("", v, k)
            }
        }
        lv.OnEvent("DoubleClick", (lv, item) => SettingsGui.OpenExtEdit("编辑"))
    }

    static OpenExtEdit(action) {
        lv := SettingsGui.controls["OpenExtLV"]
        extName := "", extRun := ""
        if action = "编辑" {
            row := lv.GetNext(0)
            if !row
                return
            extName := lv.GetText(row, 1)
            extRun := lv.GetText(row, 2)
        }
        eg := Gui(, action "内部关联后缀打开方式")
        eg.SetFont(, "Microsoft YaHei")
        eg.AddGroupBox("Section xm ym w450 h145", action "内部关联后缀打开方式")
        eg.AddText("xs+10 ys+30 w62", "文件后缀（空格分隔）")
        nameEdt := eg.AddEdit("x+5 yp-4 w350", extName)
        eg.AddButton("xs+5 y+12 w120", "打开方式软件路径").OnEvent("Click", (*) => SettingsGui.BrowseOpenExt(runEdt))
        runEdt := eg.AddEdit("x+12 yp w292 r3 -WantReturn", extRun)
        eg.AddButton("Default xs+140 y+25 w75", "保存(&Y)").OnEvent("Click", (*) => SettingsGui.SaveOpenExt(lv, action, nameEdt.Value, runEdt.Value, eg))
        eg.AddButton("x+20 yp w75", "取消(&C)").OnEvent("Click", (*) => eg.Hide())
        eg.Show("w480")
    }

    static BrowseOpenExt(runEdt) {
        path := FileSelect(, , "选择打开方式软件路径")
        if path != ""
            runEdt.Value := path
    }

    static SaveOpenExt(lv, action, name, runCmd, eg) {
        if !name || !runCmd {
            ToolTip("请填入文件后缀名和打开方式软件路径", 195, 35)
            SetTimer(() => ToolTip(), -3000)
            return
        }
        if action = "新建" {
            ; 检查是否已有相同打开方式，有则合并后缀
            Loop lv.GetCount() {
                existingRun := lv.GetText(A_Index, 2)
                if runCmd = existingRun {
                    existingName := lv.GetText(A_Index, 1)
                    lv.Modify(A_Index, "", existingName " " name, runCmd)
                    lv.ModifyCol()
                    ToolTip("已自动合并后缀到相同打开方式中", 195, -20)
                    SetTimer(() => ToolTip(), -3000)
                    eg.Hide()
                    return
                }
            }
            lv.Add("", name, runCmd)
        } else {
            row := lv.GetNext(0)
            lv.Modify(row, "", name, runCmd)
        }
        lv.ModifyCol()
        eg.Hide()
    }

    static OpenExtRemove() {
        lv := SettingsGui.controls["OpenExtLV"]
        row := lv.GetNext(0)
        if row
            lv.Delete(row)
    }

    ; ═══════ Tab8: 热字符串 ═══════
    static BuildTab8(g) {
        g.AddGroupBox("xm-10 y+10 w660 h270", "热字符串设置")
        SettingsGui.CB(g, "HideHotStr", "隐藏热字符串提示", "xm yp+30")
        g.AddText("xm y+15 w250", "按几个字符出现提示(默认3):")
        SettingsGui.ED(g, "HotStrHintLen", "3", "x+5 yp-5 w60")
        g.AddText("xm y+15 w250", "提示启动路径最长字数(0为隐藏):")
        SettingsGui.ED(g, "HotStrShowLen", "30", "x+5 yp-5 w60")
        g.AddText("xm y+15 w250", "提示显示时长(毫秒):")
        SettingsGui.ED(g, "HotStrShowTime", "3000", "x+5 yp-5 w80")
        g.AddText("xm y+18 w250", "提示显示透明度百分比(%):")
        SettingsGui.controls["HotStrShowTransparent"] := g.AddSlider("x+5 yp-5 w200 ToolTip", Integer(ConfigReader.ReadSetting("HotStrShowTransparent", "80")))
        g.AddText("xm y+10 w250", "提示相对于鼠标坐标X:")
        SettingsGui.ED(g, "HotStrShowX", "0", "x+5 yp-5 w60")
        g.AddText("xm y+15 w250", "提示相对于鼠标坐标Y:")
        SettingsGui.ED(g, "HotStrShowY", "0", "x+5 w60")
        g.AddText("xm y+30", "短语key(huiZz_Text):")
        SettingsGui.ED(g, "SendStrEcKey", "", "x+5 yp-5 w200 Password")
        g.AddText("xm y+20 cBlue", "提示文字自动消失后，而且后续输入字符不触发热字符串功能")
        g.AddText("xm y+2 cBlue", "需要按Tab/回车/句点/空格等键之后才会再次进行提示")
    }

    ; ═══════ Tab9: 图标设置 ═══════
    static BuildTab9(g) {
        SettingsGui.CB(g, "HideMenuTrayIcon", "隐藏任务栏托盘图标", "xm-10 y+10")
        g.AddText("x+20 yp", "菜单图标大小(像素):")
        SettingsGui.ED(g, "MenuIconSize", "24", "x+3 w45 h18")
        g.AddText("x+15 yp", "托盘图标大小:")
        SettingsGui.ED(g, "MenuTrayIconSize", "", "x+3 w45 h18")

        g.AddGroupBox("Section xm-10 y+8 w660 h285", "图标自定义设置（图片或图标文件路径,序号）")
        icons := [
            ["AnyIcon", "RunAny图标", "shell32.dll,283"],
            ["MenuIcon", "准备图标", "shell32.dll,2"],
            ["TreeIcon", "分类图标", "shell32.dll,3"],
            ["FolderIcon", "文件夹图标", "shell32.dll,5"],
            ["UrlIcon", "网址图标", "shell32.dll,14"],
            ["EXEIcon", "EXE图标", "shell32.dll,3"],
            ["FuncIcon", "脚本插件函数", "shell32.dll,131"],
        ]
        for i, ic in icons {
            yPos := (i = 1) ? "ys+30" : "y+10"
            g.AddButton("xs+10 " yPos " w80", ic[2]).OnEvent("Click", SettingsGui.BrowseIcon.Bind(ic[1]))
            SettingsGui.ED(g, ic[1], ic[3], "x+5 yp w550")
        }

        

        g.AddGroupBox("Section xs y+40 w660 h240", APP_NAME "图标识别库")
        g.AddText("xs+10 ys+25", "提示：图标识别库支持多行，要求图标名与菜单项名相同，不包含热字符串和全局热键")
        g.AddButton("xs+10 y+10 w130", "生成所有EXE图标").OnEvent("Click", (*) => SettingsGui.ExtractExeIcons())
        g.AddButton("xs+10 y+10 w50", "选择").OnEvent("Click", (*) => SettingsGui.BrowseFolder("IconFolderPath"))
        SettingsGui.ED(g, "IconFolderPath", "", "x+10 yp w580 r8")
        ; 显示时 | 转成换行，多行编辑更直观
        if SettingsGui.controls.Has("IconFolderPath")
            SettingsGui.controls["IconFolderPath"].Value := StrReplace(SettingsGui.controls["IconFolderPath"].Value, "|", "`n")
    }

    static BrowseIcon(varName, *) {
        file := FileSelect(1, , "图标图片路径")
        if file != "" && SettingsGui.controls.Has(varName)
            SettingsGui.controls[varName].Value := file
    }

    static ExtractExeIcons() {
        global g_MenuBuilder
        result := MsgBox(
            "将提取 RunAny 菜单中所有 EXE 程序的图标并保存为 .ico 文件`n`n"
            "是：覆盖已有图标重新提取`n"
            "否：仅提取尚未缓存的图标`n"
            "取消：取消操作",
            APP_NAME " 生成EXE图标",
            0x23  ; Yes/No/Cancel + Question
        )
        overwrite := false
        if result = "Cancel"
            return
        if result = "Yes"
            overwrite := true
        ToolTip("RunAny 正在提取 EXE 图标，请稍等……")
        try {
            count := IconLoader.ExtractAllIcons(g_MenuBuilder.categories, overwrite)
            ToolTip()
            if count > 0
                MsgBox("成功提取 " count " 个 EXE 图标到 RunIcon\ExeIcon 目录", APP_NAME, 64)
            else
                MsgBox("没有新的 EXE 图标需要提取", APP_NAME, 64)
        } catch as e {
            ToolTip()
            MsgBox("提取 EXE 图标失败:`n" e.Message, APP_NAME, 16)
        }
    }

    ; ═══════ Tab10: 高级配置 ═══════
    static BuildTab10(g) {
        g.AddText("xm-10 y+5 w660", APP_NAME "高级配置列表（请理解说明后修改，双击进行修改）")
        lv := g.AddListView("xm-10 y+5 w660 r30 grid -Multi", ["1或有值=启用，0或空=停用", "单位", "配置说明", "配置项名"])
        lv.ModifyCol(1, 120)
        lv.ModifyCol(2, 60)
        lv.ModifyCol(3, 340)
        lv.ModifyCol(4, 120)
        SettingsGui.controls["AdvancedLV"] := lv

        ; ImageList for enable/disable icons (DPI-aware)
        iconCx := DllCall("User32\GetSystemMetrics", "Int", 49)
        iconCy := DllCall("User32\GetSystemMetrics", "Int", 50)
        il := DllCall("comctl32.dll\ImageList_Create", "Int", iconCx, "Int", iconCy, "UInt", 0x21, "Int", 2, "Int", 2, "Ptr")
        iconIdx := (A_OSVersion = "WIN_7") ? 102 : 297
        IL_Add(il, (A_OSVersion = "WIN_7") ? "imageres.dll" : "shell32.dll", iconIdx)
        IL_Add(il, "shell32.dll", 132)
        DllCall("User32\SendMessageW", "Ptr", lv.Hwnd, "UInt", 0x1003, "Ptr", 1, "Ptr", il)

        lv.Opt("-Redraw")
        configs := [
            ["JumpSearch", ConfigReader.ReadSetting("JumpSearch", "0"), "", "跳过点击批量搜索时的确认弹窗", 1],
            ["ShowGetZzLen", ConfigReader.ReadSetting("ShowGetZzLen", "30"), "字", "[选中] 菜单第一行显示选中文字最大截取字数", 1],
            ["ClipWaitApp", ConfigReader.ReadSetting("ClipWaitApp", ""), "逗号分隔", "[选中] 指定软件解决剪贴板等待时间过短获取不到选中内容", 1],
            ["ClipWaitTime", ConfigReader.ReadSetting("ClipWaitTime", "0.1"), "秒", "[选中] 指定软件获取选中目标到剪贴板等待时间", 1],
            ["GetZzCopyKey", ConfigReader.ReadSetting("GetZzCopyKey", "^{Insert}"), "热键", "[选中] 自定义在一些软件界面获取选中内容的热键", 1],
            ["GetZzCopyKeyApp", ConfigReader.ReadSetting("GetZzCopyKeyApp", ""), "逗号分隔", "[选中] 自定义在哪些软件界面改变获取选中内容热键", 1],
            ["GetZzTransformVal", ConfigReader.ReadSetting("GetZzTransformVal", "0"), "", "[选中] 对选中的双百分号内容%%自动转换成变量值", 1],
            ["HoldCtrlRun", ConfigReader.ReadSetting("HoldCtrlRun", "2"), "", "[按住Ctrl键] 回车或点击菜单项 2:打开该软件所在目录", 1],
            ["HoldShiftRun", ConfigReader.ReadSetting("HoldShiftRun", "5"), "", "[按住Shift键] 回车或点击菜单项 5:打开多功能菜单运行方式", 1],
            ["HoldCtrlShiftRun", ConfigReader.ReadSetting("HoldCtrlShiftRun", "3"), "", "[按住Ctrl+Shift键] 回车或点击菜单项 3:编辑该菜单项", 1],
            ["HoldCtrlWinRun", ConfigReader.ReadSetting("HoldCtrlWinRun", ""), "", "[按住Ctrl+Win键] 11:管理员 12:最小化 13:最大化 14:隐藏", 1],
            ["HoldShiftWinRun", ConfigReader.ReadSetting("HoldShiftWinRun", ""), "", "[按住Shift+Win键] 31:复制路径 32:输出路径 33:复制软件名 34:输出软件名", 1],
            ["HoldCtrlShiftWinRun", ConfigReader.ReadSetting("HoldCtrlShiftWinRun", ""), "", "[按住Ctrl+Shift+Win键] 4:强制结束该软件名进程", 1],
            ["HoldKeyShowTime", ConfigReader.ReadSetting("HoldKeyShowTime", "1000"), "毫秒", "按键运行菜单项复制运行路径、软件名等提示信息的显示时间", 1],
            ["RunAnyMenuTransparent", ConfigReader.ReadSetting("RunAnyMenuTransparent", "225"), "", "RunAny菜单和右键菜单透明度数值（0全透明-255不透明）", 1],
            ["RUNANY_SELF_MENU_ITEM1", ConfigReader.ReadSetting("RUNANY_SELF_MENU_ITEM1", "&1批量搜索"), "", "RunAny自身功能菜单项名称修改1", 1],
            ["RUNANY_SELF_MENU_ITEM2", ConfigReader.ReadSetting("RUNANY_SELF_MENU_ITEM2", "RunAny设置"), "", "RunAny自身功能菜单项名称修改2", 1],
            ["RUNANY_SELF_MENU_ITEM3", ConfigReader.ReadSetting("RUNANY_SELF_MENU_ITEM3", "0【添加到此菜单】"), "", "RunAny自身功能菜单项名称修改3", 1],
            ["RUNANY_SELF_MENU_ITEM4", ConfigReader.ReadSetting("RUNANY_SELF_MENU_ITEM4", "-【显示菜单全部】"), "", "RunAny自身功能菜单项名称修改4", 1],
            ["DebugMode", ConfigReader.ReadSetting("DebugMode", "0"), "", "[调试模式] 实时显示菜单运行的信息", 1],
            ["DebugModeShowTime", ConfigReader.ReadSetting("DebugModeShowTime", "8000"), "毫秒", "[调试模式] 实时显示菜单运行信息的自动隐藏时间", 1],
            ["DebugModeShowTrans", ConfigReader.ReadSetting("DebugModeShowTrans", ""), "%", "[调试模式] 实时显示菜单运行信息的透明度", 1],
            ["DisableExeIcon", ConfigReader.ReadSetting("DisableExeIcon", "0"), "", "菜单中exe程序不加载本身图标", 1],
            ["RunAEncoding", ConfigReader.ReadSetting("RunAEncoding", ""), "", "使用指定编码读取RunAny.ini（默认ANSI）", 1],
            ["AutoGetZz", ConfigReader.ReadSetting("AutoGetZz", "1"), "", "【慎改】菜单程序运行自动带上当前选中文件，关闭后需要手动加%getZz%", 1],
            ["EvNo", ConfigReader.ReadSetting("EvNo", "0"), "", "【慎改】不使用Everything模式，所有无路径应用缓存需要手动新增修改", 1],
            ["CtrlGQuickSwitch", ConfigReader.ReadSetting("CtrlGQuickSwitch", "1"), "", "在资源管理器和文件对话框按Ctrl+G快速切换目录", 1],
        ]
        for cfg in configs {
            icon := (cfg[2] != "" && cfg[2] != "0") ? "Icon1" : "Icon2"
            lv.Add(icon, cfg[2], cfg[3], cfg[4], cfg[1])
        }

        lv.ModifyCol(2, "Auto Center")
        lv.ModifyCol(3, "Auto")
        lv.ModifyCol(4, "Auto")
        lv.Opt("+Redraw")

        lv.OnEvent("DoubleClick", (ctrl, item) => SettingsGui.EditAdvancedItem(ctrl, item))
    }

    static EditAdvancedItem(lv, item) {
        val := lv.GetText(item, 1)
        name := lv.GetText(item, 4)
        desc := lv.GetText(item, 3)
        ib := InputBox(desc, "修改: " name,, val)
        if ib.Result != "Cancel" {
            lv.Modify(item, "", ib.Value, lv.GetText(item, 2), desc, name)
        }
    }

    ; ═══════ 工具函数 ═══════
    static EvReindex() {
        evPath := SettingsGui.controls["EvPath"].Value
        if evPath = ""
            evPath := ExeResolver.EvExePath
            
        if evPath != "" {
            evPath := ConfigReader.TransformVar(evPath)
            try {
                Run('"' evPath '" -reindex')
                ToolTip("已发送重建索引指令到 Everything")
            } catch as e {
                MsgBox("重建索引失败，请检查 Everything 路径是否正确。`n`n错误信息: " e.Message, APP_NAME, 48)
            }
        } else {
            MsgBox("未找到 Everything，无法重建索引。", APP_NAME, 48)
        }
        SetTimer(() => ToolTip(), -3000)
    }

    static EnableMenu2() {
        iniPath2 := A_ScriptDir "\RunAny2.ini"
        if !FileExist(iniPath2) {
            FileAppend(";这里添加第2菜单内容`n-菜单2分类`n", iniPath2)
        }
        MsgBox("已创建 RunAny2.ini，请重新打开设置界面配置菜单2热键", APP_NAME, 64)
        SettingsGui.guiObj.Destroy()
        SettingsGui.guiObj := ""
        SettingsGui.Show()
    }

    static BrowseFile(key, filter := "") {
        file := FileSelect(1, , "选择文件", filter)
        if file != "" {
            ctrl := SettingsGui.controls[key]
            if ctrl
                ctrl.Value := file
        }
    }

    static SetScheduledTasks() {
        exe := FileExist(A_ScriptDir "\RunAny_v2.exe") ? A_ScriptDir "\RunAny_v2.exe" : A_ScriptFullPath
        try {
            Run('schtasks /create /tn "RunAny_v2" /tr "' exe '" /sc onlogon /rl highest /f',, "Hide")
            ToolTip("已创建开机管理员启动任务计划")
        } catch {
            ToolTip("创建任务计划失败，请以管理员身份运行")
        }
        SetTimer(() => ToolTip(), -3000)
    }

    static ClearRecentMax() {
        RecentItems.Clear()
        ToolTip("已清理最近运行项")
        SetTimer(() => ToolTip(), -2000)
    }

    static PickRunningProcess() {
        pg := Gui("+Owner" (SettingsGui.guiObj ? SettingsGui.guiObj.Hwnd : ""), "运行中进程 - 双击选择要屏蔽的程序")
        pg.SetFont(, "Microsoft YaHei")
        pg.MarginX := 10
        pg.MarginY := 10
        lv := pg.AddListView("w600 r20 grid", ["进程名", "窗口标题", "PID"])
        ; 获取所有运行进程，按窗口标题分组显示
        seen := Map()
        DllCall("Psapi.dll\EnumProcesses", "Ptr", Buf := Buffer(4096*4), "UInt", Buf.Size, "UIntP", &byteCnt := 0)
        rows := []
        Loop byteCnt // 4 {
            pid := NumGet(Buf, (A_Index - 1) * 4, "UInt")
            if pid = 0
                continue
            try name := ProcessGetName(pid)
            catch
                continue
            if seen.Has(name)
                continue
            seen[name] := true
            ; 获取该进程的窗口标题
            title := ""
            try {
                hwnd := WinGetList("ahk_pid " pid)
                if hwnd is Integer && hwnd
                    title := WinGetTitle("ahk_id " hwnd)
                else if hwnd is Array && hwnd.Length > 0
                    title := WinGetTitle("ahk_id " hwnd[1])
            }
            rows.Push(title = "" ? [name, "(无窗口)", pid] : [name, title, pid])
        }
        ; 按窗口标题排序，有窗口的排前面
        for r in rows
            lv.Add("", r[1], r[2], r[3])
        lv.ModifyCol(1, 160)
        lv.ModifyCol(2, 320)
        lv.ModifyCol(3, 60, "Integer")
        lv.OnEvent("DoubleClick", (ctrl, item) => SettingsGui.AddProcessFromList(ctrl, item, pg))
        pg.AddText("xm", "双击进程名添加到屏蔽列表")
        pg.OnEvent("Close", (*) => pg.Destroy())
        pg.Show()
    }

    static AddProcessFromList(lv, item, pg) {
        exeName := lv.GetText(item, 1)
        ed := SettingsGui.controls["DisableApp"]
        cur := ed.Value
        if InStr(cur, exeName) {
            ToolTip("「" exeName "」已在屏蔽列表中")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        ed.Value := cur = "" ? exeName : cur "," exeName
        ToolTip("已添加：「" exeName "」")
        SetTimer(() => ToolTip(), -2000)
        pg.Destroy()
    }

    static OnReset(*) {
        result := MsgBox("此操作会删除RunAny所有配置！`n确认重置吗？", "重置RunAny配置", 0x31)
        if result = "OK" {
            try RegDelete("HKEY_CURRENT_USER\SOFTWARE\RunAny_v2")
            try RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "RunAny")
            try FileDelete(CONFIG_PATH)
            SafeReload()
        }
    }

    static OnOK(*) {
        c := SettingsGui.controls

        if c.Has("AutoRun_Reg") && c["AutoRun_Reg"].Value {
            exe := FileExist(A_ScriptDir "\RunAny_v2.exe") ? A_ScriptDir "\RunAny_v2.exe" : A_ScriptFullPath
            try RegWrite('"' exe '"', "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "RunAny")
        } else {
            try RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "RunAny")
        }

        saveKeys := [
            "AdminRun","HideFail","HideSend","HideWeb","HideGetZz","HideSelectZz",
            "HideAddItem","HideMenuTray","RecentMax","AutoGetZz","AutoReloadMTime",
            "RunABackupRule","RunABackupMax","RunABackupFormat","RunABackupDir","DisableApp",
            "MenuKey","MenuWinKey","MenuKey2","MenuWinKey2","MenuNoGetKey","MenuNoGetWinKey",
            "MenuDoubleCtrlKey","MenuDoubleAltKey","MenuDoubleLWinKey","MenuDoubleRWinKey",
            "MenuCtrlRightKey","MenuShiftRightKey","MenuXButton1Key","MenuXButton2Key","MenuMButtonKey",
            "TreeHotKey1","TreeWinKey1","TreeHotKey2","TreeWinKey2",
            "TreeIniHotKey1","TreeIniWinKey1","TreeIniHotKey2","TreeIniWinKey2",
            "EvKey","EvWinKey","EvPath","EvAutoClose","EvShowExt","EvShowFolder","EvExeVerNew","EvExeMTimeNew",
            "EvDemandSearch","EvCommand",
            "OneKey","OneWinKey","OneKeyUrl","OneKeyMenu",
            "RunATrayHotKey","RunATrayWinKey","RunASetHotKey","RunASetWinKey",
            "RunAReloadHotKey","RunAReloadWinKey","RunASuspendHotKey","RunASuspendWinKey",
            "RunAExitHotKey","RunAExitWinKey","PluginsManageHotKey","PluginsManageWinKey",
            "RunCtrlManageHotKey","RunCtrlManageWinKey",
            "PluginsAlonePauseHotKey","PluginsAlonePauseWinKey",
            "PluginsAloneSuspendHotKey","PluginsAloneSuspendWinKey",
            "PluginsAloneCloseHotKey","PluginsAloneCloseWinKey",
            "BrowserPath",
            "HideHotStr","HotStrHintLen","HotStrShowLen","HotStrShowTime","HotStrShowTransparent",
            "HotStrShowX","HotStrShowY","SendStrEcKey",
            "HideMenuTrayIcon","MenuIconSize","MenuTrayIconSize",
            "AnyIcon","MenuIcon","TreeIcon","FolderIcon","UrlIcon","EXEIcon","FuncIcon","IconFolderPath",
            "ShowGetZzLen","ClipWaitTime","ClipWaitApp","GetZzCopyKey","GetZzCopyKeyApp","GetZzTransformVal",
            "HoldCtrlRun","HoldShiftRun","HoldCtrlShiftRun","HoldCtrlWinRun","HoldShiftWinRun",
            "HoldCtrlShiftWinRun","HoldKeyShowTime","RunAnyMenuTransparent","DisableExeIcon",
            "RunAEncoding","AutoGetZz","EvNo","DebugMode","DebugModeShowTime",
            "RunAEvFullPathIniDir","CtrlGQuickSwitch",
        ]
        for key in saveKeys {
            if c.Has(key) {
                val := c[key].Value
                ; IconFolderPath：多行编辑，保存时换行转 | 分隔
                if key = "IconFolderPath"
                    val := StrReplace(val, "`n", "|")
                SettingsGui.Save(key, val)
            }
        }

        SettingsGui.SaveMenuVarLV()
        SettingsGui.SavePathCacheLV()
        SettingsGui.SaveOneKeyLV()
        SettingsGui.SaveOpenExtLV()
        SettingsGui.SaveAdvancedLV()

        SettingsGui.guiObj.Hide()
        SafeReload()
    }

    static Save(key, value) {
        ; Filter vkE5 (IME intercepted key — invalid as hotkey)
        if value = "vkE5"
            value := ""
        if value = "" {
            try IniDelete(CONFIG_PATH, "Config", key)
        } else {
            try IniWrite(value, CONFIG_PATH, "Config", key)
        }
    }

    static SaveMenuVarLV() {
        lv := SettingsGui.controls["MenuVarLV"]
        if !lv
            return
        try IniDelete(CONFIG_PATH, "MenuVar")
        Loop lv.GetCount() {
            name := lv.GetText(A_Index, 1)
            val := lv.GetText(A_Index, 3)
            if name != "" {
                mtype := lv.GetText(A_Index, 2)
                if !InStr(mtype, "动态")
                    try IniWrite(val, CONFIG_PATH, "MenuVar", name)
            }
        }
    }

    static SavePathCacheLV() {
        lv := SettingsGui.controls["PathCacheLV"]
        if !lv
            return
        cacheFile := SettingsGui.GetEvFullPathIni()
        try FileDelete(cacheFile)
        Loop lv.GetCount() {
            name := lv.GetText(A_Index, 1)
            val := lv.GetText(A_Index, 2)
            if name != ""
                try IniWrite(val, cacheFile, "FullPath", name)
        }
    }

    static SaveOneKeyLV() {
        lv := SettingsGui.controls["OneKeyLV"]
        if !lv
            return
        try IniDelete(CONFIG_PATH, "OneKey")
        Loop lv.GetCount() {
            regex := lv.GetText(A_Index, 1)
            name := lv.GetText(A_Index, 2)
            status := lv.GetText(A_Index, 3)
            runCmd := lv.GetText(A_Index, 4)
            if name != "" {
                if name = "一键公式计算" runCmd := ""
                try IniWrite(regex, CONFIG_PATH, "OneKey", name "_Regex")
                try IniWrite(runCmd, CONFIG_PATH, "OneKey", name "_Run")
            }
        }
    }

    static SaveOpenExtLV() {
        lv := SettingsGui.controls["OpenExtLV"]
        if !lv
            return
        try IniDelete(CONFIG_PATH, "OpenExt")
        Loop lv.GetCount() {
            extName := lv.GetText(A_Index, 1)
            extRun := lv.GetText(A_Index, 2)
            if extRun != ""
                try IniWrite(extName, CONFIG_PATH, "OpenExt", extRun)
        }
    }

    static SaveAdvancedLV() {
        lv := SettingsGui.controls["AdvancedLV"]
        if !lv
            return
        Loop lv.GetCount() {
            val := lv.GetText(A_Index, 1)
            name := lv.GetText(A_Index, 4)
            if name != ""
                SettingsGui.Save(name, val)
        }
    }
}
