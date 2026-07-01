class OneKeyDirect {
    ; 硬编码默认正则（V1 兼容：INI 中缺少 _Regex 时回退）
    static DefaultRegex := Map(
        "一键公式计算", "S)^[\(\)\.\s\d]*\d+\s*[+*/-]+[\(\)\.+*/-\d\s]+($|=$)",
        "一键打开文件", "S)^(\\\\|[A-Za-z]:\\).*?\\..+",
        "一键打开目录", "S)^(\\\\|[A-Za-z]:\\)",
        "一键打开网址", "iS)^([\w-]+://?|www[.]).*",
        "一键磁力链接", "iS)^magnet:\\?xt=urn:btih:.*",
    )

    ; 获取规则正则：优先 INI，缺失时回退到默认
    static GetRegex(baseName) {
        try regexVal := IniRead(CONFIG_PATH, "OneKey", baseName "_Regex", "")
        catch
            regexVal := ""
        if regexVal = "" && OneKeyDirect.DefaultRegex.Has(baseName)
            regexVal := OneKeyDirect.DefaultRegex[baseName]
        return regexVal
    }

    static Execute(getZz) {
        if getZz = ""
            return false

        try {
            rules := IniRead(CONFIG_PATH, "OneKey")
        } catch
            return false

        ; Multi-line matching: entire selection as one string
        Loop Parse rules, "`n", "`r" {
            eq := InStr(A_LoopField, "=")
            if eq = 0
                continue
            keyName := SubStr(A_LoopField, 1, eq - 1)
            if RegExMatch(keyName, "_Regex$")
                continue
            ; 从 "一键打开网址_Run" 提取基名 "一键打开网址"
            baseName := RegExReplace(keyName, "_Run$", "")
            regexVal := OneKeyDirect.GetRegex(baseName)
            if regexVal = ""
                continue
            try runCmd := IniRead(CONFIG_PATH, "OneKey", baseName "_Run", "")
            catch
                runCmd := ""
            if runCmd = ""
                runCmd := "%getZz%"  ; 无自定义命令时，直接执行匹配文本（V1兼容）

            opts := ""
            if RegExMatch(regexVal, "^(\w+?\))(.+)$", &m) {
                opts := m[1]
                regexVal := m[2]
            }

            ; Try multi-line match first (entire selection)
            if RegExMatch(getZz, opts regexVal) {
                if baseName = "一键公式计算"
                    continue  ; 让第二遍逐行处理（有正确的粘贴结果逻辑）
                runCmd := StrReplace(runCmd, "%getZz%", getZz)
                runCmd := StrReplace(runCmd, "%s", getZz)
                runCmd := StrReplace(runCmd, "%S", ConfigReader.UrlEncode(getZz))
                runCmd := ConfigReader.TransformVar(runCmd)
                OneKeyDirect.RunCommand(runCmd, getZz)
                return true
            }
        }

        ; Per-line matching for single-line patterns
        lines := StrSplit(getZz, "`n", "`r")
        calcFlag := false
        notCalcFlag := false
        calcResult := ""
        selectResult := ""
        openFlag := false

        for line in lines {
            if line = "" {
                if calcResult
                    calcResult .= "`n"
                if selectResult
                    selectResult .= "`n"
                continue
            }

            ; Formula calculation per line
            calcRegex := IniRead(CONFIG_PATH, "OneKey", "一键公式计算_Regex", "")
            if calcRegex != "" && RegExMatch(line, calcRegex) {
                formula := line
                if RegExMatch(line, "S)=$")
                    formula := RegExReplace(line, "S)=$")
                calc := OneKeyDirect.EvalExpr(formula)
                selectResult .= line
                if RegExMatch(line, "S)=$") {
                    calcFlag := true
                    selectResult .= calc
                } else {
                    calcResult .= calc "`n"
                }
                selectResult .= "`n"
                if !notCalcFlag
                    openFlag := true
                continue
            } else {
                notCalcFlag := true
            }

            ; Try per-line regex matching for each OneKey rule
            Loop Parse rules, "`n", "`r" {
                eq := InStr(A_LoopField, "=")
                if eq = 0
                    continue
                pKeyName := SubStr(A_LoopField, 1, eq - 1)
                if RegExMatch(pKeyName, "_Regex$")
                    continue
                ; 从 "一键打开网址_Run" 提取基名 "一键打开网址"
                pBaseName := RegExReplace(pKeyName, "_Run$", "")
                if pBaseName = "一键公式计算"
                    continue
                pRegex := OneKeyDirect.GetRegex(pBaseName)
                if pRegex = ""
                    continue
                try pRun := IniRead(CONFIG_PATH, "OneKey", pBaseName "_Run", "")
                catch
                    pRun := ""
                if pRun = ""
                    pRun := "%getZz%"  ; 无自定义命令时，直接执行匹配文本（V1兼容）

                pOpts := ""
                if RegExMatch(pRegex, "^(\w+?\))(.+)$", &pm) {
                    pOpts := pm[1]
                    pRegex := pm[2]
                }

                if RegExMatch(line, pOpts pRegex) {
                    ; Skip if name-specific conditions don't match
                    if pBaseName = "一键打开目录" && !InStr(FileExist(line), "D")
                        continue
                    if pBaseName = "一键打开文件" && (!FileExist(line) || InStr(FileExist(line), "D"))
                        continue

                    runCmd := StrReplace(pRun, "%getZz%", line)
                    runCmd := StrReplace(runCmd, "%s", line)
                    runCmd := StrReplace(runCmd, "%S", ConfigReader.UrlEncode(line))
                    runCmd := ConfigReader.TransformVar(runCmd)
                    OneKeyDirect.RunCommand(runCmd, line)
                    openFlag := true
                    break
                }
            }
        }

        ; Output calc results if applicable
        if calcResult {
            calcResult := RTrim(calcResult, "`n")
            MouseGetPos(&MouseX, &MouseY)
            ToolTip(calcResult, MouseX - 25, MouseY + 5)
            A_Clipboard := calcResult
            SetTimer(() => ToolTip(), calcResult = "?" ? -1000 : -3000)
        }
        if calcFlag && !notCalcFlag && selectResult {
            selectResult := RTrim(selectResult, "`n")
            savedClip := A_Clipboard
            A_Clipboard := selectResult
            Sleep(50)
            Send("^v")
            Sleep(80)
            A_Clipboard := savedClip
        }

        return openFlag
    }

    static RunCommand(runCmd, getZz := "") {
        global g_SelectedText
        if getZz != ""
            g_SelectedText := getZz
        if RegExMatch(runCmd, "iS)^runany\[.+?\]\(.*?\)$") || RegExMatch(runCmd, "S).+?\[.+?\]%?\(.*?\)") {
            Remote_Dyna_Run(runCmd, getZz, false)
            return
        }
        try Run(runCmd)
    }

    static EvalExpr(expr) {
        expr := Trim(expr)
        try {
            tmpFile := A_Temp "\runany_eval.js"
            outFile := A_Temp "\runany_eval_out.txt"
            try FileDelete(tmpFile)
            try FileDelete(outFile)
            FileAppend('WScript.echo(eval("' expr '"))', tmpFile)
            RunWait(A_ComSpec ' /c cscript //nologo "' tmpFile '" > "' outFile '"', , "Hide")
            result := FileRead(outFile)
            try FileDelete(tmpFile)
            try FileDelete(outFile)
            result := Trim(result, "`r`n ")
            if result != "" && !InStr(result, "undefined")
                return result
        }
        return ""
    }

    static EvalMultiline(expr) {
        expr := Trim(expr)
        ; 去末尾 = 号（V1 兼容）
        if RegExMatch(expr, "S)=$")
            expr := RegExReplace(expr, "S)=$")
        try {
            tmpFile := A_Temp "\runany_eval_ml.js"
            outFile := A_Temp "\runany_eval_ml_out.txt"
            try FileDelete(tmpFile)
            try FileDelete(outFile)
            ; Replace newlines with JS expression separator
            jsExpr := StrReplace(expr, "`r`n", ";")
            jsExpr := StrReplace(jsExpr, "`n", ";")
            FileAppend('WScript.echo(eval("' jsExpr '"))', tmpFile)
            RunWait(A_ComSpec ' /c cscript //nologo "' tmpFile '" > "' outFile '"', , "Hide")
            result := FileRead(outFile)
            try FileDelete(tmpFile)
            try FileDelete(outFile)
            result := Trim(result, "`r`n ")
            if result != "" && !InStr(result, "undefined")
                return result
        }
        return ""
    }
}
