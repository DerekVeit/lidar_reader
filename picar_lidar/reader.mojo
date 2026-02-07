from sys import argv
from time import monotonic

from picar_lidar.strings import hex_string_from_bytes
from picar_lidar.strings import print_bytes
from picar_lidar.strings import print_value
from picar_lidar.strings import show_value


@fieldwise_init
struct AngleDatum(Copyable):
    var distance: UInt16
    var strength: UInt16
    var error: UInt8
    var rpm: Float64
    var time: UInt

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

fn read_packet(file: FileHandle) raises -> List[UInt8]:
    comptime PACKET_SIZE: Int = 22
    comptime START_BYTE: UInt8 = 0xfa
    comptime MIN_PACKET_INDEX: UInt8 = 0xa0
    comptime MAX_PACKET_INDEX: UInt8 = 0xf9

    var bytes: List[UInt8]
    var attempts = 4

    for _ in range(attempts):
        bytes = file.read_bytes(PACKET_SIZE)
        if len(bytes) < PACKET_SIZE:
            raise Error("Failed to read {} bytes for packet search".format(PACKET_SIZE))

        for index, byte in enumerate(bytes):
            if byte == START_BYTE:
                if MIN_PACKET_INDEX <= bytes[index + 1] <= MAX_PACKET_INDEX or index == PACKET_SIZE - 1:
                    if index == 0:
                        return bytes^
                    # read and discard the remainder of this packet
                    _ = file.read_bytes(index)
                    break

    raise Error("Could not find a packet in {} bytes".format(PACKET_SIZE * attempts))

fn main() raises:
    var serial_path = parse_args()

    var read_buffer = BytesBuffer[64]()

    print_value("serial_path", serial_path)

    with open(serial_path, "r") as file:
        var data: List[UInt8]
        var length_added: Int

        print()
        data = file.read_bytes(12)
        print_bytes("data", data)
        length_added = read_buffer.add(data^)
        print_value("length_added", length_added)
        var some_bytes = read_buffer.read(4)
        print_bytes("some_bytes", some_bytes)
        print_value("some_bytes[2]", some_bytes[2])
        print_value("read_buffer.offset", read_buffer.offset)

        print()
        length_added = read_buffer.add(file.read_bytes(12))
        print("added {} more bytes to the buffer".format(length_added))
        some_bytes = read_buffer.read(20)
        print_bytes("some_bytes", some_bytes)
        print_value("read_buffer.offset", read_buffer.offset)

        print()
        length_added = read_buffer.add(file.read_bytes(24))
        print("added {} more bytes to the buffer".format(length_added))
        some_bytes = read_buffer.read(24)
        print_bytes("some_bytes", some_bytes)
        print_value("read_buffer.offset", read_buffer.offset)

        print()
        length_added = read_buffer.add(file.read_bytes(24))
        print("added {} more bytes to the buffer".format(length_added))
        some_bytes = read_buffer.read(24)
        print_bytes("some_bytes", some_bytes)
        print_value("read_buffer.offset", read_buffer.offset)

        var angle_data = InlineArray[AngleDatum, 360](uninitialized=True)
        for angle in range(360):
            angle_data[angle] = AngleDatum(
                distance=0,
                strength=0,
                error=0,
                rpm=0.0,
                time=0,
            )

        packet = read_packet(file)
        print_bytes("packet", packet)

        packet = read_packet(file)
        print_bytes("packet", packet)

        packet = read_packet(file)
        print_bytes("packet", packet)

        print()

        for _ in range(90):
            var packet = read_packet(file)
            print_bytes("packet", packet)
            var end_time = monotonic()
            var start_angle = Int(packet[1] - 0xa0) * 4
            for angle in range(start_angle, start_angle + 4):
                angle_data[angle].time = end_time

        for angle in range(0, 12):
            print_value("angle_data[{}].time".format(angle), angle_data[angle].time)

        for angle in range(348, 360):
            print_value("angle_data[{}].time".format(angle), angle_data[angle].time)

