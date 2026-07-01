class EverythingSDK {
    static hModule := 0
    static everyDLL := ""
    static sdkVersion := 0
    static client := 0
    static searchState := 0
    static resultList := 0
    static regex := false
    static matchWholeWord := false
    static activeInstanceName := ""
    static initDone := false

    static Init() {
        if EverythingSDK.initDone
            return true
        if EverythingSDK.InitSDK3()
            return true
        return EverythingSDK.InitSDK1()
    }

    static InitSDK3() {
        dll := EverythingSDK.FindSDK3Dll()
        if dll = ""
            return false
        instance := ConfigReader.ReadSetting("EverythingInstanceName", "")
        try {
            hModule := DllCall("LoadLibrary", "Str", dll, "Ptr")
            if !hModule
                return false
            client := DllCall(dll "\Everything3_ConnectW", "Str", instance, "Ptr")
            if !client && instance = "" {
                client := DllCall(dll "\Everything3_ConnectW", "Str", "1.5a", "Ptr")
                if client
                    instance := "1.5a"
            }
            if !client {
                try DllCall("FreeLibrary", "Ptr", hModule)
                return false
            }
            EverythingSDK.hModule := hModule
            EverythingSDK.everyDLL := dll
            EverythingSDK.client := client
            EverythingSDK.activeInstanceName := instance
            EverythingSDK.sdkVersion := 3
            EverythingSDK.initDone := true
            return true
        } catch {
            return false
        }
    }

    static InitSDK1() {
        ; Determine DLL path based on OS bitness.
        if A_PtrSize = 8
            EverythingSDK.everyDLL := A_ScriptDir "\Everything64.dll"
        else
            EverythingSDK.everyDLL := A_ScriptDir "\Everything.dll"
        if !FileExist(EverythingSDK.everyDLL) {
            if FileExist(A_ScriptDir "\Everything\Everything64.dll")
                EverythingSDK.everyDLL := A_ScriptDir "\Everything\Everything64.dll"
            else if FileExist(A_ScriptDir "\Everything\Everything.dll")
                EverythingSDK.everyDLL := A_ScriptDir "\Everything\Everything.dll"
            else
                return false
        }
        try {
            EverythingSDK.hModule := DllCall("LoadLibrary", "Str", EverythingSDK.everyDLL, "Ptr")
            EverythingSDK.sdkVersion := 1
            EverythingSDK.initDone := true
            return true
        } catch {
            return false
        }
    }

    static FindSDK3Dll() {
        name := A_PtrSize = 8 ? "Everything3_x64.dll" : "Everything3_x86.dll"
        candidates := [
            A_ScriptDir "\" name,
            A_ScriptDir "\Everything\" name
        ]
        for dll in candidates {
            if FileExist(dll)
                return dll
        }
        return ""
    }

    static SetSearch(searchStr) {
        if EverythingSDK.sdkVersion = 3 {
            EverythingSDK.DestroySDK3Search()
            try {
                EverythingSDK.searchState := DllCall(EverythingSDK.everyDLL "\Everything3_CreateSearchState", "Ptr")
                if !EverythingSDK.searchState
                    return
                DllCall(EverythingSDK.everyDLL "\Everything3_SetSearchRegex", "Ptr", EverythingSDK.searchState, "Int", EverythingSDK.regex, "Int")
                DllCall(EverythingSDK.everyDLL "\Everything3_SetSearchMatchWholeWords", "Ptr", EverythingSDK.searchState, "Int", EverythingSDK.matchWholeWord, "Int")
                DllCall(EverythingSDK.everyDLL "\Everything3_SetSearchTextW", "Ptr", EverythingSDK.searchState, "Str", searchStr, "Int")
            }
            return
        }
        try DllCall(EverythingSDK.everyDLL "\Everything_SetSearch", "Str", searchStr)
    }

    static SetMatchWholeWord(enable) {
        EverythingSDK.matchWholeWord := enable
        if EverythingSDK.sdkVersion = 3 {
            if EverythingSDK.searchState
                try DllCall(EverythingSDK.everyDLL "\Everything3_SetSearchMatchWholeWords", "Ptr", EverythingSDK.searchState, "Int", enable, "Int")
            return
        }
        try DllCall(EverythingSDK.everyDLL "\Everything_SetMatchWholeWord", "Int", enable)
    }

    static SetRegex(enable) {
        EverythingSDK.regex := enable
        if EverythingSDK.sdkVersion = 3 {
            if EverythingSDK.searchState
                try DllCall(EverythingSDK.everyDLL "\Everything3_SetSearchRegex", "Ptr", EverythingSDK.searchState, "Int", enable, "Int")
            return
        }
        try DllCall(EverythingSDK.everyDLL "\Everything_SetRegex", "Int", enable)
    }

    static Query(wait := 1) {
        if EverythingSDK.sdkVersion = 3 {
            if !EverythingSDK.client || !EverythingSDK.searchState
                return false
            if EverythingSDK.resultList {
                try DllCall(EverythingSDK.everyDLL "\Everything3_DestroyResultList", "Ptr", EverythingSDK.resultList, "Int")
                EverythingSDK.resultList := 0
            }
            try {
                EverythingSDK.resultList := DllCall(EverythingSDK.everyDLL "\Everything3_Search", "Ptr", EverythingSDK.client, "Ptr", EverythingSDK.searchState, "Ptr")
                return EverythingSDK.resultList ? true : false
            }
            return false
        }
        try return DllCall(EverythingSDK.everyDLL "\Everything_Query", "Int", wait)
    }

    static GetIsAdmin() {
        if EverythingSDK.sdkVersion = 3
            return true
        try return DllCall(EverythingSDK.everyDLL "\Everything_IsAdmin")
    }

    static GetTotResults() {
        if EverythingSDK.sdkVersion = 3
            return EverythingSDK.GetNumFileResults()
        try return DllCall(EverythingSDK.everyDLL "\Everything_GetTotResults")
    }

    static GetNumFileResults() {
        if EverythingSDK.sdkVersion = 3 {
            if !EverythingSDK.resultList
                return 0
            try return DllCall(EverythingSDK.everyDLL "\Everything3_GetResultListViewportCount", "Ptr", EverythingSDK.resultList, "UPtr")
            return 0
        }
        try return DllCall(EverythingSDK.everyDLL "\Everything_GetNumFileResults")
    }

    static GetResultFileName(index) {
        if EverythingSDK.sdkVersion = 3 {
            if !EverythingSDK.resultList
                return ""
            try {
                buf := Buffer(32768 * 2)
                DllCall(EverythingSDK.everyDLL "\Everything3_GetResultNameW", "Ptr", EverythingSDK.resultList, "UPtr", index, "Ptr", buf, "UPtr", 32768, "UPtr")
                return StrGet(buf)
            }
            return ""
        }
        try return StrGet(DllCall(EverythingSDK.everyDLL "\Everything_GetResultFileName", "Int", index))
    }

    static GetResultFullPathName(index, bufSize := 260) {
        if EverythingSDK.sdkVersion = 3 {
            if !EverythingSDK.resultList
                return ""
            try {
                if bufSize < 32768
                    bufSize := 32768
                buf := Buffer(bufSize * 2)
                DllCall(EverythingSDK.everyDLL "\Everything3_GetResultFullPathNameW", "Ptr", EverythingSDK.resultList, "UPtr", index, "Ptr", buf, "UPtr", bufSize, "UPtr")
                return StrGet(buf)
            }
            return ""
        }
        try {
            buf := Buffer(bufSize * 2)
            DllCall(EverythingSDK.everyDLL "\Everything_GetResultFullPathName", "Int", index, "Ptr", buf, "Int", bufSize)
            return StrGet(buf)
        }
        return ""
    }

    static GetResultPath(index, bufSize := 260) {
        if EverythingSDK.sdkVersion = 3 {
            if !EverythingSDK.resultList
                return ""
            try {
                if bufSize < 32768
                    bufSize := 32768
                buf := Buffer(bufSize * 2)
                DllCall(EverythingSDK.everyDLL "\Everything3_GetResultPathW", "Ptr", EverythingSDK.resultList, "UPtr", index, "Ptr", buf, "UPtr", bufSize, "UPtr")
                return StrGet(buf)
            }
            return ""
        }
        try {
            buf := Buffer(bufSize * 2)
            DllCall(EverythingSDK.everyDLL "\Everything_GetResultPath", "Int", index, "Ptr", buf, "Int", bufSize)
            return StrGet(buf)
        }
        return ""
    }

    static DestroySDK3Search() {
        if EverythingSDK.resultList {
            try DllCall(EverythingSDK.everyDLL "\Everything3_DestroyResultList", "Ptr", EverythingSDK.resultList, "Int")
            EverythingSDK.resultList := 0
        }
        if EverythingSDK.searchState {
            try DllCall(EverythingSDK.everyDLL "\Everything3_DestroySearchState", "Ptr", EverythingSDK.searchState, "Int")
            EverythingSDK.searchState := 0
        }
    }

    static Free() {
        if EverythingSDK.sdkVersion = 3 {
            EverythingSDK.DestroySDK3Search()
            if EverythingSDK.client {
                try DllCall(EverythingSDK.everyDLL "\Everything3_DestroyClient", "Ptr", EverythingSDK.client, "Int")
                EverythingSDK.client := 0
            }
        }
        if EverythingSDK.hModule {
            try DllCall("FreeLibrary", "Ptr", EverythingSDK.hModule)
            EverythingSDK.hModule := 0
        }
        EverythingSDK.sdkVersion := 0
        EverythingSDK.everyDLL := ""
        EverythingSDK.regex := false
        EverythingSDK.matchWholeWord := false
        EverythingSDK.activeInstanceName := ""
        EverythingSDK.initDone := false
    }
}

class ExeResolver {
    static EvExePath := ""
    static EsExePath := ""

    static Init() {
        evPath := ConfigReader.TransformVar(ConfigReader.ReadSetting("EvPath", ""))
        if evPath != "" && FileExist(evPath) {
            ExeResolver.EvExePath := evPath
            evDir := RegExReplace(evPath, "\\[^\\]+$")
            if FileExist(evDir "\es.exe")
                ExeResolver.EsExePath := evDir "\es.exe"
        }
        evDirs := [A_ScriptDir "\Everything\", A_ScriptDir]
        for d in evDirs {
            if ExeResolver.EvExePath != ""
                break
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
        evPid := ExeResolver.FindEverythingProcess(true)
        if evPid {
            if A_IsAdmin && EverythingSDK.sdkVersion != 3 {
                evIsAdmin := false
                try evIsAdmin := EverythingSDK.GetIsAdmin()
                if !evIsAdmin {
                    evRunPath := ExeResolver.EvExePath
                    try evRunPath := ProcessGetPath(evPid)
                    try Run('"' evRunPath '" -exit' ExeResolver.GetInstanceArgs(),, "Hide")
                    Sleep(500)
                    try Run('"' evRunPath '" -startup' ExeResolver.GetInstanceArgs() ' -admin',, "Hide")
                    Sleep(500)
                    EverythingSDK.Free()
                    ExeResolver.InitSDK()
                    try TrayTip("RunAny与Everything权限不一致，已自动调整后启动", "RunAny", 17)
                }
            }
            return
        }
        ExeResolver.StopMismatchedEverythingProcess()
        adminArg := A_IsAdmin ? " -admin" : ""
        try Run('"' ExeResolver.EvExePath '" -startup' ExeResolver.GetInstanceArgs() adminArg,, "Hide")
        Sleep(500)
        EverythingSDK.Free()
        ExeResolver.InitSDK()
    }

    static FindEverythingProcess(matchConfiguredPath := false) {
        targetPath := matchConfiguredPath ? ExeResolver.NormalizePath(ExeResolver.EvExePath) : ""
        try {
            for proc in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId,ExecutablePath FROM Win32_Process WHERE Name='Everything64.exe' OR Name='Everything.exe'") {
                pid := Integer(proc.ProcessId)
                if !matchConfiguredPath
                    return pid
                procPath := ""
                try procPath := proc.ExecutablePath
                if targetPath != "" && ExeResolver.NormalizePath(procPath) = targetPath
                    return pid
            }
        }
        for name in ["Everything64.exe", "Everything.exe"] {
            pid := ProcessExist(name)
            if !pid
                continue
            if !matchConfiguredPath
                return pid
            try {
                if targetPath != "" && ExeResolver.NormalizePath(ProcessGetPath(pid)) = targetPath
                    return pid
            }
        }
        return 0
    }

    static FindEverythingWindow(matchConfiguredPath := true) {
        for hwnd in WinGetList("ahk_class EVERYTHING") {
            try {
                pid := WinGetPID("ahk_id " hwnd)
                if !matchConfiguredPath || ExeResolver.IsConfiguredEverythingPid(pid)
                    return hwnd
            }
        }
        return 0
    }

    static IsConfiguredEverythingPid(pid) {
        targetPath := ExeResolver.NormalizePath(ExeResolver.EvExePath)
        if !pid || targetPath = ""
            return false
        try return ExeResolver.NormalizePath(ProcessGetPath(pid)) = targetPath
        return false
    }

    static StopMismatchedEverythingProcess() {
        targetPath := ExeResolver.NormalizePath(ExeResolver.EvExePath)
        if targetPath = ""
            return
        try {
            for proc in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId,ExecutablePath FROM Win32_Process WHERE Name='Everything64.exe' OR Name='Everything.exe'") {
                procPath := ""
                try procPath := proc.ExecutablePath
                if procPath = "" || ExeResolver.NormalizePath(procPath) = targetPath
                    continue
                try Run('"' procPath '" -exit' ExeResolver.GetInstanceArgs(),, "Hide")
                Sleep(500)
                return
            }
        }
        pid := ExeResolver.FindEverythingProcess(false)
        if !pid
            return
        try {
            procPath := ProcessGetPath(pid)
            if procPath != "" && ExeResolver.NormalizePath(procPath) != targetPath {
                try Run('"' procPath '" -exit' ExeResolver.GetInstanceArgs(),, "Hide")
                Sleep(500)
            }
        }
    }

    static NormalizePath(path) {
        path := Trim(path, " `t`r`n`"")
        if path = ""
            return ""
        return StrLower(StrReplace(path, "/", "\"))
    }

    static GetInstanceArgs() {
        instance := ConfigReader.ReadSetting("EverythingInstanceName", "")
        if instance = ""
            return ""
        return ' -instance "' StrReplace(instance, '"', '\"') '"'
    }

    ; 批量预解析所有无路径 EXE（V1 方式：Everything SDK 逐条搜索，进程内调用无开销）
    static PreResolveAll(parsed) {
        if ConfigReader.ReadSetting("ResolveNoPathOnStartup", "0") != "1"
            return

        exeSet := Map()
        for cat in parsed.categories {
            ExeResolver._CollectExes(cat, exeSet)
        }
        if parsed.HasProp("rootItems")
            ExeResolver._CollectItemExes(parsed.rootItems, exeSet)
        if exeSet.Count = 0
            return

        uncached := Map()
        for exeName in exeSet {
            key := PathCache.NormalizeKey(exeName)
            if key != "" && !PathCache.Has(key) && !PathCache.IsNotFound(key) {
                uncached[key] := exeName
            }
        }
        if uncached.Count = 0
            return

        ExeResolver.StartEverything()
        if EverythingSDK.sdkVersion != 3 && EverythingSDK.FindSDK3Dll() != "" {
            EverythingSDK.Free()
            ExeResolver.InitSDK()
        } else if !EverythingSDK.initDone {
            ExeResolver.InitSDK()
        }
        if !EverythingSDK.initDone
            return

        ; Everything SDK is ready here; query only the missing no-path EXE entries.
        regex := ""
        for key, exeName in uncached {
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
                key := PathCache.NormalizeKey(fName)
                if key != "" && uncached.Has(key) {
                    PathCache.Put(key, path)
                    newCache[key] := path
                }
            }
        }
        PathCache.BatchSave(newCache)
        ; Do not persist batch misses. Everything can return partial/empty results
        ; while starting or reindexing; on-demand Find() can retry later.
        EverythingSDK.SetRegex(false)
    }

    static _CollectExes(cat, exeSet) {
        ExeResolver._CollectItemExes(cat.Items, exeSet)
        for child in cat.Children {
            ExeResolver._CollectExes(child, exeSet)
        }
    }

    static _CollectItemExes(items, exeSet) {
        for item in items {
            if item.Mode != ItemMode.PROGRAM
                continue
            exePath := item.RunPath
            if InStr(exePath, "`t")
                exePath := StrSplit(exePath, "`t",, 2)[1]
            if RegExMatch(exePath, "iS)(.*?\.exe)($| .*)", &em)
                exePath := em[1]
            if exePath != "" && !RegExMatch(exePath, "i)^(\\\\|[A-Za-z]:\\)")
                exeSet[exePath] := true
        }
    }

    static Find(exeName) {
        key := PathCache.NormalizeKey(exeName)
        if key = ""
            return ""

        if InStr(exeName, ":") || InStr(exeName, "\\")
            return exeName

        if PathCache.IsNotFound(key)
            return ""

        cached := PathCache.Get(key)
        if cached != ""
            return cached

        ; 优先 Everything SDK（V1 方式，1.8s 批量），where.exe 作为后备
        path := ExeResolver.SearchEs(key)
        if path {
            PathCache.Save(key, path)
            return path
        }

        path := ExeResolver.SearchWhere(key)
        if path {
            PathCache.Save(key, path)
            return path
        }

        PathCache.MarkNotFound(key)
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
        if ConfigReader.ReadSetting("EvNo", "0") = "1"
            return ""

        if !ExeResolver.FindEverythingProcess(true) {
            ExeResolver.StartEverything()
            EverythingSDK.Free()
            ExeResolver.InitSDK()
        } else if EverythingSDK.sdkVersion != 3 && EverythingSDK.FindSDK3Dll() != "" {
            EverythingSDK.Free()
            ExeResolver.InitSDK()
        } else if !EverythingSDK.initDone {
            ExeResolver.InitSDK()
        }

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
