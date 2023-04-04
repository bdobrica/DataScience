#!/usr/bin/env python3
import argparse
import atexit
import os
import signal
import subprocess
import types
from pathlib import Path

SCRIPT_NAME = Path(__file__).stem
children_pids = []


def parse_args(args: list) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        description="Read data from Arduino serial port in batches and upload it to Minio",
        epilog=f"Example usage:\n{SCRIPT_NAME} --batch-length 12 --output-path /opt/sensors/data",
    )

    def validate_path(path: str) -> Path:
        path = Path(path)
        if path.exists() and not path.is_dir():
            raise argparse.ArgumentTypeError(f"Path {path} is not a directory")
        return path

    parser.add_argument(
        "-r",
        "--rows-per-file",
        type=int,
        default=12,
        help="Number of records to read in a batch and store them in a temporart CSV file",
    )
    parser.add_argument(
        "-f",
        "--files-per-upload",
        type=int,
        default=60,
        help="Number of CSV files to upload to Minio at a time",
    )
    parser.add_argument(
        "-k",
        "--files-to-keep",
        type=int,
        default=60,
        help="Number of CSV files to keep on disk to visualize the data",
    )
    parser.add_argument(
        "-d",
        "--data-path",
        type=validate_path,
        default=Path("/opt/sensors/data"),
        help="Path to temporary store the data in files",
    )
    args = parser.parse_args(args)
    if not args.output_path.exists():
        args.output_path.mkdir(parents=True, exist_ok=True)
    return args


def graceful_exit() -> None:
    for child_pid in children_pids:
        try:
            os.kill(child_pid, signal.SIGQUIT)
        except ProcessLookupError:
            pass


def handle_signal(signum: int, frame: types.FrameType) -> None:
    graceful_exit()
    exit(0)


def main(args: list = None) -> None:
    args = parse_args(args)
    atexit.register(graceful_exit)
    signal.signal(signal.SIGUSR1, handle_signal)

    children_pids.append(
        subprocess.Popen(
            ["/opt/sensors/arduino.py", "--batch-length", str(args.rows_per_file), "--output-path", str(args.data_path)]
        ).pid
    )
    children_pids.append(subprocess.Popen(["/opt/sensors/webserver.py", "--input-path", str(args.data_path)]).pid)
    children_pids.append(
        subprocess.Popen(
            [
                "/opt/sensors/uploader.py",
                "--input-path",
                str(args.data_path),
                "--batch-size",
                str(args.files_per_upload),
                "--min-keep",
                str(args.files_to_keep),
            ]
        ).pid
    )


if __name__ == "__main__":
    main()
