from sys import argv


struct BytesBuffer[size: Int]:
    var data: List[UInt8]
    var offset: Int

    fn __init__(out self, offset: Int = 0):
        self.offset = offset
        self.data = List[UInt8](capacity=Self.size)

    fn read(mut self, length: Int) -> Span[mut=False, UInt8, origin_of(self.data)]:
        var new_offset = self.offset + length
        var bytes = self.data[self.offset:new_offset]

        if new_offset > Self.size // 2:
            self.data = List(self.data[new_offset:])
            self.offset = 0
        else:
            self.offset = new_offset

        return bytes

    fn add(mut self, var bytes: List[UInt8]) -> Int:
        var length = len(bytes)
        self.data.extend(bytes^)
        return length

fn parse_args() raises -> String:
    var args = argv()

    var serial_path: String
    if len(args) == 1:
        serial_path = "/dev/serial0"
    elif len(args) == 2:
        serial_path = args[1]
    else:
        raise Error("expected no more than 1 argument")

    return serial_path

fn hex_string_from_bytes(bytes: Span[UInt8]) -> String:
    var bytes_str = ""
    for byte in bytes:
        if bytes_str:
            bytes_str += " "
        if byte > 0xf:
            bytes_str += hex(byte, prefix="")
        else:
            bytes_str += hex(byte, prefix="0")
    return bytes_str

fn show_value(name: String, value: Some[Representable]) -> String:
    var style_bold = "\x1b[1m"
    var style_reset = "\x1b[0m"
    return "{}{}{} = {}".format(style_bold, name, style_reset, repr(value))

fn print_value(name: String, value: Some[Representable]):
    print(show_value(name, value))

fn main() raises:
    var serial_path = parse_args()

    var read_buffer = BytesBuffer[64]()

    print_value("serial_path", serial_path)

    with open(serial_path, "r") as file:
        var data: List[UInt8]
        var length_added: Int

        print()
        data = file.read_bytes(12)
        print(repr(data))
        length_added = read_buffer.add(data^)
        print_value("length_added", length_added)
        var some_bytes = read_buffer.read(4)
        print("read from the buffer: {}".format(repr(List(some_bytes))))
        print_value("some_bytes[2]", some_bytes[2])
        print_value("read_buffer.offset", read_buffer.offset)

        print()
        length_added = read_buffer.add(file.read_bytes(12))
        print("added {} more bytes to the buffer".format(length_added))
        some_bytes = read_buffer.read(20)
        print("read these bytes from the buffer:\n  {}".format(hex_string_from_bytes(some_bytes)))
        print_value("read_buffer.offset", read_buffer.offset)

        print()
        length_added = read_buffer.add(file.read_bytes(24))
        print("added {} more bytes to the buffer".format(length_added))
        some_bytes = read_buffer.read(24)
        print("read these bytes from the buffer:\n  {}".format(hex_string_from_bytes(some_bytes)))
        print_value("read_buffer.offset", read_buffer.offset)

        print()
        length_added = read_buffer.add(file.read_bytes(24))
        print("added {} more bytes to the buffer".format(length_added))
        some_bytes = read_buffer.read(24)
        print("read these bytes from the buffer:\n  {}".format(hex_string_from_bytes(some_bytes)))
        print_value("read_buffer.offset", read_buffer.offset)

