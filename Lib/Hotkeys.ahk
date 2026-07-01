global g_DisableAppGroup := ""

SetupDisableAppGroup() {
    apps := ConfigReader.ReadSetting("DisableApp", "vmware-vmx.exe,TeamViewer.exe,SunloginClient.exe")
    if apps = ""
        return
    Loop Parse apps, "," {
        exe := Trim(A_LoopField)
        if exe != "" {
            try GroupAdd("DisableGUI", "ahk_exe " exe)
        }
    }
}

IsNotDisableApp() {
    return !WinActive("ahk_group DisableGUI")
}

RegisterHotkeys(parsed) {
    SetupDisableAppGroup()
    for cat in parsed.categories {
        RegisterHotkeysInCat(cat)
    }
}

RegisterHotkeysInCat(cat) {
    for item in cat.Items {
        if item.Hotkey != "" && !MenuParser.IsHotstring(item.Hotkey) {
            try {
                cb := MakeHotkeyCallback(item)
                Hotif((*) => !WinActive("ahk_group DisableGUI"))
                Hotkey(item.Hotkey, cb, "On")
                Hotif
                g_MenuObjKey[item.Hotkey] := item
            } catch as e {
                ToolTip("热键注册失败: " item.Hotkey " - " item.DisplayText "`n" e.Message)
                SetTimer(() => ToolTip(), -5000)
            }
        }

        if MenuParser.IsHotstring(item.DisplayText) {
            hsInfo := MenuParser.GetOriginalHotstringInfo(item.DisplayText)
        } else if MenuParser.IsHotstring(item.Hotkey) {
            hsInfo := MenuParser.GetOriginalHotstringInfo(item.Hotkey)
        } else {
            hsInfo := ""
        }
        if hsInfo {
                try {
                    if hsInfo.hasX {
                        ; X hotstring - callback mode
                        if InStr(item.RunPath, "%getZz%") {
                            cb := MakeHotstringCallback(item)
                        } else {
                            cb := MakeHotstringNoGetCallback(item)
                        }
                        Hotstring(hsInfo.options hsInfo.trigger, cb)
                    } else {
                        ; Non-X hotstring - direct text replacement
                        replacement := item.RunPath
                        if item.Mode = ItemMode.TYPING_PHRASE
                            replacement := RegExReplace(replacement, ";;$")
                        else if item.Mode = ItemMode.PHRASE
                            replacement := RegExReplace(replacement, ";$")
                        else if item.Mode = ItemMode.AHK_HOTKEY
                            replacement := RegExReplace(replacement, ":::$")
                        else if item.Mode = ItemMode.HOTKEY
                            replacement := RegExReplace(replacement, "::$")
                        Hotstring(hsInfo.options hsInfo.trigger, replacement)
                    }
                } catch as e {
                    ToolTip("热字符串注册失败: " item.DisplayText "`n" e.Message)
                    SetTimer(() => ToolTip(), -5000)
                }
            }
    }

    for child in cat.Children {
        RegisterHotkeysInCat(child)
    }
}

MakeHotkeyCallback(item) {
    return (*) => OnHotkeyRun(item)
}

MakeHotstringCallback(item) {
    return (*) => OnHotstringFire(item)
}

MakeHotstringNoGetCallback(item) {
    return (*) => OnHotstringNoGetFire(item)
}

OnHotkeyRun(item) {
    global g_SelectedText, g_SelectedIsFile, g_SelectedFileExt
    g_SelectedText := GetSelectedText()
    g_SelectedFileExt := ""
    if g_SelectedIsFile {
        SplitPath(g_SelectedText, &fName, &fDir, &fExt)
        if InStr(FileExist(g_SelectedText), "D")
            fExt := "folder"
        g_SelectedFileExt := fExt
    }
    Launcher.RunItem(item)
}

OnHotstringFire(item) {
    global g_SelectedText, g_SelectedIsFile, g_SelectedFileExt
    g_SelectedText := GetSelectedText()
    g_SelectedFileExt := ""
    if g_SelectedIsFile {
        SplitPath(g_SelectedText, &fName, &fDir, &fExt)
        if InStr(FileExist(g_SelectedText), "D")
            fExt := "folder"
        g_SelectedFileExt := fExt
    }
    Launcher.RunItem(item)
}

OnHotstringNoGetFire(item) {
    Launcher.RunItem(item)
}
