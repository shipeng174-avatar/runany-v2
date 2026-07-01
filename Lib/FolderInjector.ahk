#Warn VarUnset, Off
CreateShellWindows() {
    shell := ComObjCreate("Shell.Application")
    wins := shell.Windows
    return wins
}

class FolderHelper {
    static GetOpenFolders() {
        folders := []
        seen := Map()

        try {
            wins := CreateShellWindows()
            for exp in wins {
                try {
                    folder := exp.Document.Folder.Self.Path
                    if folder != "" && !seen.Has(folder) {
                        seen[folder] := true
                        folders.Push({ path: folder, icon: "shell32.dll", iconIndex: 5 })
                    }
                }
            }
        }

        tcPath := ProcessExist("totalcmd.exe") || ProcessExist("TotalCMD64.exe")
        if tcPath {
            try {
                tcIcon := "" 
                try tcIcon := WinGetProcessPath("ahk_class TTOTAL_CMD")
                cm_CopySrcPathToClip := 2029
                cm_CopyTrgPathToClip := 2030
                savedClip := A_Clipboard
                A_Clipboard := ""
                SendMessage(1075, cm_CopySrcPathToClip, 0, , "ahk_class TTOTAL_CMD")
                folder := RegExReplace(A_Clipboard, "^\\\\(?!file)")
                if folder != "" && !seen.Has(folder) {
                    seen[folder] := true
                    folders.Push({ path: folder, icon: tcIcon, iconIndex: 1 })
                }
                A_Clipboard := ""
                SendMessage(1075, cm_CopyTrgPathToClip, 0, , "ahk_class TTOTAL_CMD")
                folder := RegExReplace(A_Clipboard, "^\\\\(?!file)")
                if folder != "" && !seen.Has(folder) {
                    seen[folder] := true
                    folders.Push({ path: folder, icon: tcIcon, iconIndex: 1 })
                }
                A_Clipboard := savedClip
            }
        }

        try {
            doIcon := WinGetProcessPath("ahk_exe dopus.exe")
            if doIcon != "" {
                try {
                    folder := ControlGetText("Edit1", "ahk_class dopus.lister")
                    if folder != "" && !seen.Has(folder) {
                        seen[folder] := true
                        folders.Push({ path: folder, icon: doIcon, iconIndex: 1 })
                    }
                }
                try {
                    folder := ControlGetText("Edit2", "ahk_class dopus.lister")
                    if folder != "" && !seen.Has(folder) {
                        seen[folder] := true
                        folders.Push({ path: folder, icon: doIcon, iconIndex: 1 })
                    }
                }
            }
        }

        try {
            xyIcon := WinGetProcessPath("ahk_exe XYplorer.exe")
            if xyIcon = ""
                xyIcon := WinGetProcessPath("ahk_exe XYplorerFree.exe")
            if xyIcon != "" {
                SplitPath(xyIcon, &xyName)
                folder := ControlGetText("Edit18", "ahk_exe " xyName)
                if folder != "" && !seen.Has(folder) {
                    seen[folder] := true
                    folders.Push({ path: folder, icon: xyIcon, iconIndex: 1 })
                }
            }
        }

        return folders
    }

    static SetupHotkey() {
        if ConfigReader.ReadSetting("CtrlGQuickSwitch", "1") != "1"
            return
        try {
            HotIf((*) => FolderHelper.CanQuickSwitch())
            Hotkey("^g", (*) => FolderHelper.ShowQuickSwitch(), "On")
            HotIf()
        }
    }

    static CanQuickSwitch() {
        try {
            cls := WinGetClass("A")
            if cls = "#32770" || cls = "CabinetWClass" || cls = "ExploreWClass"
                return true
            pname := WinGetProcessName("A")
            return pname = "totalcmd.exe" || pname = "TotalCMD64.exe" || pname = "dopus.exe"
                || pname = "XYplorer.exe" || pname = "XYplorerFree.exe"
        }
        return false
    }

    static ShowQuickSwitch() {
        folders := FolderHelper.GetOpenFolders()
        if folders.Length = 0 {
            ToolTip("没有获取到其他已打开的文件夹")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        m := Menu()
        for i, f in folders {
            label := "&" i " " f.path
            m.Add(label, FolderHelper.MakeSwitchCb(f.path))
            try m.SetIcon(label, f.icon, f.iconIndex)
        }
        m.Show()
    }

    static SwitchTo(folderPath) {
        cls := WinGetClass("A")
        if (cls = "#32770") {
            FolderHelper.NavigateDialog(folderPath)
        } else if (cls = "CabinetWClass" || cls = "ExploreWClass") {
            try {
                hwnd := WinGetID("A")
                for exp in CreateShellWindows() {
                    if exp.Hwnd = hwnd {
                        exp.Navigate(folderPath)
                        break
                    }
                }
            }
        }
    }

    static MakeSwitchCb(p) => (*) => FolderHelper.SwitchTo(p)

    static IsActiveDialog() {
        try {
            cls := WinGetClass("A")
            return cls = "#32770"
        }
        return false
    }

    static NavigateDialog(folderPath) {
        if !FolderHelper.IsActiveDialog()
            return false

        try {
            if RegExMatch(folderPath, "^[A-Za-z]:\\") || RegExMatch(folderPath, "^\\\\file")
                FolderHelper._FeedEdit1(folderPath)
            else
                FolderHelper._FeedEdit2(folderPath)
            return true
        }
        return false
    }

    static _FeedEdit1(folderPath) {
        oldText := ""
        try oldText := ControlGetText("Edit1", "A")
        ControlFocus("Edit1", "A")
        Loop 5 {
            ControlSetText(folderPath, "Edit1", "A")
            Sleep(50)
            try {
                cur := ControlGetText("Edit1", "A")
                if cur = folderPath
                    break
            }
        }
        Sleep(50)
        ControlSend("{Enter}", "Edit1", "A")
        Sleep(50)
        if oldText = ""
            return
        Loop 5 {
            ControlSetText(oldText, "Edit1", "A")
            Sleep(50)
            try {
                cur := ControlGetText("Edit1", "A")
                if cur = oldText
                    break
            }
        }
    }

    static _FeedEdit2(folderPath) {
        ControlFocus("Edit2", "A")
        ControlSend("{F4}", "Edit2", "A")
        Sleep(50)
        ControlSetText(folderPath, "Edit2", "A")
        Sleep(50)
        ControlSend("{Enter}", "Edit2", "A")
    }

    static MakeNavCb(p) => (*) => FolderHelper.NavigateDialog(p)

    static BuildFolderMenu(folders) {
        m := Menu()
        idx := 0
        for f in folders {
            idx++
            label := "&" idx " " f.path
            m.Add(label, FolderHelper.MakeNavCb(f.path))
            try m.SetIcon(label, f.icon, f.iconIndex)
        }
        return m
    }

    static ShowWithFolders(baseMenu) {
        folders := FolderHelper.GetOpenFolders()
        if folders.Length = 0 {
            baseMenu.Show()
            return
        }

        wrapper := Menu()

        for i, f in folders {
            label := "&" i " " f.path
            wrapper.Add(label, FolderHelper.MakeNavCb(f.path))
            try wrapper.SetIcon(label, f.icon, f.iconIndex)
        }

        wrapper.Add()
        wrapper.Add("▶ 显示全部菜单", (*) => baseMenu.Show())

        try wrapper.Show()
    }
}
