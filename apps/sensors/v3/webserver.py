#!/usr/bin/env python3
import argparse
import atexit
import json
import logging
import os
import signal
from pathlib import Path

import pandas as pd
import plotly
import plotly.express as px
from flask import Flask, render_template, request
from logger import init_logger

SCRIPT_NAME = Path(__file__).stem
DEFAULT_FEATURE = "temperature_1_value"

logger = init_logger(SCRIPT_NAME)
app = Flask(SCRIPT_NAME)


def get_data() -> pd.DataFrame:
    """Read all CSV files from the input path and return a DataFrame"""
    csv_files = list(app.config["input_path"].glob("*.csv"))
    if not csv_files:
        logger.warning(f"Could not find any CSV data files in {app.config['input_path']} ...")
        return pd.DataFrame(columns=["datetime", DEFAULT_FEATURE])
    else:
        logger.warning(f"Found {len(csv_files)}  CSV data files in {app.config['input_path']} ...")
    df = pd.concat([pd.read_csv(csv_path) for csv_path in app.config["input_path"].glob("*.csv")])
    df.sort_values(by="datetime", inplace=True)
    return df


@app.route("/")
def index():
    selected = [DEFAULT_FEATURE]
    df = get_data()
    fig = px.line(df, x="datetime", y=selected)
    graph = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return render_template(
        "index.html",
        graph=graph,
        parameters={col: col in selected for col in df.columns[1:]},
    )


@app.route("/data")
def data():
    selected = request.args.getlist("features[]")
    logger.info(f"Selected features: {selected}")
    df = get_data()
    logger.info(f"Found {len(df)} data points")
    fig = px.line(df, x="datetime", y=selected)
    graph = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return graph


def signal_parent() -> None:
    """Send a signal to the parent process to indicate that the webserver has terminated"""
    os.kill(os.getppid(), signal.SIGUSR1)


def parse_args(args: list) -> argparse.Namespace:
    """Parse command line arguments"""
    script_name = Path(__file__).stem
    parser = argparse.ArgumentParser(
        prog=script_name,
        description="Start a webserver to display data using Plotly",
        epilog=f"{script_name} --input-path /opt/sensors/data",
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
        help="Path from where to read sensor data files",
    )
    args = parser.parse_args(args)
    return args


def main(args: list = None) -> None:
    """Start the webserver"""
    atexit.register(signal_parent)
    args = parse_args(args)

    app.config["input_path"] = args.input_path
    app.run(host="0.0.0.0")


if __name__ == "__main__":
    main()
