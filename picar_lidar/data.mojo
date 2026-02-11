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

    fn take_packet(mut self, packet: List[UInt8], capture_time: UInt) raises -> List[UInt]:
        if len(packet) != 22:
            raise Error("AngleData.take_packet needs 22 bytes, got {} bytes".format(len(packet)))

        var start_angle = UInt(packet[1] - 0xa0) * 4

        var angles = List[UInt]()

        var rpm = Float64(UInt16(packet[2]) | UInt16(packet[3]) << 8) / 64.0

        # ns/degree = 1e9 ns/sec * 60 sec/min / (360 degrees/rev * N rev/min)
        var inter_angle_period = Int(1_000_000_000.0 * 60.0 / (360.0 * rpm))

        comptime BIT_7 = 0b1000_0000
        comptime BIT_6 = 0b0100_0000

        for i in range(4):
            var num  = UInt(i)
            var angle = start_angle + num
            angles.append(angle)
            ref datum = self.data[angle]

            datum.rpm = rpm

            var offset = (Int(num) + 1) * 4
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

        return angles^

    fn __getitem__(self, index: UInt) -> AngleDatum:
        return self.data[index].copy()

struct RingBuffer[ElementType: Copyable & ImplicitlyDestructible]:
    var data: List[Self.ElementType]
    var next_addable_index: Int
    var limit: Int
    var is_full: Bool

    fn __init__(out self, limit: Int):
        self.data = List[Self.ElementType]()
        self.next_addable_index = 0
        self.limit = limit
        self.is_full = False

    fn _increment(mut self):
        self.next_addable_index += 1
        if self.next_addable_index == self.limit:
            self.next_addable_index = 0

    fn add(mut self, value: Self.ElementType):
        if self.is_full:
            self.data[self.next_addable_index] = value.copy()
            self._increment()
        else:
            self.data.append(value.copy())
            self._increment()
            if self.next_addable_index == 0:
                self.is_full = True

