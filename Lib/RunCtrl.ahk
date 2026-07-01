class RunCtrlEntry {
    name := ""
    enable := false
    noPath := true
    noMenu := true
    key := ""
    ruleLogic := true
    ruleMostRun := 0
    ruleIntervalTime := 0
    runNums := 0
    runList := []
    ruleFile := Map()
    ruleList := []

    __New(name, enable, ruleLogic, ruleMostRun, ruleIntervalTime, key) {
        this.name := name
        this.enable := enable
        this.ruleLogic := ruleLogic
        this.ruleMostRun := ruleMostRun
        this.ruleIntervalTime := ruleIntervalTime
        this.key := key

        try {
            ctrlAppsVar := IniRead(CONFIG_PATH, name "_Run")
            Loop Parse ctrlAppsVar, "`n", "`r" {
                varList := StrSplit(A_LoopField, "=",, 2)
                if varList[1] = ""
                    continue
                runObj := RunCtrlRunItem()
                runObj.path := varList[2]
                itemList := StrSplit(varList[1], "|",, 4)
                noPathStr := itemList[1]
                runObj.repeatRun := itemList.Has(2) && itemList[2] != "" ? itemList[2] : 0
                runObj.adminRun := itemList.Has(3) && itemList[3] != "" ? itemList[3] : 0
                runObj.runWay := itemList.Has(4) && itemList[4] != "" ? itemList[4] : 1
                if noPathStr = "path" {
                    this.noPath := false
                    runObj.noPath := false
                } else if noPathStr = "menu" {
                    this.noMenu := false
                }
                try {
                    runObj.lastRunTime := IniRead(RunCtrlEngine.LastTimeIni, "last_run_time", runObj.path, "")
                } catch {
                    runObj.lastRunTime := ""
                }
                this.runList.Push(runObj)
            }
        }

        try {
            ruleAppsVar := IniRead(CONFIG_PATH, name "_Rule")
            Loop Parse ruleAppsVar, "`n", "`r" {
                varList := StrSplit(A_LoopField, "=",, 2)
                itemList := StrSplit(varList[1], "|",, 3)
                if varList[1] = "" || itemList[1] = ""
                    continue
                runRuleObj := RunCtrlRunRule()
                runRuleObj.value := varList[2]
                runRuleObj.name := itemList[1]
                runRuleObj.logic := itemList.Has(2) ? itemList[2] : 1
                runRuleObj.ruleBreak := itemList.Has(3) ? itemList[3] : ""
                runRuleObj.file := RunCtrlEngine.ruleItemList.Has(itemList[1]) ? RunCtrlEngine.ruleItemList[itemList[1]] : ""
                this.ruleList.Push(runRuleObj)
                if RunCtrlEngine.ruleStatusList.Has(runRuleObj.name) && RunCtrlEngine.ruleStatusList[runRuleObj.name] {
                    pluginName := RunCtrlEngine.ruleItemList[runRuleObj.name]
                    if pluginName != ""
                        this.ruleFile[pluginName] := true
                }
            }
        }
    }
}

class RunCtrlRunItem {
    num := 0
    path := ""
    noPath := true
    repeatRun := false
    adminRun := false
    runWay := 1
    lastRunTime := ""
}

class RunCtrlRunRule {
    file := ""
    name := ""
    value := ""
    ruleBreak := ""
    logic := 1
}

class RunCtrlEngine {
    static ruleFileList := Map()
    static ruleItemList := Map()
    static ruleFuncList := Map()
    static ruleStatusList := Map()
    static ruleTypeList := Map()
    static ruleParamList := Map()
    static ruleNameStr := ""
    static runCtrlList := Map()
    static runCtrlListBoxList := []
    static runCtrlListContentList := Map()
    static runIndex := Map()
    static ruleRunFailList := Map()
    static timerRefs := Map()

    static LogicEnum := Map("eq", "相等", "ne", "不相等", "ge", "大于等于", "le", "小于等于", "gt", "大于", "lt", "小于", "regex", "正则表达式")
    static LogicOps := Map(
        "eq", (a, b) => a = b,
        "ne", (a, b) => a != b,
        "gt", (a, b) => a > b,
        "ge", (a, b) => a >= b,
        "lt", (a, b) => a < b,
        "le", (a, b) => a <= b,
        "regex", (a, b) => RegExMatch(a, b) > 0,
    )
    static RunWayList := ["启动", "置顶启动", "最小化启动", "最大化启动", "隐藏启动", "结束软件进程_启动"]

    static LastTimeIni := A_AppData "\RunAny_v2\RunCtrlLastTime.ini"

    static Read() {
        RunCtrlEngine.ruleFileList := Map()
        RunCtrlEngine.ruleItemList := Map()
        RunCtrlEngine.ruleFuncList := Map()
        RunCtrlEngine.ruleStatusList := Map()
        RunCtrlEngine.ruleTypeList := Map()
        RunCtrlEngine.ruleParamList := Map()
        RunCtrlEngine.ruleNameStr := ""

        try {
            ruleitemVar := IniRead(CONFIG_PATH, "RunCtrlRule")
            Loop Parse ruleitemVar, "`n", "`r" {
                varList := StrSplit(A_LoopField, "=",, 2)
                itemList := StrSplit(varList[1], "|",, 2)
                if varList[1] = "" || varList[2] = "" || itemList[1] = "" || itemList[2] = ""
                    continue
                RunCtrlEngine.ruleNameStr .= itemList[1] "|"
                RunCtrlEngine.ruleFuncList[itemList[1]] := itemList[2]
                RunCtrlEngine.ruleFileList[itemList[1]] := varList[2]
                SplitPath(varList[2], &fileName, &fileDir, &fileExt, &nameNotExt)
                if fileExt != ""
                    nameNotExt := RegExReplace(fileName, "\.[^.]+$")
                if varList[2] = "RunAny_v2.ahk" || varList[2] = APP_NAME ".ahk"
                    nameNotExt := "RunAny"
                RunCtrlEngine.ruleItemList[itemList[1]] := nameNotExt

                if varList[2] = "0" {
                    RunCtrlEngine.ruleTypeList[itemList[1]] := true
                    expanded := ConfigReader.TransformVar("%" itemList[2] "%")
                    RunCtrlEngine.ruleStatusList[itemList[1]] := expanded != itemList[2]
                } else {
                    RunCtrlEngine.ruleStatusList[itemList[1]] := true
                }

                if varList[2] = "0" {
                    RunCtrlEngine.ruleParamList[itemList[1]] := false
                } else {
                    RunCtrlEngine.ruleParamList[itemList[1]] := InStr(itemList[2], "(") && !InStr(itemList[2], "()")
                }
            }
        }

        if RunCtrlEngine.ruleParamList.Has("联网状态")
            RunCtrlEngine.ruleParamList["联网状态"] := true

        if RunCtrlEngine.ruleNameStr != ""
            RunCtrlEngine.ruleNameStr := SubStr(RunCtrlEngine.ruleNameStr, 1, -1)

        RunCtrlEngine.runCtrlList := Map()
        RunCtrlEngine.runCtrlListBoxList := []
        RunCtrlEngine.runCtrlListContentList := Map()

        try {
            runCtrlListVar := IniRead(CONFIG_PATH, "RunCtrlList")
            Loop Parse runCtrlListVar, "`n", "`r" {
                trimmed := Trim(A_LoopField)
                if trimmed = ""
                    continue
                varList := StrSplit(trimmed, "=",, 2)
                if varList[1] = ""
                    continue
                runCtrlName := varList[1]
                RunCtrlEngine.runCtrlListBoxList.Push(runCtrlName)
                RunCtrlEngine.runCtrlListContentList[runCtrlName] := varList[2]
                itemList := StrSplit(varList[2], "|",, 5)
                enable := itemList[1] = "1"
                logic := itemList.Has(2) ? itemList[2] : 1
                mostRun := itemList.Has(3) && itemList[3] != "" ? itemList[3] : 0
                intervalTime := itemList.Has(4) && itemList[4] != "" ? itemList[4] : 0
                key := itemList.Has(5) ? itemList[5] : ""
                RunCtrlObj := RunCtrlEntry(runCtrlName, enable, logic, mostRun, intervalTime, key)
                RunCtrlEngine.runCtrlList[runCtrlName] := RunCtrlObj
                try {
                    if enable && key != "" {
                        actualKey := key
                        if InStr(key, "#") {
                            actualKey := StrReplace(key, "#")
                        }
                        Hotkey(actualKey, (hk) => RunCtrlEngine.RunRules(RunCtrlObj, true), "On")
                    }
                }
            }
        }
    }

    static RunEffect() {
        RunCtrlEngine.ruleRunFailList := Map()
        try {
            for n, obj in RunCtrlEngine.runCtrlList {
                if !obj.enable
                    continue
                if obj.ruleMostRun != "" && obj.ruleMostRun > 0 {
                    RunCtrlEngine.runIndex[n] := 0
                    ruleTime := obj.ruleIntervalTime > 0 ? obj.ruleIntervalTime * 1000 : 1000
                    timerFunc := () => RunCtrlEngine.RunRules(obj)
                    RunCtrlEngine.timerRefs[n] := timerFunc
                    SetTimer(timerFunc, ruleTime)
                } else {
                    RunCtrlEngine.RunRules(obj)
                }
            }
            if RunCtrlEngine.ruleRunFailList.Count > 0 {
                failStr := ""
                for k in RunCtrlEngine.ruleRunFailList
                    failStr .= (failStr = "" ? "" : "`n") k
                TrayTip("规则插件脚本没有启动：`n" failStr)
            }
        } catch as e {
            MsgBox("规则判断出错:`n" e.Message, APP_NAME, 48)
        }
    }

    static RunRules(runCtrlObj, show := 0) {
        rcName := runCtrlObj.name
        try {
            effectResult := RunCtrlEngine.RuleEffect(runCtrlObj)
            if effectResult {
                for runv in runCtrlObj.runList {
                    if !runCtrlObj.noPath || !runCtrlObj.noMenu {
                        RunCtrlEngine.RunApps(runv.path, runv.noPath, runv.repeatRun, runv.adminRun, runv.runWay)
                    }
                }
            } else if show {
                ToolTip("❎ 规则验证失败")
                SetTimer(() => ToolTip(), -3000)
                if RunCtrlEngine.ruleRunFailList.Count > 0 {
                    failStr := ""
                    for k in RunCtrlEngine.ruleRunFailList
                        failStr .= (failStr = "" ? "" : "`n") k
                    TrayTip("规则插件脚本没有启动：`n" failStr)
                }
            }
        } catch as e {
            MsgBox("启动规则出错:`n规则名：" rcName "`n" e.Message, APP_NAME, 48)
        }
        if RunCtrlEngine.runIndex.Has(rcName) {
            RunCtrlEngine.runIndex[rcName]++
            if RunCtrlEngine.runIndex[rcName] >= runCtrlObj.ruleMostRun {
                if RunCtrlEngine.timerRefs.Has(rcName) {
                    try SetTimer(RunCtrlEngine.timerRefs[rcName], 0)
                }
            }
        }
    }

    static RunApps(path, noPath, repeatRun := 0, adminRun := 0, runWay := 1) {
        try {
            if noPath {
                tfPath := ConfigReader.TransformVar(Trim(path, " `t`r`n"))
                if !repeatRun && runWay != 6 && ProcessExist(tfPath)
                    return
                mode := MenuParser.GetItemMode(tfPath)
                itemObj := MenuItem(tfPath, tfPath, mode)
                Launcher.RunItem(itemObj, {
                    admin: adminRun,
                    runWay: RunCtrlEngine.RunWayList.Has(runWay) ? ["", "Min", "Max", "", "", "Hide"][runWay] : "",
                    kill: runWay = 6
                })
            } else {
                any := ConfigReader.TransformVar(path)
                SplitPath(any, &exeName, &exeDir)
                if !repeatRun && runWay != 6 && ProcessExist(exeName)
                    return
                if runWay = 6 {
                    try Run(A_ComSpec ' /C taskkill /f /im "' exeName '"',, "Hide")
                    return
                }
                runOpt := ""
                switch runWay {
                    case 2: runOpt := "Topmost"
                    case 3: runOpt := "Min"
                    case 4: runOpt := "Max"
                    case 5: runOpt := "Hide"
                }
                itemObj := MenuItem(exeName, any, ItemMode.PROGRAM)
                Launcher.RunProgram(any, itemObj, { admin: adminRun, runWay: runOpt })
            }
            RunCtrlEngine.WriteLastRunTime(path)
        } catch as e {
            MsgBox("规则启动应用出错:`n" path "`n" e.Message, APP_NAME, 48)
        }
    }

    static WriteLastRunTime(path) {
        try {
            dir := RegExReplace(RunCtrlEngine.LastTimeIni, "\\[^\\]*$")
            if !DirExist(dir)
                DirCreate(dir)
            IniWrite(A_Now, RunCtrlEngine.LastTimeIni, "last_run_time", path)
        }
    }

    static RuleEffect(runCtrlObj) {
        effectFlag := false
        ruleRunCount := 0
        rcName := runCtrlObj.name

        for ruleFile, ruleStatus in runCtrlObj.ruleFile {
            if ruleStatus && ruleFile != "0" && ruleFile != "RunAny" {
                pluginPath := PluginManager.pathList.Has(ruleFile ".ahk") ? PluginManager.pathList[ruleFile ".ahk"] : ""
                if pluginPath != "" && ProcessExist(pluginPath " ahk_class AutoHotkey") {
                    try {
                        if !PluginManager.objRegActive.Has(ruleFile) || !PluginManager.objRegActive[ruleFile] {
                            if PluginManager.regGUID.Has(ruleFile)
                                PluginManager.objRegActive[ruleFile] := ComObjActive(PluginManager.regGUID[ruleFile])
                        }
                    }
                } else {
                    RunCtrlEngine.ruleRunFailList[ruleFile] := ""
                }
            }
        }

        for rulev in runCtrlObj.ruleList {
            ruleRunCount++
            if !RunCtrlEngine.ruleFuncList.Has(rulev.name) || !RunCtrlEngine.ruleFuncList[rulev.name]
                continue
            effectResult := RunCtrlEngine.RuleResult(rulev.name, rulev.file, rulev.value)

            if RunCtrlEngine.ruleParamList.Has(rulev.name) && RunCtrlEngine.ruleParamList[rulev.name] {
                if rulev.logic = 0 || rulev.logic = "ne"
                    effectFlag := !effectResult
                else
                    effectFlag := effectResult
            } else {
                if rulev.value = "" {
                    effectFlag := (rulev.logic = 0 || rulev.logic = "ne") ? !effectResult : effectResult
                } else {
                    logicKey := rulev.logic
                    if logicKey = 1 || logicKey = 0
                        logicKey := logicKey = 1 ? "eq" : "ne"
                    effectFlag := RunCtrlEngine.LogicOps.Has(logicKey) ? RunCtrlEngine.LogicOps[logicKey](effectResult, rulev.value) : effectResult
                }
            }

            if rulev.ruleBreak {
                if !effectFlag {
                    if RunCtrlEngine.timerRefs.Has(rcName) {
                        try SetTimer(RunCtrlEngine.timerRefs[rcName], 0)
                    }
                    break
                } else {
                    continue
                }
            }

            if runCtrlObj.ruleLogic {
                if !effectFlag
                    break
            } else if effectFlag {
                break
            }
        }
        return ruleRunCount > 0 ? effectFlag : true
    }

    static RuleResult(ruleName, ruleFile, ruleValue := "") {
        effectResult := ""
        if RunCtrlEngine.ruleParamList.Has(ruleName) && RunCtrlEngine.ruleParamList[ruleName] {
            if ruleFile = "RunAny" || ruleFile = "RunAny_v2" {
                funcRef := Func(RunCtrlEngine.ruleFuncList[ruleName])
                if funcRef
                    effectResult := funcRef.Call(ruleValue)
            } else {
                appParms := StrSplit(ruleValue, "``n")
                try {
                    if !PluginManager.objRegActive.Has(ruleFile) || !PluginManager.objRegActive[ruleFile] {
                        if PluginManager.regGUID.Has(ruleFile)
                            PluginManager.objRegActive[ruleFile] := ComObjActive(PluginManager.regGUID[ruleFile])
                    }
                    if PluginManager.objRegActive.Has(ruleFile) {
                        obj := PluginManager.objRegActive[ruleFile]
                        funcName := RunCtrlEngine.ruleFuncList[ruleName]
                        effectResult := obj[funcName](appParms*)
                    }
                }
            }
        } else {
            if RunCtrlEngine.ruleTypeList.Has(ruleName) && RunCtrlEngine.ruleTypeList[ruleName] {
                effectResult := ConfigReader.TransformVar("%" RunCtrlEngine.ruleFuncList[ruleName] "%")
            } else if ruleFile = "RunAny" || ruleFile = "RunAny_v2" {
                funcRef := Func(RunCtrlEngine.ruleFuncList[ruleName])
                if funcRef
                    effectResult := funcRef.Call()
            } else {
                try {
                    if !PluginManager.objRegActive.Has(ruleFile) || !PluginManager.objRegActive[ruleFile] {
                        if PluginManager.regGUID.Has(ruleFile)
                            PluginManager.objRegActive[ruleFile] := ComObjActive(PluginManager.regGUID[ruleFile])
                    }
                    if PluginManager.objRegActive.Has(ruleFile) {
                        obj := PluginManager.objRegActive[ruleFile]
                        funcName := RunCtrlEngine.ruleFuncList[ruleName]
                        effectResult := obj[funcName]()
                    }
                }
            }
        }
        return effectResult
    }

    static RunCtrlRunIniKeyJoin(runNoPath, runRepeat, runAdminRun, runRunWay) {
        newNoPath := runNoPath ? "menu" : "path"
        newRunRepeat := runRepeat ? "|1" : "|"
        newAdminRun := runAdminRun ? "|1" : "|"
        newRunWay := (runRunWay != "" && runRunWay != "1") ? "|" runRunWay : ""
        newRunStr := (newRunRepeat = "|" && newAdminRun = "|" && newRunWay = "") ? "" : newRunRepeat newAdminRun newRunWay
        return newNoPath newRunStr
    }

    static GetKeyByVal(list, val) {
        for k, v in list {
            if v = val
                return k
        }
        for i, v in list {
            if v = val
                return i
        }
        return ""
    }

    static KnowAhkFunc(ahkPath) {
        ahkPath := ConfigReader.TransformVar(ahkPath)
        if PluginManager.pathList.Has(ahkPath)
            ahkPath := PluginManager.pathList[ahkPath]
        funcnameStr := ""
        checkPath := StrReplace(ahkPath, "%A_ScriptDir%", A_ScriptDir)
        if FileExist(checkPath) {
            getFuncNameReg := 'iS)^\t*\s*(?!if)([^\s\.,:=\(]*)\(.*?\)\t*\s*'
            Loop Read checkPath {
                if RegExMatch(A_LoopReadLine, getFuncNameReg "\{") {
                    funcnameStr .= RegExReplace(A_LoopReadLine, getFuncNameReg "\{", "$1") "|"
                }
            }
            if funcnameStr != ""
                funcnameStr := SubStr(funcnameStr, 1, -1)
        }
        return funcnameStr
    }
}
