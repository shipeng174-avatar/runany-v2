#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir A_ScriptDir
CoordMode "Menu"

; 安全重启：恢复 V1 的光速重启逻辑
SafeReload() {
    Critical()
    Run(A_AhkPath ' /force /restart "' A_ScriptFullPath '"')
    ExitApp()
}

global APP_NAME := "RunAny_v2"
global APP_VERSION := "0.4.0"

; V1 兼容：自动禁用的程序列表（热键在这些程序里不生效）
; 在 RunAnyConfig.ini [Settings] 下配置 DisableApp=blender.exe,vmware-vmx.exe
; 读取后构建窗口组，在 TryRegHotkey 中用 HotIf 排除
global INI_PATH := A_ScriptDir "\RunAny.ini"
global INI2_PATH := A_ScriptDir "\RunAny2.ini"
global CONFIG_PATH := A_ScriptDir "\RunAnyConfig.ini"
global g_MenuBuilder := ""
global g_RootMenu := ""
global g_RootMenuDefault := ""
global g_RootMenuText := ""
global g_RootMenuFile := ""
global g_Menu2Active := false
global g_Menu2Builder := ""
global g_RootMenu2Default := ""
global g_RootMenu2Text := ""
global g_RootMenu2File := ""
global g_PathCache := Map()
global g_PathNotFound := Map()
global g_SelectedText := ""
global g_SelectedIsFile := 0
global g_SelectedFileExt := ""
global g_MenuObjKey := Map()
global g_INIModTime := ""
global g_INI2ModTime := ""
global g_StartupTick := A_TickCount
global g_SubMenuMap := Map()
global g_RecentMax := 5
global g_EvShowExt := true
global g_EvShowFolder := true
global g_Suspended := false
global g_textCategories := []
global g_fileCategories := []

#Include "Lib\Config.ahk"
#Include "Lib\ExeResolver.ahk"
#Include "Lib\MenuParser.ahk"
#Include "Lib\Recent.ahk"
#Include "Lib\MenuBuilder.ahk"
#Include "Lib\Launcher.ahk"
#Include "Lib\MultiMenu.ahk"
#Include "Lib\Hotkeys.ahk"
#Include "Lib\DoubleTap.ahk"
#Include "Lib\Everything.ahk"
#Include "Lib\PluginManager.ahk"
#Include "Lib\SettingsGui.ahk"
#Include "Lib\RunCtrl.ahk"
#Include "Lib\RunCtrlGui.ahk"
#Include "Lib\OneKey.ahk"
#Include "Lib\FolderInjector.ahk"
#Include "Lib\HotStrHint.ahk"
#Include "Lib\PathCache.ahk"
#Include "Lib\MenuEditor.ahk"
#Include "Lib\MenuKeys.ahk"

GetSelectedText() {
    global g_SelectedIsFile
    g_SelectedIsFile := 0  ; V1 兼容：每次调用先清零

    copyKey := "^c"
    copyKeyApp := ConfigReader.ReadSetting("GetZzCopyKeyApp", "cmd.exe,powershell.exe")
    altCopyKey := ConfigReader.ReadSetting("GetZzCopyKey", "^{Insert}")
    if altCopyKey != "" && copyKeyApp != "" {
        Loop Parse copyKeyApp, "," {
            if WinActive("ahk_exe " Trim(A_LoopField)) {
                copyKey := altCopyKey
                break
            }
        }
    }

    clipWaitTime := 0.1
    clipWaitApp := ConfigReader.ReadSetting("ClipWaitApp", "")
    if clipWaitApp != "" {
        clipWaitAppTime := ConfigReader.ReadSetting("ClipWaitTime", "1.2")
        Loop Parse clipWaitApp, "," {
            if WinActive("ahk_exe " Trim(A_LoopField)) {
                clipWaitTime := Float(clipWaitAppTime)
                break
            }
        }
    }

    savedClip := A_Clipboard
    A_Clipboard := ""
    Send(copyKey)
    if !ClipWait(clipWaitTime) {
        A_Clipboard := savedClip
        return ""
    }
    g_SelectedIsFile := DllCall("IsClipboardFormatAvailable", "UInt", 15)
    result := A_Clipboard
    ; 文件复制时 A_Clipboard 可能为空（只有 CF_HDROP），降级提取文件路径
    if g_SelectedIsFile && result = "" {
        try {
            DllCall("OpenClipboard", "Ptr", 0)
            hDrop := DllCall("GetClipboardData", "UInt", 15, "Ptr")
            if hDrop {
                fileCount := DllCall("shell32\DragQueryFile", "Ptr", hDrop, "UInt", 0xFFFFFFFF, "Ptr", 0, "UInt", 0)
                Loop fileCount {
                    buf := Buffer(520)
                    DllCall("shell32\DragQueryFile", "Ptr", hDrop, "UInt", A_Index - 1, "Ptr", buf, "UInt", 520)
                    result .= (result ? "`n" : "") StrGet(buf)
                }
            }
            DllCall("CloseClipboard")
        }
    }
    A_Clipboard := savedClip
    return result
}

SetupAutoReload() {
    global g_INIModTime, g_INI2ModTime
    interval := Integer(ConfigReader.ReadSetting("AutoReloadMTime", "3000"))
    try g_INIModTime := FileGetTime(INI_PATH, "M")
    if g_Menu2Active {
        try g_INI2ModTime := FileGetTime(INI2_PATH, "M")
    }
    SetTimer(CheckINIChange, interval)
}

CheckINIChange() {
    global g_INIModTime, g_INI2ModTime
    if (A_TickCount - g_StartupTick) < 5000
        return
    if !FileExist(INI_PATH)
        return
    try {
        curTime := FileGetTime(INI_PATH, "M")
        if curTime != g_INIModTime {
            g_INIModTime := curTime
            DoBackup()
            Sleep(100)
            SafeReload()
        }
    }
    if g_Menu2Active && FileExist(INI2_PATH) {
        try {
            curTime2 := FileGetTime(INI2_PATH, "M")
            if curTime2 != g_INI2ModTime {
                g_INI2ModTime := curTime2
                DoBackup()
                Sleep(100)
                SafeReload()
            }
        }
    }
}

SetupTrayMenu() {
    A_TrayMenu.Delete()

    menuKey := ConfigReader.ReadSetting("MenuKey", "")
    if menuKey = ""
        menuKey := "``"
    menuWinKey := ConfigReader.ReadSetting("MenuWinKey", "0") = "1"
    if ConfigReader.ReadSetting("MenuKey", "") = "" && !menuWinKey
        menuWinKey := true
    treeHotKey1 := ConfigReader.ReadSetting("TreeHotKey1", "")
    treeIniHotKey1 := ConfigReader.ReadSetting("TreeIniHotKey1", "")
    evKey := ConfigReader.ReadSetting("EvKey", "")
    oneKey := ConfigReader.ReadSetting("OneKey", "")
    pluginsHK := ConfigReader.ReadSetting("PluginsManageHotKey", "")
    runCtrlHK := ConfigReader.ReadSetting("RunCtrlManageHotKey", "")
    setHK := ConfigReader.ReadSetting("RunASetHotKey", "")
    reloadHK := ConfigReader.ReadSetting("RunAReloadHotKey", "")
    suspendHK := ConfigReader.ReadSetting("RunASuspendHotKey", "")
    exitHK := ConfigReader.ReadSetting("RunAExitHotKey", "")

    menuKeyLabel := menuKey != "" ? "`t" menuKey : ""
    treeEditLabel := treeHotKey1 != "" ? "`t" treeHotKey1 : ""
    treeIniLabel := treeIniHotKey1 != "" ? "`t" treeIniHotKey1 : ""
    evLabel := evKey != "" ? "`t" evKey : ""
    oneLabel := oneKey != "" ? "`t" oneKey : ""
    plcLabel := pluginsHK != "" ? "`t" pluginsHK : ""
    rcLabel := runCtrlHK != "" ? "`t" runCtrlHK : ""
    setLabel := setHK != "" ? "`t" setHK : ""
    rldLabel := reloadHK != "" ? "`t" reloadHK : ""
    susLabel := suspendHK != "" ? "`t" suspendHK : ""
    extLabel := exitHK != "" ? "`t" exitHK : ""

    A_TrayMenu.Add("显示菜单(&Z)" menuKeyLabel, (*) => TrayModifierClick())
    A_TrayMenu.Add("修改菜单(&E)" treeEditLabel, (*) => MenuEditor.Show(INI_PATH))
    A_TrayMenu.Add("修改文件(&F)" treeIniLabel, (*) => Run("notepad.exe " INI_PATH))

    ; V1 的 Menu Tray Click 1 效果：单击托盘图标直接显示菜单
    A_TrayMenu.Default := "显示菜单(&Z)" menuKeyLabel
    A_TrayMenu.ClickCount := 1

    A_TrayMenu.Add()

    if g_Menu2Active {
        menu2Key := ConfigReader.ReadSetting("MenuKey2", "")
        menu2Label := menu2Key != "" ? "`t" menu2Key : ""
        treeHotKey2 := ConfigReader.ReadSetting("TreeHotKey2", "")
        treeIniHotKey2 := ConfigReader.ReadSetting("TreeIniHotKey2", "")
        A_TrayMenu.Add("显示菜单2(&2)" menu2Label, (*) => ShowMenu2())
        A_TrayMenu.Add("修改菜单2(&W)" (treeHotKey2 != "" ? "`t" treeHotKey2 : ""), (*) => MenuEditor.Show(INI2_PATH))
        A_TrayMenu.Add("修改文件2(&G)" (treeIniHotKey2 != "" ? "`t" treeIniHotKey2 : ""), (*) => Run("notepad.exe " INI2_PATH))
        A_TrayMenu.Add()
    }

    
    A_TrayMenu.Add("插件管理(&C)" plcLabel, (*) => PluginManager.ShowGui())
    A_TrayMenu.Add("启动管理(&Q)" rcLabel, (*) => RunCtrlGui.Show())
    A_TrayMenu.Add("菜单列表(&T)", (*) => ShowMenuList())
    A_TrayMenu.Add()

    A_TrayMenu.Add("设置 " APP_NAME "(&D)" setLabel, (*) => SettingsGui.Show())
    A_TrayMenu.Add("检查更新(&U)", CheckUpdate)
    A_TrayMenu.Add("关于 " APP_NAME "(&A)", AboutHandler)
    A_TrayMenu.Add()

    A_TrayMenu.Add("重启(&R)" rldLabel, (*) => SafeReload())
    A_TrayMenu.Add("停用(&S)" susLabel, ToggleSuspend)
    A_TrayMenu.Add("退出(&X)" extLabel, (*) => ExitApp())

    ; ═══ Tab9 / V1 托盘图标 ═══
    ; 主图标配置（Tab9 可自定义）
    anyIcon := IconLoader.ReadCustomIcon("AnyIcon", "shell32.dll", IconLoader.Shell32Index["run"])
    menuIcon := IconLoader.ReadCustomIcon("MenuIcon", "shell32.dll", IconLoader.Shell32Index["edit"])
    treeIcon := IconLoader.ReadCustomIcon("TreeIcon", "shell32.dll", IconLoader.Shell32Index["category"])
    ; 辅助图标（V1 默认值，Tab9 不可见但保留 ReadCustomIcon 供高级用户 INI 配置）
    zzIcon := IconLoader.ReadCustomIcon("ZzIcon", "shell32.dll", 194)       ; 显示菜单
    editIcon := IconLoader.ReadCustomIcon("EditFileIcon", "shell32.dll", 134) ; 修改文件
    plgIcon := IconLoader.ReadCustomIcon("PluginsManageIcon", "shell32.dll", 166)
    rcIcon := IconLoader.ReadCustomIcon("RunCtrlManageIcon", "shell32.dll", 25)
    traySize := IconLoader.ReadTrayIconSize()

    TraySetIcon(anyIcon.path, anyIcon.index)

    SetTI(name, icon) {
        try {
            if traySize > 0 {
                A_TrayMenu.SetIcon(name, icon.path, icon.index, traySize)
            } else {
                A_TrayMenu.SetIcon(name, icon.path, icon.index)
            }
        }
    }

    SetTI("显示菜单(&Z)" menuKeyLabel, zzIcon)
    SetTI("修改菜单(&E)" treeEditLabel, treeIcon)
    SetTI("修改文件(&F)" treeIniLabel, editIcon)
    if g_Menu2Active {
        SetTI("显示菜单2(&2)" menu2Label, zzIcon)
        SetTI("修改菜单2(&W)" (treeHotKey2 != "" ? "`t" treeHotKey2 : ""), treeIcon)
        SetTI("修改文件2(&G)" (treeIniHotKey2 != "" ? "`t" treeIniHotKey2 : ""), editIcon)
    }
    SetTI("菜单列表(&T)", {path: "imageres.dll", index: 112})  ; V1 写死
    SetTI("插件管理(&C)" plcLabel, plgIcon)
    SetTI("启动管理(&Q)" rcLabel, rcIcon)
    SetTI("设置 " APP_NAME "(&D)" setLabel, menuIcon)
    SetTI("关于 " APP_NAME "(&A)", anyIcon)
}

OneKeySearch(getZz := "") {
    if getZz = ""
        getZz := GetSelectedText()
    OneKeySearchText(getZz)
}

OneKeySearchText(getZz) {
    if getZz = "" {
        ToolTip("请先选中文字再搜索")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    urls := ConfigReader.ReadSetting("OneKeyUrl", "https://www.baidu.com/s?wd=%s")
    Loop Parse urls, "|" {
        url := StrReplace(A_LoopField, "%s", ConfigReader.UrlEncode(getZz))
        url := StrReplace(url, "%S", ConfigReader.UrlEncode(getZz))
        url := StrReplace(url, "%getZz%", getZz)
        try Run(url)
    }
}

; ===== 热键回调函数（顶级命名函数，避免闭包解析问题）=====
; AHK v2 中，Hotkey() 对直接捕获全局变量的内联 fat arrow 可能解析失败
; 使用命名函数 + global 声明是最兼容的方式
_CB_MenuKey(*) {
    global g_MenuBuilder
    g_MenuBuilder.ShowMenu()
}
_CB_MenuKey2(*) {
    global g_Menu2Builder
    g_Menu2Builder.ShowMenu()
}
_CB_MenuNoGet(*) {
    global g_MenuBuilder
    g_MenuBuilder.ShowMenu(true)
}
_CB_TreeEditor(*) {
    global INI_PATH
    MenuEditor.Show(INI_PATH)
}
_CB_TreeIniEditor(*) {
    global INI_PATH
    Run("notepad.exe " INI_PATH)
}
_CB_TreeEditor2(*) {
    global INI2_PATH
    MenuEditor.Show(INI2_PATH)
}
_CB_TreeIniEditor2(*) {
    global INI2_PATH
    Run("notepad.exe " INI2_PATH)
}
_CB_TrayMenu(*) {
    A_TrayMenu.Show()
}
_CB_EverythingSearch(*) {
    EverythingSearch.Show()
}
_CB_OneKeySearch(*) {
    OneKeySearch()
}
_CB_PluginManager(*) {
    PluginManager.ShowGui()
}
_CB_RunCtrlManager(*) {
    RunCtrlGui.Show()
}
_CB_SettingsGui(*) {
    SettingsGui.Show()
}
_CB_ReloadApp(*) {
    SafeReload()
}
_CB_ExitApp(*) {
    ExitApp()
}
_CB_PauseAllPlugins(*) {
    PluginManager.PauseAll()
}
_CB_SuspendAllPlugins(*) {
    PluginManager.SuspendAll()
}
_CB_CloseAllPlugins(*) {
    PluginManager.CloseAll()
}

CheckUpdate(*) {
    repoUrl := "https://github.com/shipeng174-avatar/Runany-v2"
    tmpCurrent := A_Temp "\runany_current_commit.txt"
    tmpLatest := A_Temp "\runany_latest_commit.txt"
    try FileDelete(tmpCurrent)
    try FileDelete(tmpLatest)

    try {
        RunWait(A_ComSpec ' /c git -C "' A_ScriptDir '" rev-parse HEAD > "' tmpCurrent '" 2>nul',, "Hide")
        RunWait(A_ComSpec ' /c git -C "' A_ScriptDir '" ls-remote origin HEAD > "' tmpLatest '" 2>nul',, "Hide")
        current := Trim(FileRead(tmpCurrent))
        latestLine := Trim(FileRead(tmpLatest))
        latest := latestLine != "" ? StrSplit(latestLine, A_Tab)[1] : ""
        if current != "" && latest != "" {
            if current = latest {
                MsgBox("当前已是最新版本。`n`n" SubStr(current, 1, 12), APP_NAME " 检查更新", 64)
            } else if MsgBox("发现远端新提交。`n`n当前: " SubStr(current, 1, 12)
                "`n远端: " SubStr(latest, 1, 12) "`n`n是否打开仓库页面？", APP_NAME " 检查更新", 0x24) = "Yes" {
                Run(repoUrl)
            }
            return
        }
    }

    if MsgBox("无法自动检查远端版本。`n`n是否打开仓库页面手动查看？", APP_NAME " 检查更新", 0x24) = "Yes"
        Run(repoUrl)
}

; 顶级函数 — HotIf 使用 fat arrow 匿名函数，避免闭包内引用全局函数时解析失败
TryRegHotkey(key, cb, winKey := false, disableCheck := false) {
    if key = ""
        return ""
    ; 反引号/波浪键 → 使用硬件扫描码 sc029，避免 AHK 转义字符解释歧义
    if (key == "``")
        key := "sc029"
    hkStr := (winKey ? "#" : "") key
    if disableCheck {
        ; 用就地匿名函数测试 HotIf 是否接受回调
        try
            HotIf((*) => !WinActive("ahk_group DisableGUI"))
        catch as hotifErr
            return hkStr " [HotIf_λ] " hotifErr.Message "`n"
    }
    try {
        Hotkey(hkStr, cb, "On")
    } catch as hotkeyErr {
        if disableCheck
            try HotIf()
        return hkStr " [Hotkey] " hotkeyErr.Message "`n"
    }
    if disableCheck
        HotIf()
    return ""
}

RegisterConfigHotkeys() {
    menuKey := ConfigReader.ReadSetting("MenuKey", "")
    menuWinKey := ConfigReader.ReadSetting("MenuWinKey", "0") = "1"
    ; First-run: no MenuKey in config → default to Win+`
    if menuKey = "" {
        menuKey := "``"
        menuWinKey := true
    }
    menuKey2 := ConfigReader.ReadSetting("MenuKey2", "")
    menuWinKey2 := ConfigReader.ReadSetting("MenuWinKey2", "0") = "1"
    menuNoGetKey := ConfigReader.ReadSetting("MenuNoGetKey", "")
    menuNoGetWinKey := ConfigReader.ReadSetting("MenuNoGetWinKey", "0") = "1"
    treeHotKey1 := ConfigReader.ReadSetting("TreeHotKey1", "")
    treeWinKey1 := ConfigReader.ReadSetting("TreeWinKey1", "0") = "1"
    treeHotKey2 := ConfigReader.ReadSetting("TreeHotKey2", "")
    treeWinKey2 := ConfigReader.ReadSetting("TreeWinKey2", "0") = "1"
    treeIniHotKey1 := ConfigReader.ReadSetting("TreeIniHotKey1", "")
    treeIniWinKey1 := ConfigReader.ReadSetting("TreeIniWinKey1", "0") = "1"
    treeIniHotKey2 := ConfigReader.ReadSetting("TreeIniHotKey2", "")
    treeIniWinKey2 := ConfigReader.ReadSetting("TreeIniWinKey2", "0") = "1"
    evKey := ConfigReader.ReadSetting("EvKey", "")
    evWinKey := ConfigReader.ReadSetting("EvWinKey", "0") = "1"
    oneKey := ConfigReader.ReadSetting("OneKey", "")
    oneWinKey := ConfigReader.ReadSetting("OneWinKey", "0") = "1"
    trayHK := ConfigReader.ReadSetting("RunATrayHotKey", "")
    trayWinKey := ConfigReader.ReadSetting("RunATrayWinKey", "0") = "1"
    pluginsHK := ConfigReader.ReadSetting("PluginsManageHotKey", "")
    pluginsWinKey := ConfigReader.ReadSetting("PluginsManageWinKey", "0") = "1"
    runCtrlHK := ConfigReader.ReadSetting("RunCtrlManageHotKey", "")
    runCtrlWinKey := ConfigReader.ReadSetting("RunCtrlManageWinKey", "0") = "1"
    setHK := ConfigReader.ReadSetting("RunASetHotKey", "")
    setWinKey := ConfigReader.ReadSetting("RunASetWinKey", "0") = "1"
    rldHK := ConfigReader.ReadSetting("RunAReloadHotKey", "")
    rldWinKey := ConfigReader.ReadSetting("RunAReloadWinKey", "0") = "1"
    susHK := ConfigReader.ReadSetting("RunASuspendHotKey", "")
    susWinKey := ConfigReader.ReadSetting("RunASuspendWinKey", "0") = "1"
    extHK := ConfigReader.ReadSetting("RunAExitHotKey", "")
    extWinKey := ConfigReader.ReadSetting("RunAExitWinKey", "0") = "1"
    pauseAllHK := ConfigReader.ReadSetting("PluginsAlonePauseHotKey", "")
    pauseAllWinKey := ConfigReader.ReadSetting("PluginsAlonePauseWinKey", "0") = "1"
    suspendAllHK := ConfigReader.ReadSetting("PluginsAloneSuspendHotKey", "")
    suspendAllWinKey := ConfigReader.ReadSetting("PluginsAloneSuspendWinKey", "0") = "1"
    closeAllHK := ConfigReader.ReadSetting("PluginsAloneCloseHotKey", "")
    closeAllWinKey := ConfigReader.ReadSetting("PluginsAloneCloseWinKey", "0") = "1"

    hkErrors := ""

    ; V1 兼容：自动排除的程序列表（热键在这些程序窗口内不生效）
    disableApps := ConfigReader.ReadSetting("DisableApp", "")
    if disableApps != "" {
        Loop Parse disableApps, "," {
            exeName := Trim(A_LoopField)
            if exeName != ""
                GroupAdd("DisableGUI", "ahk_exe " exeName)
        }
    }

    ; 使用顶级命名函数（非 fat arrow 闭包），确保 Hotkey() 正确接收
    hkErrors .= TryRegHotkey(menuKey, _CB_MenuKey, menuWinKey, true)
    hkErrors .= TryRegHotkey(menuKey2, _CB_MenuKey2, menuWinKey2, true)
    hkErrors .= TryRegHotkey(menuNoGetKey, _CB_MenuNoGet, menuNoGetWinKey, true)
    hkErrors .= TryRegHotkey(treeHotKey1, _CB_TreeEditor, treeWinKey1, true)
    if FileExist(INI2_PATH)
        hkErrors .= TryRegHotkey(treeHotKey2, _CB_TreeEditor2, treeWinKey2, true)
    hkErrors .= TryRegHotkey(treeIniHotKey1, _CB_TreeIniEditor, treeIniWinKey1)
    if FileExist(INI2_PATH)
        hkErrors .= TryRegHotkey(treeIniHotKey2, _CB_TreeIniEditor2, treeIniWinKey2)
    hkErrors .= TryRegHotkey(evKey, _CB_EverythingSearch, evWinKey, true)
    hkErrors .= TryRegHotkey(oneKey, _CB_OneKeySearch, oneWinKey, true)
    hkErrors .= TryRegHotkey(trayHK, _CB_TrayMenu, trayWinKey)
    hkErrors .= TryRegHotkey(pluginsHK, _CB_PluginManager, pluginsWinKey)
    hkErrors .= TryRegHotkey(runCtrlHK, _CB_RunCtrlManager, runCtrlWinKey)
    hkErrors .= TryRegHotkey(setHK, _CB_SettingsGui, setWinKey)
    hkErrors .= TryRegHotkey(rldHK, _CB_ReloadApp, rldWinKey)
    hkErrors .= TryRegHotkey(susHK, ToggleSuspend, susWinKey)
    hkErrors .= TryRegHotkey(extHK, _CB_ExitApp, extWinKey)
    hkErrors .= TryRegHotkey(pauseAllHK, _CB_PauseAllPlugins, pauseAllWinKey)
    hkErrors .= TryRegHotkey(suspendAllHK, _CB_SuspendAllPlugins, suspendAllWinKey)
    hkErrors .= TryRegHotkey(closeAllHK, _CB_CloseAllPlugins, closeAllWinKey)

    if hkErrors != "" {
        ToolTip("热键注册失败:`n" hkErrors)
        SetTimer(() => ToolTip(), -5000)
        ; 同时写入错误日志方便诊断
        try FileAppend("[" A_YYYY "-" A_MM "-" A_DD " " A_Hour ":" A_Min ":" A_Sec "]`n" hkErrors, A_ScriptDir "\RunAny_error.log")
    }
}

ShowTrayTip(title := "", text := "", seconds := 5, options := 0) {
    try TrayTip(text, title, Integer(options))
    if seconds != "" && Integer(seconds) > 0
        SetTimer(() => TrayTip(), -Integer(seconds) * 1000)
}

SplitRemoteParams(paramStr) {
    params := []
    cur := ""
    escaped := false
    Loop Parse paramStr {
        ch := A_LoopField
        if escaped {
            cur .= ch
            escaped := false
            continue
        }
        if ch = "``" {
            escaped := true
            continue
        }
        if ch = "," {
            params.Push(ResolveRemoteParam(cur))
            cur := ""
            continue
        }
        cur .= ch
    }
    params.Push(ResolveRemoteParam(cur))
    return params
}

ResolveRemoteParam(param) {
    global g_SelectedText
    p := Trim(param)
    if StrLen(p) >= 2 && SubStr(p, 1, 1) = '"' && SubStr(p, StrLen(p), 1) = '"'
        p := SubStr(p, 2, StrLen(p) - 2)
    if p = "getZz" || p = "%getZz%"
        return g_SelectedText
    p := StrReplace(p, "```,", ",")
    p := StrReplace(p, "%getZz%", g_SelectedText)
    return ConfigReader.TransformVar(p)
}

Receive_WM_COPYDATA(wParam, lParam, *) {
    dataPtr := NumGet(lParam, 2 * A_PtrSize, "Ptr")
    if !dataPtr
        return true
    remoteRun := StrGet(dataPtr)
    Remote_Dyna_Run(remoteRun, "", true)
    return true
}

Remote_Dyna_Run(remoteRun, remoteGetZz := "", remoteFlag := false) {
    global g_MenuBuilder, g_Menu2Builder, g_SelectedText
    remoteRun := Trim(remoteRun)
    if remoteRun = ""
        return

    if remoteGetZz != ""
        g_SelectedText := remoteGetZz

    switch remoteRun {
        case "Menu_Reload":
            SafeReload()
            return
        case "Menu_Show", "Menu_Show1":
            g_MenuBuilder.ShowMenu()
            return
        case "Menu_Show2":
            ShowMenu2()
            return
        case "Menu_Tray":
            A_TrayMenu.Show()
            return
        case "Settings_Gui":
            SettingsGui.Show()
            return
        case "Plugins_Gui":
            PluginManager.ShowGui()
            return
        case "RunCtrl_Manage_Gui":
            RunCtrlGui.Show()
            return
        case "Check_Update":
            CheckUpdate()
            return
    }

    if RegExMatch(remoteRun, "iS)^runany\[(.+?)\]\((.*)\)$", &m) {
        funcName := m[1]
        params := SplitRemoteParams(m[2])
        if funcName = "Remote_Menu_Run" {
            Remote_Menu_Run(params.Length >= 1 ? params[1] : "", params.Length >= 2 ? params[2] : "")
        } else if funcName = "Remote_Menu_Ext_Show" {
            Remote_Menu_Ext_Show(params.Length >= 1 ? params[1] : "")
        } else if funcName = "ShowTrayTip" {
            ShowTrayTip(params.Length >= 1 ? params[1] : "", params.Length >= 2 ? params[2] : ""
                , params.Length >= 3 ? params[3] : 5, params.Length >= 4 ? params[4] : 0)
        } else {
            try {
                fn := Func(funcName)
                fn.Call(params*)
            }
        }
        return
    }

    if RegExMatch(remoteRun, "S).+?\[.+?\]%?\(.*?\)") {
        fakeItem := MenuItem(remoteRun, remoteRun, ItemMode.PLUGIN, remoteRun, "", remoteRun)
        Launcher.RunPlugin(fakeItem)
        return
    }

    Remote_Menu_Run(remoteRun, remoteGetZz)
}

Remote_Menu_Run(remoteRun, remoteGetZz := "") {
    global g_MenuBuilder, g_Menu2Builder, g_SelectedText
    if remoteGetZz != ""
        g_SelectedText := remoteGetZz
    item := ""
    try item := g_MenuBuilder.FindItemByName(remoteRun)
    if !item && IsObject(g_Menu2Builder)
        try item := g_Menu2Builder.FindItemByName(remoteRun)
    if item {
        Launcher.RunItem(item)
    } else {
        try Run(ConfigReader.TransformVar(remoteRun))
    }
}

Remote_Menu_Ext_Show(fileExt) {
    global g_MenuBuilder
    fileExt := Trim(RegExReplace(fileExt, "^\."), " `t`r`n")
    if fileExt = ""
        return
    if fileExt = "public" && g_MenuBuilder.publicCategories.Length > 0 {
        menuObj := g_MenuBuilder.FindCategoryMenu(g_MenuBuilder.publicCategories[1], "file")
        if !menuObj
            menuObj := g_MenuBuilder.FindCategoryMenu(g_MenuBuilder.publicCategories[1])
        if menuObj
            g_MenuBuilder.Show(menuObj)
        return
    }
    if g_MenuBuilder.extMap.Has(fileExt) {
        cat := g_MenuBuilder.extMap[fileExt]
        menuObj := g_MenuBuilder.FindCategoryMenu(cat.Name, "file")
        if !menuObj
            menuObj := g_MenuBuilder.FindCategoryMenu(cat.Name)
        if menuObj
            g_MenuBuilder.Show(menuObj)
    }
}

ShowMenuList() {
    global g_MenuBuilder

    ; Collect all items from all categories recursively
    allItems := []
    ShowMenuList_CollectAll(g_MenuBuilder.categories, allItems)

    g := Gui("+Resize", APP_NAME " 所有菜单运行项")
    g.SetFont("s10", "Microsoft YaHei")

    lv := g.AddListView("xm w1000 r30 grid AltSubmit", ["菜单项名", "全局热键", "热字符串", "管理员", "透明度", "菜单运行路径"])

    ; Create ImageList with DPI-aware icon size
    iconCx := DllCall("User32\GetSystemMetrics", "Int", 49, "Int")  ; SM_CXSMICON
    iconCy := DllCall("User32\GetSystemMetrics", "Int", 50, "Int")  ; SM_CYSMICON
    hIL := DllCall("comctl32.dll\ImageList_Create", "Int", iconCx, "Int", iconCy, "UInt", 0x21, "Int", 50, "Int", 10, "Ptr")
    stdPhrase  := IL_Add(hIL, "shell32.dll", 71)
    IL_Add(hIL, "shell32.dll", 2)       ; idx 2 - typing
    stdExe     := IL_Add(hIL, "shell32.dll", 3)
    stdFolder  := IL_Add(hIL, "shell32.dll", 5)
    IL_Add(hIL, "shell32.dll", 4)       ; idx 5 - category
    stdUrl     := IL_Add(hIL, "shell32.dll", 14)
    stdHotkey  := IL_Add(hIL, "shell32.dll", 100)
    stdAhkHk   := IL_Add(hIL, "shell32.dll", 101)
    stdPlugin  := IL_Add(hIL, "shell32.dll", 70)
    stdFail    := IL_Add(hIL, "shell32.dll", 124)

    exeIconCache := Map()

    ; LVM_SETIMAGELIST = 0x1003, LVSIL_SMALL = 1
    DllCall("User32\SendMessageW", "Ptr", lv.Hwnd, "UInt", 0x1003, "Ptr", 1, "Ptr", hIL)

    lv.Opt("-Redraw")

    for item in allItems {
        displayText := item.DisplayText

        ; Extract transparency _:NN from display name
        transNum := ""
        if RegExMatch(displayText, "_:(\d{1,2})$", &mT) {
            transNum := mT[1]
            displayText := RegExReplace(displayText, "_:\d{1,2}$")
        }

        ; Extract hotstring :opts:trigger from display name
        hotStrShow := ""
        if RegExMatch(displayText, ":[*?a-zA-Z0-9]+?:[^:]*", &mHS) {
            hotstr := mHS[0]
            hotStrShow := RegExReplace(hotstr, "^:[^:]*?X[^:]*?:")
            temp := RegExReplace(displayText, "^([^:]*?):[*?a-zA-Z0-9]+?:[^:]*", "$1")
            if temp != ""
                displayText := temp
        }

        ; Extract admin [#] from display name
        isAdmin := ""
        if RegExMatch(displayText, "\[#\]$") {
            isAdmin := "是"
            displayText := RegExReplace(displayText, "\[#\]$")
        }

        ; Determine icon based on item mode
        iconIdx := stdExe
        switch item.Mode {
            case ItemMode.PHRASE, ItemMode.TYPING_PHRASE:
                iconIdx := stdPhrase
            case ItemMode.HOTKEY:
                iconIdx := stdHotkey
            case ItemMode.AHK_HOTKEY:
                iconIdx := stdAhkHk
            case ItemMode.URL:
                webIcon := IconLoader.GetWebIcon(item.RunPath, displayText)
                if webIcon {
                    iconIdx := ShowMenuList_AddExeIcon(hIL, webIcon.path, webIcon.index, exeIconCache)
                } else
                    iconIdx := stdUrl
            case ItemMode.EXE_URL:
                exeIcon := IconLoader.GetExeIcon(item)
                if exeIcon
                    iconIdx := ShowMenuList_AddExeIcon(hIL, exeIcon.path, exeIcon.index, exeIconCache)
                else
                    iconIdx := stdUrl
            case ItemMode.FOLDER:
                iconIdx := stdFolder
            case ItemMode.PLUGIN:
                iconIdx := stdPlugin
            case ItemMode.PROGRAM:
                exeIcon := IconLoader.GetExeIcon(item)
                if exeIcon
                    iconIdx := ShowMenuList_AddExeIcon(hIL, exeIcon.path, exeIcon.index, exeIconCache)
                else
                    iconIdx := stdFail
            default:
                iconIdx := stdExe
        }

        lv.Add("Icon" iconIdx, displayText, item.Hotkey, hotStrShow, isAdmin, transNum, item.RunPath)
    }

    lv.Opt("+Redraw")
    lv.ModifyCol()
    lv.ModifyCol(1, 200)
    lv.ModifyCol(1, "Sort")
    lv.ModifyCol(6, 400)

    g.OnEvent("Close", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.OnEvent("Size", (guiObj, minMax, w, h) => MenuList_OnSize(guiObj, minMax, w, h, lv))
    g.Show()
}

ShowMenuList_AddExeIcon(hIL, path, index, cache) {
    key := path "," index
    if cache.Has(key)
        return cache[key]
    try {
        idx := IL_Add(hIL, path, index > 0 ? index + 1 : 1)
        if idx = 0
            return 0
        cache[key] := idx
        return idx
    } catch {
        return 0
    }
}

ShowMenuList_CollectAll(categories, result) {
    for cat in categories {
        for item in cat.Items {
            if item.Mode != ItemMode.SEPARATOR
                result.Push(item)
        }
        if cat.Children.Length > 0
            ShowMenuList_CollectAll(cat.Children, result)
    }
}

MenuList_OnSize(guiObj, minMax, w, h, lv) {
    if minMax = -1
        return
    try lv.Move(, , w - 20, h - 20)
}

ShowMenu2() {
    if !g_Menu2Active || !g_Menu2Builder
        return
    try {
        g_Menu2Builder.ShowMenu()
    } catch as e {
        MsgBox("显示菜单2出错:`n" e.Message, APP_NAME, 48)
    }
}

TrayModifierClick() {
    if GetKeyState("Ctrl") && GetKeyState("Shift") {
        SettingsGui.Show()
        return
    }
    if GetKeyState("Shift") {
        MenuEditor.Show(INI_PATH)
        return
    }
    if GetKeyState("Ctrl") {
        Run("explorer.exe " A_ScriptDir)
        return
    }
    g_MenuBuilder.ShowMenu()
}

ToggleSuspend(*) {
    global g_Suspended
    g_Suspended := !g_Suspended
    Suspend(g_Suspended ? 1 : 0)
    
    susHK := ConfigReader.ReadSetting("RunASuspendHotKey", "")
    susLabel := susHK != "" ? "`t" susHK : ""
    menuItemName := "停用(&S)" susLabel
    
    if g_Suspended {
        try A_TrayMenu.Check(menuItemName)
    } else {
        try A_TrayMenu.Uncheck(menuItemName)
    }
        
    A_IconTip := APP_NAME " v" APP_VERSION (g_Suspended ? " [已停用]" : "")
    ToolTip(g_Suspended ? "RunAny 已停用" : "RunAny 已恢复")
    SetTimer(() => ToolTip(), -2000)
}

AboutHandler(*) {
    MsgBox(APP_NAME " v" APP_VERSION "`n`n"
        "AutoHotkey v2.0`nRunAny 核心框架重写`n`n"
        "原始 RunAny v5.8.2 by hui-Zz`n`n"
        "快捷键:`n"
        "  Win+`  显示菜单`n"
        "  Ctrl+点击  打开程序目录`n"
        "  Shift+点击  编辑菜单文件`n"
        "  Ctrl+Shift+点击  多功能菜单`n"
        "  双击Ctrl  显示菜单(可配置)`n`n"
        "托盘菜单:`n"
        "  左键  显示菜单`n"
        "  Ctrl+左键  打开脚本目录`n"
        "  Shift+左键  编辑INI", APP_NAME, 64)
}

; ===== RunCtrl 启动规则内置函数 =====

rule_boot_time() {
    return A_TickCount // 1000
}

rule_chassis_types() {
    try {
        objWMIService := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
        colChassis := objWMIService.ExecQuery("Select * from Win32_SystemEnclosure")
        for objChassis in colChassis {
            for chType in objChassis.ChassisTypes {
                return chType
            }
        }
    }
    return 0
}

rule_check_is_run(processName) {
    return ProcessExist(processName) ? true : false
}

rule_check_network(url := "https://www.baidu.com") {
    try return DllCall("Wininet.dll\InternetCheckConnectionW", "Ptr", StrPtr(url), "UInt", 0x1, "UInt", 0x0, "Int")
    return false
}

Init() {
    global g_MenuBuilder, g_RootMenu, g_RecentMax, g_EvShowExt, g_EvShowFolder
    global g_Menu2Active, g_Menu2Builder
    global g_RootMenuDefault, g_RootMenuText, g_RootMenuFile, g_SubMenuMap
    global g_textCategories, g_fileCategories
    global g_RootMenu2Default, g_RootMenu2Text, g_RootMenu2File

    tStart := A_TickCount

    ConfigReader.LoadMenuVars()

    if ConfigReader.ReadSetting("AdminRun", "0") = "1" && !A_IsAdmin {
        try Run("*RunAs " (A_IsCompiled ? A_ScriptFullPath : '"' A_AhkPath '" "' A_ScriptFullPath '"'))
        ExitApp
    }

    ExeResolver.Init()
    PathCache.Init()
    ExeResolver.StartEverything()

    g_RecentMax := Integer(ConfigReader.ReadSetting("RecentMax", "5"))
    g_EvShowExt := ConfigReader.ReadSetting("EvShowExt", "1") = "1"
    g_EvShowFolder := ConfigReader.ReadSetting("EvShowFolder", "1") = "1"

    tPlugins := A_TickCount - tStart
    t1 := A_TickCount
    iniContent := ConfigReader.ReadINI(INI_PATH)
    if iniContent = ""
        ExitApp

    parsed := MenuParser.Parse(iniContent)
    tParse := A_TickCount - t1

    RecentItems.Init()

    ; 批量预解析 EXE 路径（空过滤器全盘搜索，比逐项 Build 快 7 倍）
    t2 := A_TickCount
    ExeResolver.PreResolveAll(parsed)
    tResolve := A_TickCount - t2

    t3 := A_TickCount
    g_MenuBuilder := MenuBuilder(parsed)
    g_MenuBuilder.Build()
    tBuild := A_TickCount - t3

    g_RootMenuDefault := g_MenuBuilder.defaultRoot
    g_RootMenuText := g_MenuBuilder.textRoot
    g_RootMenuFile := g_MenuBuilder.fileRoot
    g_RootMenu := g_MenuBuilder.defaultRoot
    g_SubMenuMap := g_MenuBuilder.defaultSubMenuMap
    g_textCategories := g_MenuBuilder.textCategories
    g_fileCategories := g_MenuBuilder.fileCategories

    RegisterHotkeys(parsed)

    RegisterConfigHotkeys()

    if ConfigReader.ReadSetting("HideHotStr", "0") = "0"
        HotStrHint.ScanAndRegister(parsed)

    SetupDisableAppGroup()

    if FileExist(INI2_PATH) {
        g_Menu2Active := true
        iniContent2 := ConfigReader.ReadINI(INI2_PATH)
        if iniContent2 != "" {
            parsed2 := MenuParser.Parse(iniContent2)
            g_Menu2Builder := MenuBuilder(parsed2)
            g_Menu2Builder.Build()

            g_RootMenu2Default := g_Menu2Builder.defaultRoot
            g_RootMenu2Text := g_Menu2Builder.textRoot
            g_RootMenu2File := g_Menu2Builder.fileRoot

            RegisterHotkeys(parsed2)
        }
    }

    DoubleTap.Setup()
    MenuKeys.Setup()
    FolderHelper.SetupHotkey()

    PluginManager.Init()
    RunCtrlEngine.Read()
    RunCtrlEngine.RunEffect()

    SetupAutoReload()
    SetupTrayMenu()

    if ConfigReader.ReadSetting("HideMenuTrayIcon", "0") = "1"
        A_IconHidden := true

    ; V1 格式托盘提示：鼠标悬停显示启动计时
    adminTag := A_IsAdmin ? "[管理员]" : ""
    A_IconTip := "RunAny" adminTag
        . "`n初始化+运行插件:" Format("{:.3f}s", tPlugins / 1000)
        . "`n调用Everything搜索应用全路径:" Format("{:.3f}s", tResolve / 1000)
        . "`n菜单创建+加载+图标:" Format("{:.3f}s", tBuild / 1000)
        . "`n总加载时间:" Format("{:.3f}s", (A_TickCount - tStart) / 1000)

    return g_RootMenu
}

OnExitApp(exitReason, exitCode) {
    PluginManager.AutoClose()
}

OnQueryEndSession(wParam, lParam, *) {
    PluginManager.AutoClose()
    return true
}

try {
    OnExit(OnExitApp)
    OnMessage(0x004A, Receive_WM_COPYDATA)
    OnMessage(0x11, OnQueryEndSession)
    Init()
} catch as e {
    MsgBox("初始化出错:`n" e.Message "`n`n" e.Stack, APP_NAME, 48)
    ExitApp
}

DoBackup() {
    if ConfigReader.ReadSetting("RunABackupRule", "0") != "1"
        return
    maxBackups := Integer(ConfigReader.ReadSetting("RunABackupMax", "15"))
    fmt := ConfigReader.ReadSetting("RunABackupFormat", ".%A_Now%.bak")
    backupDir := ConfigReader.ReadSetting("RunABackupDir", "%A_ScriptDir%\RunBackup")
    backupDir := ConfigReader.TransformVar(backupDir)
    if !DirExist(backupDir)
        DirCreate(backupDir)

    fmt := ConfigReader.TransformVar(fmt)

    iniName := RegExReplace(INI_PATH, ".*\\")
    configName := RegExReplace(CONFIG_PATH, ".*\\")

    try FileCopy(INI_PATH, backupDir "\" iniName fmt, 1)
    try FileCopy(CONFIG_PATH, backupDir "\" configName fmt, 1)

    if g_Menu2Active && FileExist(INI2_PATH) {
        ini2Name := RegExReplace(INI2_PATH, ".*\\")
        try FileCopy(INI2_PATH, backupDir "\" ini2Name fmt, 1)
    }

    if maxBackups > 0 {
        files := []
        Loop Files backupDir "\*" iniName "*.bak" {
            files.Push({ name: A_LoopFileName, time: A_LoopFileTimeModified })
        }
        files := Buffer_SortByTime(files)
        while files.Length > maxBackups {
            try FileDelete(backupDir "\" files[1].name)
            files.RemoveAt(1)
        }
    }
}

Buffer_SortByTime(arr) {
    arr.Sort((a, b) => (a.time < b.time) - (a.time > b.time))
    return arr
}
