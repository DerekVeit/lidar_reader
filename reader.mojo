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

fn main() raises:
    var serial_path = parse_args()

    var read_buffer = BytesBuffer[8192]()

    print("serial_path: {}".format(serial_path))

    with open(serial_path, "r") as file:
        var data = file.read_bytes(12)
        var length_added = read_buffer.add(data^)
        print("added {} bytes to the buffer".format(length_added))
        var some_bytes = read_buffer.read(4)
        print("read from the buffer: {}".format(repr(List(some_bytes))))
        print("byte read from the buffer: {}".format(some_bytes[2]))
        print("buffer offset: {}".format(read_buffer.offset))

