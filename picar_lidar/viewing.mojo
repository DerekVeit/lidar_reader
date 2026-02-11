import math
from python import Python
from python.python_object import PythonObject
import time

from picar_lidar.data import AngleData


comptime Point = Tuple[Float64, Float64]
comptime Line = Tuple[Point, Point]

comptime PointData = InlineArray[Point, 360]

struct Display:
    var width: Int
    var height: Int
    var pygame: PythonObject
    var surface: PythonObject

    fn __init__(out self, pygame: PythonObject, width: Int, height: Int) raises:
        self.width = width
        self.height = height
        self.pygame = pygame
        self.pygame.init()
        self.surface = pygame.display.set_mode(Python.tuple(self.width, self.height))
        self.pygame.display.set_caption("PiCar-X LiDAR map")

    fn clear(self) raises:
        self.surface.fill(self.pygame.Color("white"))

    fn tr(self, point: Point) -> Point:
        return Point(point[1] + Float64(self.width) / 2.0, point[0] + Float64(self.height) / 2.0)

    fn draw_lines(self, color: String, lines: List[Line]) raises:
        var x1: Float64
        var x2: Float64
        var y1: Float64
        var y2: Float64
        for line in lines:
            x1, y1 = self.tr(line[0])
            x2, y2 = self.tr(line[1])
            _ = self.pygame.draw.line(
                self.surface,
                self.pygame.Color(color),
                Python.tuple(x1, y1),
                Python.tuple(x2, y2),
            )

    fn draw_circle(self, color: String, center: Point, radius: Float64, width: Int) raises:
        _ = self.pygame.draw.circle(
            self.surface,
            self.pygame.Color(color),
            Python.tuple(*self.tr(center)),
            radius,
            width,
        )

