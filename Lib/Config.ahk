class ConfigReader {
    static menuVarMap := Map()

    static LoadMenuVars() {
        global CONFIG_PATH
        if !FileExist(CONFIG_PATH)
            return
        ; 1) Read from [MenuVar] section (dedicated)
        try {
            keys := IniRead(CONFIG_PATH, "MenuVar")
            Loop Parse, keys, "`n" {
                eqPos := InStr(A_LoopField, "=")
                if eqPos > 0 {
                    key := Trim(SubStr(A_LoopField, 1, eqPos - 1))
                    val := Trim(SubStr(A_LoopField, eqPos + 1))
                    if key != ""
                        ConfigReader.menuVarMap[key] := val
                }
            }
        } catch {
            ; [MenuVar] section may not exist — not an error
        }
        ; 2) Read V1-style from [Config] section: MenuVar1=VarName, then read VarName value
        try {
            cfgKeys := IniRead(CONFIG_PATH, "Config")
            Loop Parse, cfgKeys, "`n" {
                line := A_LoopField
                eqPos := InStr(line, "=")
                if eqPos > 0 {
                    cfgKey := Trim(SubStr(line, 1, eqPos - 1))
                    if RegExMatch(cfgKey, "^MenuVar\d+$") {
                        varName := Trim(SubStr(line, eqPos + 1))
                        if varName != "" && !ConfigReader.menuVarMap.Has(varName) {
                            varVal := IniRead(CONFIG_PATH, "Config", varName, "")
                            if varVal != ""
                                ConfigReader.menuVarMap[varName] := varVal
                        }
                    }
                }
            }
        } catch {
            ; [Config] section may not exist — not an error
        }
    }

    static ReadINI(filePath) {
        global APP_NAME
        if !FileExist(filePath) {
            MsgBox("找不到配置文件:`n" filePath, APP_NAME, 48)
            return ""
        }
        try {
            f := FileOpen(filePath, "r", "CP0")
            if !f {
                MsgBox("无法打开配置文件:`n" filePath, APP_NAME, 48)
                return ""
            }
            content := f.Read()
            f.Close()
            return content
        } catch as e {
            MsgBox("读取配置文件出错:`n" e.Message, APP_NAME, 48)
            return ""
        }
    }

    static ReadSetting(key, default := "") {
        global CONFIG_PATH
        try {
            if !FileExist(CONFIG_PATH)
                return default
            val := IniRead(CONFIG_PATH, "Config", key, default)
            if val = ""
                return default
            return val
        } catch {
            return default
        }
    }

    static TransformVar(string) {
        if string = ""
            return string
        ; Expand custom menu variables FIRST (before system vars)
        if ConfigReader.menuVarMap.Count > 0 {
            for key in ConfigReader.menuVarMap {
                needle := "%" key "%"
                if InStr(string, needle)
                    string := StrReplace(string, needle, ConfigReader.menuVarMap[key])
            }
        }
        try {
            spo := 1
            out := ""
            while fpo := RegExMatch(string, "(%(.*?)%)|``(.)", &m, spo) {
                out .= SubStr(string, spo, fpo - spo)
                spo := fpo + StrLen(m[0])
                if m[1] {
                    try {
                        val := %m[2]%
                        out .= val
                    } catch {
                        ; Fallback: V1 configs use %AppData%, %WinDir%, etc.
                        ; AHK v2 requires A_ prefix: A_AppData, A_WinDir, etc.
                        try {
                            aVarName := "A_" m[2]
                            val := %aVarName%
                            out .= val
                        } catch {
                            out .= m[0]
                        }
                    }
                } else {
                    switch m[3] {
                        case "a": out .= "`a"
                        case "b": out .= "`b"
                        case "f": out .= "`f"
                        case "n": out .= "`n"
                        case "r": out .= "`r"
                        case "t": out .= "`t"
                        case "v": out .= "`v"
                        default: out .= m[3]
                    }
                }
            }
            return out SubStr(string, spo)
        } catch {
            return string
        }
    }

    static ExpandGetZz(path) {
        global g_SelectedText, g_SelectedIsFile
        isUrl := InStr(path, "http://") = 1 || InStr(path, "https://") = 1
        if g_SelectedText != "" {
            autoGetZzFlag := InStr(path, "%getZz%")
            if autoGetZzFlag || ConfigReader.ReadSetting("AutoGetZz", "1") = "1" {
                if isUrl {
                    ; URL 路径直接 URL 编码，不加引号
                    path := StrReplace(path, "%getZz%", ConfigReader.UrlEncode(g_SelectedText))
                } else if InStr(g_SelectedText, A_Space) && !InStr(path, '""%getZz%""') && !InStr(path, '"%getZz%"') {
                    path := StrReplace(path, "%getZz%", '"' g_SelectedText '"')
                } else {
                    path := StrReplace(path, "%getZz%", g_SelectedText)
                }
            } else {
                path := StrReplace(path, "%getZz%", g_SelectedText)
            }
        } else {
            path := StrReplace(path, "%getZz%", g_SelectedText)
        }
        path := StrReplace(path, "%Clipboard%", A_Clipboard)
        if isUrl
            path := StrReplace(path, "%s", ConfigReader.UrlEncode(g_SelectedText))
        else
            path := StrReplace(path, "%s", g_SelectedText)
        ; %S 始终 URL 编码（语义即为"编码后的选中文字"）
        path := StrReplace(path, "%S", ConfigReader.UrlEncode(g_SelectedText))
        if ConfigReader.ReadSetting("GetZzTransformVal", "0") = "1" {
            path := ConfigReader.TransformVar(path)
        }
        return path
    }

    static UrlEncode(str, enc := "UTF-8") {
        if enc = "" || str = ""
            return str
        size := StrPut(str, enc)  ; 包含空终止符的所需字节数
        buf := Buffer(size)
        StrPut(str, buf, enc)
        encoded := ""
        Loop size - 1 {  ; 排除空终止符，只编码实际文本字节
            code := NumGet(buf, A_Index - 1, "UChar")
            encoded .= "%" Format("{:02X}", code)
        }
        return encoded
    }
}
