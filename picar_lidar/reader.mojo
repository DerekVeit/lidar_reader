from sys import argv
from time import monotonic

from picar_lidar.data import AngleDatum
from picar_lidar.data import AngleData
from picar_lidar.data import RingBuffer
from picar_lidar.strings import print_bytes
from picar_lidar.strings import print_value


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

    print_value("serial_path", serial_path)

    with open(serial_path, "r") as file:
        print()

        var angle_data = AngleData()

        var count: Int = 0
        var output_lines = RingBuffer[String](20)
        var angles: List[Int]
        var start_angle: Int
        var datum: AngleDatum
        for _ in range(4):
            angles = angle_data.take_packet(read_packet(file), monotonic())
            start_angle = angles[0]
            datum = angle_data[start_angle]
            count += 1
            output_lines.add("rpm: {}, start_angle: {}, count: {}".format(datum.rpm, start_angle, count))

        for line in output_lines.data:
            print("\x1b[K{}".format(line))

        while True:
            angles = angle_data.take_packet(read_packet(file), monotonic())
            start_angle = angles[0]
            datum = angle_data[start_angle]
            count += 1
            output_lines.add("rpm: {}, start_angle: {}, count: {}".format(datum.rpm, start_angle, count))
            print("\x1b[{}A".format(len(output_lines.data) + 1))
            for line in output_lines.data:
                print("\x1b[K{}".format(line))


        # packet = read_packet(file)
        # print_bytes("packet", packet)
        #
        # packet = read_packet(file)
        # print_bytes("packet", packet)
        #
        # packet = read_packet(file)
        # print_bytes("packet", packet)
        #
        # print()
        #
        # for _ in range(90):
        #     angle_data.take_packet(read_packet(file), monotonic())
        #
        # for angle in range(90, 120):
        #     print_value("angle_data[{}]".format(angle), angle_data[angle])
        #
