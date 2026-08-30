def hex_string_from_bytes(bytes: Span[UInt8, _]) -> String:
    var bytes_str = ""
    for byte in bytes:
        if bytes_str:
            bytes_str += " "
        if byte > 0xf:
            bytes_str += hex(byte, prefix="")
        else:
            bytes_str += hex(byte, prefix="0")
    return bytes_str

def print_bytes(name: String, bytes: Span[UInt8, _]):
    var style_bold = "\x1b[1m"
    var style_reset = "\x1b[0m"
    print("{}{}{} = {}".format(style_bold, name, style_reset, hex_string_from_bytes(bytes)))

def show_value(name: String, value: Some[Writable]) -> String:
    var style_bold = "\x1b[1m"
    var style_reset = "\x1b[0m"
    return "{}{}{} = {}".format(style_bold, name, style_reset, repr(value))

def print_value(name: String, value: Some[Writable]):
    print(show_value(name, value))

