#!/usr/bin/env python3
import argparse
import datetime
import time
from pathlib import Path

import pandas as pd
import serial


def read_serial_once(df: pd.DataFrame) -> pd.DataFrame:
    with serial.Serial("/dev/ttyUSB0", timeout=1) as fp:
        time.sleep(5)  # Arduino gets reset when port is opened
        fp.write("r".encode("ascii"))
        data = fp.readline().decode("ascii").strip()
    df.loc[len(df)] = [datetime.datetime.now()] + [
        float(value) for value in data.split(",")
    ]
    return df


def read_serial_batch(path: Path, batch_length: int) -> None:
    df = pd.DataFrame(
        columns=[
            "datetime",
            "light_value",
            "sound_value",
            "temperature_1_value",
            "humidity_value",
            "temperature_2_value",
            "pressure_value",
            "altitude_value",
            "acceleration_x",
            "acceleration_y",
            "acceleration_z",
        ]
    )

    file_path = path / datetime.datetime.now().strftime("%Y%m%d-%H%M%S.csv")
    while len(df) < batch_length:
        _ = read_serial_once(df)
    df.to_csv(file_path, index=False)


def parse_args(args: list) -> argparse.Namespace:
    script_name = Path(__file__).stem
    parser = argparse.ArgumentParser(
        prog=script_name,
        description="Read data from Arduino",
        epilog=f"{script_name} --batch-length 12 --output-path /home/pi/weather",
    )
    parser.add_argument(
        "-b",
        "--batch-length",
        type=int,
        default=12,
        help="Number of records to read in a batch",
    )

    def validate_path(path: str) -> Path:
        path = Path(path)
        if path.exists() and not path.is_dir():
            raise argparse.ArgumentTypeError(f"Path {path} is not a directory")
        return path

    parser.add_argument(
        "-o",
        "--output-path",
        type=validate_path,
        default=Path("/home/pi/weather"),
        help="Path to write output files",
    )
    args = parser.parse_args(args)
    if not args.output_path.exists():
        args.output_path.mkdir(parents=True, exist_ok=True)
    return args


def main(args: list = None) -> None:
    args = parse_args(args)
    while True:
        read_serial_batch(path=args.output_path, batch_length=args.batch_length)


if __name__ == "__main__":
    main()
