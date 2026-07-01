global RunAny_Plugins_Name := "JSON解析库"

class JSON {
    static Load(text, reviver := "") {
        parser := JSON.Parser(text)
        value := parser.Parse()
        return value
    }

    static Dump(value, replacer := "", space := "") {
        gap := ""
        if IsInteger(space) {
            Loop Min(Abs(space), 10)
                gap .= " "
        } else if space != "" {
            gap := SubStr(space, 1, 10)
        }
        return JSON.Stringify(value, gap, "")
    }

    static Walk(holder, key, reviver) {
        value := holder.%key%
        if IsObject(value) {
            if value is Array {
                for i, _ in value {
                    newValue := JSON.Walk(value, i, reviver)
                    if JSON.IsUndefined(newValue)
                        value.RemoveAt(i)
                    else
                        value[i] := newValue
                }
            } else {
                for prop, _ in value.OwnProps() {
                    newValue := JSON.Walk(value, prop, reviver)
                    if JSON.IsUndefined(newValue)
                        value.DeleteProp(prop)
                    else
                        value.%prop% := newValue
                }
            }
        }
        return reviver.Call(holder, key, value)
    }

    static Undefined {
        get {
            static marker := {}
            return marker
        }
    }

    static IsUndefined(value) {
        return IsObject(value) && value == JSON.Undefined
    }

    static Stringify(value, gap := "", indent := "") {
        if IsObject(value) {
            stepback := indent
            indent .= gap

            if value is Array {
                parts := []
                for _, item in value {
                    itemText := JSON.Stringify(item, gap, indent)
                    parts.Push(itemText = "" ? "null" : itemText)
                }
                if gap != "" && parts.Length > 0
                    return "[" "`n" indent JSON.Join(parts, "," "`n" indent) "`n" stepback "]"
                return "[" JSON.Join(parts, ",") "]"
            }

            parts := []
            if value is Map {
                for key, item in value {
                    itemText := JSON.Stringify(item, gap, indent)
                    if itemText != ""
                        parts.Push(JSON.Quote(key) (gap != "" ? ": " : ":") itemText)
                }
            } else {
                for key, item in value.OwnProps() {
                    itemText := JSON.Stringify(item, gap, indent)
                    if itemText != ""
                        parts.Push(JSON.Quote(key) (gap != "" ? ": " : ":") itemText)
                }
            }
            if gap != "" && parts.Length > 0
                return "{" "`n" indent JSON.Join(parts, "," "`n" indent) "`n" stepback "}"
            return "{" JSON.Join(parts, ",") "}"
        }

        if value == ""
            return '""'
        if IsNumber(value)
            return String(value)
        return JSON.Quote(value)
    }

    static Join(items, delimiter) {
        result := ""
        for i, item in items
            result .= (i = 1 ? "" : delimiter) item
        return result
    }

    static Quote(value) {
        q := Chr(34)
        out := q
        Loop Parse String(value) {
            ch := A_LoopField
            switch ch {
                case "\":
                    out .= "\\"
                case q:
                    out .= "\" q
                case "`b":
                    out .= "\b"
                case "`f":
                    out .= "\f"
                case "`n":
                    out .= "\n"
                case "`r":
                    out .= "\r"
                case "`t":
                    out .= "\t"
                default:
                    code := Ord(ch)
                    out .= code < 0x20 ? "\u" Format("{:04x}", code) : ch
            }
        }
        return out q
    }

    class Parser {
        __New(text) {
            this.text := text
            this.pos := 1
            this.len := StrLen(text)
        }

        Parse() {
            value := this.ParseValue()
            this.SkipWhitespace()
            if this.pos <= this.len
                this.Error("Extra data")
            return value
        }

        ParseValue() {
            this.SkipWhitespace()
            ch := this.Peek()
            switch ch {
                case "{":
                    return this.ParseObject()
                case "[":
                    return this.ParseArray()
                case Chr(34):
                    return this.ParseString()
                case "":
                    this.Error("Unexpected end of JSON input")
                default:
                    return this.ParseToken()
            }
        }

        ParseObject() {
            obj := {}
            this.Expect("{")
            this.SkipWhitespace()
            if this.Peek() = "}" {
                this.pos++
                return obj
            }
            Loop {
                this.SkipWhitespace()
                if this.Peek() != Chr(34)
                    this.Error("Expected object key")
                key := this.ParseString()
                this.SkipWhitespace()
                this.Expect(":")
                value := this.ParseValue()
                obj.%key% := value
                this.SkipWhitespace()
                ch := this.Next()
                if ch = "}"
                    break
                if ch != ","
                    this.Error("Expected ',' or '}'")
            }
            return obj
        }

        ParseArray() {
            arr := []
            this.Expect("[")
            this.SkipWhitespace()
            if this.Peek() = "]" {
                this.pos++
                return arr
            }
            Loop {
                arr.Push(this.ParseValue())
                this.SkipWhitespace()
                ch := this.Next()
                if ch = "]"
                    break
                if ch != ","
                    this.Error("Expected ',' or ']'")
            }
            return arr
        }

        ParseString() {
            q := Chr(34)
            this.Expect(q)
            result := ""
            Loop {
                if this.pos > this.len
                    this.Error("Unterminated string")
                ch := this.Next()
                if ch = q
                    break
                if ch != "\" {
                    result .= ch
                    continue
                }
                esc := this.Next()
                switch esc {
                    case q, "\", "/":
                        result .= esc
                    case "b":
                        result .= "`b"
                    case "f":
                        result .= "`f"
                    case "n":
                        result .= "`n"
                    case "r":
                        result .= "`r"
                    case "t":
                        result .= "`t"
                    case "u":
                        hex := SubStr(this.text, this.pos, 4)
                        if !RegExMatch(hex, "i)^[0-9a-f]{4}$")
                            this.Error("Invalid unicode escape")
                        result .= Chr(Integer("0x" hex))
                        this.pos += 4
                    default:
                        this.Error("Invalid escape")
                }
            }
            return result
        }

        ParseToken() {
            start := this.pos
            while this.pos <= this.len {
                ch := this.Peek()
                if InStr(" `t`r`n,]}", ch)
                    break
                this.pos++
            }
            token := SubStr(this.text, start, this.pos - start)
            switch token {
                case "true":
                    return true
                case "false":
                    return false
                case "null":
                    return ""
                default:
                    if IsNumber(token)
                        return token + 0
                    this.Error("Invalid JSON token")
            }
        }

        SkipWhitespace() {
            while this.pos <= this.len && InStr(" `t`r`n", this.Peek())
                this.pos++
        }

        Peek() {
            return this.pos <= this.len ? SubStr(this.text, this.pos, 1) : ""
        }

        Next() {
            ch := this.Peek()
            this.pos++
            return ch
        }

        Expect(expected) {
            ch := this.Next()
            if ch != expected
                this.Error("Expected '" expected "'")
        }

        Error(message) {
            throw Error(message, -1, "Position " this.pos)
        }
    }
}
