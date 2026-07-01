#Requires AutoHotkey v2.0
#Warn VarUnset, Off
/*
【ObjReg插件对象注册工具（不用自启）】
*/
global RunAny_Plugins_Name := "ObjReg插件对象注册工具（不用自启）"
global RunAny_Plugins_Version:="1.0.4"
SplitPath(A_LineFile, , &RunAny_ObjReg_Dir)
global RunAny_ObjReg:=RunAny_ObjReg_Dir "\RunAny_ObjReg.ini" ;~插件注册配置文件
global objreg:="objreg"
SetTitleMatchMode(2)         ;~窗口标题模糊匹配
DetectHiddenWindows(true)      ;~显示隐藏窗口
SplitPath(A_ScriptFullPath, &name, , &ext, &nameNotExt)
;~[生成插件脚本GUID]
if(!FileExist(RunAny_ObjReg)){
	FileAppend("[" objreg "]", RunAny_ObjReg)
}
objGUID := IniRead(RunAny_ObjReg, objreg, nameNotExt, A_Space)
if(!objGUID && nameNotExt!="RunAny_ObjReg"){
	objGUID:=CreateGUID()
	IniWrite(objGUID, RunAny_ObjReg, objreg, nameNotExt)
    if ProcessExist("RunAny.exe")
	{
        RunAnyPath := WinGetProcessPath("ahk_exe RunAny.exe")
        RunAny_Send_WM_COPYDATA("Menu_Reload","RunAny.ahk ahk_class AutoHotkey")
    }
    if WinExist("RunAny.ahk ahk_class AutoHotkey")
    {
        PostMessage(0x111, 65400, , , "RunAny.ahk ahk_class AutoHotkey")
    }
}
global __RunAnyObjInstance := ""
if(IsSet(RunAnyObj) && IsObject(RunAnyObj)){
	; AHK v2: 注册实例而非类（类对象不暴露实例方法）
	__RunAnyObjInstance := RunAnyObj()
	ObjRegisterActive(__RunAnyObjInstance, objGUID)
}

;[注册脚本对象]
ObjRegisterActive(Object, CLSID, Flags:=0) {
    static cookieJar := Map()
    if (!CLSID) {
        if cookieJar.Has(Object) {
            cookie := cookieJar[Object]
            DllCall("oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0)
            cookieJar.Delete(Object)
        }
        return
    }
    if cookieJar.Has(Object)
        throw Error("Object is already registered", -1)
    _clsid := Buffer(16)
    if (hr := DllCall("ole32\CLSIDFromString", "wstr", CLSID, "ptr", _clsid)) < 0
        throw Error("Invalid CLSID", -1, CLSID)
    cookie := 0
    hr := DllCall("oleaut32\RegisterActiveObject"
        , "ptr", ObjPtr(Object), "ptr", _clsid, "uint", Flags, "uint*", &cookie
        , "uint")
    if (hr < 0)
        throw Error(format("Error 0x{:x}", hr), -1)
    cookieJar[Object] := cookie
}

;[生成GUID]
CreateGUID()
{
    pguid := Buffer(16)
    if !(DllCall("ole32.dll\CoCreateGuid", "ptr", pguid)) {
        sguid := Buffer(78)  ; V2固定Unicode, StringFromGUID2最多39个wchar=78字节
        if (DllCall("ole32.dll\StringFromGUID2", "ptr", pguid, "ptr", sguid, "int", 39))
            return StrGet(sguid, "UTF-16")
    }
    return ""
}
;[AHK脚本间传递消息]
RunAny_Send_WM_COPYDATA(StringToSend, TargetScriptTitle)
{
    CopyDataStruct := Buffer(3*A_PtrSize, 0)  ; 分配结构的内存区域
    ; 首先设置结构的 cbData 成员为字符串的大小, 包括它的零终止符:
    SizeInBytes := (StrLen(StringToSend) + 1) * 2  ; V2固定Unicode, 每字符2字节
    NumPut("ptr", SizeInBytes, CopyDataStruct, A_PtrSize)  ; cbData
    NumPut("ptr", StrPtr(StringToSend), CopyDataStruct, 2*A_PtrSize)  ; lpData
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    TimeOutTime := 4000  ; 可选的. 等待 receiver.ahk 响应的毫秒数. 默认是 5000
    ; 必须使用发送 SendMessage 而不是投递 PostMessage.
    result := 0
    try result := SendMessage(0x004A, 0, CopyDataStruct.Ptr, , TargetScriptTitle)  ; WM_COPYDATA
    if !result && !InStr(TargetScriptTitle, "RunAny_v2.ahk")
        try result := SendMessage(0x004A, 0, CopyDataStruct.Ptr, , "RunAny_v2.ahk ahk_class AutoHotkey")
    DetectHiddenWindows(Prev_DetectHiddenWindows)
    SetTitleMatchMode(Prev_TitleMatchMode)
    return result
}
