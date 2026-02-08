from sys import argv
from time import monotonic

from picar_lidar.strings import hex_string_from_bytes
from picar_lidar.strings import print_bytes
from picar_lidar.strings import print_value
from picar_lidar.strings import show_value


@fieldwise_init
struct AngleDatum(Copyable, Representable):
    var distance: UInt16
    var strength: UInt16
    var error: UInt8
    var rpm: Float64
    var time: UInt

    fn __init__(out self):
        self.distance = 0
        self.strength = 0
        self.error = 0
        self.rpm = 0.0
        self.time = 0

    fn __repr__(self) -> String:
        return "AngleDatum(distance={}, strength={}, error={}, rpm={}, time={})".format(
            repr(self.distance),
            repr(self.strength),
            repr(self.error),
            repr(self.rpm),
            repr(self.time),
        )

comptime _AngleData = InlineArray[AngleDatum, 360]

struct AngleData:
    var data: _AngleData

    fn __init__(out self):
        self.data = _AngleData(fill=AngleDatum())

    fn take_packet(mut self, packet: List[UInt8], capture_time: UInt) raises:
        if len(packet) != 22:
            raise Error("AngleData.take_packet needs 22 bytes, got {} bytes".format(len(packet)))

        var start_angle = Int(packet[1] - 0xa0) * 4

        var rpm = Float64(UInt16(packet[2]) | UInt16(packet[3]) << 8) / 64.0

        # ns/degree = 1e9 ns/sec * 60 sec/min / (360 degrees/rev * N rev/min)
        var inter_angle_period = Int(1_000_000_000.0 * 60.0 / (360.0 * rpm))

        comptime BIT_7 = 0b1000_0000
        comptime BIT_6 = 0b0100_0000

        for num in range(4):
            var angle = start_angle + num
            ref datum = self.data[angle]

            datum.rpm = rpm

            var offset = (num + 1) * 4
            var bytes = packet[offset:offset + 4]

            if bytes[1] & BIT_7:
                # the distance could not be calculated
                datum.distance = 0
                datum.error = UInt8(bytes[0])
            else:
                datum.distance = UInt16(bytes[0]) | UInt16(bytes[1] & 0b0011_1111) << 8
                if bytes[1] & BIT_6:
                    datum.error = BIT_6
                else:
                    datum.error = 0

            datum.strength = UInt16(bytes[2]) | UInt16(bytes[3]) << 8

            datum.time = capture_time - (3 - num) * inter_angle_period

    fn __getitem__(self, index: UInt) -> AngleDatum:
        return self.data[index].copy()

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

        var angle_data = AngleData()

        packet = read_packet(file)
        print_bytes("packet", packet)

        packet = read_packet(file)
        print_bytes("packet", packet)

        packet = read_packet(file)
        print_bytes("packet", packet)

        print()

        for _ in range(90):
            angle_data.take_packet(read_packet(file), monotonic())

