import math
from python import Python
from python.python_object import PythonObject
from sys import argv
import time

from picar_lidar.data import AngleDatum
from picar_lidar.data import AngleData
from picar_lidar.data import RingBuffer
from picar_lidar.viewing import Display
from picar_lidar.viewing import Line
from picar_lidar.viewing import Point
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

    pygame = Python.import_module("pygame")

    with open(serial_path, "r") as file:
        print()

        var angle_data = AngleData()

        var display = Display(pygame, 800, 600)

        var count: Int = 0
        var output_lines = RingBuffer[String](20)
        var angles: List[UInt]
        var start_angle: UInt
        var datum: AngleDatum
        for _ in range(4):
            angles = angle_data.take_packet(read_packet(file), time.monotonic())
            start_angle = angles[0]
            datum = angle_data[start_angle]
            count += 1
            output_lines.add("rpm: {}, start_angle: {}, count: {}".format(datum.rpm, start_angle, count))

        for line in output_lines.data:
            print("\x1b[K{}".format(line))

        var laser_lines = List[Line]()
        var wall_lines = List[Line]()

        var current_time = time.monotonic()
        var next_draw_time = current_time

        while True:
            angles = angle_data.take_packet(read_packet(file), time.monotonic())
            start_angle = angles[0]
            datum = angle_data[start_angle]
            count += 1
            output_lines.add("rpm: {}, start_angle: {}, count: {}".format(datum.rpm, start_angle, count))
            print("\x1b[{}A".format(len(output_lines.data) + 1))
            for line in output_lines.data:
                print("\x1b[K{}".format(line))

            for i in angles:
                var angle = UInt(i)
                var distance = Float64(angle_data[angle].distance)
                if distance == 0.0:
                    continue
                var x = distance * math.cos(math.pi * Float64(angle) / 180)
                var y = distance * math.sin(math.pi * Float64(angle) / 180)
                laser_lines.append(Line(Point(0.0, 0.0), Point(x, y)))

            current_time = time.monotonic()
            if current_time > next_draw_time:
                next_draw_time += UInt(1_000_000_000 / 60)
                if current_time > next_draw_time:
                    next_draw_time = current_time + UInt(1_000_000_000 / 60)
                display.clear()
                display.draw_lines("green", laser_lines)

                var x_prev = 0.0
                var y_prev = 0.0
                for angle in range(360):
                    var distance = Float64(angle_data[UInt(angle)].distance)
                    var x = distance * math.cos(math.pi * Float64(angle) / 180)
                    var y = distance * math.sin(math.pi * Float64(angle) / 180)
                    var separation = math.sqrt((x_prev - x) ** 2 + (y_prev - y) ** 2)
                    if separation < 0.1:
                        wall_lines.append(Line(
                            Point(x_prev, y_prev),
                            Point(x, y),
                            ))
                    display.draw_lines("black", wall_lines)

                pygame.display.flip()
                laser_lines.clear()


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
