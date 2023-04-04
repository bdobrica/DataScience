#!/usr/bin/env python3
import argparse
import atexit
import json
import os
import signal
from pathlib import Path

import pandas as pd
import plotly
import plotly.express as px
from flask import Flask, render_template, request

SCRIPT_NAME = Path(__file__).stem
DEFAULT_FEATURE = "temperature_1_value"

app = Flask(SCRIPT_NAME)


def parse_args(args: list) -> argparse.Namespace:
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


def get_data(selected: list) -> pd.DataFrame:
    df = pd.concat([pd.read_csv(csv_path) for csv_path in app.config["input_path"].glob("*.csv")])
    df.sort_values(by="datetime", inplace=True)
    return df


@app.route("/")
def index():
    selected = [DEFAULT_FEATURE]
    df = get_data(selected)
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
    print(selected)
    df = get_data(selected)
    fig = px.line(df, x="datetime", y=selected)
    graph = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return graph


def signal_parent() -> None:
    os.kill(os.getppid(), signal.SIGUSR1)


def main(args: list = None) -> None:
    atexit.register(signal_parent)
    args = parse_args(args)
    app.config["input_path"] = args.input_path
    app.run(host="0.0.0.0")


if __name__ == "__main__":
    main()
