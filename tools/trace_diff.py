"""Compare the core's trace with the reference model's, line by line.
The first line that differs is the first instruction the core got wrong.

Usage: python tools/trace_diff.py core.trace ref.trace
Exit code 0 = identical, 1 = mismatch.
"""
import sys

CONTEXT = 4


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    core = open(sys.argv[1]).read().splitlines()
    ref = open(sys.argv[2]).read().splitlines()

    for i in range(max(len(core), len(ref))):
        c = core[i] if i < len(core) else "<end of trace>"
        r = ref[i] if i < len(ref) else "<end of trace>"
        if c != r:
            print(f"MISMATCH at instruction {i + 1}:")
            for line in ref[max(0, i - CONTEXT):i]:
                print(f"    {line}")
            print(f"  core: {c}")
            print(f"  ref:  {r}")
            sys.exit(1)
    print(f"MATCH ({len(core)} instructions)")


if __name__ == "__main__":
    main()
