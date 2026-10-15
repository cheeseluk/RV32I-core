"""Turn a flat binary (objcopy -O binary) into a $readmemh file:
one 32-bit little-endian word per line, word 0 first.

Usage: python tools/bin2hex.py prog.bin prog.hex
"""
import sys


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    data = open(sys.argv[1], "rb").read()
    data += b"\0" * (-len(data) % 4)          # pad to a whole word
    with open(sys.argv[2], "w") as f:
        for i in range(0, len(data), 4):
            f.write(f"{int.from_bytes(data[i:i + 4], 'little'):08x}\n")


if __name__ == "__main__":
    main()
