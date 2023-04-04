#!/usr/bin/env python3
import argparse
import json
import logging
from pathlib import Path

import pandas as pd
import plotly
import plotly.express as px
from flask import Flask, render_template, request

SCRIPT_NAME = Path(__file__).stem
logger = logging.getLogger(SCRIPT_NAME)
app = Flask(SCRIPT_NAME)


def parse_args(args: list = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        description="Read data from Arduino",
        epilog=f"{SCRIPT_NAME} --batch-length 12 --output-path /home/pi/weather",
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
        default=Path("/home/pi/weather"),
        help="Path to write output files",
    )
    args = parser.parse_args(args)
    return args


def get_data(selected: list) -> pd.DataFrame:
    df = pd.concat([pd.read_csv(csv_path) for csv_path in app.config["input_path"].glob("*.csv")])
    df.sort_values(by="datetime", inplace=True)
    return df


@app.route("/")
def index():
    selected = ["temperature_1_value"]
    df = get_data(selected)
    fig = px.line(df, x="datetime", y=selected)
    graph = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return render_template(
        "index-dynamic.html",
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


if __name__ == "__main__":
    args = parse_args()
    app.config["input_path"] = args.input_path
    app.run(host="0.0.0.0")
