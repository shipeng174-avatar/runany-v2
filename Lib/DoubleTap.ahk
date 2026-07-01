class DoubleTap {
    static lastCtrlTick := 0
    static lastAltTick := 0
    static lastLWinTick := 0
    static lastRWinTick := 0
    static interval := 350

    static Setup() {
        if ConfigReader.ReadSetting("MenuDoubleCtrlKey", "0") = "1" {
            Hotkey("~Ctrl Up", (*) => DoubleTap.OnKeyUp("lastCtrlTick"), "On")
        }
        if ConfigReader.ReadSetting("MenuDoubleAltKey", "0") = "1" {
            Hotkey("~Alt Up", (*) => DoubleTap.OnKeyUp("lastAltTick"), "On")
        }
        if ConfigReader.ReadSetting("MenuDoubleLWinKey", "0") = "1" {
            Hotkey("~LWin Up", (*) => DoubleTap.OnKeyUp("lastLWinTick"), "On")
        }
        if ConfigReader.ReadSetting("MenuDoubleRWinKey", "0") = "1" {
            Hotkey("~RWin Up", (*) => DoubleTap.OnKeyUp("lastRWinTick"), "On")
        }
        if ConfigReader.ReadSetting("MenuCtrlRightKey", "0") = "1" {
            Hotkey("~Ctrl & ~RButton", (*) => DoubleTap.ShowMenu(), "On")
        }
        if ConfigReader.ReadSetting("MenuShiftRightKey", "0") = "1" {
            Hotkey("~Shift & ~RButton", (*) => DoubleTap.ShowMenu(), "On")
        }
        if ConfigReader.ReadSetting("MenuXButton1Key", "0") = "1" {
            Hotkey("XButton1", (*) => DoubleTap.ShowMenu(), "On")
        }
        if ConfigReader.ReadSetting("MenuXButton2Key", "0") = "1" {
            Hotkey("XButton2", (*) => DoubleTap.ShowMenu(), "On")
        }
        if ConfigReader.ReadSetting("MenuMButtonKey", "0") = "1" {
            Hotkey("~MButton", (*) => DoubleTap.OnMButton(), "On")
        }
    }

    static OnKeyUp(tickProp) {
        now := A_TickCount
        last := DoubleTap.%tickProp%
        if now - last < DoubleTap.interval {
            DoubleTap.%tickProp% := 0
            DoubleTap.ShowMenu()
        } else {
            DoubleTap.%tickProp% := now
        }
    }

    static OnMButton(hk) {
        DoubleTap.ShowMenu()
    }

    static ShowMenu() {
        if WinActive("ahk_group DisableGUI")
            return
        try {
            g_MenuBuilder.ShowMenu()
        } catch as e {
            ToolTip("双击显示菜单出错: " e.Message)
            SetTimer(() => ToolTip(), -3000)
        }
    }
}
