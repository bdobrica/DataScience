#!/usr/bin/env python3
import argparse
import atexit
import datetime
import os
import signal
import time
import traceback
from pathlib import Path

import pandas as pd
import serial
from logger import init_logger

SCRIPT_NAME = Path(__file__).stem
WAITING_TIME = float(os.getenv("WAITING_TIME", 5))

logger = init_logger(SCRIPT_NAME)
serial_port = None


def detect_usb_serial_port():
    """Detect USB serial port and set serial_port variable to its path"""
    global serial_port

    if serial_port and serial_port.exists():
        return

    logger.info("Start detecting USB serial port ...")
    ports = list(Path("/dev").glob("ttyUSB*"))
    if not ports:
        logger.warning("No USB serial ports found ...")
        serial_port = None
        return
    if len(ports) == 1:
        serial_port = ports[0]
        logger.info(f"Found USB serial port {serial_port} ...")
        return

    logger.info(f"Multiple USB serial port candidates {len(ports)} ...")

    for potential_port in ports:
        try:
            with serial.Serial(potential_port.as_posix(), baudrate=115200, timeout=1):
                pass
            serial_port = potential_port
        except serial.SerialException:
            continue
        if serial_port:
            break
    if serial_port:
        logger.info(f"Found USB serial port {serial_port} ...")
    else:
        logger.warning(f"No USB serial ports found ...")


def read_serial_once(df: pd.DataFrame) -> pd.DataFrame:
    """
    Read data from serial port and append it to the dataframe passed as argument.
    :param df: Dataframe to append data to
    :return: Dataframe with new data (same instance as passed as argument)
    """
    global serial_port

    detect_usb_serial_port()

    if serial_port is None or not serial_port.exists():
        logger.warning("No serial port found. Skip reading ...")
        serial_port = None
        time.sleep(WAITING_TIME)
        return df

    try:
        with serial.Serial(serial_port.as_posix(), baudrate=115200, timeout=1) as fp:
            logger.info(f"Opened serial port {serial_port}. Waiting {WAITING_TIME} seconds...")
            time.sleep(WAITING_TIME)
            fp.write("r".encode("ascii"))
            data = fp.readline().decode("ascii").strip()
        df.loc[len(df)] = [datetime.datetime.now()] + [float(value or 0) for value in data.split(",")]
    except serial.SerialException:
        logger.warning(f"Could not read data from serial port {serial_port}. Error:\n {traceback.format_exc()}")
        time.sleep(WAITING_TIME)
        serial_port = None
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


def signal_parent() -> None:
    """Send signal to parent process when exiting so that it knows we are done"""
    os.kill(os.getppid(), signal.SIGUSR1)


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


def main(args: list = None) -> None:
    """Main function"""
    atexit.register(signal_parent)
    args = parse_args(args)

    while True:
        read_serial_batch(path=args.output_path, batch_length=args.batch_length)


if __name__ == "__main__":
    main()
