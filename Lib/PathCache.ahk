; PathCache.ahk - Persistent cache for resolved exe paths
; AutoHotkey v2

class PathCache {
    static CACHE_FILE := ""

    static Init() {
        global g_PathCache, g_PathNotFound

        PathCache.CACHE_FILE := A_ScriptDir "\RunAny_exe_paths.txt"
        if FileExist(PathCache.CACHE_FILE) {
            try {
                content := FileRead(PathCache.CACHE_FILE)
                Loop Parse content, "`n", "`r" {
                    eq := InStr(A_LoopField, "=")
                    if eq = 0
                        continue
                    exeName := SubStr(A_LoopField, 1, eq - 1)
                    val := SubStr(A_LoopField, eq + 1)
                    if val = ""
                        continue
                    if val = "*" {
                        ; "*" 标记为未找到（Persist g_PathNotFound）
                        g_PathNotFound[exeName] := true
                    } else if FileExist(val) {
                        g_PathCache[exeName] := val
                        noExt := RegExReplace(exeName, "i)\.exe$")
                        if noExt != exeName
                            g_PathCache[noExt] := val
                    }
                }
            }
        }
    }

    static Save(exeName, fullPath) {
        if exeName = "" || fullPath = ""
            return
        try FileAppend(exeName "=" fullPath "`n", PathCache.CACHE_FILE)
    }

    static BatchSave(cacheMap) {
        buf := ""
        for key, val in cacheMap {
            if key = "" || val = ""
                continue
            buf .= key "=" val "`n"
        }
        if buf != ""
            try FileAppend(buf, PathCache.CACHE_FILE)
    }
}

