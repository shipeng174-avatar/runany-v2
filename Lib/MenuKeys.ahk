; MenuKeys.ahk - V1 RunAny_Menu plugin 功能复刻
; 菜单内 Space/RButton/MButton/XButton 按键复用 HoldKey 编号系统
; 当 RunAny 菜单 (#32768) 可见时，按键触发对应的修饰键模拟 + Click

class MenuKeys {
    static myPID := 0

    static Setup() {
        MenuKeys.myPID := DllCall("GetCurrentProcessId", "UInt")

        ; 仅在 RunAny 菜单显示时拦截按键（使用静态条件避免主线程阻塞）
        HotIfWinExist("ahk_class #32768 ahk_pid " MenuKeys.myPID)
        try Hotkey("Space", MenuKeys_OnSpace, "On")
        try Hotkey("RButton", MenuKeys_OnRButton, "On")
        try Hotkey("MButton", MenuKeys_OnMButton, "On")
        try Hotkey("XButton1", MenuKeys_OnXButton1, "On")
        try Hotkey("XButton2", MenuKeys_OnXButton2, "On")
        HotIf()

        ; 菜单透明化定时器（V1 RunAny_Menu 行为）
        transLevel := Integer(ConfigReader.ReadSetting("RunAnyMenuTransparent", "255"))
        if transLevel < 255 && transLevel > 0 {
            SetTimer(MenuKeys_TransparentLoop, 10)
        }
    }

    static MenuExecute(buttonRun, triggerType) {
        if buttonRun <= 0 {
            if triggerType = "Enter"
                Send("{Space}")
            else
                Click()
            return
        }

        Launcher.SetHoldKeyOverride(buttonRun)

        if triggerType = "Enter"
            Send("{Enter}")
        else
            Click()
    }
}

; --- 热键回调函数 ---
MenuKeys_OnSpace(hk) {
    action := Integer(ConfigReader.ReadSetting("RunAnyMenuSpaceRun", "2"))
    MenuKeys.MenuExecute(action, "Enter")
}

MenuKeys_OnRButton(hk) {
    action := Integer(ConfigReader.ReadSetting("RunAnyMenuRButtonRun", "5"))
    MenuKeys.MenuExecute(action, "Click")
}

MenuKeys_OnMButton(hk) {
    action := Integer(ConfigReader.ReadSetting("RunAnyMenuMButtonRun", "0"))
    MenuKeys.MenuExecute(action, "Click")
}

MenuKeys_OnXButton1(hk) {
    action := Integer(ConfigReader.ReadSetting("RunAnyMenuXButton1Run", "0"))
    MenuKeys.MenuExecute(action, "Click")
}

MenuKeys_OnXButton2(hk) {
    action := Integer(ConfigReader.ReadSetting("RunAnyMenuXButton2Run", "0"))
    MenuKeys.MenuExecute(action, "Click")
}

; --- 菜单透明化 ---
MenuKeys_TransparentLoop() {
    transLevel := Integer(ConfigReader.ReadSetting("RunAnyMenuTransparent", "255"))
    if transLevel >= 255
        return
    hwnd := WinExist("ahk_class #32768")
    if hwnd {
        try {
            pid := WinGetPID(hwnd)
            if (pid = MenuKeys.myPID) && (A_TimeIdle < 1000)
                WinSetTransparent(transLevel, "ahk_id " hwnd)
        } catch {
            ; Ignore errors
        }
    }
}
