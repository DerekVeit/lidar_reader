import math
from python import Python
from python.python_object import PythonObject
import time

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

    fn __init__(out self, pygame: PythonObject, width: Int, height: Int, bg_color: PythonObject) raises:
        self.width = width
        self.height = height
        self.bg_color = bg_color
        self.pygame = pygame
        self.pygame.init()
        self.surface = pygame.display.set_mode(Python.tuple(self.width, self.height))
        self.zoom = 1.0
        self.pygame.display.set_caption("PiCar-X LiDAR map")

    fn clear(self) raises:
        self.surface.fill(self.bg_color)

    fn tr(self, point: Point) -> Point:
        var scale = 0.25 * self.zoom
        return Point(
            scale * point[1] + Float64(self.width) / 2.0,
            scale * point[0] + Float64(self.height) / 2.0
        )

    fn draw_lines(self, color: PythonObject, lines: List[Line]) raises:
        for line in lines:
            self.draw_line(color, line)

    fn draw_line(self, color: PythonObject, line: Line) raises:
        x1, y1 = self.tr(line[0])
        x2, y2 = self.tr(line[1])
        _ = self.pygame.draw.line(
            self.surface,
            color,
            Python.tuple(x1, y1),
            Python.tuple(x2, y2),
        )

    fn draw_circle(self, circle: Circle) raises:
        var x1: Float64
        var y1: Float64
        x1, y1 = self.tr(circle[0])
        _ = self.pygame.draw.circle(
            self.surface,
            circle[2],
            Python.tuple(x1, y1),
            circle[1],
        )

