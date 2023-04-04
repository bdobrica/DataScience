#!/usr/bin/env python3
import argparse
import atexit
import logging
import os
import signal
import time
import traceback
from io import BytesIO
from pathlib import Path

import pandas as pd
from minio import Minio

SCRIPT_NAME = Path(__file__).stem
logger = logging.getLogger(SCRIPT_NAME)


def parse_args(args: list = None) -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        description="Collect old files and upload them to Minio",
        epilog=f"{SCRIPT_NAME} --input-path /opt/sensors/data --batch-size 60 --min-keep 60",
    )

    def validate_path(path: str) -> Path:
        path = Path(path)
        if not path.exists() or not path.is_dir():
            raise argparse.ArgumentTypeError(f"Path {path} is not a directory")
        return path

    parser.add_argument(
        "-i",
        "--input-path",
        type=validate_path,
        default=Path("/opt/sensors/data"),
        help="Path to write output files",
    )
    parser.add_argument(
        "-b",
        "--batch-size",
        type=int,
        default=60,
        help="Number of files to upload at once",
    )
    parser.add_argument(
        "-m",
        "--min-keep",
        type=int,
        default=60,
        help="Minimum number of files to keep",
    )
    args = parser.parse_args(args)
    return args


def upload_to_minio(client: Minio, df: pd.DataFrame) -> None:
    """
    Upload a DataFrame to Minio. It uses also MINIO_BUCKET_NAME environment
    variable to specify the bucket name and also creates partitions based on
    the datetime column.
    :param client: Minio client
    :param df: DataFrame to upload
    """
    csv = df.to_csv(index=False).encode("utf-8")
    min_date = df.datetime.min()
    object_path = Path("sensors")
    object_path /= f"date={min_date.strftime('%Y-%m-%d')}"
    object_path /= f"hour={min_date.strftime('%H')}"
    object_path /= f"{min_date.strftime('%Y%m%d-%H%M%S')}.csv"
    bucket_name = os.getenv("MINIO_BUCKET_NAME")

    logger.info(f"Uploading {len(df)} records to minio://{bucket_name}/{object_path}")

    client.put_object(
        bucket_name=os.getenv("MINIO_BUCKET_NAME"),
        object_name=object_path.as_posix(),
        data=BytesIO(csv),
        length=len(csv),
        content_type="application/csv",
    )


def prepare_batch(files: list) -> pd.DataFrame:
    """
    Given a list of files, it returns a DataFrame with all the data in it.
    :param files: List of files to read
    :return: DataFrame with all the data sorted by datetime
    """
    df = pd.concat([pd.read_csv(csv_path) for csv_path in files])
    df.sort_values(by="datetime", inplace=True)
    return df


def clean_up(files: list) -> None:
    """Given a list of files, it removes them from the filesystem."""
    for file in files:
        file.unlink()


def detect_files(input_path: Path, batch_size: int, min_keep: int) -> list:
    """
    Given a path, it returns a list of files to upload. It will upload the
    oldest {batch_size} ones and keep at least {min_keep} files for the web app
    to use.
    :param input_path: Path to look for files
    :param batch_size: Number of files to upload
    :param min_keep: Minimum number of files to keep
    :return: List of files to upload
    """
    files = list(input_path.glob("*.csv"))
    files.sort(key=lambda file: file.stat().st_mtime)
    if len(files) > batch_size + min_keep:
        return files[:batch_size]
    return []


def signal_parent() -> None:
    """Send a signal to the parent process to notify it that we are done."""
    os.kill(os.getppid(), signal.SIGUSR1)


def main(args: list = None) -> None:
    """Main function"""
    atexit.register(signal_parent)
    client = Minio(
        os.getenv("MINIO_HOST"),
        access_key=os.getenv("MINIO_ACCESS_KEY"),
        secret_key=os.getenv("MINIO_SECRET_KEY"),
        secure=False,
    )

    while True:
        args = parse_args(args)
        files = detect_files(args.input_path, args.batch_size, args.min_keep)
        if files:
            logger.info(f"Found {len(files)} files to upload ...")
            df = prepare_batch(files)
            try:
                upload_to_minio(client, df)
                clean_up(files)
            except Exception:
                logger.warn(f"Error uploading to Minio: {traceback.format_exc()}")
        time.sleep(float(os.getenv("UPLOAD_INTERVAL", 60)))


if __name__ == "__main__":
    main()
