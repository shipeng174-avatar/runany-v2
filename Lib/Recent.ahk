class RecentItems {
    static MAX := 5
    static list := []
    static REG_KEY := "HKEY_CURRENT_USER\SOFTWARE\RunAny_v2"
    static REG_VAL := "MenuCommonList"

    static Init() {
        RecentItems.MAX := g_RecentMax
        RecentItems.Load()
    }

    static Load() {
        try {
            data := RegRead(RecentItems.REG_KEY, RecentItems.REG_VAL)
            if data = ""
                return
            entries := StrSplit(data, "|")
            for entry in entries {
                parts := StrSplit(entry, "§",, 3)
                if parts.Length >= 3 {
                    mode := 1
                    try mode := Integer(parts[3])
                    RecentItems.list.Push({
                        display: parts[1],
                        path: parts[2],
                        mode: mode
                    })
                }
            }
        } catch {
        }
    }

    static Save() {
        entries := []
        max := Min(RecentItems.list.Length, RecentItems.MAX)
        Loop max {
            entry := RecentItems.list[A_Index]
            entries.Push(entry.display "§" entry.path "§" entry.mode)
        }
        data := ""
        for e in entries
            data .= (data = "" ? "" : "|") e
        try RegWrite(data, "REG_SZ", RecentItems.REG_KEY, RecentItems.REG_VAL)
    }

    static Clear() {
        RecentItems.list := []
        try RegDelete(RecentItems.REG_KEY, RecentItems.REG_VAL)
        catch {
            ; May not exist
        }
    }

    static Add(item) {
        if !item || !item.HasProp("DisplayText")
            return
        display := item.DisplayText
        path := item.RunPath
        mode := item.Mode

        newList := []
        for e in RecentItems.list {
            if e.display != display
                newList.Push(e)
        }
        RecentItems.list := newList

        RecentItems.list.InsertAt(1, { display: display, path: path, mode: mode })

        while RecentItems.list.Length > RecentItems.MAX
            RecentItems.list.Pop()

        RecentItems.Save()
    }

    static lastAddedPrefixes := []

    static AddToMenu(menuObj) {
        for i, entry in RecentItems.list {
            item := MenuItem(entry.display, entry.path, entry.mode)
            cb := MakeRecentCallback(item)
            prefix := "&" i " "
            try {
                menuObj.Add(prefix entry.display, cb)
                icon := IconLoader.GetItemIcon(item)
                if icon
                    IconLoader.SetIcon(menuObj, prefix entry.display, icon.path, icon.index)
            }
        }
    }

    static InjectToMenu(menuObj) {
        ; 1. Delete previously injected recent items (and the separator)
        ; Because AHK's Menu.Delete(Name) works well for named items but not easily for unnamed separators,
        ; we instead delete by position. Since we always inject them at the very top (positions 1 through N),
        ; we just delete the first item repeatedly.
        countToDelete := RecentItems.lastAddedPrefixes.Length
        Loop countToDelete {
            try menuObj.Delete("1&")
        }
        RecentItems.lastAddedPrefixes := []

        if RecentItems.list.Length = 0 || g_RecentMax = 0
            return

        ; 2. Insert the separator at the top (it will be pushed down as we insert items)
        try menuObj.Insert("1&")
        RecentItems.lastAddedPrefixes.Push("---SEPARATOR---") ; Track count

        ; 3. Reverse insert the recent items at the top
        maxIndex := Min(RecentItems.list.Length, RecentItems.MAX)
        Loop maxIndex {
            i := maxIndex - A_Index + 1
            entry := RecentItems.list[i]
            prefix := "&" i " "
            if ConfigReader.ReadSetting("RecentNum", "1") = "0"
                prefix := ""
            displayStr := prefix entry.display
            item := MenuItem(entry.display, entry.path, entry.mode)
            cb := MakeRecentCallback(item)
            try {
                menuObj.Insert("1&", displayStr, cb)
                icon := IconLoader.GetItemIcon(item)
                if icon
                    IconLoader.SetIcon(menuObj, displayStr, icon.path, icon.index)
                RecentItems.lastAddedPrefixes.Push(displayStr) ; Track count
            }
        }
    }
}

MakeRecentCallback(item) {
    return (*) => Launcher.RunItem(item)
}
