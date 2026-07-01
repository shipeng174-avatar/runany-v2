; PathCache.ahk - Persistent cache for resolved exe paths
; AutoHotkey v2

class PathCache {
    static CACHE_FILE := ""

    static Init() {
        global g_PathCache, g_PathNotFound

        PathCache.CACHE_FILE := A_ScriptDir "\RunAny_exe_paths.txt"
        dirty := false
        if FileExist(PathCache.CACHE_FILE) {
            try {
                content := FileRead(PathCache.CACHE_FILE)
                Loop Parse content, "`n", "`r" {
                    eq := InStr(A_LoopField, "=")
                    if eq = 0 {
                        dirty := true
                        continue
                    }
                    exeName := SubStr(A_LoopField, 1, eq - 1)
                    val := SubStr(A_LoopField, eq + 1)
                    key := PathCache.NormalizeKey(exeName)
                    if val = "" || key = "" {
                        dirty := true
                        continue
                    }
                    if key != exeName
                        dirty := true
                    if val = "*" {
                        ; Old versions persisted transient Everything misses as "*".
                        ; Ignore them so moved/new apps can be resolved again.
                        dirty := true
                        continue
                    } else if FileExist(val) {
                        if g_PathCache.Has(key)
                            dirty := true
                        g_PathCache[key] := val
                    } else
                        dirty := true
                }
            }
        }
        if dirty
            PathCache.Compact()
    }

    static NormalizeKey(exeName) {
        exeName := Trim(exeName)
        if exeName = ""
            return ""
        if InStr(exeName, "`t")
            exeName := StrSplit(exeName, "`t",, 2)[1]
        if RegExMatch(exeName, "iS)(.*?\.exe)($| .*)", &em)
            exeName := em[1]
        if RegExMatch(exeName, "i)^(\\\\|[A-Za-z]:\\)") {
            SplitPath(exeName, &fileName)
            exeName := fileName
        }
        exeName := Trim(exeName)
        if exeName = ""
            return ""
        if !RegExMatch(exeName, "i)\.exe$")
            exeName .= ".exe"
        return StrLower(exeName)
    }

    static Get(exeName, defaultValue := "") {
        global g_PathCache
        key := PathCache.NormalizeKey(exeName)
        if key != "" && g_PathCache.Has(key)
            return g_PathCache[key]
        return defaultValue
    }

    static Has(exeName) {
        global g_PathCache
        key := PathCache.NormalizeKey(exeName)
        return key != "" && g_PathCache.Has(key)
    }

    static Put(exeName, fullPath) {
        global g_PathCache
        key := PathCache.NormalizeKey(exeName)
        if key = "" || fullPath = ""
            return ""
        g_PathCache[key] := fullPath
        return key
    }

    static IsNotFound(exeName) {
        global g_PathNotFound
        key := PathCache.NormalizeKey(exeName)
        return key != "" && g_PathNotFound.Has(key)
    }

    static MarkNotFound(exeName) {
        global g_PathNotFound
        key := PathCache.NormalizeKey(exeName)
        if key != ""
            g_PathNotFound[key] := true
    }

    static Save(exeName, fullPath) {
        if exeName = "" || fullPath = ""
            return
        PathCache.Put(exeName, fullPath)
        PathCache.Compact()
    }

    static BatchSave(cacheMap) {
        for key, val in cacheMap {
            if key = "" || val = ""
                continue
            PathCache.Put(key, val)
        }
        PathCache.Compact()
    }

    static Compact() {
        global g_PathCache
        if PathCache.CACHE_FILE = ""
            return
        compacted := Map()
        for key, val in g_PathCache {
            normKey := PathCache.NormalizeKey(key)
            if normKey = "" || val = ""
                continue
            if !FileExist(val)
                continue
            compacted[normKey] := val
        }
        g_PathCache := compacted
        buf := ""
        for key, val in compacted {
            buf .= key "=" val "`n"
        }
        try {
            f := FileOpen(PathCache.CACHE_FILE, "w", "UTF-8")
            if f {
                f.Write(buf)
                f.Close()
            }
        }
    }
}
