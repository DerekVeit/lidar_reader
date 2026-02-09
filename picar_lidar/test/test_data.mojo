from testing import assert_equal, TestSuite

from picar_lidar import data as sut_module

def test_RingBuffer_init():
    # act / assert
    _ = sut_module.RingBuffer[Int](3)

def main():
    TestSuite.discover_tests[__functions_in_module()]().run()

