class HotStrHint {
    static hintList := []
    static Init(arr := "") {
        HotStrHint.hintList := []
        if arr != "" && arr is Array
            HotStrHint.hintList := arr
    }

    static Add(item) {
        ; 热字符串可能在 DisplayText 或 Hotkey 中
        hotStrSource := ""
        if MenuParser.IsHotstring(item.DisplayText)
            hotStrSource := item.DisplayText
        else if MenuParser.IsHotstring(item.Hotkey)
            hotStrSource := item.Hotkey
        if hotStrSource = ""
            return

        hsInfo := MenuParser.GetHotstringInfo(hotStrSource)
        if !hsInfo
            return

        hotStrShow := RegExReplace(hsInfo.trigger, "i)^[:*?a-zA-Z0-9]+:")
        if hotStrShow = hsInfo.trigger
            hotStrShow := hsInfo.trigger

        hotStrLen := StrLen(hotStrShow)
        HintLen := Integer(ConfigReader.ReadSetting("HotStrHintLen", "3"))
        if HintLen < 1
            HintLen := 1

        if hotStrLen = 0
            return

        if hotStrLen = 1 {
            HotStrHint._RegisterHint(hotStrShow, item, hotStrShow)
            return
        }

        if hotStrLen <= HintLen {
            hint := SubStr(hotStrShow, 1, hotStrLen - 1)
            HotStrHint._RegisterHint(hint, item, hotStrShow)
            return
        }

        Loop hotStrLen - HintLen {
            hint := SubStr(hotStrShow, 1, A_Index + HintLen - 1)
            HotStrHint._RegisterHint(hint, item, hotStrShow)
        }
    }

    static _RegisterHint(hintText, item, fullText) {
        if hintText = ""
            return

        ; 始终添加到列表（多个项可能共享同一个 hint 前缀）
        HotStrHint.hintList.Push({
            hint: hintText,
            full: fullText,
            item: item
        })

        try {
            Hotstring(":*Xb0:" hintText, (hs) => HotStrHint.OnHint(hs))
        }
    }

    static OnHint(hs) {
        hint := RegExReplace(hs, "^:[^:]*?Xb0:")
        showLen := Integer(ConfigReader.ReadSetting("HotStrShowLen", "30"))
        showTime := Integer(ConfigReader.ReadSetting("HotStrShowTime", "3000"))
        transparent := Integer(ConfigReader.ReadSetting("HotStrShowTransparent", "80"))
        xOff := Integer(ConfigReader.ReadSetting("HotStrShowX", "0"))
        yOff := Integer(ConfigReader.ReadSetting("HotStrShowY", "0"))

        hintTip := ""
        for entry in HotStrHint.hintList {
            if entry.hint = hint {
                hotStrName := entry.item.DisplayText
                if RegExMatch(hotStrName, "\t", &m)
                    hotStrName .= "`t" entry.item.DisplayText

                hotStrAny := entry.item.RunPath
                hotStrFixed := RegExReplace(hotStrAny, "iS);+$")
                hotStrFlexible := ConfigReader.TransformVar(hotStrFixed)

                if showLen <= 0 {
                    hotStrAny := ""
                } else if StrLen(hotStrAny) > showLen {
                    hotStrAny := "`t" SubStr(hotStrFlexible, 1, showLen) "..."
                } else {
                    hotStrAny := "`t" hotStrFlexible
                }
                hintTip .= entry.full hotStrName hotStrAny "`n"
            }
        }
        hintTip := RTrim(hintTip, "`n")

        if hintTip = ""
            return

        MouseGetPos(&MouseX, &MouseY)
        if xOff = 0 && yOff = 0
            ToolTip(hintTip)
        else
            ToolTip(hintTip, MouseX + xOff, MouseY + yOff)

        try WinSetTransparent(Round(transparent / 100 * 255), "ahk_class tooltips_class32")
        SetTimer(() => ToolTip(), -showTime)
    }

    static RemoveToolTip() {
        ToolTip()
    }

    static ScanAndRegister(parsed) {
        for cat in parsed.categories {
            HotStrHint._ScanCat(cat)
        }
    }

    static _ScanCat(cat) {
        for item in cat.Items {
            if item.Mode = ItemMode.SEPARATOR
                continue
            if MenuParser.IsHotstring(item.DisplayText) || MenuParser.IsHotstring(item.Hotkey)
                HotStrHint.Add(item)
        }
        for child in cat.Children
            HotStrHint._ScanCat(child)
    }
}
