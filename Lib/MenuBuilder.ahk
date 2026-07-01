class IconLoader {
    static Shell32Index := Map(
        "phrase", 71,
        "typing", 2,
        "hotkey", 100,
        "ahkhotkey", 101,
        "url", 14,
        "folder", 5,
        "plugin", 70,
        "fail", 124,
        "category", 4,
        "recent", 3,
        "run", 283,
        "edit", 134,
        "folder_open", 5,
        "admin", 78,
        "minimize", 284,
        "maximize", 285,
        "hide", 286,
        "topmost", 247,
        "transparent", 165,
        "kill", 274,
        "copy", 261,
        "search", 23,
    )

    ; 系统图标库白名单（裸文件名不带路径时，用于识别有效系统 DLL）
    static SysIconLibs := Map(
        "shell32.dll", 1, "imageres.dll", 1, "ddores.dll", 1,
        "moricons.dll", 1, "wmploc.dll", 1, "compstui.dll", 1,
        "ieframe.dll", 1, "mmcndmgr.dll", 1, "pifmgr.dll", 1,
    )

    static SetIcon(menuObj, itemName, iconPath, iconIndex := 0) {
        try {
            if !IconLoader.HasProp("_iconSize") {
                val := ConfigReader.ReadSetting("MenuIconSize", "")
                IconLoader._iconSize := val != "" ? Integer(val) : 0
            }
            if IconLoader._iconSize > 0
                menuObj.SetIcon(itemName, iconPath, iconIndex, IconLoader._iconSize)
            else
                menuObj.SetIcon(itemName, iconPath, iconIndex)
        }
    }

    static ReadIconSize() {
        val := ConfigReader.ReadSetting("MenuIconSize", "")
        return val != "" ? Integer(val) : 0
    }

    static ReadTrayIconSize() {
        val := ConfigReader.ReadSetting("MenuTrayIconSize", "")
        return val != "" ? Integer(val) : 0
    }

    ; 从 RunAnyConfig.ini 读取自定义图标配置，文件不存在时回退默认值（结果缓存）
    static _iconCache := Map()
    static ReadCustomIcon(key, defaultPath, defaultIndex) {
        if IconLoader._iconCache.Has(key)
            return IconLoader._iconCache[key]
        val := ConfigReader.ReadSetting(key, "")
        if val != "" {
            parts := StrSplit(val, ",")
            path := ConfigReader.TransformVar(Trim(parts[1]))
            index := parts.Length >= 2 ? Integer(Trim(parts[2])) : 0
            ; 带路径的文件：必须 FileExist
            if RegExMatch(path, "^[A-Za-z]:|\\") {
                if FileExist(path) {
                    result := { path: path, index: index }
                    IconLoader._iconCache[key] := result
                    return result
                }
            } else {
                ; 裸文件名：脚本目录存在 或 是系统 DLL
                if FileExist(A_ScriptDir "\" path) || IconLoader.SysIconLibs.Has(StrLower(path)) {
                    result := { path: path, index: index }
                    IconLoader._iconCache[key] := result
                    return result
                }
            }
        }
        result := { path: defaultPath, index: defaultIndex }
        IconLoader._iconCache[key] := result
        return result
    }

    static GetExeIcon(item) {
        ; 优先使用 BuildCategoryMenu 预解析的路径（避免重复调用 SearchWhere/searchEs）
        if item.HasProp("_resolvedPath") && FileExist(item._resolvedPath)
            return { path: item._resolvedPath, index: 0 }
        if RegExMatch(item.RunPath, "i)^(\\\\|[A-Za-z]:\\).*?\.exe", &m) {
            if FileExist(m[0])
                return { path: m[0], index: 0 }
        }
        ; 无路径 EXE (如 "notepad.exe") → 通过缓存/解析器查找完整路径
        exeName := item.RunPath
        if InStr(exeName, "`t")
            exeName := StrSplit(exeName, "`t",, 2)[1]
        if RegExMatch(exeName, "iS)(.*?\.exe)($| .*)", &em)
            exeName := em[1]
        if exeName != "" && !RegExMatch(exeName, "i)^(\\\\|[A-Za-z]:\\)") {
            resolved := PathCache.Get(exeName)
            if resolved != ""
                return { path: resolved, index: 0 }
        }
        return ""
    }

    static FindIconInLibrary(displayName) {
        ; 首次调用时预扫描所有图标文件夹，构建缓存 Map（O(1) 查找，V1 无此操作）
        if !IconLoader.HasProp("_iconDirCache") {
            IconLoader._iconDirCache := Map()
            IconLoader._iconDirsCache := ""
            iconFolders := ConfigReader.ReadSetting("IconFolderPath", "")
            defDirs := A_ScriptDir "\RunIcon\ExeIcon|" A_ScriptDir "\RunIcon\WebIcon|" A_ScriptDir "\RunIcon\MenuIcon"
            if iconFolders != ""
                defDirs := iconFolders "|" defDirs
            Loop Parse defDirs, "|", " `t" {
                folder := A_LoopField
                if folder = ""
                    continue
                folder := ConfigReader.TransformVar(folder)
                if !DirExist(folder)
                    continue
                Loop Files folder "\*" {
                    nameNoExt := RegExReplace(A_LoopFileName, "\.[^.]+$")
                    if !IconLoader._iconDirCache.Has(nameNoExt)
                        IconLoader._iconDirCache[nameNoExt] := A_LoopFilePath ",1"
                }
            }
        }
        cleanName := RegExReplace(displayName, "\t.*$", "")
        cleanName := Trim(cleanName)
        return IconLoader._iconDirCache.Has(cleanName) ? IconLoader._iconDirCache[cleanName] : ""
    }

    static GetItemIcon(item) {
        libResult := IconLoader.FindIconInLibrary(item.DisplayText)
        if libResult != "" {
            parts := StrSplit(libResult, ",")
            return { path: parts[1], index: Integer(parts[2]) }
        }
        switch item.Mode {
            case ItemMode.PHRASE, ItemMode.TYPING_PHRASE:
                return { path: "shell32.dll", index: IconLoader.Shell32Index["phrase"] }
            case ItemMode.HOTKEY:
                return { path: "shell32.dll", index: IconLoader.Shell32Index["hotkey"] }
            case ItemMode.AHK_HOTKEY:
                return { path: "shell32.dll", index: IconLoader.Shell32Index["ahkhotkey"] }
            case ItemMode.URL:
            {
                urlIconCfg := ConfigReader.ReadSetting("UrlIcon", "")
                if urlIconCfg != "" {
                    parts := StrSplit(urlIconCfg, ",")
                    return { path: Trim(parts[1]), index: parts.Length >= 2 ? Integer(Trim(parts[2])) : 0 }
                }
                webIcon := IconLoader.GetWebIcon(item.RunPath, item.DisplayText)
                if webIcon
                    return webIcon
                return { path: "shell32.dll", index: IconLoader.Shell32Index["url"] }
            }
            case ItemMode.FOLDER:
                return IconLoader.ReadCustomIcon("FolderIcon", "shell32.dll", IconLoader.Shell32Index["folder"])
            case ItemMode.PLUGIN:
                return IconLoader.ReadCustomIcon("FuncIcon", "shell32.dll", IconLoader.Shell32Index["plugin"])
            case ItemMode.PROGRAM, ItemMode.EXE_URL:
                icon := IconLoader.GetExeIcon(item)
                if icon
                    return icon
                extIcon := IconLoader.GetExtIcon(item.RunPath)
                if extIcon
                    return extIcon
                return IconLoader.ReadCustomIcon("EXEIcon", "shell32.dll", IconLoader.Shell32Index["fail"])
            case ItemMode.FAIL:
                extIcon := IconLoader.GetExtIcon(item.RunPath)
                if extIcon
                    return extIcon
                return IconLoader.ReadCustomIcon("EXEIcon", "shell32.dll", IconLoader.Shell32Index["fail"])
            default:
                return ""
        }
    }

    ; 通过注册表获取文件扩展名的关联图标（V1 行为复刻）
    ; 流程：.ext → ProgID → ProgID\DefaultIcon → path,index
    static _extIconCache := Map()
    static GetExtIcon(runPath) {
        try {
            ; 从路径中提取扩展名
            ext := ""
            if RegExMatch(runPath, "i)\.([a-zA-Z0-9]{1,10})$", &m)
                ext := m[1]
            if ext = ""
                return ""
            ; 命中缓存直接返回
            if IconLoader._extIconCache.Has(ext)
                return IconLoader._extIconCache[ext]

            ; 尝试直接读取 .ext\DefaultIcon
            try {
                extIcon := RegRead("HKEY_CLASSES_ROOT\." ext, "DefaultIcon")
                if extIcon != "" {
                    parsed := IconLoader.ParseIconString(extIcon)
                    if parsed.path != "" {
                        IconLoader._extIconCache[ext] := parsed
                        return parsed
                    }
                }
            }

            ; 回退：读取 ProgID 再查 DefaultIcon
            progID := ""
            try progID := RegRead("HKEY_CLASSES_ROOT\." ext)
            if progID = "" {
                IconLoader._extIconCache[ext] := ""
                return ""
            }

            regIcon := ""
            try regIcon := RegRead("HKEY_CLASSES_ROOT\" progID "\DefaultIcon")
            if regIcon = "" {
                IconLoader._extIconCache[ext] := ""
                return ""
            }

            result := IconLoader.ParseIconString(regIcon)
            IconLoader._extIconCache[ext] := result
            return result
        } catch {
            if IsSet(ext) && ext != ""
                IconLoader._extIconCache[ext] := ""
            return ""
        }
    }

    ; 解析注册表图标字符串 "path,index" 或 """path"",index"
    static ParseIconString(iconStr) {
        iconStr := Trim(iconStr)
        if iconStr = ""
            return { path: "", index: 0 }

        iconPath := iconStr
        iconIndex := 0

        pos := InStr(iconStr, ",",, -1)  ; 从末尾找逗号
        ; 排除路径中含逗号的情况（引号内的逗号）
        if pos > 0 {
            beforeComma := SubStr(iconStr, 1, pos - 1)
            afterComma := Trim(SubStr(iconStr, pos + 1))
            ; 检查 afterComma 是否为数字
            if RegExMatch(afterComma, "^-?\d+$") {
                iconPath := Trim(beforeComma)
                iconIndex := Integer(afterComma)
            }
        }

        ; 去除路径两端的引号
        if SubStr(iconPath, 1, 1) = '"'
            iconPath := SubStr(iconPath, 2, -1)

        iconPath := Trim(iconPath)
        if iconPath = ""
            return { path: "", index: 0 }

        ; 展开环境变量
        iconPath := IconLoader.ExpandEnvPath(iconPath)

        if !FileExist(iconPath)
            return { path: "", index: 0 }

        return { path: iconPath, index: iconIndex > 0 ? iconIndex : 0 }
    }

    ; 展开含环境变量的路径（如 %ProgramFiles%\xxx）
    static ExpandEnvPath(path) {
        try {
            bufSize := DllCall("ExpandEnvironmentStringsW", "Str", path, "Ptr", 0, "Int", 0)
            buf := Buffer(bufSize * 2)
            DllCall("ExpandEnvironmentStringsW", "Str", path, "Ptr", buf, "Int", bufSize)
            return StrGet(buf)
        } catch {
            return path
        }
    }

    ; EXE 图标提取：从所有菜单 PROGRAM 项提取图标并保存为 .ico 文件
    ; 保存到 RunIcon\ExeIcon 目录，加速后续菜单加载
    static ExtractAllIcons(categories, overwrite := false) {
        exeIconDir := ConfigReader.ReadSetting("ExeIconDir", A_ScriptDir "\RunIcon\ExeIcon")
        exeIconDir := ConfigReader.TransformVar(exeIconDir)
        if !DirExist(exeIconDir)
            DirCreate(exeIconDir)

        count := 0
        items := []
        IconLoader._CollectProgramItems(categories, items)

        for item in items {
            exePath := item.RunPath
            if RegExMatch(exePath, "`t")
                exePath := StrSplit(exePath, "`t",, 2)[1]
            if RegExMatch(exePath, "iS)(.*?\.exe)($| .*)", &em)
                exePath := em[1]
            if exePath = "" || RegExMatch(exePath, "i)^(\\\\|[A-Za-z]:\\)") = 0 {
                resolved := PathCache.Get(exePath)
                if resolved = ""
                    try resolved := ExeResolver.Find(exePath)
                if resolved != ""
                    exePath := resolved
            }
            if exePath = "" || !FileExist(exePath)
                continue

            cleanName := RegExReplace(item.DisplayText, "\t.*$", "")
            cleanName := Trim(cleanName)
            ; 清理文件名中不允许的字符
            cleanName := RegExReplace(cleanName, '[\\/:*?"<>|]', "_")
            icoFile := exeIconDir "\" cleanName ".ico"

            if !overwrite && FileExist(icoFile)
                continue

            ; 使用 PrivateExtractIcons 提取图标并保存
            if IconLoader.ExtractIconToFile(exePath, icoFile)
                count++
        }
        return count
    }

    static _CollectProgramItems(categories, result) {
        for cat in categories {
            for item in cat.Items {
                if item.Mode = ItemMode.PROGRAM
                    result.Push(item)
            }
            if cat.Children.Length > 0
                IconLoader._CollectProgramItems(cat.Children, result)
        }
    }

    ; 从 EXE 文件提取第一个图标并保存为 .ico 文件
    static ExtractIconToFile(exePath, icoPath) {
        try {
            ; 获取图标数量
            iconCount := DllCall("Shell32\PrivateExtractIconsW"
                , "Str", exePath
                , "Int", 0       ; iconIndex
                , "Int", 0       ; cx (0 = don't extract, just count)
                , "Int", 0       ; cy
                , "Ptr", 0       ; phicon
                , "Ptr", 0       ; piconid
                , "Int", 0       ; nIcons
                , "Int", 0       ; flags
                , "UInt")

            if iconCount <= 0
                return false

            ; 分配缓冲区
            hIcons := Buffer(A_PtrSize * 1)
            iconIds := Buffer(4 * 1)

            ; 提取 32x32 图标
            extracted := DllCall("Shell32\PrivateExtractIconsW"
                , "Str", exePath
                , "Int", 0
                , "Int", 32
                , "Int", 32
                , "Ptr", hIcons
                , "Ptr", iconIds
                , "Int", 1
                , "Int", 0
                , "UInt")

            if extracted <= 0
                return false

            hIcon := NumGet(hIcons, 0, "Ptr")
            if !hIcon
                return false

            ; 将图标保存为 .ico 文件
            result := IconLoader.SaveIconToFile(hIcon, icoPath)

            ; 释放图标句柄
            DllCall("User32\DestroyIcon", "Ptr", hIcon)

            return result
        } catch {
            return false
        }
    }

    ; 将图标句柄保存为 .ico 文件
    static SaveIconToFile(hIcon, icoPath) {
        try {
            ; 获取图标信息
            ii := Buffer(A_PtrSize + 4 * 4 + A_PtrSize * 4)
            DllCall("User32\GetIconInfo", "Ptr", hIcon, "Ptr", ii)

            ; 获取位图信息以确定图标大小
            bm := Buffer(32)  ; BITMAP structure
            hColor := NumGet(ii, A_PtrSize + 16, "Ptr")
            DllCall("User32\GetObjectW", "Ptr", hColor, "Int", 32, "Ptr", bm)
            width := NumGet(bm, 4, "Int")
            height := NumGet(bm, 8, "Int")

            ; 创建 .ico 文件
            ; ICO header: reserved(2) + type(2) + count(2) = 6 bytes
            ; ICO directory entry: width(1) + height(1) + colors(1) + reserved(1) + planes(2) + bpp(2) + size(4) + offset(4) = 16 bytes
            ; Total header = 22 bytes, data starts at offset 22

            ; 写入文件
            f := FileOpen(icoPath, "w", "UTF-8-RAW")

            ; ICO header
            f.WriteUShort(0)        ; reserved
            f.WriteUShort(1)        ; type = ICO
            f.WriteUShort(1)        ; count = 1 icon

            ; Directory entry (placeholder - we'll fill size later)
            f.WriteUChar(width > 255 ? 0 : width)
            f.WriteUChar(height > 255 ? 0 : height)
            f.WriteUChar(0)         ; color palette
            f.WriteUChar(0)         ; reserved
            f.WriteUShort(1)        ; color planes
            f.WriteUShort(32)       ; bits per pixel

            ; Create icon data using ICONDIRENTRY approach
            ; Use a memory DC to get the bitmap bits
            hdc := DllCall("User32\GetDC", "Ptr", 0, "Ptr")
            hMemDC := DllCall("Gdi32\CreateCompatibleDC", "Ptr", hdc, "Ptr")

            ; Create DIB section for color bitmap
            bi := Buffer(40)  ; BITMAPINFOHEADER
            NumPut("UInt", 40, bi, 0)            ; biSize
            NumPut("Int", width, bi, 4)           ; biWidth
            NumPut("Int", height * 2, bi, 8)      ; biHeight (color + mask)
            NumPut("UShort", 1, bi, 12)            ; biPlanes
            NumPut("UShort", 32, bi, 14)           ; biBitCount (32-bit ARGB)
            NumPut("UInt", 0, bi, 16)              ; biCompression = BI_RGB
            NumPut("UInt", 0, bi, 20)              ; biSizeImage (0 for BI_RGB)
            NumPut("Int", 0, bi, 24)               ; biXPelsPerMeter
            NumPut("Int", 0, bi, 28)               ; biYPelsPerMeter
            NumPut("UInt", 0, bi, 32)              ; biClrUsed
            NumPut("UInt", 0, bi, 36)              ; biClrImportant

            pBits := 0
            hDIB := DllCall("Gdi32\CreateDIBSection"
                , "Ptr", hMemDC
                , "Ptr", bi
                , "UInt", 0         ; DIB_RGB_COLORS
                , "Ptr*", &pBits
                , "Ptr", 0
                , "UInt", 0
                , "Ptr")

            hOldObj := DllCall("Gdi32\SelectObject", "Ptr", hMemDC, "Ptr", hDIB, "Ptr")

            ; Draw the icon onto the DIB section
            DllCall("User32\DrawIconEx"
                , "Ptr", hMemDC
                , "Int", 0, "Int", 0
                , "Ptr", hIcon
                , "Int", width, "Int", height
                , "UInt", 0
                , "Ptr", 0     ; hbrFlickerFreeDraw
                , "UInt", 0x03) ; DI_MASK | DI_IMAGE

            ; Calculate data size
            colorRowSize := ((width * 32 + 31) // 32) * 4
            maskRowSize := ((width + 31) // 32) * 4
            colorSize := colorRowSize * height
            maskSize := maskRowSize * height
            dataSize := 40 + colorSize + maskSize  ; BITMAPINFOHEADER + color + mask

            ; Now write the directory entry with actual size
            ; We already wrote partial entry, need to go back
            f.WriteUInt(dataSize)   ; size of image data
            f.WriteUInt(22)         ; offset to image data

            ; Write BITMAPINFOHEADER for the icon
            f.WriteUInt(40)           ; biSize
            f.WriteInt(width)         ; biWidth
            f.WriteInt(height * 2)    ; biHeight (doubled for XOR + AND masks)
            f.WriteUShort(1)          ; biPlanes
            f.WriteUShort(32)         ; biBitCount
            f.WriteUInt(0)            ; biCompression
            f.WriteUInt(dataSize - 40) ; biSizeImage
            f.WriteInt(0)             ; biXPelsPerMeter
            f.WriteInt(0)             ; biYPelsPerMeter
            f.WriteUInt(0)            ; biClrUsed
            f.WriteUInt(0)            ; biClrImportant

            ; Write color (XOR) bits
            colorData := Buffer(colorSize)
            DllCall("RtlMoveMemory", "Ptr", colorData.Ptr, "Ptr", pBits, "Ptr", colorSize)
            ; Flip rows (BITMAP is bottom-up)
            rowBuf := Buffer(colorRowSize)
            Loop height / 2 {
                srcOff := (A_Index - 1) * colorRowSize
                dstOff := (height - A_Index) * colorRowSize
                DllCall("RtlMoveMemory", "Ptr", rowBuf.Ptr, "Ptr", colorData.Ptr + srcOff, "Ptr", colorRowSize)
                DllCall("RtlMoveMemory", "Ptr", colorData.Ptr + srcOff, "Ptr", colorData.Ptr + dstOff, "Ptr", colorRowSize)
                DllCall("RtlMoveMemory", "Ptr", colorData.Ptr + dstOff, "Ptr", rowBuf.Ptr, "Ptr", colorRowSize)
            }
            f.RawWrite(colorData)

            ; Write AND mask (all zeros = fully opaque)
            maskData := Buffer(maskSize, 0)
            f.RawWrite(maskData)

            ; Cleanup
            DllCall("Gdi32\SelectObject", "Ptr", hMemDC, "Ptr", hOldObj, "Ptr")
            DllCall("Gdi32\DeleteObject", "Ptr", hDIB)
            DllCall("Gdi32\DeleteDC", "Ptr", hMemDC)
            DllCall("User32\ReleaseDC", "Ptr", 0, "Ptr", hdc)
            DllCall("Gdi32\DeleteObject", "Ptr", hColor)
            hMask := NumGet(ii, A_PtrSize + 16 + A_PtrSize, "Ptr")
            if hMask
                DllCall("Gdi32\DeleteObject", "Ptr", hMask)

            f.Close()
            return true
        } catch {
            return false
        }
    }

    static GetWebIcon(url, displayName := "") {
        domain := RegExReplace(url, "i)[\w-]+://?((\w+\.)+\w+).*", "$1")
        if domain = url
            return ""
        iconDir := ConfigReader.ReadSetting("WebIconDir", A_ScriptDir "\RunIcon\WebIcon")
        iconDir := ConfigReader.TransformVar(iconDir)
        namedIcon := iconDir "\" domain ".ico"
        if FileExist(namedIcon)
            return { path: namedIcon, index: 0 }
        if displayName != "" {
            cleanName := RegExReplace(displayName, "\t.*$", "")
            cleanName := Trim(cleanName)
            namedIcon := iconDir "\" cleanName ".ico"
            if FileExist(namedIcon)
                return { path: namedIcon, index: 0 }
        }
        return ""
    }
}

class MenuBuilder {
    extMap := Map()
    categories := []
    textCategories := []
    fileCategories := []
    publicCategories := []
    windowCategories := Map()
    defaultRoot := ""
    textRoot := ""
    fileRoot := ""
    defaultSubMenuMap := Map()
    textSubMenuMap := Map()
    fileSubMenuMap := Map()
    textRootFlag := false
    treeHotkeyMap := Map()
    menuShowFlag := false
    treeImageListID := 0

    __New(parsed) {
        this.categories := parsed.categories
        this.rootItems := parsed.HasProp("rootItems") ? parsed.rootItems : []
        this.extMap := parsed.extMap
        this.textCategories := parsed.textCategories
        this.fileCategories := parsed.fileCategories
        this.publicCategories := parsed.publicCategories
        this.windowCategories := parsed.windowCategories
        this.treeHotkeyMap := parsed.treeHotkeyMap
    }

    Build() {
        this.defaultSubMenuMap := Map()
        this.textSubMenuMap := Map()
        this.fileSubMenuMap := Map()
        this.textRootFlag := false

        this.defaultRoot := this.BuildRoot("default")
        this.textRoot := this.BuildRoot("text")
        this.fileRoot := this.BuildRoot("file")

        ; Register tree category hotkeys
        this.RegisterTreeHotkeys()

        ; Preload icon cache
        this.PreloadIcons()

        this.menuShowFlag := true

        return this.defaultRoot
    }

    RegisterTreeHotkeys() {
        for hotkey, catName in this.treeHotkeyMap {
            try {
                subMenu := this.FindCategoryMenu(catName)
                if subMenu {
                    Hotkey(hotkey, (hk) => this.Show(subMenu), "On")
                }
            }
        }
    }

    PreloadIcons() {
        ; Pre-create image list for icon caching
        try {
            this.treeImageListID := IL_Create(20)
        } catch {
            this.treeImageListID := 0
        }
    }

    BuildRoot(rootType) {
        root := Menu()
        subMap := rootType = "default" ? this.defaultSubMenuMap
                 : rootType = "text" ? this.textSubMenuMap
                 : this.fileSubMenuMap

        ; We intentionally do NOT call RecentItems.AddToMenu(root) here anymore.
        ; Recent items are injected dynamically in ShowMenu() to ensure real-time updates.
        ; However, we add a dummy separator if there will be recent items, to separate them from the rest.
        ; Or rather, we let InjectToMenu handle the insertion cleanly at position 1.

        hasTextCats := this.textCategories.Length > 0
        hasFileCats := this.fileCategories.Length > 0

        for cat in this.categories {
            if rootType = "text" && hasTextCats && !this.InCategoryList(this.textCategories, cat.Name)
                continue
            if rootType = "file" && hasFileCats && !this.InCategoryList(this.fileCategories, cat.Name)
                continue
            this.BuildCategoryMenu(root, cat, rootType, subMap)
        }

        ; 根级项目（单独一行 - 回归后落到 root.Items 的项）
        if rootType = "default" {
            for item in this.rootItems {
                if item.Mode = ItemMode.SEPARATOR {
                    root.Add()
                } else {
                    callback := ObjBindMethod(this, "OnItem", item)
                    root.Add(item.DisplayText, callback)
                    icon := IconLoader.GetItemIcon(item)
                    if icon
                        IconLoader.SetIcon(root, item.DisplayText, icon.path, icon.index)
                }
            }
        }

        ; Add "设置" menu item at the bottom for default root
        if rootType = "default" {
            hideMenuTray := ConfigReader.ReadSetting("HideMenuTray", "0") = "1"
            if !hideMenuTray {
                try root.Add()
                itemName := "RunAny 设置"
                try root.Add(itemName, (*) => SettingsGui.Show())
                icon := IconLoader.ReadCustomIcon("MenuIcon", "shell32.dll", IconLoader.Shell32Index["edit"])
                IconLoader.SetIcon(root, itemName, icon.path, icon.index)
            }
        }

        return root
    }

    InCategoryList(catList, name) {
        for c in catList
            if c = name
                return true
        return false
    }

    BuildCategoryMenu(parentMenu, cat, rootType, subMap) {
        sub := Menu()
        hasTextCats := this.textCategories.Length > 0
        hasFileCats := this.fileCategories.Length > 0
        urlItems := []

        ; 一次性读取隐藏设置（避免循环内每项都 IniRead）
        localHideFail := ConfigReader.ReadSetting("HideFail", "0") = "1"
        localHideSend := ConfigReader.ReadSetting("HideSend", "0") = "1"
        localHideWeb := ConfigReader.ReadSetting("HideWeb", "0") = "1"
        localHideGetZz := ConfigReader.ReadSetting("HideGetZz", "0") = "1"

        for item in cat.Items {
            if item.Mode = ItemMode.SEPARATOR {
                try sub.Add()
                continue
            }

            mode := item.Mode
            path := item.RunPath

            if rootType = "text" && hasTextCats {
                if !InStr(path, "%getZz%") && !InStr(path, "%s")
                    continue
            }

            if rootType = "file" && hasFileCats {
                if !InStr(path, "%getZz%") && !InStr(path, "%s") && mode != ItemMode.PROGRAM && mode != ItemMode.FAIL
                    continue
            }

            ; Resolve paths and detect failures for all root types
            if mode = ItemMode.PROGRAM {
                if item.HasProp("_resolvedChecked") {
                    if item.HasProp("_resolvedFailed") && item._resolvedFailed
                        mode := ItemMode.FAIL
                } else {
                    item._resolvedChecked := true
                    item._resolvedFailed := false
                    exePath := path
                    if InStr(exePath, "`t")
                        exePath := StrSplit(exePath, "`t",, 2)[1]
                    if RegExMatch(exePath, "iS)(.*?\.exe)($| .*)", &em)
                        exePath := em[1]
                    if exePath != "" && !RegExMatch(exePath, "i)^(\\\\|[A-Za-z]:\\)") {
                        resolved := PathCache.Get(exePath)
                        if resolved != "" && FileExist(resolved) {
                            item._resolvedPath := resolved
                        } else if PathCache.IsNotFound(exePath) {
                            item._resolvedFailed := true
                            mode := ItemMode.FAIL
                        } else {
                            item._resolvedPending := true
                        }
                    } else if exePath != "" && !FileExist(exePath) {
                        item._resolvedFailed := true
                        mode := ItemMode.FAIL
                    }
                }
            }

            ; Apply hiding settings for all roots (consistent with V1)
            if localHideFail && mode = ItemMode.FAIL
                continue
            if localHideSend && (mode = ItemMode.PHRASE || mode = ItemMode.TYPING_PHRASE)
                continue
            if localHideWeb && mode = ItemMode.URL && InStr(path, "%s")
                continue
            if localHideGetZz && InStr(path, "%getZz%")
                continue

            ; Collect URL items for batch search
            if (mode = ItemMode.URL || mode = ItemMode.EXE_URL) && (InStr(path, "%s") || InStr(path, "%getZz%"))
                urlItems.Push(item)

            callback := ObjBindMethod(this, "OnItem", item)
            try sub.Add(item.DisplayText, callback)

            icon := IconLoader.GetItemIcon(item)
            if icon {
                try IconLoader.SetIcon(sub, item.DisplayText, icon.path, icon.index)
            }
        }

        ; Add batch search item if 2+ URL items with %s/%getZz%
        if urlItems.Length >= 2 {
            try sub.Add()
            try sub.Add("🔍 批量搜索", (*) => Launcher.BatchSearch(urlItems, g_SelectedText))
            try IconLoader.SetIcon(sub, "🔍 批量搜索", "shell32.dll", IconLoader.Shell32Index["search"])
        }

        for child in cat.Children {
            if rootType = "text" && hasTextCats && !this.InCategoryList(this.textCategories, child.Name)
                continue
            if rootType = "file" && hasFileCats && !this.InCategoryList(this.fileCategories, child.Name)
                continue
            this.BuildCategoryMenu(sub, child, rootType, subMap)
        }

        ; V1: "添加到此菜单" 和 "显示全部菜单" 在 ShowMenu() 时动态注入/移除，
        ; 不在 BuildCategoryMenu 中静态写入每个子菜单

        subMap[cat.Name] := sub

        try {
            parentMenu.Add(cat.Name, sub)
            ; V1 逻辑：分类图标名 = treeLevel（"-"/"--"等）+ cat.Name，优先匹配图标库
            dashes := ""
            Loop cat.Level
                dashes .= "-"
            libIcon := IconLoader.FindIconInLibrary(dashes . cat.Name)
            if libIcon != "" {
                parts := StrSplit(libIcon, ",")
                IconLoader.SetIcon(parentMenu, cat.Name, parts[1], Integer(parts[2]))
            } else {
                ci := IconLoader.ReadCustomIcon("TreeIcon", "shell32.dll", IconLoader.Shell32Index["category"])
                IconLoader.SetIcon(parentMenu, cat.Name, ci.path, ci.index)
            }
        }
    }

    OnItem(item, itemName, itemPos, menu) {
        Launcher.RunItem(item)
    }

    NormalizeLookupName(name) {
        name := Trim(RegExReplace(name, "\t.*$"))
        name := RegExReplace(name, "\(&?.\)")
        name := StrReplace(name, "&")
        return name
    }

    FindItemByName(itemName) {
        target := this.NormalizeLookupName(itemName)
        return this._FindItemInCategories(this.categories, target)
    }

    _FindItemInCategories(cats, target) {
        for cat in cats {
            for item in cat.Items {
                if item.Mode = ItemMode.SEPARATOR
                    continue
                if item.DisplayText = target || item.Name = target
                    return item
                if this.NormalizeLookupName(item.DisplayText) = target
                    return item
            }
            found := this._FindItemInCategories(cat.Children, target)
            if found
                return found
        }
        return ""
    }

    FindCategoryMenu(catName, rootType := "default") {
        if rootType = "default" && this.defaultSubMenuMap.Has(catName)
            return this.defaultSubMenuMap[catName]
        if rootType = "text" && this.textSubMenuMap.Has(catName)
            return this.textSubMenuMap[catName]
        if rootType = "file" && this.fileSubMenuMap.Has(catName)
            return this.fileSubMenuMap[catName]
        if this.defaultSubMenuMap.Has(catName)
            return this.defaultSubMenuMap[catName]
        return ""
    }

    Show(menuObj, x := unset, y := unset) {
        global g_SelectedText, g_RootMenuDefault, g_RootMenuFile, g_RootMenuText, g_RootMenu2Default, g_RootMenu2File, g_RootMenu2Text
        
        ; 动态注入最近运行项（仅限根菜单）
        if menuObj = g_RootMenuDefault || menuObj = g_RootMenuFile || menuObj = g_RootMenuText || menuObj = g_RootMenu2Default || menuObj = g_RootMenu2File || menuObj = g_RootMenu2Text {
            RecentItems.InjectToMenu(menuObj)
        }

        showLen := Integer(ConfigReader.ReadSetting("ShowGetZzLen", "30"))
        hideSelect := ConfigReader.ReadSetting("HideSelectZz", "0") = "1"
        hasSelect := !hideSelect && g_SelectedText != ""
        selectLabel := ""

        if hasSelect {
            selectLabel := g_SelectedText
            if StrLen(selectLabel) > showLen
                selectLabel := SubStr(selectLabel, 1, showLen) "..."
            try {
                menuObj.Insert(1, selectLabel, (*) => (A_Clipboard := g_SelectedText))
            }
        }

        ; V1 行为：非根菜单时动态注入 "显示全部菜单"（显示后删除）
        allShowInjected := false
        showAllLabel := ""
        isNotDefaultRoot := (menuObj != g_RootMenuDefault && menuObj != g_RootMenu2Default)
        if isNotDefaultRoot {
            showAllLabel := ConfigReader.ReadSetting("RUNANY_SELF_MENU_ITEM4", "-【显示全部菜单】")
            try {
                menuObj.Add(showAllLabel, (*) => this.Show(g_RootMenuDefault))
                allShowInjected := true
            }
        }

        try {
            if IsSet(x) && IsSet(y)
                menuObj.Show(x, y)
            else
                menuObj.Show()
        } catch as e {
            ToolTip("显示菜单出错: " e.Message)
            SetTimer(() => ToolTip(), -3000)
        }

        ; 清理临时注入的项（按名称删除）
        if allShowInjected {
            try menuObj.Delete(showAllLabel)
        }
        if hasSelect {
            try menuObj.Delete(selectLabel)
        }
    }

    ShowMenu(noGet := false) {
        global g_SelectedText, g_SelectedIsFile, g_SelectedFileExt

        ; Anti-flicker: wait for menu to be ready
        if !this.menuShowFlag {
            SetTimer(() => this.ShowMenu(noGet), -10)
            return
        }

        if noGet {
            g_SelectedText := ""
            g_SelectedIsFile := 0
        } else {
            g_SelectedText := GetSelectedText()
        }
        g_SelectedFileExt := ""

        try pname := WinGetProcessName("A")
        try pclass := WinGetClass("A")
        hasWindowCats := this.windowCategories.Count > 0

        hideAddItem := ConfigReader.ReadSetting("HideAddItem", "0") = "1"

        ; 无选中内容时显示默认/窗口关联菜单
        if g_SelectedText = "" {
            if hasWindowCats {
                if this.windowCategories.Has(pclass) {
                    cats := this.windowCategories[pclass]
                    if cats.Length > 0 {
                        catMenu := this.FindCategoryMenu(cats[1])
                        if catMenu {
                            if FolderHelper.IsActiveDialog() {
                                FolderHelper.ShowWithFolders(catMenu)
                            } else {
                                this.Show(catMenu)
                            }
                            return
                        }
                    }
                }
                if this.windowCategories.Has(pname) {
                    cats := this.windowCategories[pname]
                    if cats.Length > 0 {
                        catMenu := this.FindCategoryMenu(cats[1])
                        if catMenu {
                            if FolderHelper.IsActiveDialog() {
                                FolderHelper.ShowWithFolders(catMenu)
                            } else {
                                this.Show(catMenu)
                            }
                            return
                        }
                    }
                }
            }
            if FolderHelper.IsActiveDialog() {
                FolderHelper.ShowWithFolders(this.defaultRoot)
            } else {
                this.Show(this.defaultRoot)
            }
            return
        }

        if g_SelectedIsFile {
            SplitPath(g_SelectedText, &fName, &fDir, &fExt)
            if InStr(FileExist(g_SelectedText), "D")
                fExt := "folder"
            g_SelectedFileExt := fExt

            if fExt != "" && this.extMap.Has(fExt) {
                cat := this.extMap[fExt]
                extMenu := this.FindCategoryMenu(cat.Name, "file")
                if !extMenu
                    extMenu := this.FindCategoryMenu(cat.Name, "default")
                if extMenu {
                    items := this.GetCategoryItems(cat.Name)
                    if items.Length = 1 {
                        Launcher.RunItem(items[1])
                        return
                    }
                    ; V1：文件匹配后缀菜单时，动态注入 "添加到此菜单"
                    addItemLabel := ""
                    if !hideAddItem {
                        addItemLabel := ConfigReader.ReadSetting("RUNANY_SELF_MENU_ITEM3", "0【添加到此菜单】")
                        try extMenu.Add(addItemLabel, (*) => this.AddFileToMenu())
                    }
                    this.Show(extMenu)
                    if addItemLabel != ""
                        try extMenu.Delete(addItemLabel)
                    return
                }
            }

            showTarget := this.fileCategories.Length > 0 ? this.fileRoot : this.defaultRoot
            ; V1 行为：选中文件时动态注入 "添加到此菜单"
            addItemLabel := ""
            if !hideAddItem {
                addItemLabel := ConfigReader.ReadSetting("RUNANY_SELF_MENU_ITEM3", "0【添加到此菜单】")
                try showTarget.Add(addItemLabel, (*) => this.AddFileToMenu())
            }
            this.Show(showTarget)
            if addItemLabel != ""
                try showTarget.Delete(addItemLabel)
            return
        }

        ; V1 行为：选中文字（非文件）时，先尝试一键直达正则匹配
        ; 匹配成功则直接执行（不显示菜单）
        if OneKeyDirect.Execute(g_SelectedText)
            return
        if ConfigReader.ReadSetting("OneKeyMenu", "0") = "1" {
            OneKeySearch(g_SelectedText)
            return
        }

        if this.textCategories.Length > 0 {
            if hasWindowCats && this.windowCategories.Has(pname) {
                cats := this.windowCategories[pname]
                if cats.Length > 0 {
                    showMenu := this.BuildWindowInjectedMenu(cats, this.textRoot)
                    this.Show(showMenu)
                    return
                }
            }
            if this.textCategories.Length = 1 && !this.textRootFlag {
                singleCat := this.textCategories[1]
                singleMenu := this.FindCategoryMenu(singleCat, "text")
                if singleMenu {
                    this.Show(singleMenu)
                    return
                }
            }
            this.Show(this.textRoot)
        } else {
            this.Show(this.defaultRoot)
        }
    }

    AddTempAddToMenuItem(menuObj) {
        ADD_ITEM_NAME := "➕ 添加到此菜单"
        try {
            try menuObj.Insert(1, ADD_ITEM_NAME, (*) => this.AddFileToMenu())
            try menuObj.SetIcon(ADD_ITEM_NAME, "shell32.dll", 166)
            try menuObj.Insert(2)  ; separator after
        }
    }

    RemoveTempAddToMenuItem(menuObj) {
        ADD_ITEM_NAME := "➕ 添加到此菜单"
        try menuObj.Delete(2)    ; separator first
        try menuObj.Delete(ADD_ITEM_NAME)
    }

    AddFileToMenu() {
        global g_SelectedText, g_SelectedIsFile, INI_PATH
        if !g_SelectedIsFile || g_SelectedText = ""
            return

        entries := StrSplit(g_SelectedText, "`n", "`r")
        count := 0
        for entry in entries {
            if Trim(entry) = ""
                continue
            isDir := InStr(FileExist(entry), "D")
            SplitPath(entry, &fName, &fDir, &fExt, &fNameNoExt)
            if isDir {
                itemName := fName
                itemPath := entry
            } else if fExt = "exe" || fExt = "lnk" {
                itemName := fNameNoExt
                itemPath := entry
            } else {
                itemName := fName
                itemPath := entry
            }

            ; ═══ V1 风格编辑对话框 ═══
            eg := Gui("-MinimizeBox -MaximizeBox", "新增修改菜单项 - " APP_NAME " - 支持拖放应用" (A_IsAdmin ? " 【管理员】" : ""))
            eg.SetFont("s10", "Microsoft YaHei")
            eg.MarginX := 15
            eg.MarginY := 15
            
            eg.AddText("xm y20 w70", "菜单项名:")
            nameEd := eg.AddEdit("x+5 yp-3 w340", itemName)
            eg.SetFont("s9")
            eg.AddLink("x+5 yp+3 w100 cGreen Right", '<a>点击添加图标</a>').OnEvent("Click", (*) => (
                iconFile := FileSelect(1, , "选择图标文件", "图标 (*.exe; *.ico; *.dll)"),
                iconFile != "" && (nameEd.Value := nameEd.Value . "_" . iconFile)
            ))
            eg.SetFont("s10")
            
            eg.AddText("xm y+15 w70", "热字符串:")
            hsValEd := eg.AddEdit("x+5 yp-3 w120")
            
            eg.AddText("xm y+15 w70", "制表符:")
            eg.AddText("x+5 yp", "Tab")
            
            eg.AddText("xm y+15 w70", "全局热键:")
            hkEd := eg.AddHotkey("x+5 yp-3 w220")
            winCb := eg.AddCheckbox("x+10 yp", "Win")
            
            eg.AddText("xm y+15 w70", "分隔符:")
            eg.AddText("x+5 yp w10", "|")
            
            modes := ["启动路径", "短语模式(;)", "模拟打字(;;)", "热键映射(::)", "AHK热键(:::)", "网址", "文件夹", "插件脚本函数"]
            modeIdx := 1
            if !isDir {
                if fExt = "exe" || fExt = "lnk" || fExt = "bat" || fExt = "cmd" || fExt = "ps1" || fExt = "ahk"
                    modeIdx := 1
                else if RegExMatch(itemPath, "i)^(http|www\.)")
                    modeIdx := 6
            } else {
                modeIdx := 7
            }
            modeSel := eg.AddDropDownList("x+250 yp-3 w130 Choose" modeIdx, modes)
            
            ; 4 vertical buttons on the left, one large edit box on the right
            btnW := 80
            eg.AddButton("Section xm y+15 w" btnW, "启动路径").OnEvent("Click", (*) => (
                p := FileSelect(, , "选择程序或文件"), p != "" && (pathEd.Value := p)
            ))
            eg.AddButton("xs y+8 w" btnW, "相对路径").OnEvent("Click", (*) => (
                pathEd.Value := StrReplace(pathEd.Value, A_ScriptDir, "%A_ScriptDir%")
            ))
            eg.AddButton("xs y+8 w" btnW, "选中变量").OnEvent("Click", (*) => (
                pathEd.Focus(), SendInput("{Text}%getZz%")
            ))
            eg.AddButton("xs y+8 w" btnW, "剪贴板").OnEvent("Click", (*) => (
                pathEd.Focus(), SendInput("{Text}%Clipboard%")
            ))
            
            ; 放置在启动路径按钮的右侧，高度(h)大约为4个按钮(每个约25)+3个间距(8) = 100+24 = 124
            pathEd := eg.AddEdit("ys x+10 w450 h124 -WantReturn", itemPath)

            saved := false
            eg.AddButton("Default xm+180 y+15 w80", "保存").OnEvent("Click", (*) => (
                saved := true, eg.Hide()
            ))
            eg.AddButton("x+50 yp w80", "取消").OnEvent("Click", (*) => eg.Hide())
            
            eg.SetFont("s9")
            eg.AddText("xm y+20 cBlue", "新增项会在『编辑(Edit)』分类下")
            eg.SetFont("s10")

            eg.OnEvent("Close", (*) => eg.Hide())
            eg.OnEvent("Escape", (*) => eg.Hide())
            eg.Show("w580")
            
            while WinExist("ahk_id " eg.Hwnd)
                Sleep(50)
            if !saved
                continue

            finalName := nameEd.Value
            finalPath := pathEd.Value
            if finalName = "" || finalPath = ""
                continue

            if hsValEd.Value != ""
                finalName .= ":*X:" hsValEd.Value

            ; 拼接 INI 行
            iniLine := finalName
            if hkEd.Value != "" {
                hkVal := hkEd.Value
                if winCb.Value
                    hkVal := "#" hkVal
                iniLine .= "`t" hkVal
            }
            iniLine .= "|" finalPath

            selMode := modeSel.Value
            if selMode = 2
                iniLine .= ";"
            else if selMode = 3
                iniLine .= ";;"
            else if selMode = 4
                iniLine .= "::"
            else if selMode = 5
                iniLine .= ":::"

            if isDir && selMode = 7 {
                ; 文件夹并且保持为文件夹模式：插一个分类头 + 路径
                this._InsertToINI("`n- " StrReplace(finalName, "|", "") "`n" iniLine)
            } else {
                this._InsertToINI(iniLine)
            }
            count++
        }

        if count > 0 {
            ToolTip("已添加 " count " 个项目到菜单`n下次重启生效")
            SetTimer(() => ToolTip(), -3000)
        }
    }

    ; 智能插入：找到 INI 中最后一个非注释/非分类头的有效行之后插入
    _InsertToINI(line) {
        global INI_PATH
        content := ""
        try content := FileRead(INI_PATH, "CP0")
        lines := StrSplit(content, "`n", "`r")

        ; 从后往前找到最后一个有效菜单项或分类头的位置
        insertAt := lines.Length
        Loop lines.Length {
            i := lines.Length - A_Index + 1
            if i < 1
                break
            l := Trim(lines[i])
            if l = "" || InStr(l, ";") = 1
                continue
            insertAt := i
            break
        }

        ; 在找到的位置后插入新行
        newContent := ""
        for i, l in lines {
            newContent .= l "`n"
            if i = insertAt
                newContent .= line "`n"
        }
        if insertAt = lines.Length  ; 空文件或无有效行
            newContent := line "`n"
        try {
            f := FileOpen(INI_PATH, "w", "CP0")
            f.Write(newContent)
            f.Close()
        }
    }

    BuildWindowInjectedMenu(windowCats, baseMenu) {
        tempMenu := Menu()

        for catName in windowCats {
            catSubMenu := this.FindCategoryMenu(catName)
            if catSubMenu {
                try tempMenu.Add(catName, catSubMenu)
                libIcon := IconLoader.FindIconInLibrary(catName)
                if libIcon != "" {
                    parts := StrSplit(libIcon, ",")
                    IconLoader.SetIcon(tempMenu, catName, parts[1], Integer(parts[2]))
                } else {
                    ci := IconLoader.ReadCustomIcon("TreeIcon", "shell32.dll", IconLoader.Shell32Index["category"])
                    IconLoader.SetIcon(tempMenu, catName, ci.path, ci.index)
                }
            }
        }

        try tempMenu.Add()
        tempMenu.Add("▶ 显示全部菜单", (*) => this.Show(baseMenu))

        return tempMenu
    }

    GetCategoryItems(catName) {
        items := []
        this._CollectItems(this.categories, catName, items)
        return items
    }

    _CollectItems(cats, targetName, result) {
        for cat in cats {
            if cat.Name = targetName {
                for item in cat.Items {
                    if item.Mode != ItemMode.SEPARATOR
                        result.Push(item)
                }
                return true
            }
            if cat.Children.Length > 0 {
                if this._CollectItems(cat.Children, targetName, result)
                    return true
            }
        }
        return false
    }
}

; IL_Create compatibility wrapper for AHK v2 (DPI-aware)
IL_Create(count := 10, grow := 5, large := false) {
    static ILC_COLOR32 := 0x20
    static ILC_MASK := 0x1
    flags := ILC_COLOR32 | ILC_MASK
    cx := large ? DllCall("User32\GetSystemMetrics", "Int", 11) : DllCall("User32\GetSystemMetrics", "Int", 49)  ; SM_CXICON / SM_CXSMICON
    cy := large ? DllCall("User32\GetSystemMetrics", "Int", 12) : DllCall("User32\GetSystemMetrics", "Int", 50)  ; SM_CYICON / SM_CYSMICON
    return DllCall("comctl32.dll\ImageList_Create", "Int", cx, "Int", cy, "UInt", flags, "Int", count, "Int", grow, "Ptr")
}
