class EverythingSDK {
    static hModule := 0
    static everyDLL := ""
    static initDone := false

    static Init() {
        if EverythingSDK.initDone
            return true
        ; Determine DLL path based on OS bitness
        if A_PtrSize = 8
            EverythingSDK.everyDLL := A_ScriptDir "\Everything64.dll"
        else
            EverythingSDK.everyDLL := A_ScriptDir "\Everything.dll"
        if !FileExist(EverythingSDK.everyDLL) {
            ; Try alternate locations
            if FileExist(A_ScriptDir "\Everything\Everything64.dll")
                EverythingSDK.everyDLL := A_ScriptDir "\Everything\Everything64.dll"
            else if FileExist(A_ScriptDir "\Everything\Everything.dll")
                EverythingSDK.everyDLL := A_ScriptDir "\Everything\Everything.dll"
            else
                return false
        }
        try {
            EverythingSDK.hModule := DllCall("LoadLibrary", "Str", EverythingSDK.everyDLL, "Ptr")
            EverythingSDK.initDone := true
            return true
        } catch {
            return false
        }
    }

    static SetSearch(searchStr) {
        try DllCall(EverythingSDK.everyDLL "\Everything_SetSearch", "Str", searchStr)
    }

    static SetMatchWholeWord(enable) {
        try DllCall(EverythingSDK.everyDLL "\Everything_SetMatchWholeWord", "Int", enable)
    }

    static SetRegex(enable) {
        try DllCall(EverythingSDK.everyDLL "\Everything_SetRegex", "Int", enable)
    }

    static Query(wait := 1) {
        try return DllCall(EverythingSDK.everyDLL "\Everything_Query", "Int", wait)
    }

    static GetIsAdmin() {
        try return DllCall(EverythingSDK.everyDLL "\Everything_IsAdmin")
    }

    static GetTotResults() {
        try return DllCall(EverythingSDK.everyDLL "\Everything_GetTotResults")
    }

    static GetNumFileResults() {
        try return DllCall(EverythingSDK.everyDLL "\Everything_GetNumFileResults")
    }

    static GetResultFileName(index) {
        try return StrGet(DllCall(EverythingSDK.everyDLL "\Everything_GetResultFileName", "Int", index))
    }

    static GetResultFullPathName(index, bufSize := 260) {
        try {
            buf := Buffer(bufSize * 2)
            DllCall(EverythingSDK.everyDLL "\Everything_GetResultFullPathName", "Int", index, "Ptr", buf, "Int", bufSize)
            return StrGet(buf)
        }
        return ""
    }

    static GetResultPath(index, bufSize := 260) {
        try {
            buf := Buffer(bufSize * 2)
            DllCall(EverythingSDK.everyDLL "\Everything_GetResultPath", "Int", index, "Ptr", buf, "Int", bufSize)
            return StrGet(buf)
        }
        return ""
    }

    static Free() {
        if EverythingSDK.hModule {
            try DllCall("FreeLibrary", "Ptr", EverythingSDK.hModule)
            EverythingSDK.hModule := 0
        }
        EverythingSDK.initDone := false
    }
}

class ExeResolver {
    static EvExePath := ""
    static EsExePath := ""

    static Init() {
        evDirs := [A_ScriptDir "\Everything\", A_ScriptDir]
        for d in evDirs {
            if FileExist(d "\Everything.exe") {
                ExeResolver.EvExePath := d "\Everything.exe"
                if FileExist(d "\es.exe")
                    ExeResolver.EsExePath := d "\es.exe"
                break
            }
        }
        ExeResolver.InitSDK()
    }

    static InitSDK() {
        if ConfigReader.ReadSetting("EvNo", "0") = "1"
            return false
        return EverythingSDK.Init()
    }

    static StartEverything() {
        if ExeResolver.EvExePath = ""
            return
        evPid := ProcessExist("Everything.exe")
        if evPid {
            if A_IsAdmin {
                evIsAdmin := false
                try evIsAdmin := EverythingSDK.GetIsAdmin()
                if !evIsAdmin {
                    evRunPath := ExeResolver.EvExePath
                    try evRunPath := ProcessGetPath(evPid)
                    try Run('"' evRunPath '" -exit',, "Hide")
                    Sleep(500)
                    try Run('"' evRunPath '" -startup -admin',, "Hide")
                    Sleep(500)
                    EverythingSDK.Free()
                    ExeResolver.InitSDK()
                    try TrayTip("RunAny与Everything权限不一致，已自动调整后启动", "RunAny", 17)
                }
            }
            return
        }
        adminArg := A_IsAdmin ? " -admin" : ""
        try Run('"' ExeResolver.EvExePath '" -startup' adminArg,, "Hide")
        Sleep(500)
    }

    ; 批量预解析所有无路径 EXE（V1 方式：Everything SDK 逐条搜索，进程内调用无开销）
    static PreResolveAll(parsed) {
        global g_PathCache, g_PathNotFound
        exeSet := Map()
        for cat in parsed.categories {
            ExeResolver._CollectExes(cat, exeSet)
        }
        if exeSet.Count = 0
            return

        if EverythingSDK.initDone {
            ; 过滤掉已在缓存中的 EXE（二次启动全命中 → 直接跳过 Everything 查询）
            uncached := Map()
            for exeName in exeSet {
                if !g_PathCache.Has(exeName) && !g_PathNotFound.Has(exeName)
                    uncached[exeName] := true
            }
            if uncached.Count = 0
                return

            ; V1 方式：构建正则 `^exe1\.exe$|^exe2\.exe$|...` 一次查询全部
            regex := ""
            for exeName in uncached {
                escaped := StrReplace(exeName, ".", "\.")
                escaped := StrReplace(escaped, "+", "\+")
                escaped := StrReplace(escaped, "[", "\[")
                escaped := StrReplace(escaped, "^", "\^")
                escaped := StrReplace(escaped, "$", "\$")
                if regex != ""
                    regex .= "|"
                regex .= "^" escaped "$"
            }
            EverythingSDK.SetRegex(true)
            EverythingSDK.SetSearch(regex)
            EverythingSDK.Query()
            numResults := EverythingSDK.GetNumFileResults()
            newCache := Map()
            Loop numResults {
                idx := A_Index - 1
                path := EverythingSDK.GetResultFullPathName(idx)
                if path != "" && FileExist(path) && !InStr(FileExist(path), "D") {
                    fName := EverythingSDK.GetResultFileName(idx)
                    if uncached.Has(fName) {
                        g_PathCache[fName] := path
                        newCache[fName] := path
                        noExt := RegExReplace(fName, "i)\.exe$")
                        if noExt != fName {
                            g_PathCache[noExt] := path
                            newCache[noExt] := path
                        }
                    }
                }
            }
            PathCache.BatchSave(newCache)
            for exeName in uncached {
                if !g_PathCache.Has(exeName)
                    g_PathNotFound[exeName] := true
            }
            ; 持久化未找到的 EXE，避免每次重启重复查询
            notFoundBuf := ""
            for exeName in uncached {
                if !g_PathCache.Has(exeName)
                    notFoundBuf .= exeName "=*`n"
            }
            if notFoundBuf != ""
                try FileAppend(notFoundBuf, PathCache.CACHE_FILE)
            EverythingSDK.SetRegex(false)
        }
    }

    static _CollectExes(cat, exeSet) {
        for item in cat.Items {
            if item.Mode = ItemMode.PROGRAM {
                exePath := item.RunPath
                if InStr(exePath, "`t")
                    exePath := StrSplit(exePath, "`t",, 2)[1]
                if RegExMatch(exePath, "iS)(.*?\.exe)($| .*)", &em)
                    exePath := em[1]
                if exePath != "" && !RegExMatch(exePath, "i)^(\\\\|[A-Za-z]:\\)") {
                    exeSet[exePath] := true
                }
            }
        }
        for child in cat.Children {
            ExeResolver._CollectExes(child, exeSet)
        }
    }

    static Find(exeName) {
        global g_PathCache, g_PathNotFound
        exeName := RegExReplace(exeName, "i)\.exe$", ".exe")
        exeNoExt := RegExReplace(exeName, "i)\.exe$")

        if g_PathNotFound.Has(exeName) || g_PathNotFound.Has(exeNoExt)
            return ""

        if g_PathCache.Has(exeName)
            return g_PathCache[exeName]
        if g_PathCache.Has(exeNoExt)
            return g_PathCache[exeNoExt]

        if InStr(exeName, ":") || InStr(exeName, "\\")
            return exeName

        ; 优先 Everything SDK（V1 方式，1.8s 批量），where.exe 作为后备
        path := ExeResolver.SearchEs(exeName)
        if path {
            g_PathCache[exeName] := path
            g_PathCache[exeNoExt] := path
            PathCache.Save(exeName, path)
            return path
        }

        path := ExeResolver.SearchWhere(exeName)
        if path {
            g_PathCache[exeName] := path
            g_PathCache[exeNoExt] := path
            PathCache.Save(exeName, path)
            return path
        }

        g_PathNotFound[exeName] := true
        g_PathNotFound[exeNoExt] := true
        return ""
    }

    static SearchWhere(exeName) {
        try {
            tmpFile := A_Temp "\_ra_where.tmp"
            RunWait(A_ComSpec ' /c where.exe "' exeName '" 2>nul > "' tmpFile '"',, "Hide")
            if !FileExist(tmpFile)
                return ""
            output := FileRead(tmpFile)
            try FileDelete(tmpFile)
            if output != "" {
                Loop Parse output, "`n", "`r" {
                    line := Trim(A_LoopField)
                    if line != "" && FileExist(line)
                        return line
                }
            }
        } catch {
        }
        return ""
    }

    static ResolveLnk(lnkPath) {
        try {
            FileGetShortcut(lnkPath, &target, &dir, &args, &desc, &icon, &iconNum)
            if icon != "" && FileExist(icon)
                return { target: target, icon: icon "," (iconNum != "" ? iconNum : 0) }
            if target != "" && FileExist(target)
                return { target: target, icon: target ",0" }
        }
        return ""
    }

    static GetEvCommand() {
        evCmd := "!" A_WinDir "* !?:\$RECYCLE.BIN* !?:\Users\*\AppData\Local\Temp*"
        evCmd .= " !?:\Users\*\AppData\Roaming\*.exe"
        try {
            scoopPath := EnvGet("SCOOP")
            if scoopPath != "" {
                scoopPath := RegExReplace(scoopPath, "([A-Za-z]:\\.*)", "?$1")
                evCmd .= " !" scoopPath "\shims\*"
            }
        }
        return evCmd
    }

    static SearchEs(exeName) {
        if !ProcessExist("Everything.exe")
            ExeResolver.StartEverything()

        if EverythingSDK.initDone
            return ExeResolver.SearchEsSDK(exeName)

        return ""  ; ponytail: removed es.exe CLI fallback - SDK covers 99% of cases
    }

    static SearchEsSDK(exeName, evCmd := "") {
        try {
            if evCmd = ""
                evCmd := ConfigReader.ReadSetting("EvCommand", ExeResolver.GetEvCommand())
            EverythingSDK.SetMatchWholeWord(true)
            EverythingSDK.SetSearch(exeName " " evCmd)
            EverythingSDK.Query()
            Loop EverythingSDK.GetNumFileResults() {
                idx := A_Index - 1
                path := EverythingSDK.GetResultFullPathName(idx)
                if path != "" && FileExist(path) && !InStr(FileExist(path), "D")
                    return path
            }
        }
        return ""
    }

}
