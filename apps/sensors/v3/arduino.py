#!/usr/bin/env python3
import argparse
import atexit
import datetime
import logging
import os
import signal
import time
import traceback
from pathlib import Path

import pandas as pd
import serial

SCRIPT_NAME = Path(__file__).stem
SERIAL_PORT = Path(os.getenv("SERIAL_PORT", "/dev/ttyUSB0"))
WAITING_TIME = float(os.getenv("WAITING_TIME", 5))

logger = logging.getLogger(Path(__file__).stem)


def read_serial_once(df: pd.DataFrame) -> pd.DataFrame:
    """
    Read data from serial port and append it to the dataframe passed as argument.
    :param df: Dataframe to append data to
    :return: Dataframe with new data (same instance as passed as argument)
    """
    if not SERIAL_PORT.exists():
        logger.warning(f"Serial port {SERIAL_PORT} does not exist")
        return df

    try:
        with serial.Serial(SERIAL_PORT.as_posix(), timeout=1) as fp:
            logger.info(f"Opened serial port {SERIAL_PORT}. Waiting {WAITING_TIME} seconds...")
            time.sleep(WAITING_TIME)
            fp.write("r".encode("ascii"))
            data = fp.readline().decode("ascii").strip()
        df.loc[len(df)] = [datetime.datetime.now()] + [float(value) for value in data.split(",")]
    except serial.SerialException:
        logger.warning(f"Could not read data from serial port {SERIAL_PORT}. Error:\n {traceback.format_exc()}")
    return df


def read_serial_batch(path: Path, batch_length: int) -> None:
    """
    Read data from serial port and write it to a CSV file.
    :param path: Path to write CSV file to
    :param batch_length: Number of records to read from serial port
    """
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
    logger.info(f"Preparing to read {batch_length} data from serial port...")
    while len(df) < batch_length:
        _ = read_serial_once(df)
    if not df.empty:
        logger.info(f"Writing data to {file_path}...")
        df.to_csv(file_path, index=False)
    else:
        logger.warning("No data was read from serial port")


def parse_args(args: list) -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        description="Read data from Arduino serial port",
        epilog=f"Example usage:\n{SCRIPT_NAME} --batch-length 12 --output-path /opt/sensors/data",
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
        default=Path("/opt/sensors/data"),
        help="Path to write output files",
    )
    args = parser.parse_args(args)
    if not args.output_path.exists():
        args.output_path.mkdir(parents=True, exist_ok=True)
    return args


def signal_parent() -> None:
    """Send signal to parent process when exiting so that it knows we are done"""
    os.kill(os.getppid(), signal.SIGUSR1)


def main(args: list = None) -> None:
    """Main function"""
    atexit.register(signal_parent)
    args = parse_args(args)
    while True:
        read_serial_batch(path=args.output_path, batch_length=args.batch_length)


if __name__ == "__main__":
    main()
