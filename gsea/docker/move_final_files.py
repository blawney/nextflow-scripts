import glob
import sys
import shutil
import argparse


def parse_cl_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--pattern', dest='pattern', required=True)
    parser.add_argument('-o', '--output', dest='output', required=True)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_cl_args()
    matching_files = glob.glob(args.pattern)
    if len(matching_files) != 1:
        sys.stderr.write(f'Unexpected file match: {matching_files}')
        sys.exit(1)
    else:
        f = matching_files[0]
        shutil.copyfile(f, args.output)
