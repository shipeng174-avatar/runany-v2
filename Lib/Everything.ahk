class EverythingSearch {
    static Show() {
        getZz := GetSelectedText()
        EverythingSearch.Search(getZz)
    }

    static Search(getZz := "") {
        global g_EvShowExt, g_EvShowFolder
        if ExeResolver.EvExePath = "" {
            MsgBox("未找到 Everything.exe", APP_NAME, 48)
            return
        }

        evSearch := ""
        evShowFolderSpace := ""
        if Trim(getZz, " `t`r`n") != "" {
            lines := StrSplit(getZz, "`n", "`r")
            getZzLength := lines.Length

            for idx, line in lines {
                s := Trim(line, " `t`r`n")
                s := Trim(s, '"')
                s := Trim(s, "\")
                if s = ""
                    continue

                if g_EvShowFolder && (InStr(FileExist(s), "D") || RegExMatch(s, ".*\\$")) {
                    ; Folder search mode
                    evShowFolderSpace := A_Space
                } else {
                    SplitPath(s, &fileName, &fDir, &fExt, &fNameNoExt)
                    if fDir != "" || RegExMatch(s, "i)^[A-Z]:\\") {
                        ; Full path: always use just the name part for searching
                        s := g_EvShowExt ? fileName : fNameNoExt
                    } else if !g_EvShowExt && fExt != "" {
                        ; Plain filename: strip extension if requested
                        s := fNameNoExt
                    }
                }

                ; Multi-condition support: wrap lines with spaces in quotes
                if InStr(s, A_Space) && getZzLength > 1
                    s := '"' s '"'

                evSearch .= s "|"
            }
            evSearch := SubStr(evSearch, 1, -1)
        }

        ; Support regex search toggle
        useRegex := ConfigReader.ReadSetting("EvUseRegex", "0") = "1"
        if useRegex && evSearch != "" {
            evSearch := "regex:" evSearch
        }

        DetectHiddenWindows(true)
        if evSearch {
            ExeResolver.StartEverything()
            Run('"' ExeResolver.EvExePath '"' ExeResolver.GetInstanceArgs() ' -search "' evSearch '"' evShowFolderSpace)
        } else {
            hwnd := ExeResolver.FindEverythingWindow(true)
            if hwnd {
                if !WinActive("ahk_id " hwnd)
                    WinActivate("ahk_id " hwnd)
                else
                    WinMinimize("ahk_id " hwnd)
            } else
                ExeResolver.StartEverything()
        }
        DetectHiddenWindows(false)
    }
}
