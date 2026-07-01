class MenuEditor {
    static guiObj := ""
    static tv := ""
    static iniPath := ""
    static iniContent := ""
    static modified := false
    static itemEditGui := ""
    static ctxMenu := ""

    static Show(filePath := "") {
        MenuEditor.iniPath := filePath != "" ? filePath : INI_PATH
        try {
            if MenuEditor.guiObj && MenuEditor.guiObj.Hwnd && WinExist("ahk_id " MenuEditor.guiObj.Hwnd) {
                MenuEditor.guiObj.Show()
                return
            }
        } catch {
            MenuEditor.guiObj := ""
        }

        MenuEditor.modified := false
        MenuEditor.iniContent := ConfigReader.ReadINI(MenuEditor.iniPath)
        if MenuEditor.iniContent = ""
            return

        g := Gui("+Resize", APP_NAME " 菜单树管理（双击修改，右键操作）")
        g.SetFont("s10", "Microsoft YaHei")
        g.MarginX := 10
        g.MarginY := 10
        MenuEditor.guiObj := g

        ; ═══════ 顶部工具栏按钮（2排） ═══════
        g.AddButton("xm w60", "保存").OnEvent("Click", (*) => MenuEditor.SaveToFile())
        g.AddButton("x+3 w80", "添加应用").OnEvent("Click", (*) => MenuEditor.AddItem(false))
        g.AddButton("x+3 w80", "添加分类").OnEvent("Click", (*) => MenuEditor.AddItem(true))
        g.AddButton("x+3 w50", "编辑").OnEvent("Click", (*) => MenuEditor.EditItem())
        g.AddButton("x+3 w50", "删除").OnEvent("Click", (*) => MenuEditor.DeleteItem())
        g.AddButton("x+3 w60", "向下").OnEvent("Click", (*) => MenuEditor.MoveItem(1))
        g.AddButton("x+3 w60", "向上").OnEvent("Click", (*) => MenuEditor.MoveItem(-1))
        g.AddButton("x+3 w60", "注释").OnEvent("Click", (*) => MenuEditor.ToggleComment())
        g.AddButton("xm y+3 w80", "多选导入").OnEvent("Click", (*) => MenuEditor.ImportFiles())
        g.AddButton("x+3 w80", "批量导入").OnEvent("Click", (*) => MenuEditor.ImportFolder())
        g.AddButton("x+3 w80", "桌面导入").OnEvent("Click", (*) => MenuEditor.ImportDesktop())
        g.AddButton("x+3 w80", "网站图标").OnEvent("Click", (*) => MenuEditor.OpenIconSite())
        g.AddButton("x+3 w100", "生成EXE图标").OnEvent("Click", (*) => MenuEditor.ExtractExeIcons())

        tv := g.AddTreeView("xm w650 r25 -ReadOnly AltSubmit Checked")
        MenuEditor.tv := tv
        MenuEditor.BuildTree(tv, MenuEditor.iniContent)

        g.OnEvent("Close", (*) => MenuEditor.CloseWindow(g))
        g.OnEvent("Escape", (*) => MenuEditor.HideWindow(g))
        g.OnEvent("Size", (guiObj, minMax, w, h) => tv.Move(, , w - 20, h - 50))

        ; Context menu
        cm := Menu()
        cm.Add("保存`tCtrl+S", (*) => MenuEditor.SaveToFile())
        cm.Add("添加应用`tF3", (*) => MenuEditor.AddItem(false))
        cm.Add("添加分类`tF4", (*) => MenuEditor.AddItem(true))
        cm.Add("编辑`tF2", (*) => MenuEditor.EditItem())
        cm.Add("删除`tDel", (*) => MenuEditor.DeleteItem())
        cm.Add("注释`tCtrl+Q", (*) => MenuEditor.ToggleComment())
        cm.Add()
        cm.Add("移动到分类...", (*) => MenuEditor.MoveToCategory())
        cm.Add("向下`tF5", (*) => MenuEditor.MoveItem(1))
        cm.Add("向上`tF6", (*) => MenuEditor.MoveItem(-1))
        cm.Add()
        cm.Add("多选导入`tF8", (*) => MenuEditor.ImportFiles())
        cm.Add("批量导入`tF9", (*) => MenuEditor.ImportFolder())
        MenuEditor.ctxMenu := cm

        tv.OnEvent("DoubleClick", (tvCtrl, item) => MenuEditor.EditItem())
        tv.OnEvent("ContextMenu", (tvCtrl, item, isRight, x, y) => cm.Show())
        tv.OnEvent("ItemEdit", (tvCtrl, item) => MenuEditor.OnItemEdited(item))

        ; Register context hotkeys
        HotIf(MenuEditor._IsMenuEditorWin)
        Hotkey("^s", (*) => MenuEditor.SaveToFile(), "On")
        Hotkey("F2", (*) => MenuEditor.EditItem(), "On")
        Hotkey("F3", (*) => MenuEditor.AddItem(false), "On")
        Hotkey("F4", (*) => MenuEditor.AddItem(true), "On")
        Hotkey("F5", (*) => MenuEditor.MoveItem(1), "On")
        Hotkey("F6", (*) => MenuEditor.MoveItem(-1), "On")
        Hotkey("F8", (*) => MenuEditor.ImportFiles(), "On")
        Hotkey("F9", (*) => MenuEditor.ImportFolder(), "On")
        Hotkey("Del", (*) => MenuEditor.DeleteItem(), "On")
        HotIf

        g.Show("w680 h680")
    }

    static _IsMenuEditorWin(*) {
        return WinActive(APP_NAME " 菜单树管理")
    }

    static CloseWindow(g) {
        if !MenuEditor.AskSave()
            return true
        g.Destroy()
        MenuEditor.guiObj := ""
        return true
    }

    static HideWindow(g) {
        if !MenuEditor.AskSave()
            return true
        g.Hide()
        return true
    }

    static GetParent(treeRoot, treeLevel) {
        return (treeLevel > 0 && treeRoot.Length >= treeLevel) ? treeRoot[treeLevel] : 0
    }

    static BuildTree(tv, content) {
        tv.Opt("-Redraw")
        tv.Delete()

        treeRoot := []
        treeLevel := 0

        Loop Parse content, "`n", "`r" {
            line := A_LoopField
            if line = ""
                continue

            if SubStr(line, 1, 1) = "-" {
                ; Category line
                dashLen := StrLen(RegExReplace(line, "^(-+).+", "$1"))
                if dashLen = 0
                    dashLen := 1

                if RegExMatch(line, "^-+[^-]+") {
                    if dashLen = 1 {
                        treeRoot.InsertAt(dashLen, tv.Add(line, , "Bold"))
                    } else if treeRoot.Length >= dashLen - 1 {
                        treeRoot.InsertAt(dashLen, tv.Add(line, treeRoot[dashLen - 1], "Bold"))
                    }
                    treeLevel := dashLen
                } else if line = "-" {
                    treeLevel := 0
                    tv.Add(line, , "Bold")
                } else {
                    tv.Add(line, MenuEditor.GetParent(treeRoot, treeLevel), "Bold")
                }
            } else if line = "|" || line = "||" {
                tv.Add(line, MenuEditor.GetParent(treeRoot, treeLevel), "Bold")
            } else if SubStr(line, 1, 1) = ";" {
                tv.Add(line, MenuEditor.GetParent(treeRoot, treeLevel))
            } else {
                tv.Add(line, MenuEditor.GetParent(treeRoot, treeLevel))
            }
        }
        tv.Opt("+Redraw")
        ; Expand first level
        itemID := 0
        Loop {
            itemID := tv.GetChild(itemID ? itemID : 0)
            if !itemID
                break
            tv.Modify(itemID, "Expand")
        }
    }

    ; ═══════ Tree Operations ═══════

    static AddItem(isCategory) {
        selID := MenuEditor.tv.GetSelection()
        parentID := selID ? MenuEditor.tv.GetParent(selID) : 0
        if !parentID
            parentID := 0

        if isCategory {
            parentText := ""
            if selID
                parentText := MenuEditor.tv.GetText(MenuEditor.tv.GetParent(selID) ? MenuEditor.tv.GetParent(selID) : selID)
            prefix := "-"
            if RegExMatch(parentText, "^(-+)", &m)
                prefix := m[1] "-"
            newID := MenuEditor.tv.Add("", parentID ? parentID : selID, "Bold Select")
            MenuEditor.EditItem(newID, true, prefix)
        } else {
            newID := MenuEditor.tv.Add("", parentID ? parentID : selID, "Select")
            MenuEditor.EditItem(newID, true, "")
        }
        MenuEditor.modified := true
    }

    static EditItem(itemID := 0, isNew := false, prefix := "") {
        if !itemID
            itemID := MenuEditor.tv.GetSelection()
        if !itemID
            return

        itemText := MenuEditor.tv.GetText(itemID)

        ; Parse existing item
        itemName := "", itemPath := "", hkKey := "", hkWin := false, adminRun := false
        hotStrOpt := "", hotStrShow := ""

        if InStr(itemText, "|") {
            parts := StrSplit(itemText, "|", , 2)
            namePart := parts[1]
            itemPath := parts.Length > 1 ? parts[2] : ""

            ; Extract tab hotkey
            tabParts := StrSplit(namePart, "`t")
            itemName := tabParts[1]
            if tabParts.Length > 1 && tabParts[2] != "" {
                hkKey := tabParts[2]
                if InStr(hkKey, "#") {
                    hkWin := true
                    hkKey := StrReplace(hkKey, "#")
                }
            }

            ; Extract hotstring
            if RegExMatch(itemName, "S)(: [*?a-zA-Z0-9]+:[^:]*)", &m) {
                hotStrFull := m[1]
                hotStrOpt := RegExReplace(hotStrFull, "^(:[*?a-zA-Z0-9]+:).*", "$1")
                hotStrShow := RegExReplace(hotStrFull, "^:[^:]*?X[^:]*?:")
                itemName := RegExReplace(itemName, "S)([^:]*?):[*?a-zA-Z0-9]+:[^:]*", "$1")
            }

            ; Extract admin
            if RegExMatch(itemName, "\[#\]$") {
                adminRun := true
                itemName := RegExReplace(itemName, "\[#\]$")
            }
        } else if SubStr(itemText, 1, 1) = "-" {
            itemName := itemText
        } else {
            itemPath := itemText
        }

        isTree := SubStr(itemName, 1, 1) = "-" || (isNew && prefix != "")
        if isNew && prefix != ""
            itemName := prefix

        MenuEditor.ShowItemEditor(itemID, isNew, itemName, itemPath, hkKey, hkWin, adminRun, hotStrOpt, hotStrShow, isTree)
    }

    static ShowItemEditor(itemID, isNew, itemName, itemPath, hkKey, hkWin, adminRun, hotStrOpt, hotStrShow, isTree) {
        if MenuEditor.itemEditGui {
            try MenuEditor.itemEditGui.Destroy()
        }

        eg := Gui(, (isNew ? "新增" : "修改") "菜单项 - " APP_NAME)
        eg.SetFont(, "Microsoft YaHei")
        eg.MarginX := 20
        eg.MarginY := 15

        nameText := isTree ? "菜单分类" : "菜单项名"
        treeY := isTree ? 20 : 10

        eg.AddText("xm+10 y20 w70", nameText "：")
        nameEdt := eg.AddEdit("x+5 yp-3 w300", itemName)
        adminCB := eg.AddCheckBox("x+15 yp+3 Checked" (adminRun ? 1 : 0), "管理员运行")

        if !isTree {
            eg.AddText("xm+10 y+10 w70", "热字符串：")
            eg.AddEdit("x+5 yp-1 w70", hotStrOpt)
            hsShowEdt := eg.AddEdit("x+5 yp w100", hotStrShow)
            eg.AddText("x+5 yp+3", "全局热键：")
            hkCtrl := eg.AddHotkey("x+5 yp-3 w130", hkKey)
            winCB := eg.AddCheckBox("x+5 yp+3 Checked" (hkWin ? 1 : 0), "Win")
        }

        eg.AddText("xm+10 y+" treeY " w70", "启动路径：")
        eg.AddButton("xm+6 y+5 w60", "选择文件").OnEvent("Click", (*) => MenuEditor.BrowsePath(pathEdt))
        eg.AddButton("x+5 w60", "选择目录").OnEvent("Click", (*) => MenuEditor.BrowseDir(pathEdt))
        eg.AddText("x+10 yp cBlue w300", "分隔符: |   Tab: 制表符   选中变量: %getZz%")

        pathEdt := eg.AddEdit("xm+6 y+5 w560 r4 -WantReturn", itemPath)

        eg.AddButton("Default xm+200 y+15 w75", "保存").OnEvent("Click", (*) => MenuEditor.SaveItemEdit(eg, itemID, isNew, isTree, nameEdt, pathEdt, adminCB, hkCtrl, winCB))
        eg.AddButton("x+20 w75", "取消").OnEvent("Click", (*) => eg.Destroy())

        eg.OnEvent("Close", (*) => eg.Destroy())
        eg.OnEvent("Escape", (*) => eg.Destroy())
        MenuEditor.itemEditGui := eg
        eg.Show("w610")
    }

    static BrowsePath(edt) {
        file := FileSelect(1, , "选择应用")
        if file != ""
            edt.Value := file
    }

    static BrowseDir(edt) {
        dir := DirSelect()
        if dir != ""
            edt.Value := dir
    }

    static SaveItemEdit(eg, itemID, isNew, isTree, nameEdt, pathEdt, adminCB, hkCtrl, winCB) {
        name := nameEdt.Value
        path := pathEdt.Value
        admin := adminCB.Value

        if name = "" && path = "" {
            if isNew
                MenuEditor.tv.Delete(itemID)
            eg.Destroy()
            return
        }

        ; Build hotkey string
        hkStr := ""
        if !isTree && hkCtrl {
            key := hkCtrl.Value
            if key != "" {
                hkStr := (winCB && winCB.Value ? "#" : "") key
                hkStr := "`t" hkStr
            }
        }

        ; Build admin suffix
        adminStr := admin ? "[#]" : ""

        ; Build final text
        if isTree {
            saveText := name
        } else if name != "" && path != "" {
            saveText := name adminStr hkStr "|" path
        } else if name != "" {
            saveText := name adminStr hkStr
        } else {
            saveText := path
        }

        MenuEditor.tv.Modify(itemID, , saveText)

        if isNew && isTree {
            ; Add empty child under new category
            newChild := MenuEditor.tv.Add("", itemID)
            MenuEditor.tv.Modify(itemID, "Bold Expand")
            MenuEditor.tv.Modify(newChild, "Select Vis")
        }

        MenuEditor.modified := true
        eg.Destroy()
    }

    static OnItemEdited(itemID) {
        MenuEditor.modified := true
    }

    static DeleteItem() {
        itemID := MenuEditor.tv.GetSelection()
        if !itemID
            return
        MenuEditor.tv.Delete(itemID)
        MenuEditor.modified := true
    }

    static MoveItem(dir) {
        itemID := MenuEditor.tv.GetSelection()
        if !itemID
            return

        parentID := MenuEditor.tv.GetParent(itemID)
        ; Get siblings
        siblings := []
        childID := MenuEditor.tv.GetChild(parentID)
        Loop {
            if !childID
                break
            siblings.Push(childID)
            childID := MenuEditor.tv.GetNext(childID)
        }

        ; Find current index
        curIdx := 0
        for i, id in siblings {
            if id = itemID {
                curIdx := i
                break
            }
        }

        newIdx := curIdx + dir
        if newIdx < 1 || newIdx > siblings.Length
            return

        ; Swap text
        curText := MenuEditor.tv.GetText(siblings[curIdx])
        newText := MenuEditor.tv.GetText(siblings[newIdx])
        MenuEditor.tv.Modify(siblings[curIdx], , newText)
        MenuEditor.tv.Modify(siblings[newIdx], , curText)
        MenuEditor.tv.Modify(siblings[newIdx], "Select Vis")
        MenuEditor.modified := true
    }

    static ImportFiles() {
        selID := MenuEditor.tv.GetSelection()
        parentID := selID ? MenuEditor.tv.GetParent(selID) : 0

        files := FileSelect("M3", , "选择多个文件导入")
        if files = ""
            return

        parts := StrSplit(files, "`n")
        dir := parts[1]
        Loop parts.Length - 1 {
            fullPath := dir "\" parts[A_Index + 1]
            MenuEditor.tv.Add(parts[A_Index + 1], parentID ? parentID : selID)
        }
        MenuEditor.modified := true
    }

    static ImportFolder() {
        selID := MenuEditor.tv.GetSelection()
        parentID := selID ? MenuEditor.tv.GetParent(selID) : 0

        folder := DirSelect()
        if folder = ""
            return

        Loop Files folder "\*", "D" {
            MenuEditor.tv.Add(A_LoopFileName, parentID ? parentID : selID)
        }
        Loop Files folder "\*.exe", "F" {
            SplitPath(A_LoopFilePath, &fName, &fDir, &fExt, &fNameNoExt)
            MenuEditor.tv.Add(fNameNoExt "|" A_LoopFilePath, parentID ? parentID : selID)
        }
        Loop Files folder "\*.lnk", "F" {
            SplitPath(A_LoopFilePath, &fName, , , &fNameNoExt)
            MenuEditor.tv.Add(fNameNoExt "|" A_LoopFilePath, parentID ? parentID : selID)
        }
        MenuEditor.modified := true
    }

    static ToggleComment() {
        ; 对选中的项（支持多选Checked）切换注释
        hadAny := false
        itemID := 0
        Loop {
            itemID := MenuEditor.tv.GetNext(itemID, "Checked")
            if !itemID
                break
            text := MenuEditor.tv.GetText(itemID)
            if SubStr(text, 1, 1) = ";" {
                text := SubStr(text, 2)
            } else {
                text := ";" text
            }
            MenuEditor.tv.Modify(itemID, , text)
            hadAny := true
        }
        if !hadAny {
            selID := MenuEditor.tv.GetSelection()
            if selID {
                text := MenuEditor.tv.GetText(selID)
                if SubStr(text, 1, 1) = ";"
                    text := SubStr(text, 2)
                else
                    text := ";" text
                MenuEditor.tv.Modify(selID, , text)
            }
        }
        MenuEditor.modified := true
    }

    static MoveToCategory() {
        selID := MenuEditor.tv.GetSelection()
        if !selID
            return

        ; 收集所有分类（以-开头的节点）
        cats := []
        itemID := 0
        Loop {
            itemID := MenuEditor.tv.GetNext(itemID, "Full")
            if !itemID
                break
            text := MenuEditor.tv.GetText(itemID)
            if RegExMatch(text, "^-+[^-]+")
                cats.Push({id: itemID, text: text})
        }

        if cats.Length = 0 {
            MsgBox("没有可用的分类节点", APP_NAME, 48)
            return
        }

        ; 弹出选择窗口
        selGui := Gui(, "移动到分类 - " APP_NAME)
        selGui.SetFont(, "Microsoft YaHei")
        selGui.MarginX := 15
        selGui.MarginY := 10
        selGui.AddText("xm", "选择目标分类：")
        lv := selGui.AddListView("xm w350 r15 grid", ["分类名"])
        for c in cats
            lv.Add("", c.text)
        lv.ModifyCol(1, 320)
        selGui.AddButton("Default xm+120 y+10 w75", "确定").OnEvent("Click", (*) => MenuEditor.DoMoveToCategory(selGui, lv, cats, selID))
        selGui.AddButton("x+10 w75", "取消").OnEvent("Click", (*) => selGui.Destroy())
        lv.OnEvent("DoubleClick", (ctrl, item) => MenuEditor.DoMoveToCategory(selGui, lv, cats, selID))
        selGui.OnEvent("Close", (*) => selGui.Destroy())
        selGui.Show()
    }

    static DoMoveToCategory(selGui, lv, cats, selID) {
        row := lv.GetNext(0)
        if !row {
            selGui.Destroy()
            return
        }
        targetID := cats[row].id
        text := MenuEditor.tv.GetText(selID)
        MenuEditor.tv.Add(text, targetID)
        MenuEditor.tv.Delete(selID)
        MenuEditor.tv.Modify(targetID, "Expand")
        MenuEditor.modified := true
        selGui.Destroy()
    }

    static ImportDesktop() {
        if MsgBox("确定导入桌面程序到菜单当中吗？", APP_NAME, 0x21) != "OK"
            return

        selID := MenuEditor.tv.GetSelection()
        parentID := selID ? MenuEditor.tv.GetParent(selID) : 0

        desktopNodeID := MenuEditor.tv.Add("-桌面(&Desktop)", parentID ? parentID : 0, "Bold")

        Loop Files A_Desktop "\*.lnk", "FR" {
            SplitPath(A_LoopFilePath, &fName, , , &fNameNoExt)
            MenuEditor.tv.Add(fNameNoExt "|" A_LoopFilePath, desktopNodeID)
        }
        Loop Files A_Desktop "\*.exe", "F" {
            SplitPath(A_LoopFilePath, &fName, , , &fNameNoExt)
            MenuEditor.tv.Add(fNameNoExt "|" A_LoopFilePath, desktopNodeID)
        }
        MenuEditor.tv.Modify(desktopNodeID, "Expand")
        MenuEditor.modified := true
    }

    static OpenIconSite() {
        try Run("https://www.iconfont.cn/")
    }

    ; ═══════ Save / Serialize ═══════

    static AskSave() {
        if !MenuEditor.modified
            return true
        result := MsgBox("菜单已修改，是否保存？", APP_NAME, 0x23)
        if result = "Yes"
            return MenuEditor.SaveToFile()
        if result = "Cancel"
            return false
        return true
    }

    static SaveToFile() {
        content := MenuEditor.Serialize()
        if content = ""
            return

        ; Backup
        try {
            if FileExist(MenuEditor.iniPath) {
                backupDir := ConfigReader.TransformVar(ConfigReader.ReadSetting("RunABackupDir", "%A_ScriptDir%\\RunBackup"))
                if !DirExist(backupDir)
                    DirCreate(backupDir)
                iniName := RegExReplace(MenuEditor.iniPath, ".*\\")
                fmt := ConfigReader.TransformVar(ConfigReader.ReadSetting("RunABackupFormat", ".%A_Now%.bak"))
                try FileCopy(MenuEditor.iniPath, backupDir "\" iniName fmt, 1)
            }
        }

        try {
            f := FileOpen(MenuEditor.iniPath, "w", "UTF-8")
            f.Write(content)
            f.Close()
            MenuEditor.modified := false
            ToolTip("菜单已保存，正在重启 RunAny...")
            SetTimer(() => SafeReload(), -300)
            return true
        } catch as e {
            MsgBox("保存失败: " e.Message, APP_NAME, 48)
            return false
        }
    }

    static Serialize() {
        result := ""
        MenuEditor.SerializeLevel(0, &result)
        return RTrim(result, "`n")
    }

    static SerializeLevel(parentID, &result) {
        itemID := MenuEditor.tv.GetChild(parentID)
        Loop {
            if !itemID
                break
            text := MenuEditor.tv.GetText(itemID)
            if text != ""
                result .= text "`n"
            ; Recurse children
            MenuEditor.SerializeLevel(itemID, &result)
            itemID := MenuEditor.tv.GetNext(itemID)
        }
    }

    static ExtractExeIcons(*) {
        result := MsgBox(
            "将提取菜单中所有 EXE 程序的图标并保存为 .ico 文件`n`n"
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
            MsgBox("提取图标出错: " e.Message, APP_NAME, 48)
        }
    }
}
