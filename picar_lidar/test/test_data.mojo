from testing import assert_equal, TestSuite

from picar_lidar import data as sut_module

def test_RingBuffer_init():
    # act / assert
    _ = sut_module.RingBuffer[Int](3)

def test_RingBuffer_add__one():
    # arrange
    rb = sut_module.RingBuffer[Int](3)

    # act
    rb.add(100)

    # assert
    assert_equal(len(rb._data), 1)
    assert_equal(rb._data[0], 100)

def main():
    TestSuite.discover_tests[__functions_in_module()]().run()

