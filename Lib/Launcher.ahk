class Launcher {
    static overrideHoldKey := 0

    static SetHoldKeyOverride(holdKey) {
        Launcher.overrideHoldKey := holdKey
        SetTimer(() => Launcher.ClearHoldKeyOverride(), -1000)
    }

    static ClearHoldKeyOverride() {
        Launcher.overrideHoldKey := 0
    }

    static RunItem(item, runOptions := "") {
        path := item.RunPath
        mode := item.Mode

        if ConfigReader.ReadSetting("DebugMode", "0") = "1" {
            showTime := Integer(ConfigReader.ReadSetting("DebugModeShowTime", "8000"))
            ToolTip("运行项: " item.DisplayText "`n类型: " mode "`n路径: " path "`n原始行: " item.RawLine)
            SetTimer(() => ToolTip(), -showTime)
        }

        holdKey := Launcher.GetHoldKey()

        if holdKey = 3 {
            MultiMenu.Show(item)
            return
        }

        if holdKey = 2 && (mode = ItemMode.PROGRAM || mode = ItemMode.EXE_URL) {
            Launcher.OpenDirectory(item)
            return
        }

        if holdKey = 2 && mode = ItemMode.FOLDER {
            Launcher.OpenDirectory(item)
            return
        }

        if holdKey = 5 {
            Launcher.EditItem(item)
            return
        }

        if holdKey = 4 || holdKey = 11 {
            Launcher.RunProgram(path, item, { admin: true })
            return
        }

        if holdKey = 6 || holdKey = 31 {
            exePath := Launcher.ResolveExePath(item)
            if exePath != "" {
                A_Clipboard := exePath
                ToolTip("已复制路径")
                SetTimer(() => ToolTip(), -2000)
            }
            return
        }

        if holdKey = 7 {
            Launcher.KillProcess(item)
            return
        }

        adminRun := runOptions != "" && runOptions.HasProp("admin") ? runOptions.admin : false
        transLevel := runOptions != "" && runOptions.HasProp("transparent") ? runOptions.transparent : 100
        topmost := runOptions != "" && runOptions.HasProp("topmost") ? runOptions.topmost : false
        runWay := runOptions != "" && runOptions.HasProp("runWay") ? runOptions.runWay : ""
        killProcess := runOptions != "" && runOptions.HasProp("kill") ? runOptions.kill : false

        displayName := item.DisplayText
        if RegExMatch(displayName, "^.*?\\[#\\]")
            adminRun := true

        if RegExMatch(displayName, "_:(\\d{1,2})$", &tm)
            transLevel := Integer(tm[1])

        if killProcess && (mode = ItemMode.PROGRAM || mode = ItemMode.EXE_URL) {
            Launcher.KillProcess(item)
            return
        }

        RecentItems.Add(item)

        switch mode {
            case ItemMode.URL:
                Launcher.RunURL(path)
            case ItemMode.PHRASE:
                Launcher.RunPhrase(item)
            case ItemMode.TYPING_PHRASE:
                Launcher.RunTypingPhrase(item)
            case ItemMode.HOTKEY, ItemMode.AHK_HOTKEY:
                Launcher.RunHotkey(item)
            case ItemMode.PLUGIN:
                Launcher.RunPlugin(item)
            case ItemMode.EXE_URL:
                Launcher.RunExeUrl(item, { admin: adminRun, transparent: transLevel, topmost: topmost, runWay: runWay })
            case ItemMode.FOLDER:
                Launcher.RunFolder(path)
            default:
                if !adminRun && transLevel >= 100 && !topmost && runWay = ""
                    Launcher.RunOrActivate(path, item)
                else
                    Launcher.RunProgram(path, item, { admin: adminRun, transparent: transLevel, topmost: topmost, runWay: runWay })
        }
    }

    static GetHoldKey() {
        if Launcher.overrideHoldKey {
            hk := Launcher.overrideHoldKey
            Launcher.overrideHoldKey := 0
            return hk
        }

        holdKey := 0
        if GetKeyState("Ctrl")
            holdKey := 2
        if GetKeyState("Shift")
            holdKey := holdKey = 2 ? 3 : 5
        if GetKeyState("LWin") || GetKeyState("RWin") {
            if holdKey = 2
                holdKey := 4
            else if holdKey = 5
                holdKey := 6
            else if holdKey = 3
                holdKey := 7
        }
        return holdKey
    }

    static OpenDirectory(item) {
        exePath := Launcher.ResolveExePath(item)
        if exePath = ""
            exePath := item.RunPath
        if FolderHelper.IsActiveDialog() {
            if RegExMatch(exePath, "i).*?\.exe$") {
                SplitPath(exePath, , &dir)
                FolderHelper.NavigateDialog(dir)
            } else if InStr(FileExist(exePath), "D") {
                FolderHelper.NavigateDialog(exePath)
            }
            return
        }
        if InStr(FileExist(exePath), "D") {
            Run('explorer.exe "' exePath '"')
        } else {
            SplitPath(exePath, &fName, &fDir)
            if fDir != ""
                Run('explorer.exe "' fDir '"')
        }
    }

    static EditItem(item) {
        Run("notepad.exe " INI_PATH)
    }

    static KillProcess(item) {
        exePath := Launcher.ResolveExePath(item)
        if exePath = ""
            exePath := item.RunPath
        SplitPath(exePath, &exeName)
        if exeName != "" {
            try Run(A_ComSpec ' /C taskkill /f /im "' exeName '"',, "Hide")
        }
    }

    static ResolveExePath(item) {
        path := item.RunPath
        if RegExMatch(path, "i)^(\\\\|[A-Za-z]:\\).*?\.exe") {
            if FileExist(path)
                return path
        }
        if RegExMatch(path, "i)^(.+?\.exe)", &m) {
            resolved := ExeResolver.Find(m[1])
            if resolved != ""
                return resolved
        }
        return ""
    }

    static RunProgram(path, item := "", options := "") {
        if path = ""
            return
        path := ConfigReader.ExpandGetZz(path)
        path := Trim(path)

        if RegExMatch(path, "i)\.exe") && !RegExMatch(path, "i)^(\\\\|[A-Za-z]:\\)") && !RegExMatch(path, "i)^([\w-]+://?|www[.]).*") {
            exeMatch := RegExMatch(path, "i)^(.+?\.exe)(.*$)", &m)
            if exeMatch {
                exeName := m[1]
                params := m[2]
                resolved := ExeResolver.Find(exeName)
                if resolved != ""
                    path := '"' resolved '"' params
            }
        }

        adminRun := false
        transLevel := 100
        topmost := false
        runWay := ""

        if options {
            if options.HasProp("admin")
                adminRun := options.admin
            if options.HasProp("transparent")
                transLevel := options.transparent
            if options.HasProp("topmost")
                topmost := options.topmost
            if options.HasProp("runWay")
                runWay := options.runWay
        }

        if adminRun
            path := "*RunAs " path

        try {
            switch runWay {
                case "Min": Run(path,, "Min")
                case "Max": Run(path,, "Max")
                case "Hide": Run(path,, "Hide")
                default: Run(path)
            }

            if topmost || transLevel < 100 {
                Launcher.ApplyWindowEffects(item, transLevel, topmost)
            }
        } catch as e {
            MsgBox("运行出错:`n" path "`n`n" e.Message, APP_NAME, 48)
        }
    }

    static ApplyWindowEffects(item, transLevel, topmost) {
        exePath := ""
        if item && item.HasProp("RunPath")
            exePath := Launcher.ResolveExePath(item)
        if exePath = ""
            return
        SplitPath(exePath, &exeName)
        if exeName = ""
            return
        try {
            WinWait("ahk_exe " exeName,, 3)
        } catch
            return
        if topmost {
            try WinSetAlwaysOnTop(1, "ahk_exe " exeName)
        }
        if transLevel < 100 {
            try WinSetTransparent(Round(transLevel / 100 * 255), "ahk_exe " exeName)
        }
    }

    static RunURL(url) {
        url := ConfigReader.ExpandGetZz(url)
        url := ConfigReader.TransformVar(url)
        browserPath := ConfigReader.ReadSetting("BrowserPath", "")
        if browserPath != "" {
            browserPath := ConfigReader.TransformVar(browserPath)
            if FileExist(browserPath) {
                try Run('"' browserPath '" "' url '"')
                return
            }
        }
        opener := Launcher.GetOpenExtOpener("http")
        if opener != "" {
            try Run('"' opener '" "' url '"')
            return
        }
        try Run(url)
        catch as e {
            MsgBox("打开网址出错:`n" url "`n`n" e.Message, APP_NAME, 48)
        }
    }

    ; V1 Open_Ext_Set: INI 格式为 程序路径=后缀1 后缀2，需要反向建表
    ; 缓存：ext → program path
    static openExtCache := Map()
    static openExtCacheLoaded := false

    static LoadOpenExtCache() {
        if Launcher.openExtCacheLoaded
            return
        Launcher.openExtCacheLoaded := true
        try {
            exts := IniRead(CONFIG_PATH, "OpenExt")
            Loop Parse exts, "`n", "`r" {
                eq := InStr(A_LoopField, "=")
                if eq = 0
                    continue
                progPath := SubStr(A_LoopField, 1, eq - 1)
                extList := SubStr(A_LoopField, eq + 1)
                Loop Parse extList, A_Space {
                    extField := Trim(A_LoopField)
                    if extField = ""
                        continue
                    extField := RegExReplace(extField, "^\.", "")  ; 去前导点
                    extField := StrLower(extField)              ; 统一小写（大小写不敏感）
                    if !Launcher.openExtCache.Has(extField)
                        Launcher.openExtCache[extField] := ConfigReader.TransformVar(progPath)
                }
            }
        }
    }

    static GetOpenExtOpener(ext) {
        Launcher.LoadOpenExtCache()
        ; 标准化：去前导点 + 小写
        ext := RegExReplace(ext, "^\.", "")
        ext := StrLower(ext)
        if Launcher.openExtCache.Has(ext)
            return Launcher.openExtCache[ext]
        return ""
    }

    static RunWithOpenExt(path, item?) {
        SplitPath(path, , , &ext)  ; 修正：3个逗号取扩展名（第4参数）
        if ext = "" {
            SplitPath(path, &name)
            ext := "." name
        }
        opener := Launcher.GetOpenExtOpener(ext)
        if opener != "" {
            try Run('"' opener '" "' path '"')
            return true
        }
        opener := Launcher.GetOpenExtOpener("folder")
        if opener != "" && InStr(FileExist(path), "D") {
            try Run('"' opener '" "' path '"')
            return true
        }
        return false
    }

    static RunFolder(path) {
        path := StrReplace(path, "%getZz%", "")
        path := ConfigReader.TransformVar(path)

        if FolderHelper.IsActiveDialog() {
            FolderHelper.NavigateDialog(path)
            return
        }

        try {
            if Launcher.RunWithOpenExt(path)
                return
            if InStr(FileExist(path), "D")
                Run('explorer.exe "' path '"')
            else
                Run('explorer.exe /select,"' path '"')
        } catch as e {
            MsgBox("打开文件夹出错:`n" path "`n`n" e.Message, APP_NAME, 48)
        }
    }

    static RunOrActivate(path, item) {
        path := ConfigReader.ExpandGetZz(path)
        path := ConfigReader.TransformVar(Trim(path))
        if RegExMatch(path, "i)^(.+?\.exe)", &m) {
            exeName := m[1]
            resolved := ExeResolver.Find(exeName)
            if resolved != ""
                exeName := resolved
            SplitPath(exeName, &pureName)
            if WinExist("ahk_exe " pureName) {
                if WinActive("ahk_exe " pureName) {
                    WinMinimize("ahk_exe " pureName)
                } else {
                    WinActivate("ahk_exe " pureName)
                }
                return
            }
        }
        if !RegExMatch(path, "i)\.exe$") && Launcher.RunWithOpenExt(path, item)
            return
        Launcher.RunProgram(path, item)
    }

    static RunPhrase(item) {
        text := item.RunPath
        if SubStr(text, -1) = ";"
            text := SubStr(text, 1, -1)
        if RegExMatch(text, "S)\$") {
            text := Launcher.DecryptPhrase(StrReplace(text, "$"))
        }
        text := ConfigReader.TransformVar(text)
        text := ConfigReader.ExpandGetZz(text)
        savedClip := A_Clipboard
        A_Clipboard := text
        Sleep(50)
        Send("^v")
        Sleep(80)
        A_Clipboard := savedClip
    }

    static RunTypingPhrase(item) {
        text := item.RunPath
        ; 先去掉尾部分隔符再检查 $ 加密标记
        if SubStr(text, -1) = ";"
            text := SubStr(text, 1, -1)
        if RegExMatch(text, "S)\$")
            text := Launcher.DecryptPhrase(StrReplace(text, "$"))
        text := ConfigReader.TransformVar(text)
        text := ConfigReader.ExpandGetZz(text)
        Send("{Text}" text)
    }

    static DecryptPhrase(text) {
        encKey := ConfigReader.ReadSetting("SendStrEcKey", "")
        if encKey = ""
            return text
        try {
            result := Launcher.LocalDecrypt(text, encKey)
            if result != ""
                return result
        }
        return text
    }

    static RunHotkey(item) {
        text := item.RunPath
        len := StrLen(text)
        if SubStr(text, len - 1, 2) = "::"
            text := SubStr(text, 1, len - 2)
        else if SubStr(text, len - 2, 3) = ":::"
            text := SubStr(text, 1, len - 3)
        try {
            if item.Mode = ItemMode.AHK_HOTKEY
                SendLevel(1)
            Send(text)
            if item.Mode = ItemMode.AHK_HOTKEY
                SendLevel(0)
        } catch as e {
            MsgBox("发送热键出错:`n" text "`n`n" e.Message, APP_NAME, 48)
        }
    }

    static RunPlugin(item) {
        any := item.RunPath
        appPlugins := RegExReplace(any, "iS)(.+?)\[.+?\]%?\(.*?\)$", "$1")
        appFunc := RegExReplace(any, "iS).+?\[(.+?)\]%?\(.*?\)$", "$1")
        appParmStr := RegExReplace(any, "iS).+?\[.+?\]%?\((.*?)\)$", "$1")

        if appPlugins = "" || appFunc = "" {
            MsgBox("插件格式错误:`n" any, APP_NAME, 48)
            return
        }

        if !PluginManager.regGUID.Has(appPlugins) && appPlugins != APP_NAME {
            ToolTip("❎ 插件" appPlugins "没有找到！请检查后重启")
            SetTimer(() => ToolTip(), -8000)
            return
        }

        isDynamic := RegExMatch(any, "iS).+?\[.+?\]%\(.*?\)")
        if isDynamic {
            Launcher.DynaExprPlugin(appPlugins, appFunc, appParmStr)
            return
        }

        if appPlugins != APP_NAME {
            try {
                if !PluginManager.objRegActive.Has(appPlugins) || !PluginManager.objRegActive[appPlugins] {
                    PluginManager.objRegActive[appPlugins] := ComObjActive(PluginManager.regGUID[appPlugins])
                }
            } catch {
                TrayTip(appPlugins " 外接脚本失败，请检查是否已启动并设为自动启动")
                return
            }
        }

        appParmStr := StrReplace(appParmStr, "``,", Chr(3))
        appParms := StrSplit(appParmStr, ",")
        Loop appParms.Length {
            appParms[A_Index] := StrReplace(appParms[A_Index], Chr(3), ",")
            if RegExMatch(appParms[A_Index], 'iS)%""(.+?)""%') {
                appNoPath := RegExReplace(appParms[A_Index], 'iS)%""(.+?)""%', "$1")
                appNoPathName := RegExReplace(appNoPath, "iS)\.exe($| .*)")
                appNoPathVal := ConfigReader.TransformVar("%" appNoPath "%")
                if appNoPathVal = "%" appNoPath "%" {
                    appParms[A_Index] := RegExReplace(appParms[A_Index], 'iS)%"".+?""%', appNoPath)
                } else {
                    appParms[A_Index] := appNoPathVal
                }
            }
            appParms[A_Index] := ConfigReader.TransformVar(appParms[A_Index])
            appParms[A_Index] := ConfigReader.ExpandGetZz(appParms[A_Index])
            if A_Index = 1 && InStr(appParms[1], "%getZz%") = 0
                ToolTip("g_SelectedText=[" g_SelectedText "]`nadParms[1]=[" appParms[1] "]", -25, -25)
        }

        if appPlugins = APP_NAME {
            funcRef := Func(appFunc)
            if !funcRef {
                TrayTip("没有在 " appPlugins " 中找到 " appFunc " 函数")
                return
            }
            if appParms.Length = 0
                result := funcRef.Call()
            else if appParms.Length <= 10
                result := funcRef.Call(appParms*)
            else {
                ToolTip("❎ 参数数量最多为10个")
                SetTimer(() => ToolTip(), -8000)
                return
            }
            Launcher.SendOrShow(result)
            return
        }

        ; huiZz_Text 加解密：本地处理（参数已展开，不走 COM）
        if appPlugins = "huiZz_Text" && (appFunc = "runany_encrypt" || appFunc = "encrypt" || appFunc = "runany_decrypt" || appFunc = "decrypt") {
            Launcher.LocalCryptCall(appFunc, appParms)
            return
        }

        ; 直接通过 objRegActive 缓存
        if !PluginManager.objRegActive.Has(appPlugins) || !PluginManager.objRegActive[appPlugins] {
            try PluginManager.objRegActive[appPlugins] := ComObjActive(PluginManager.regGUID[appPlugins])
        }
        objRef := PluginManager.objRegActive[appPlugins]
        if !objRef {
            ToolTip("❎ 插件 " appPlugins " 连接失败")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        ; 先取方法引用再调用（绕过 COM 直接调用）
        if appParms.Length > 10 {
            ToolTip("❎ 参数数量最多为10个")
            SetTimer(() => ToolTip(), -8000)
            return
        }
        result := objRef.%appFunc%(appParms*)
        Launcher.SendOrShow(result)
    }

    static DynaExprPlugin(appPlugins, appFunc, appParmStr, getZz := "") {
        if getZz = ""
            getZz := g_SelectedText
        appParmStr := ConfigReader.ExpandGetZz(appParmStr)
        appParmStr := ConfigReader.TransformVar(appParmStr)
        if appPlugins != APP_NAME {
            try {
                if !PluginManager.objRegActive.Has(appPlugins) || !PluginManager.objRegActive[appPlugins] {
                    PluginManager.objRegActive[appPlugins] := ComObjActive(PluginManager.regGUID[appPlugins])
                }
                comObj := PluginManager.objRegActive[appPlugins]
                result := comObj.%appFunc%(appParmStr, getZz)
                Launcher.SendOrShow(result)
            }
        }
    }

    static SendOrShow(result) {
        if result = "" || result = 0
            return
        if result = 1
            return
        if InStr(result, "`n") || StrLen(result) > 100 {
            A_Clipboard := result
            ToolTip("已复制到剪贴板")
            SetTimer(() => ToolTip(), -2000)
        } else {
            savedClip := A_Clipboard
            A_Clipboard := result
            Sleep(50)
            Send("^v")
            Sleep(80)
            A_Clipboard := savedClip
        }
    }

    ; 本地加解密（appParms 是已展开的参数数组）
    static LocalCryptCall(appFunc, appParms) {
        p2 := appParms.Length >= 2 ? appParms[2] : ""
        MouseGetPos(&_mx, &_my)
        ToolTip("加解密调试:`n函数=" appFunc "`n参数1=[" appParms[1] "]`n参数2=[" p2 "]`n(3秒后自动继续)", _mx, _my + 20)
        Sleep(3000)
        ToolTip()
        text := appParms.Length >= 1 ? Trim(appParms[1]) : ""
        key := appParms.Length >= 2 ? Trim(appParms[2]) : ""
        if text = "" || key = "" {
            ToolTip("❎ 加密参数错误")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        result := ""
        if appFunc = "runany_encrypt" || appFunc = "encrypt"
            result := Launcher.LocalEncrypt(text, key)
        else
            result := Launcher.LocalDecrypt(text, key)
        Launcher.SendOrShow(result)
    }

    static LocalEncrypt(str, pass) {
        if !(enclen := StrPut(str, "UTF-16"))
            return "Error: Nothing to Encrypt"
        if !(passlen := StrPut(pass, "utf-8") - 1)
            return "Error: No Pass"
        enclen := Mod(enclen, 4) ? enclen : enclen - 2
        encbin := Buffer(enclen, 0)
        StrPut(str, encbin.Ptr, enclen / 2, "UTF-16")
        passlen += Mod(4 - Mod(passlen, 4), 4)
        passbin := Buffer(passlen, 0)
        StrPut(pass, passbin.Ptr, , "utf-8")
        Launcher._E_encrypt(encbin, enclen, passbin, passlen)
        ; base64 encode
        s := 0
        DllCall("crypt32\CryptBinaryToStringW", "ptr", encbin.Ptr, "uint", enclen, "uint", 1, "ptr", 0, "uint*", &s)
        out := Buffer(s * 2, 0)
        DllCall("crypt32\CryptBinaryToStringW", "ptr", encbin.Ptr, "uint", enclen, "uint", 1, "ptr", out.Ptr, "uint*", &s)
        return StrGet(out.Ptr, "utf-16")
    }

    static LocalDecrypt(str, pass) {
        if !(StrPut(str, "utf-16") * 2)
            return "Error: Nothing to Decrypt"
        if !(passlen := StrPut(pass, "utf-8") - 1)
            return "Error: No Pass"
        passlen += Mod(4 - Mod(passlen, 4), 4)
        passbin := Buffer(passlen, 0)
        StrPut(pass, passbin.Ptr, , "utf-8")
        ; base64 decode（buffer 多 2 字节放 UTF-16 null）
        s := 0
        DllCall("crypt32\CryptStringToBinaryW", "wstr", str, "uint", 0, "uint", 1, "ptr", 0, "uint*", &s, "ptr", 0, "ptr", 0)
        encbin := Buffer(s + 2, 0)
        DllCall("crypt32\CryptStringToBinaryW", "wstr", str, "uint", 0, "uint", 1, "ptr", encbin.Ptr, "uint*", &s, "ptr", 0, "ptr", 0)
        Launcher._E_decrypt(encbin, s, passbin, passlen)
        return StrGet(encbin.Ptr, "UTF-16")
    }

    ; 加解密核心算法（从 huiZz_Text 移植）
    static _E_encrypt(bin, binlen, passbin, passlen) {
        b := 0
        Loop binlen / 4 {
            n := binlen - A_Index * 4
            a := NumGet(bin.Ptr, n, "uint")
            NumPut("uint", a + b, bin.Ptr, n)
            b := (a + b) * a
        }
        Loop passlen / 4 {
            c := NumGet(passbin.Ptr, (A_Index - 1) * 4, "uint")
            b := 0
            Loop binlen / 4 {
                a := NumGet(bin.Ptr, (A_Index - 1) * 4, "uint")
                NumPut("uint", (a + b) ^ c, bin.Ptr, (A_Index - 1) * 4)
                b := (a + b) * a
            }
        }
    }

    static _E_decrypt(bin, binlen, passbin, passlen) {
        Loop passlen / 4 {
            c := NumGet(passbin.Ptr, passlen - A_Index * 4, "uint")
            b := 0
            Loop binlen / 4 {
                a := NumGet(bin.Ptr, (A_Index - 1) * 4, "uint")
                orig := (a ^ c) - b
                NumPut("uint", orig, bin.Ptr, (A_Index - 1) * 4)
                b := (orig + b) * orig
            }
        }
        b := 0
        Loop binlen / 4 {
            n := binlen - A_Index * 4
            a := NumGet(bin.Ptr, n, "uint")
            orig := a - b
            NumPut("uint", orig, bin.Ptr, n)
            b := (orig + b) * orig
        }
    }

    static BatchSearch(urlItems, getZz) {
        if ConfigReader.ReadSetting("JumpSearch", "0") != "1" {
            webList := ""
            for item in urlItems {
                name := Trim(RegExReplace(item.DisplayText, "\t.*$"))
                if name != ""
                    webList .= (webList = "" ? "" : "`n") " - " name
            }
            result := MsgBox("确定用【" getZz "】批量搜索以下网站：`n" webList
                , APP_NAME " 批量搜索", 0x21)
            if result != "OK"
                return
        }

        for item in urlItems {
            mode := item.Mode
            path := item.RunPath

            if mode = ItemMode.URL {
                expanded := StrReplace(path, "%getZz%", ConfigReader.UrlEncode(getZz))
                expanded := StrReplace(expanded, "%s", ConfigReader.UrlEncode(getZz))
                expanded := StrReplace(expanded, "%S", ConfigReader.UrlEncode(getZz))
                expanded := ConfigReader.TransformVar(expanded)
                try Run(expanded)
            } else if mode = ItemMode.EXE_URL {
                exeMatch := RegExMatch(path, "i)^(.+?\.(exe|lnk|bat|cmd|vbs|ps1|ahk)) (.+)$", &m)
                if exeMatch {
                    exePath := m[1]
                    urlPart := m[3]
                    resolved := ExeResolver.Find(exePath)
                    if resolved != ""
                        exePath := resolved
                    urlPart := StrReplace(urlPart, "%getZz%", getZz)
                    urlPart := StrReplace(urlPart, "%s", getZz)
                    urlPart := StrReplace(urlPart, "%S", ConfigReader.UrlEncode(getZz))
                    urlPart := ConfigReader.TransformVar(urlPart)
                    try Run('"' exePath '" "' urlPart '"')
                }
            }
        }
    }

    static RunExeUrl(item, options := "") {
        path := item.RunPath
        exeMatch := RegExMatch(path, "i)^(.+?\.(exe|lnk|bat|cmd|vbs|ps1|ahk)) (.+)$", &m)
        if exeMatch {
            exePath := m[1]
            urlPart := m[3]
            resolved := ExeResolver.Find(exePath)
            if resolved != ""
                exePath := resolved
            urlPart := ConfigReader.ExpandGetZz(urlPart)
            urlPart := ConfigReader.TransformVar(urlPart)
            try {
                Run('"' exePath '" "' urlPart '"')
            } catch as e {
                MsgBox("运行出错:`n" exePath " " urlPart "`n`n" e.Message, APP_NAME, 48)
            }
        } else {
            Launcher.RunProgram(item.RunPath, item, options)
        }
    }
}
