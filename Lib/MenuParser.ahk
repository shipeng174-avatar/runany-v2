class ItemMode {
    static PROGRAM := 1
    static PHRASE := 2
    static TYPING_PHRASE := 3
    static HOTKEY := 4
    static AHK_HOTKEY := 5
    static URL := 6
    static FOLDER := 7
    static PLUGIN := 8
    static CATEGORY := 10
    static SEPARATOR := 11
    static COMMENT := 12
    static EXE_URL := 60
    static FAIL := 99
}

class MenuItem {
    Name := ""
    RunPath := ""
    Mode := 0
    DisplayText := ""
    Hotkey := ""
    RawLine := ""

    __New(name, runPath, mode, displayText := "", hotkey := "", rawLine := "") {
        this.Name := name
        this.RunPath := runPath
        this.Mode := mode
        this.DisplayText := displayText != "" ? displayText : name
        this.Hotkey := hotkey
        this.RawLine := rawLine
    }
}

class MenuCategory {
    Name := ""
    Level := 0
    Items := []
    Children := []
    Parent := ""
    Extensions := ""
    RawName := ""

    __New(name, level, parent := "") {
        this.Name := name
        this.Level := level
        this.Parent := parent
        this.Items := []
        this.Children := []
        this.Extensions := ""
        this.RawName := name
    }
}

class MenuParser {
    static GetItemMode(item, fullItemFlag := false) {
        if fullItemFlag {
            if InStr(item, ";") = 1
                return ItemMode.COMMENT
            if RegExMatch(item, "^-+[^-]+.*")
                return ItemMode.CATEGORY
            if RegExMatch(item, "^-+$") || RegExMatch(item, "^\|+$")
                return ItemMode.SEPARATOR
            parts := StrSplit(item, "|",, 2)
            item := parts.Has(2) && parts[2] != "" ? parts[2] : parts[1]
        }
        len := StrLen(item)
        if len = 0
            return ItemMode.PROGRAM
        if SubStr(item, len, 1) = ";" {
            if SubStr(item, len - 1, 2) = ";;"
                return ItemMode.TYPING_PHRASE
            return ItemMode.PHRASE
        }
        if SubStr(item, len - 2, 3) = ":::" {
            return ItemMode.AHK_HOTKEY
        }
        if SubStr(item, len - 1, 2) = "::" {
            return ItemMode.HOTKEY
        }
        if RegExMatch(item, "i)^.*?\.(exe|lnk|bat|cmd|vbs|ps1|ahk) .*?([\w-]+://?|www[.]).*")
            return ItemMode.EXE_URL
        if RegExMatch(item, "i)^([\w-]+://?|www[.]).*")
            return ItemMode.URL
        if RegExMatch(item, ".+?\[.+?\]%?\(.*?\)")
            return ItemMode.PLUGIN
        if RegExMatch(item, "^[A-Za-z]:\\.*") && InStr(FileExist(item), "D")
            return ItemMode.FOLDER
        if RegExMatch(item, "^\\\\.*") && InStr(FileExist(item), "D")
            return ItemMode.FOLDER
        return ItemMode.PROGRAM
    }

    static SplitHotkey(displayName) {
        keyStr := RegExReplace(displayName, "\t+", "`t")
        parts := StrSplit(keyStr, "`t",, 2)
        if parts.Has(2) && parts[2] != ""
            return { name: parts[1], hotkey: parts[2] }

        ; V1 格式：名字:*X:触发词（热字符串选项用冒号分隔，不是 Tab）
        if RegExMatch(keyStr, "S)^[^:]*?(:[*?a-zA-Z0-9]+?:[^:]+)$", &m) {
            name := RegExReplace(keyStr, "S):[*?a-zA-Z0-9]+?:[^:]+$")
            return { name: name, hotkey: m[1] }
        }

        return { name: parts[1], hotkey: "" }
    }

    static IsHotstring(displayText) {
        return RegExMatch(displayText, "^:[COSTEPXZRQE*?0-9]*:[^:]+") > 0
    }

    static GetHotstringInfo(displayText) {
        if RegExMatch(displayText, "^(:[COSTEPXZRQE*?0-9]*:)(.+)$", &m) {
            opts := m[1]
            trigger := m[2]
            if !InStr(opts, "X") && !InStr(opts, "x") {
                innerOpts := SubStr(opts, 2, StrLen(opts) - 2)
                opts := ":" innerOpts "X:"
            }
            return { options: opts, trigger: trigger }
        }
        return ""
    }

    static GetOriginalHotstringInfo(displayText) {
        if RegExMatch(displayText, "^(:[COSTEPXZRQE*?0-9]*:)(.+)$", &m) {
            opts := m[1]
            trigger := m[2]
            hasX := InStr(opts, "X") || InStr(opts, "x")
            return { options: opts, trigger: trigger, hasX: hasX }
        }
        return ""
    }

    static Parse(iniContent) {
        extMap := Map()
        textCategories := []
        fileCategories := []
        publicCategories := []
        windowCategories := Map()
        treeHotkeyMap := Map()
        categoryStack := [MenuCategory("RunAny", 0)]

        lines := StrSplit(iniContent, "`n", "`r")

        for line in lines {
            trimmed := Trim(line)
            trimmed := LTrim(trimmed)

            if trimmed = "" || InStr(trimmed, ";") = 1
                continue

            if InStr(trimmed, "-") = 1 {
                treeStr := RegExReplace(trimmed, "(^-+).*", "$1")
                catName := RegExReplace(trimmed, "^-+")
                catLevel := StrLen(treeStr)

                if catName = "" {
                    ; V1：catLevel=1 且无文字 → 回归1级分类（弹出到根）
                    ; catLevel>1 且无文字 → 当前分类内加分隔符
                    if catLevel = 1 {
                        while categoryStack.Length > 1
                            categoryStack.Pop()
                    } else {
                        currentCat := categoryStack[categoryStack.Length]
                        if currentCat.Level > 0 {
                            sep := MenuItem("--", "", ItemMode.SEPARATOR, "--", "", trimmed)
                            currentCat.Items.Push(sep)
                        }
                    }
                    continue
                }

                extensions := ""
                treeHotkey := ""
                if InStr(catName, "|") {
                    parts := StrSplit(catName, "|",, 2)
                    catName := parts[1]
                    extensions := parts.Has(2) ? parts[2] : ""
                }

                ; Extract tree hotkey from category name (Tab-separated)
                if InStr(catName, "`t") {
                    hkParts := StrSplit(catName, "`t",, 2)
                    catName := hkParts[1]
                    treeHotkey := hkParts.Has(2) ? hkParts[2] : ""
                }

                cat := MenuCategory(catName, catLevel)
                cat.Extensions := extensions

                ; Store tree hotkey
                if treeHotkey != ""
                    treeHotkeyMap[treeHotkey] := catName

                while categoryStack.Length > 1 && categoryStack[categoryStack.Length].Level >= catLevel {
                    categoryStack.Pop()
                }

                categoryStack[categoryStack.Length].Children.Push(cat)
                categoryStack.Push(cat)

                if extensions != "" {
                    Loop Parse extensions, A_Space {
                        ext := A_LoopField
                        if ext = ""
                            continue
                        if ext = "text" {
                            textCategories.Push(catName)
                        } else if ext = "file" {
                            fileCategories.Push(catName)
                        } else if ext = "public" {
                            publicCategories.Push(catName)
                        } else if RegExMatch(ext, "i).+\.(exe|class)$") {
                            windowItem := RegExReplace(ext, "i)\.class$")
                            if !windowCategories.Has(windowItem)
                                windowCategories[windowItem] := []
                            windowCategories[windowItem].Push(catName)
                        } else {
                            extMap[ext] := cat
                        }
                    }
                }
                continue
            }

            if trimmed = "|" || trimmed = "||" {
                currentCat := categoryStack[categoryStack.Length]
                if currentCat.Level > 0 {
                    colBreak := MenuItem("──", "", ItemMode.SEPARATOR, "──", "", trimmed)
                    currentCat.Items.Push(colBreak)
                }
                continue
            }

            currentCat := categoryStack[categoryStack.Length]

            mode := MenuParser.GetItemMode(trimmed, true)
            if mode = ItemMode.COMMENT || mode = ItemMode.CATEGORY || mode = ItemMode.SEPARATOR
                continue

            item := MenuParser.ParseItemLine(trimmed)
            if item
                currentCat.Items.Push(item)
        }

        return { categories: categoryStack[1].Children, rootItems: categoryStack[1].Items, extMap: extMap
            , textCategories: textCategories, fileCategories: fileCategories
            , publicCategories: publicCategories, windowCategories: windowCategories
            , treeHotkeyMap: treeHotkeyMap }
    }

    static ParseItemLine(line) {
        displayName := ""
        runPath := ""

        if InStr(line, "|") {
            parts := StrSplit(line, "|",, 2)
            displayName := parts[1]
            runPath := parts.Has(2) ? parts[2] : ""
        } else {
            displayName := line
            runPath := line
        }

        hkInfo := MenuParser.SplitHotkey(displayName)
        displayName := hkInfo.name
        hotkey := hkInfo.hotkey

        mode := MenuParser.GetItemMode(runPath, false)

        runPath := MenuParser.ResolvePath(runPath, mode)

        item := MenuItem(displayName, runPath, mode, displayName, hotkey, line)

        return item
    }

    static ResolvePath(runPath, mode) {
        if mode = ItemMode.URL || mode = ItemMode.PHRASE || mode = ItemMode.TYPING_PHRASE
                || mode = ItemMode.HOTKEY || mode = ItemMode.AHK_HOTKEY || mode = ItemMode.PLUGIN
            return runPath

        runPath := ConfigReader.TransformVar(runPath)

        if RegExMatch(runPath, "i)^([\w-]+://?|www[.]).*")
            return runPath

        if RegExMatch(runPath, "i)^(\\\\|[A-Za-z]:\\).*")
            return runPath

        exeMatch := RegExMatch(runPath, "i)^(.+?\.exe)(.*$)", &m)
        if exeMatch {
            exeName := m[1]
            params := m[2]
            if FileExist(A_WinDir "\" exeName)
                return A_WinDir "\" exeName params
            if FileExist(A_WinDir "\system32\" exeName)
                return A_WinDir "\system32\" exeName params
            return runPath
        }

        return runPath
    }
}
