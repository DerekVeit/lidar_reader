from std.bit import count_leading_zeros
from std import math
from std.python import Python
from std.python.python_object import PythonObject
from std import time

from picar_lidar.data import AngleData


comptime Point = Tuple[Float64, Float64]
comptime Line = Tuple[Point, Point]
comptime Circle = Tuple[Point, Float64, PythonObject]

comptime PointData = InlineArray[Point, 360]

struct Display:
    var width: Int
    var height: Int
    var bg_color: PythonObject
    var pygame: PythonObject
    var surface: PythonObject
    var zoom: Float64

    def __init__(out self, pygame: PythonObject, width: Int, height: Int, bg_color: PythonObject) raises:
        self.width = width
        self.height = height
        self.bg_color = bg_color
        self.pygame = pygame
        self.pygame.init()
        self.surface = pygame.display.set_mode(Python.tuple(self.width, self.height))
        self.zoom = 1.0
        self.pygame.display.set_caption("PiCar-X LiDAR map")

    def clear(self) raises:
        self.surface.fill(self.bg_color)

    def tr(self, point: Point) -> Point:
        var scale = 0.25 * self.zoom
        return Point(
            scale * point[1] + Float64(self.width) / 2.0,
            scale * point[0] + Float64(self.height) / 2.0
        )

    def draw_lines(self, color: PythonObject, lines: List[Line]) raises:
        for line in lines:
            self.draw_line(color, line)

    def draw_line(self, color: PythonObject, line: Line) raises:
        x1, y1 = self.tr(line[0])
        x2, y2 = self.tr(line[1])
        _ = self.pygame.draw.line(
            self.surface,
            color,
            Python.tuple(x1, y1),
            Python.tuple(x2, y2),
        )

    def draw_circle(self, circle: Circle) raises:
        var x1: Float64
        var y1: Float64
        x1, y1 = self.tr(circle[0])
        _ = self.pygame.draw.circle(
            self.surface,
            circle[2],
            Python.tuple(x1, y1),
            circle[1],
        )

def get_lidar_color(strength: UInt16) -> Tuple[UInt8, UInt8, UInt8]:
    if strength == 0:
        return (0xcc, 0xcf, 0xcc)

    level = 16 - UInt8(count_leading_zeros(strength))

    if level < 8:
        return (0xcc, 0xcc + level * 6, 0xcc)
    else:
        return (0xcc + (level - 8) * 6, 0xff, 0xcc + (level - 8) * 6)

