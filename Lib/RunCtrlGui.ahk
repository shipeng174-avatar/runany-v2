class RunCtrlGui {
    static guiObj := ""
    static listBox := ""
    static lv := ""
    static lastSel := ""

    static Show() {
        RunCtrlEngine.Read()
        try {
            if RunCtrlGui.guiObj && RunCtrlGui.guiObj.Hwnd && WinExist("ahk_id " RunCtrlGui.guiObj.Hwnd) {
                RunCtrlGui.guiObj.Show()
                return
            }
        } catch {
            RunCtrlGui.guiObj := ""
        }

        g := Gui("+Resize", "RunCtrl 启动管理 " APP_VERSION " (双击修改，右键操作)")
        g.SetFont("s10", "Microsoft YaHei")

        listVar := ""
        for v in RunCtrlEngine.runCtrlListBoxList
            listVar .= v "|"
        if listVar != ""
            listVar := SubStr(listVar, 1, -1)

        listItems := listVar != "" ? StrSplit(listVar, "|") : [""]
        lb := g.AddListBox("x16 y15 w130 h400 vRunCtrlListBox", listItems)
        lb.OnEvent("DoubleClick", (lbCtrl, item) => RunCtrlGui.EditGroup())
        RunCtrlGui.listBox := lb

        lv := g.AddListView("x+15 y15 w570 r15 grid AltSubmit", ["启动项", "类型", "重复运行", "管理员运行", "运行方式", "最后运行时间"])
        lv.OnEvent("DoubleClick", (lvCtrl, item) => RunCtrlGui.EditRunItem())
        lv.OnEvent("ContextMenu", (lvCtrl, item, isRight, x, y) => RunCtrlGui.ShowContextMenu(x, y))
        RunCtrlGui.lv := lv

        mb := MenuBar()
        mb.Add("启动`tF1", (*) => RunCtrlGui.RunGroup())
        mb.Add("添加规则组`tF3", (*) => RunCtrlGui.AddGroup())
        mb.Add("添加启动应用`tF4", (*) => RunCtrlGui.AddRunItem())
        mb.Add("编辑`tF2", (*) => RunCtrlGui.EditGroup())
        mb.Add("移除`tDel", (*) => RunCtrlGui.Remove())
        mb.Add("规则管理`tF7", (*) => RunCtrlRuleManage.Show())
        mb.Add("导入`tF8", (*) => RunCtrlGui.Import())
        mb.Add("下移`tF5", (*) => RunCtrlGui.MoveDown())
        mb.Add("上移`tF6", (*) => RunCtrlGui.MoveUp())
        g.MenuBar := mb

        g.OnEvent("Close", (*) => (SetTimer(RunCtrlGui_PollSel, 0), g.Hide(), RunCtrlGui.guiObj := ""))
        g.OnEvent("Escape", (*) => (SetTimer(RunCtrlGui_PollSel, 0), g.Hide(), RunCtrlGui.guiObj := ""))
        g.OnEvent("Size", (guiObj, minMax, w, h) => RunCtrlGui.OnSize(guiObj, minMax, w, h))

        RunCtrlGui.guiObj := g

        g.OnEvent("DropFiles", (guiObj, ctrl, files, x, y) => RunCtrlGui.OnDropFiles(guiObj, ctrl, files, x, y))
        g.Show("w755")

        RunCtrlGui.lastSel := ""
        if RunCtrlEngine.runCtrlListBoxList.Length > 0 {
            lb.Choose(1)
            RunCtrlGui.RefreshLV()
        }
        SetTimer(RunCtrlGui_PollSel, 200)

        SetTimer(() => RunCtrlGui.CheckFirstUse(), -300)
    }

    static OnDropFiles(guiObj, ctrl, files, x, y) {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        
        runContent := ""
        try {
            runContent := IniRead(CONFIG_PATH, groupName "_Run")
            if runContent = "ERROR"
                runContent := ""
        } catch {
            runContent := ""
        }
        
        for file in files {
            runContent .= (runContent = "" ? "" : "`n") "path=" file
        }
        
        try IniWrite(runContent, CONFIG_PATH, groupName "_Run")
        RunCtrlEngine.Read()
        RunCtrlGui.RefreshLV()
    }

    static CheckFirstUse() {
        if RunCtrlEngine.ruleNameStr = "" || RunCtrlEngine.runCtrlListBoxList.Length = 0 {
            MsgBox('首次使用请阅读：`n1. 先点击"规则管理"后再点击"添加默认规则"`n'
                . '2. 然后返回界面点击"添加规则组"`n'
                . '3. 最后再点击"添加启动应用"`n`n'
                . '这样就可以自动根据不同规则判断来运行不同的程序了', APP_NAME, 64)
        }
    }

    static RefreshLV() {
        chosen := RunCtrlGui.listBox.Text
        if chosen = ""
            return
        lv := RunCtrlGui.lv
        lv.Delete()
        if !RunCtrlEngine.runCtrlList.Has(chosen)
            return
        rcObj := RunCtrlEngine.runCtrlList[chosen]
        for runv in rcObj.runList {
            wayIdx := runv.runWay > 0 && runv.runWay <= RunCtrlEngine.RunWayList.Length ? runv.runWay : 1
            wayStr := StrReplace(RunCtrlEngine.RunWayList[wayIdx], "启动")
            lv.Add("", runv.path
                , runv.noPath ? "菜单项" : "全路径"
                , runv.repeatRun ? "重复" : ""
                , runv.adminRun ? "管理员" : ""
                , wayStr
                , RunCtrlGui.FormatTime(runv.lastRunTime))
        }
        lv.ModifyCol()
        lv.ModifyCol(1, 245)
        lv.ModifyCol(6, 150)
    }

    static FormatTime(t) {
        if t = "" || t = " "
            return ""
        try {
            return SubStr(t, 1, 4) "-" SubStr(t, 5, 2) "-" SubStr(t, 7, 2)
                . " " SubStr(t, 9, 2) ":" SubStr(t, 11, 2) ":" SubStr(t, 13, 2)
        }
        return t
    }

    static ShowContextMenu(x, y) {
        cm := Menu()
        cm.Add("启动`tF1", (*) => RunCtrlGui.RunGroup())
        cm.Add("添加规则组`tF3", (*) => RunCtrlGui.AddGroup())
        cm.Add("添加启动应用`tF4", (*) => RunCtrlGui.AddRunItem())
        cm.Add("编辑`tF2", (*) => RunCtrlGui.EditGroup())
        cm.Add("移除`tDel", (*) => RunCtrlGui.Remove())
        cm.Add("规则管理`tF7", (*) => RunCtrlRuleManage.Show())
        cm.Add("导入`tF8", (*) => RunCtrlGui.Import())
        cm.Add("下移`tF5", (*) => RunCtrlGui.MoveDown())
        cm.Add("上移`tF6", (*) => RunCtrlGui.MoveUp())
        cm.Add("全选`tCtrl+A", (*) => RunCtrlGui.lv.Modify(0, "Select"))
        cm.Show(x, y)
    }

    static GetSelectedGroup() {
        try {
            return RunCtrlGui.listBox.Text
        }
        return ""
    }

    static RunGroup() {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        if RunCtrlEngine.runCtrlList.Has(groupName) {
            RunCtrlEngine.RunRules(RunCtrlEngine.runCtrlList[groupName], true)
        }
    }

    static AddGroup() {
        RunCtrlGroupConfig.Show("新建")
    }

    static EditGroup() {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        RunCtrlGroupConfig.Show("编辑", groupName)
    }

    static AddRunItem() {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        RunCtrlRunConfig.Show("新建", groupName)
    }

    static EditRunItem() {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        RunCtrlRunConfig.Show("编辑", groupName)
    }

    static Remove() {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        row := RunCtrlGui.lv.GetNext(0, "F")
        if row = 0 {
            result := MsgBox("确定移除规则组：" groupName "？`n【注意!】：同时会移除所有启动项和规则条件！", "确认移除", 0x23)
            if result = "Yes" {
                try IniDelete(CONFIG_PATH, "RunCtrlList", groupName)
                try IniDelete(CONFIG_PATH, groupName "_Run")
                try IniDelete(CONFIG_PATH, groupName "_Rule")
                RunCtrlGui.Show()
            }
            return
        }
        result := MsgBox("确定移除当前选中的启动项？", "确认移除", 0x23)
        if result != "Yes"
            return

        delKeys := Map()
        rowNum := 0
        loop {
            rowNum := RunCtrlGui.lv.GetNext(rowNum)
            if !rowNum
                break
            val := RunCtrlGui.lv.GetText(rowNum, 1)
            noPath := RunCtrlGui.lv.GetText(rowNum, 2) = "菜单项"
            repeat := RunCtrlGui.lv.GetText(rowNum, 3) = "重复"
            admin := RunCtrlGui.lv.GetText(rowNum, 4) = "管理员"
            way := RunCtrlEngine.GetKeyByVal(RunCtrlEngine.RunWayList, RunCtrlGui.lv.GetText(rowNum, 5) "启动")
            key := RunCtrlEngine.RunCtrlRunIniKeyJoin(!noPath, repeat, admin, way) "=" val
            delKeys[key] := true
        }

        try {
            ctrlAppsVar := IniRead(CONFIG_PATH, groupName "_Run")
            newContent := ""
            Loop Parse ctrlAppsVar, "`n", "`r" {
                if !delKeys.Has(A_LoopField)
                    newContent .= A_LoopField "`n"
            }
            if newContent != ""
                newContent := SubStr(newContent, 1, -1)
            try IniWrite(newContent, CONFIG_PATH, groupName "_Run")
        }
        RunCtrlEngine.Read()
        RunCtrlGui.RefreshLV()
    }

    static Import() {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        selectName := FileSelect("M3",, "选择多个你要导入的启动项")
        if selectName = ""
            return
        parts := StrSplit(selectName, "`n")
        runContent := ""
        dir := parts[1]
        Loop parts.Length - 1 {
            fullPath := dir "\" parts[A_Index + 1]
            runContent .= "path=" fullPath "`n"
        }
        if runContent != ""
            runContent := SubStr(runContent, 1, -1)
        try {
            existing := IniRead(CONFIG_PATH, groupName "_Run")
            if existing != ""
                runContent := existing "`n" runContent
            IniWrite(runContent, CONFIG_PATH, groupName "_Run")
        }
        RunCtrlGui.Show()
    }

    static MoveUp() {
        RunCtrlGui.SwapItems(-1)
    }
    static MoveDown() {
        RunCtrlGui.SwapItems(1)
    }

    static SwapItems(dir) {
        groupName := RunCtrlGui.GetSelectedGroup()
        if groupName = ""
            return
        row := RunCtrlGui.lv.GetNext(0, "F")
        if !row
            return
        newRow := row + dir
        if newRow < 1 || newRow > RunCtrlGui.lv.GetCount()
            return

        ; Swap text between two rows
        tmp := []
        Loop 6
            tmp.Push(RunCtrlGui.lv.GetText(row, A_Index))
        Loop 6
            RunCtrlGui.lv.Modify(row, "", RunCtrlGui.lv.GetText(newRow, A_Index))
        RunCtrlGui.lv.Modify(newRow, "", tmp*)

        ; Persist by reading INI, swapping lines, writing back
        try {
            existing := IniRead(CONFIG_PATH, groupName "_Run")
            lines := StrSplit(existing, "`n", "`r")
            tmpLine := lines[row]
            lines[row] := lines[newRow]
            lines[newRow] := tmpLine
            newContent := ""
            for l in lines
                newContent .= l "`n"
            IniWrite(RTrim(newContent, "`n"), CONFIG_PATH, groupName "_Run")
        }
        RunCtrlGui.lv.Modify(0, "-Select")
        RunCtrlGui.lv.Modify(newRow, "Select Focus")
    }

    static OnSize(guiObj, minMax, width, height) {
        if minMax = -1
            return
        try {
            RunCtrlGui.listBox.Move(,, , height - 30)
            RunCtrlGui.lv.Move(,, width - 180, height - 30)
        }
    }
}

class RunCtrlGroupConfig {
    static Show(action, groupName := "") {
        eg := Gui(, "RunCtrl 规则组 - " action " " APP_VERSION)
        eg.SetFont(, "Microsoft YaHei")
        eg.MarginX := 20
        eg.MarginY := 20

        enable := true, logic1 := true, logic2 := false
        mostRun := "", intervalTime := "", key := "", winKey := false
        ruleList := []

        if action = "编辑" && RunCtrlEngine.runCtrlList.Has(groupName) {
            rcObj := RunCtrlEngine.runCtrlList[groupName]
            enable := rcObj.enable
            logic1 := rcObj.ruleLogic
            logic2 := !logic1
            mostRun := rcObj.ruleMostRun > 0 ? rcObj.ruleMostRun : ""
            intervalTime := rcObj.ruleIntervalTime > 0 ? rcObj.ruleIntervalTime : ""
            key := rcObj.key
            if InStr(key, "#") {
                winKey := true
                key := StrReplace(key, "#")
            }
            for r in rcObj.ruleList
                ruleList.Push({ name: r.name, ruleBreak: r.ruleBreak, logic: r.logic, value: r.value })
        }

        cbEnable := eg.AddCheckBox("xm+5 y+15 Checked" (enable ? 1 : 0), "启用规则组")
        eg.AddText("x+30 yp w60", "全局热键：")
        hkCtrl := eg.AddHotkey("x+5 yp-2 w130 h22", key)
        cbWin := eg.AddCheckBox("x+10 yp+3 w55 Checked" (winKey ? 1 : 0), "Win")
        eg.AddText("xm+5 yp+30 w60", "规则组名：")
        edtName := eg.AddEdit("x+5 yp-3 w300", action = "新建" ? "" : groupName)

        eg.AddGroupBox("xm y+10 w500 h385", "规则组设置")
        rbLogic1 := eg.AddRadio("xm+10 yp+25 Checked" (logic1 ? 1 : 0), "与（全部规则都验证成立）(&A)")
        rbLogic2 := eg.AddRadio("x+10 yp Checked" (logic2 ? 1 : 0), "或（一个规则即验证成立）(&O)")

        eg.AddText("xm+10 y+15 w100", "规则循环最大次数:")
        edtMostRun := eg.AddEdit("x+2 yp-3 Number w70 h20", mostRun)
        eg.AddText("x+20 yp+3 w110", "循环间隔时间(秒):")
        edtInterval := eg.AddEdit("x+2 yp-3 w100 h20", intervalTime)

        eg.AddButton("xm+10 y+15 w85", "+ 增加规则(&A)").OnEvent("Click", (*) => RunCtrlGroupConfig.AddRule(ruleLV))
        eg.AddButton("x+10 yp w85", "· 修改规则(&E)").OnEvent("Click", (*) => RunCtrlGroupConfig.EditRule(ruleLV))
        eg.AddButton("x+10 yp w85", "- 减少规则(&D)").OnEvent("Click", (*) => RunCtrlGroupConfig.RemoveRule(ruleLV))

        eg.SetFont("s10", "Microsoft YaHei")
        ruleLV := eg.AddListView("xm+10 y+10 w480 r10 grid AltSubmit C0x808000", ["规则名", "中断", "条件", "条件值"])
        for r in ruleList {
            logicStr := RunCtrlGui_LogicStr(r.logic)
            ruleLV.Add("", r.name, r.ruleBreak, logicStr, r.value)
        }
        ruleLV.ModifyCol()
        ruleLV.OnEvent("DoubleClick", (lv, item) => RunCtrlGroupConfig.EditRule(ruleLV))

        eg.AddButton("Default xm+150 y+15 w75", "保存(&Y)").OnEvent("Click", (*) => RunCtrlGroupConfig.Save(eg, edtName, cbEnable, rbLogic1, hkCtrl, cbWin, edtMostRun, edtInterval, ruleLV, action, groupName))
        eg.AddButton("x+20 w75", "取消(&C)").OnEvent("Click", (*) => eg.Hide())
        eg.Show()
    }

    static Save(eg, edtName, cbEnable, rbLogic1, hkCtrl, cbWin, edtMostRun, edtInterval, ruleLV, action, origName) {
        name := edtName.Value
        if name = "" {
            ToolTip("请填入规则组名")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        if action = "新建" && RunCtrlEngine.runCtrlList.Has(name) {
            ToolTip("已存在相同的规则组名，请修改")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        if InStr(name, " ") {
            ToolTip("规则组名不能带有空格，请用_代替")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        if !RegExMatch(name, "^[\p{Han}A-Za-z0-9_]+$") {
            ToolTip("规则组名只能为中文、数字、字母、下划线")
            SetTimer(() => ToolTip(), -3500)
            return
        }

        enableVal := cbEnable.Value ? 1 : 0
        logicVal := rbLogic1.Value ? 1 : 0
        mostRunVal := edtMostRun.Value
        intervalVal := edtInterval.Value
        keyVal := hkCtrl.Value
        if cbWin.Value && keyVal != ""
            keyVal := "#" keyVal

        ruleContent := ""
        Loop ruleLV.GetCount() {
            rn := ruleLV.GetText(A_Index, 1)
            fb := ruleLV.GetText(A_Index, 2)
            fl := ruleLV.GetText(A_Index, 3)
            fv := ruleLV.GetText(A_Index, 4)
            logicKey := RunCtrlGui_LogicKey(fl)
            fbStr := fb ? "|" fb : ""
            ruleContent .= rn "|" logicKey fbStr "=" fv "`n"
        }
        if ruleContent != ""
            ruleContent := SubStr(ruleContent, 1, -1)

        ruleRunListVal := enableVal "|" logicVal
        if mostRunVal != ""
            ruleRunListVal .= "|" mostRunVal "|" intervalVal
        if keyVal != "" {
            if mostRunVal = ""
                ruleRunListVal .= "||"
            ruleRunListVal .= "|" keyVal
        }

        if action = "编辑" && origName != name {
            try IniDelete(CONFIG_PATH, "RunCtrlList", origName)
            try IniDelete(CONFIG_PATH, origName "_Rule")
            try IniDelete(CONFIG_PATH, origName "_Run")
        }

        try IniWrite(ruleRunListVal, CONFIG_PATH, "RunCtrlList", name)

        runContent := ""
        if action = "编辑" && RunCtrlEngine.runCtrlList.Has(origName) {
            for runv in RunCtrlEngine.runCtrlList[origName].runList {
                runContent .= RunCtrlEngine.RunCtrlRunIniKeyJoin(!runv.noPath, runv.repeatRun, runv.adminRun, runv.runWay) "=" runv.path "`n"
            }
            if runContent != ""
                runContent := SubStr(runContent, 1, -1)
        }
        try IniWrite(runContent, CONFIG_PATH, name "_Run")
        try IniWrite(ruleContent, CONFIG_PATH, name "_Rule")

        eg.Hide()
        RunCtrlGui.Show()
    }

    static AddRule(ruleLV) {
        RunCtrlRuleConfig.Show("新建规则函数", ruleLV, 0)
    }

    static EditRule(ruleLV) {
        row := ruleLV.GetNext(0, "F")
        if !row
            return
        RunCtrlRuleConfig.Show("修改规则函数", ruleLV, row)
    }

    static RemoveRule(ruleLV) {
        delList := ""
        rowNum := 0
        loop {
            rowNum := ruleLV.GetNext(rowNum)
            if !rowNum
                break
            delList := rowNum ":" delList
        }
        if delList = ""
            return
        delList := SubStr(delList, 1, -1)
        Loop Parse delList, ":"
            ruleLV.Delete(A_LoopField)
    }
}

class RunCtrlRuleConfig {
    static Show(menuItem, ruleLV, editRow) {
        ruleName := "", funcBreak := false, funcBoolean := "eq", funcValue := ""
        if editRow > 0 {
            ruleName := ruleLV.GetText(editRow, 1)
            funcBreak := ruleLV.GetText(editRow, 2) != ""
            funcBoolean := RunCtrlGui_LogicKey(ruleLV.GetText(editRow, 3))
            funcValue := ruleLV.GetText(editRow, 4)
            funcValue := StrReplace(funcValue, "``t", "`t")
            funcValue := StrReplace(funcValue, "``n", "`n")
        }

        eg := Gui(, "RunCtrl " menuItem " " APP_VERSION)
        eg.SetFont(, "Microsoft YaHei")
        eg.MarginX := 20
        eg.MarginY := 10

        eg.AddText("xm y+10 w60", "规则名：")
        nameStr := RunCtrlEngine.ruleNameStr
        ddRule := eg.AddDropDownList("xm+60 yp-3 Choose1", StrSplit(nameStr, "|"))
        if ruleName != "" {
            idx := 1
            Loop ddRule.Choose.Length {
                if ddRule.GetText(A_Index) = ruleName {
                    idx := A_Index
                    break
                }
            }
            ddRule.Choose(idx)
        }
        resultText := eg.AddText("x+10 yp+3 cblue w150", "")

        eg.AddRadio("xm y+10 Checked" (funcBoolean = "eq" ? 1 : 0) " vvFuncBooleanEQ", "相等 ( 真 &True 1 )")
        eg.AddRadio("x+4 yp Checked" (funcBoolean = "ne" ? 1 : 0) " vvFuncBooleanNE", "不相等 ( 假 &False 0 )")
        eg.AddRadio("xm y+10 Checked" (funcBoolean = "ge" ? 1 : 0) " vvFuncBooleanGE", "大于等于")
        eg.AddRadio("x+6 yp Checked" (funcBoolean = "le" ? 1 : 0) " vvFuncBooleanLE", "小于等于")
        eg.AddRadio("xm y+10 Checked" (funcBoolean = "gt" ? 1 : 0) " vvFuncBooleanGT", "大于")
        eg.AddRadio("x+6 yp Checked" (funcBoolean = "lt" ? 1 : 0) " vvFuncBooleanLT", "小于")
        eg.AddRadio("x+6 yp Checked" (funcBoolean = "regex" ? 1 : 0) " vvFuncBooleanRegEx", "正则表达式")

        cbBreak := eg.AddCheckBox("xm y+10 Checked" (funcBreak ? 1 : 0), "不满足此条件就中断整个规则循环（建议排在其他规则前面）")
        eg.AddText("xm y+10 w350", "条件值：（只判断规则真假，可不填写）")
        edtValue := eg.AddEdit("xm y+10 w350 r6", funcValue)

        eg.AddButton("Default xm+80 y+15 w75", "保存(&Y)").OnEvent("Click", (*) => RunCtrlRuleConfig.Save(eg, ddRule, cbBreak, edtValue, ruleLV, editRow, menuItem))
        eg.AddButton("x+10 w75", "取消(&C)").OnEvent("Click", (*) => eg.Hide())

        UpdateResult(*) {
            try {
                rName := ddRule.Text
                if rName != "" && RunCtrlEngine.ruleItemList.Has(rName) {
                    resultText.Value := RunCtrlEngine.RuleResult(rName, RunCtrlEngine.ruleItemList[rName], "")
                }
            }
        }
        ddRule.OnEvent("Change", UpdateResult)
        UpdateResult()

        eg.Show("w480")
    }

    static Save(eg, ddRule, cbBreak, edtValue, ruleLV, editRow, menuItem) {
        rName := ddRule.Text
        if rName = "" {
            ToolTip("请选择使用的规则")
            SetTimer(() => ToolTip(), -3000)
            return
        }

        funcValue := RTrim(edtValue.Value, "`n")
        funcValue := StrReplace(funcValue, "`t", "``t")
        funcValue := StrReplace(funcValue, "`n", "``n")

        breakStr := cbBreak.Value ? "*" : ""
        logicStr := "eq"
        for ctrl in eg {
            if ctrl.HasProp("Value") && ctrl.Value = true {
                name := ctrl.Name
                if InStr(name, "FuncBoolean") {
                    logicStr := StrReplace(StrReplace(name, "FuncBoolean", ""), "vv", "")
                    logicStr := StrReplace(logicStr, "EQ", "eq")
                    logicStr := StrReplace(logicStr, "NE", "ne")
                    logicStr := StrReplace(logicStr, "GE", "ge")
                    logicStr := StrReplace(logicStr, "LE", "le")
                    logicStr := StrReplace(logicStr, "GT", "gt")
                    logicStr := StrReplace(logicStr, "LT", "lt")
                    logicStr := StrReplace(logicStr, "RegEx", "regex")
                    break
                }
            }
        }

        eg.Hide()

        displayLogic := RunCtrlGui_LogicStr(logicStr)
        if menuItem = "修改规则函数" && editRow > 0 {
            ruleLV.Modify(editRow, "", rName, breakStr, displayLogic, funcValue)
        } else {
            ruleLV.Add("", rName, breakStr, displayLogic, funcValue)
        }
        ruleLV.ModifyCol()
    }
}

class RunCtrlRunConfig {
    static eg := ""
    static Show(action, groupName) {
        runValue := "", noPath := "menu", repeatRun := false, adminRun := false, runWay := 1

        if action = "编辑" {
            row := RunCtrlGui.lv.GetNext(0, "F")
            if !row
                return
            runValue := RunCtrlGui.lv.GetText(row, 1)
            noPath := RunCtrlGui.lv.GetText(row, 2) = "菜单项" ? "menu" : "path"
            repeatRun := RunCtrlGui.lv.GetText(row, 3) = "重复"
            adminRun := RunCtrlGui.lv.GetText(row, 4) = "管理员"
            wayStr := RunCtrlGui.lv.GetText(row, 5) "启动"
            runWay := 1
            for i, w in RunCtrlEngine.RunWayList {
                if w = wayStr {
                    runWay := i
                    break
                }
            }
        }

        eg := Gui(, "RunCtrl - " action "启动项 " APP_VERSION)
        RunCtrlRunConfig.eg := eg
        eg.SetFont(, "Microsoft YaHei")
        eg.MarginX := 20
        eg.MarginY := 20

        rb1 := eg.AddRadio("xm+10 yp+20 Checked" (noPath = "menu" ? 1 : 0), "菜单项(&Z)")
        rb2 := eg.AddRadio("x+42 yp Checked" (noPath = "path" ? 1 : 0), "全路径(&A)")

        eg.AddGroupBox("xm y+5 w410 h50")
        cbRepeat := eg.AddCheckBox("xm+10 yp+20 Checked" (repeatRun ? 1 : 0), "重复启动(&R)")
        cbAdmin := eg.AddCheckBox("x+30 yp Checked" (adminRun ? 1 : 0), "管理员启动(&G)")
        ddWay := eg.AddDropDownList("x+30 yp-3 Choose" runWay, RunCtrlEngine.RunWayList)

        eg.AddButton("xm y+20 w100 h60", "运行软件路径`n或菜单项").OnEvent("Click", (*) => RunCtrlRunConfig.Browse(rb1, edtPath))
        edtPath := eg.AddEdit("x+12 yp+1 w300 r3 -WantReturn", runValue)

        eg.AddButton("Default xm+100 y+25 w75", "保存(&Y)").OnEvent("Click", (*) => RunCtrlRunConfig.Save(eg, rb1, cbRepeat, cbAdmin, ddWay, edtPath, action, groupName, runValue, noPath, repeatRun, adminRun, runWay))
        eg.AddButton("x+20 w75", "取消(&C)").OnEvent("Click", (*) => eg.Hide())
        eg.Show()
    }

    static Browse(rb1, edtPath) {
        global g_MenuBuilder
        if rb1.Value {
            ; Show a menu item picker
            pg := Gui(, "选择菜单项")
            pg.SetFont(, "Microsoft YaHei")
            pg.MarginX := 10
            pg.MarginY := 10
            
            pg.AddText("xm y10 w380", "双击选择要关联的菜单项：")
            lv := pg.AddListView("xm y+5 w380 r15 grid -Multi", ["菜单项名称", "启动路径"])
            
            ; Collect items
            global g_MenuBuilder
            if IsSet(g_MenuBuilder) {
                items := []
                IconLoader._CollectProgramItems(g_MenuBuilder.categories, items)
                for item in items {
                    lv.Add("", item.DisplayText, item.RunPath)
                }
            }
            lv.ModifyCol(1, 150)
            lv.ModifyCol(2, 210)
            
            lv.OnEvent("DoubleClick", (ctrl, item) => (
                edtPath.Value := lv.GetText(item, 1),
                pg.Destroy()
            ))
            
            pg.Show()
        } else {
            path := FileSelect(1,, "启动程序路径")
            if path != ""
                edtPath.Value := path
        }
    }

    static Save(eg, rb1, cbRepeat, cbAdmin, ddWay, edtPath, action, groupName, origValue, origNoPath, origRepeat, origAdmin, origWay) {
        if groupName = "" {
            eg.Hide()
            return
        }
        val := edtPath.Value
        if val = "" {
            ToolTip("请填写启动项")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        if !rb1.Value && !InStr(val, ".") {
            ToolTip("全路径是直接运行，请填写正确的启动项")
            SetTimer(() => ToolTip(), -5000)
            return
        }

        isMenu := rb1.Value
        newRepeat := cbRepeat.Value
        newAdmin := cbAdmin.Value
        newWay := ddWay.Value

        oldKey := RunCtrlEngine.RunCtrlRunIniKeyJoin(origNoPath = "path", origRepeat, origAdmin, origWay) "=" origValue
        newKey := RunCtrlEngine.RunCtrlRunIniKeyJoin(!isMenu, newRepeat, newAdmin, newWay) "=" val

        if oldKey = newKey {
            eg.Hide()
            return
        }

        try {
            existing := IniRead(CONFIG_PATH, groupName "_Run")
            runContent := ""
            if action = "编辑" {
                Loop Parse existing, "`n", "`r" {
                    runContent .= (A_LoopField = oldKey ? newKey : A_LoopField) "`n"
                }
                if runContent != ""
                    runContent := SubStr(runContent, 1, -1)
            } else {
                runContent := existing != "" ? existing "`n" newKey : newKey
            }
            IniWrite(runContent, CONFIG_PATH, groupName "_Run")
        }
        eg.Hide()
        RunCtrlGui.Show()
    }
}

class RunCtrlRuleManage {
    static Show() {
        RunCtrlEngine.Read()
        eg := Gui("+Resize", "RunCtrl 规则管理 " APP_VERSION)
        eg.SetFont("s10", "Microsoft YaHei")

        lv := eg.AddListView("xm w685 r18 grid AltSubmit Background0xF6F6E8", ["规则名", "规则函数", "状态", "类型", "参数", "示例", "规则插件名"])
        for kName, kVal in RunCtrlEngine.ruleFileList {
            ruleStatus := RunCtrlEngine.ruleStatusList.Has(kName) && RunCtrlEngine.ruleStatusList[kName] ? "正常" : "未找到"
            ruleResult := ""
            if ruleStatus = "正常" {
                try {
                    ruleResult := RunCtrlEngine.RuleResult(kName, RunCtrlEngine.ruleItemList[kName], "")
                }
            }
            isVar := RunCtrlEngine.ruleTypeList.Has(kName) && RunCtrlEngine.ruleTypeList[kName]
            hasParam := RunCtrlEngine.ruleParamList.Has(kName) && RunCtrlEngine.ruleParamList[kName]
            lv.Add("", kName
                , RunCtrlEngine.ruleFuncList.Has(kName) ? RunCtrlEngine.ruleFuncList[kName] : ""
                , ruleStatus
                , isVar ? "变量" : "插件"
                , hasParam ? "传参" : ""
                , ruleResult
                , kVal)
        }
        lv.ModifyCol()
        lv.OnEvent("DoubleClick", (lvCtrl, item) => RunCtrlRuleManage.EditRule(lv))

        rmMenu := Menu()
        rmMenu.Add("新增", (*) => RunCtrlRuleManage.AddRule(lv))
        rmMenu.Add("修改", (*) => RunCtrlRuleManage.EditRule(lv))
        rmMenu.Add("减少", (*) => RunCtrlRuleManage.RemoveRule(lv))
        rmMenu.Add("添加最新默认规则", (*) => RunCtrlRuleManage.AddDefaults(lv))
        rmMenu.Add("全选", (*) => lv.Modify(0, "Select"))
        lv.OnEvent("ContextMenu", (lvCtrl, item, isRight, x, y) => rmMenu.Show(x, y))

        eg.OnEvent("Close", (*) => eg.Hide())
        eg.OnEvent("Escape", (*) => eg.Hide())
        eg.Show()
    }

    static AddRule(lv) {
        RunCtrlRuleEdit.Show("规则新建", lv)
    }

    static EditRule(lv) {
        row := lv.GetNext(0, "F")
        if !row
            return
        RunCtrlRuleEdit.Show("规则编辑", lv, row)
    }

    static RemoveRule(lv) {
        row := lv.GetNext(0, "F")
        if !row
            return
        result := MsgBox("确定删除选中的规则项？`n【注意！】此操作会连带删除所有规则组中用到的这个规则", "确认删除", 0x23)
        if result != "Yes"
            return
        rowNum := 0
        loop {
            rowNum := lv.GetNext(rowNum)
            if !rowNum
                break
            rName := lv.GetText(rowNum, 1)
            rFunc := lv.GetText(rowNum, 2)
            try IniDelete(CONFIG_PATH, "RunCtrlRule", rName "|" rFunc)
        }
        RunCtrlRuleManage.Show()
    }

    static AddDefaults(lv) {
        result := MsgBox("需要添加最新版本的默认规则吗？`n（不影响原有规则，重复的规则不会添加）", "添加默认规则", 0x21)
        if result != "OK"
            return

        varRules := Map(
            "电脑名", "A_ComputerName", "用户名", "A_UserName", "系统版本", "A_OSVersion",
            "系统64位", "A_Is64bitOS", "主屏幕宽度", "A_ScreenWidth", "主屏幕高度", "A_ScreenHeight",
            "本地时间", "A_Now", "年", "A_YYYY", "月", "A_MM", "星期", "A_WDay",
            "日", "A_DD", "时", "A_Hour", "分", "A_Min", "秒", "A_Sec",
            "剪贴板文字", "Clipboard")

        for rName, rFunc in varRules {
            if !RunCtrlEngine.ruleFileList.Has(rName)
                try IniWrite(0, CONFIG_PATH, "RunCtrlRule", rName "|" rFunc)
        }

        builtinRules := Map("开机时长(秒)", "rule_boot_time", "电脑机型", "rule_chassis_types", "运行状态", "rule_check_is_run", "联网状态", "rule_check_network")
        for rName, rFunc in builtinRules {
            if !RunCtrlEngine.ruleFileList.Has(rName)
                try IniWrite(APP_NAME ".ahk", CONFIG_PATH, "RunCtrlRule", rName "|" rFunc)
        }

        if PluginManager.pathList.Has("RunCtrl_Common.ahk") {
            commonRules := Map("内网IP", "rule_ip_internal", "WiFi名", "rule_wifi_silence",
                "验证注册表的值", "rule_check_regedit", "验证ini配置的值", "rule_check_ini",
                "运行过(今天)", "rule_run_today", "最近打开文件(今天)", "rule_run_today_file")
            for rName, rFunc in commonRules {
                if !RunCtrlEngine.ruleFileList.Has(rName)
                    try IniWrite("RunCtrl_Common.ahk", CONFIG_PATH, "RunCtrlRule", rName "|" rFunc)
            }
        }

        if PluginManager.pathList.Has("RunCtrl_Network.ahk") {
            networkRules := Map("城市", "rule_ip_city", "国家", "rule_ip_country", "国家代码", "rule_ip_countryCode",
                "省", "rule_ip_region", "省缩写", "rule_ip_regionName", "纬度", "rule_ip_lat",
                "经度", "rule_ip_lon", "时区", "rule_ip_timezone", "运营商", "rule_ip_isp", "外网IP", "rule_ip_external")
            for rName, rFunc in networkRules {
                if !RunCtrlEngine.ruleFileList.Has(rName)
                    try IniWrite("RunCtrl_Network.ahk", CONFIG_PATH, "RunCtrlRule", rName "|" rFunc)
            }
        }

        RunCtrlRuleManage.Show()
    }
}

class RunCtrlRuleEdit {
    static Show(menuItem, lv, row := 0) {
        ruleName := "", ruleFunc := "", rulePath := "", typeVar := true

        if row > 0 {
            ruleName := lv.GetText(row, 1)
            ruleFunc := lv.GetText(row, 2)
            ruleType := lv.GetText(row, 4)
            rulePath := lv.GetText(row, 7)
            typeVar := ruleType = "变量"
        }

        eg := Gui(, "RunCtrl 规则编辑 " APP_VERSION)
        eg.SetFont(, "Microsoft YaHei")
        eg.MarginX := 20
        eg.MarginY := 10

        eg.AddText("xm y+10 w60", "规则名：")
        edtName := eg.AddEdit("xm+60 yp-3 w450", ruleName)
        eg.AddText("xm y+10 w60", "规则类型：")
        rbTypeVar := eg.AddRadio("x+4 yp Checked" (typeVar ? 1 : 0), "菜单变量")
        rbTypeFunc := eg.AddRadio("x+4 yp Checked" (typeVar ? 0 : 1), "插件函数")

        eg.AddText("xm y+10 w60", "规则函数：")
        edtFunc := eg.AddEdit("xm+60 yp-3 w225", ruleFunc)
        funcStr := rulePath != "" && rulePath != "0" ? RunCtrlEngine.KnowAhkFunc(rulePath) : ""
        ddFunc := eg.AddDropDownList("x+5 yp+2 w220", funcStr != "" ? StrSplit(funcStr, "|") : [""])

        eg.AddButton("xm-5 yp+30 w60 h60", "规则路径`n可自动识别函数名").OnEvent("Click", (*) => RunCtrlRuleEdit.BrowsePath(edtPath, ddFunc, edtFunc))
        edtPath := eg.AddEdit("xm+60 yp w450 r3", typeVar ? "0" : (rulePath = "0" ? "RunCtrl_Common.ahk" : rulePath))

        eg.AddButton("Default xm+180 y+10 w75", "保存(&Y)").OnEvent("Click", (*) => RunCtrlRuleEdit.Save(eg, edtName, rbTypeVar, edtFunc, edtPath, lv, row, menuItem))
        eg.AddButton("x+10 w75", "取消(&C)").OnEvent("Click", (*) => eg.Hide())

        UpdateType(*) {
            if rbTypeVar.Value {
                edtPath.Value := "0"
                edtPath.Enabled := false
            } else {
                if edtPath.Value = "0"
                    edtPath.Value := "RunCtrl_Common.ahk"
                edtPath.Enabled := true
            }
        }
        rbTypeVar.OnEvent("Click", UpdateType)
        rbTypeFunc.OnEvent("Click", UpdateType)
        UpdateType()

        eg.Show()
    }

    static BrowsePath(edtPath, ddFunc, edtFunc) {
        rulePath := FileSelect(3,, "请选择要使用的AutoHotkey规则脚本", "AutoHotkey (*.ahk)")
        if rulePath = ""
            return
        rulePath := StrReplace(rulePath, A_ScriptDir "\RunPlugins\")
        rulePath := StrReplace(rulePath, A_ScriptDir "\")
        edtPath.Value := rulePath
        funcStr := RunCtrlEngine.KnowAhkFunc(rulePath)
        if funcStr != "" {
            funcs := StrSplit(funcStr, "|")
            ddFunc.Delete()
            ddFunc.Add(funcs)
            ddFunc.Choose(1)
            edtFunc.Value := funcs[1]
        }
    }

    static Save(eg, edtName, rbTypeVar, edtFunc, edtPath, lv, row, menuItem) {
        name := edtName.Value
        func := edtFunc.Value
        path := rbTypeVar.Value ? "0" : edtPath.Value

        if name = "" || func = "" || path = "" {
            MsgBox("请填入规则名、规则函数和规则路径", APP_NAME, 48)
            return
        }
        if InStr(name, "|") {
            MsgBox('规则名不能包含有"|"分割符', APP_NAME, 48)
            return
        }

        try IniWrite(path, CONFIG_PATH, "RunCtrlRule", name "|" func)
        RunCtrlEngine.Read()
        eg.Hide()

        RunCtrlRuleManage.Show()
    }
}

RunCtrlGui_LogicStr(logic) {
    if logic = 1 || logic = "eq"
        return "相等"
    if logic = 0 || logic = "ne"
        return "不相等"
    if RunCtrlEngine.LogicEnum.Has(logic)
        return RunCtrlEngine.LogicEnum[logic]
    return "相等"
}

RunCtrlGui_LogicKey(str) {
    for k, v in RunCtrlEngine.LogicEnum {
        if v = str
            return k
    }
    if str = "相等"
        return "eq"
    if str = "不相等"
        return "ne"
    return "eq"
}

RunCtrlGui_PollSel() {
    if !RunCtrlGui.guiObj || !WinExist("ahk_id " RunCtrlGui.guiObj.Hwnd)
        return
    cur := RunCtrlGui.listBox.Text
    if cur != RunCtrlGui.lastSel {
        RunCtrlGui.lastSel := cur
        RunCtrlGui.RefreshLV()
    }
}
