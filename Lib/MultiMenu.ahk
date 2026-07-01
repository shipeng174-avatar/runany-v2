class MultiMenu {
    static currentItem := ""

    static Show(item) {
        MultiMenu.currentItem := item
        m := Menu()

        m.Add("运行(&R) " item.DisplayText, (*) => Launcher.RunItem(MultiMenu.currentItem))
        m.Add("编辑(&E)", (*) => Run("notepad.exe " INI_PATH))

        if item.Mode = ItemMode.PROGRAM || item.Mode = ItemMode.EXE_URL || item.Mode = ItemMode.FOLDER {
            m.Add("软件目录(&D)", (*) => Launcher.OpenDirectory(MultiMenu.currentItem))
            m.Add()
            transSub := Menu()
            Loop 9 {
                pct := A_Index * 10
                fn := MakeTransparentCB.Bind(pct)
                transSub.Add("透明运行:&" pct "%", fn)
            }
            m.Add("透明运行(&Q)", transSub)
            m.Add("置顶运行(&T)", (*) => Launcher.RunItem(MultiMenu.currentItem, { topmost: true }))
            m.Add("管理员权限运行(&A)", (*) => Launcher.RunItem(MultiMenu.currentItem, { admin: true }))
            m.Add("最小化运行(&I)", (*) => Launcher.RunItem(MultiMenu.currentItem, { runWay: "Min" }))
            m.Add("最大化运行(&P)", (*) => Launcher.RunItem(MultiMenu.currentItem, { runWay: "Max" }))
            m.Add("隐藏运行(&H)", (*) => Launcher.RunItem(MultiMenu.currentItem, { runWay: "Hide" }))
            m.Add("结束软件进程(&X)", (*) => MultiMenu.DoKill())
        }

        m.Add()
        m.Add("复制运行路径(&C)", (*) => MultiMenu.DoCopyPath())
        m.Add("输出运行路径(&V)", (*) => MultiMenu.DoSendPath())
        m.Add("复制软件名(&N)", (*) => MultiMenu.DoCopyName())
        m.Add("输出软件名(&M)", (*) => MultiMenu.DoSendName())

        try m.Show()
    }

    static DoKill() {
        Launcher.KillProcess(MultiMenu.currentItem)
    }

    static DoCopyPath() {
        item := MultiMenu.currentItem
        path := item.RunPath
        exePath := Launcher.ResolveExePath(item)
        if exePath != ""
            path := exePath
        A_Clipboard := path
        ToolTip(path)
        SetTimer(() => ToolTip(), -2000)
    }

    static DoSendPath() {
        item := MultiMenu.currentItem
        path := item.RunPath
        exePath := Launcher.ResolveExePath(item)
        if exePath != ""
            path := exePath
        savedClip := A_Clipboard
        A_Clipboard := path
        Sleep(50)
        Send("^v")
        Sleep(80)
        A_Clipboard := savedClip
    }

    static DoCopyName() {
        item := MultiMenu.currentItem
        exePath := Launcher.ResolveExePath(item)
        if exePath != "" {
            SplitPath(exePath, &fName, &fDir, &fExt, &fNameNoExt)
            A_Clipboard := fNameNoExt
        } else {
            A_Clipboard := RegExReplace(item.RunPath, "i)\.exe$", "")
        }
        ToolTip(A_Clipboard)
        SetTimer(() => ToolTip(), -2000)
    }

    static DoSendName() {
        MultiMenu.DoCopyName()
        savedClip := A_Clipboard
        Sleep(50)
        Send("^v")
        Sleep(80)
        A_Clipboard := savedClip
    }
}

MakeTransparentCB(pct, *) {
    Launcher.RunItem(MultiMenu.currentItem, { transparent: pct })
}
