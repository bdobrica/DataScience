#!/usr/bin/env python3
import argparse
import atexit
import os
import signal
from io import BytesIO
from pathlib import Path

import pandas as pd
from minio import Minio


def parse_args(args: list = None) -> argparse.Namespace:
    script_name = Path(__file__).stem
    parser = argparse.ArgumentParser(
        prog=script_name,
        description="Collect old files and upload them to Minio",
        epilog=f"{script_name} --input-path /opt/sensors/data --batch-size 60 --min-keep 60",
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
    csv = df.to_csv(index=False).encode("utf-8")

    client.put_object(
        bucket_name=os.getenv("MINIO_BUCKET_NAME"),
        object_name="sensors.csv",
        data=BytesIO(csv),
        length=len(csv),
        content_type="application/csv",
    )


def prepare_batch(files: list) -> pd.DataFrame:
    df = pd.concat([pd.read_csv(csv_path) for csv_path in files])
    df.sort_values(by="datetime", inplace=True)
    return df


def clean_up(files: list) -> None:
    for file in files:
        file.unlink()


def detect_files(input_path: Path, batch_size: int, min_keep: int) -> list:
    files = list(input_path.glob("*.csv"))
    files.sort(key=lambda file: file.stat().st_mtime)
    if len(files) > batch_size + min_keep:
        return files[:batch_size]
    return []


def signal_parent() -> None:
    os.kill(os.getppid(), signal.SIGUSR1)


def main(args: list = None) -> None:
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
            df = prepare_batch(files)
            upload_to_minio(client, df)
            clean_up(files)


if __name__ == "__main__":
    main()
