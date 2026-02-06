from sys import argv


fn main() raises:
    var args = argv()

    var serial_path: String
    if len(args) == 1:
        serial_path = "/dev/serial0"
    elif len(args) == 2:
        serial_path = args[1]
    else:
        raise Error("expected no more than 1 argument")

    print("OK")
    if serial_path:
        print("serial_path: {}".format(serial_path))

