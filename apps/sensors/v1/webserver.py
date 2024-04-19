#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

import pandas as pd
import plotly
import plotly.express as px
from flask import Flask, render_template

app = Flask(__name__)


def parse_args(args: list = None) -> argparse.Namespace:
    script_name = Path(__file__).stem
    parser = argparse.ArgumentParser(
        prog=script_name,
        description="Read saved data and display it using Plotly",
        epilog=f"{script_name} --input-path /home/pi/weather",
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
        help="Path to read the data files from",
    )
    args = parser.parse_args(args)
    return args


@app.route("/")
def index():
    df = pd.concat([pd.read_csv(csv_path) for csv_path in app.config["input_path"].glob("*.csv")])
    df.sort_values(by="datetime", inplace=True)
    fig = px.line(df, x="datetime", y="temperature_1_value")
    graph = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return render_template("index.html", graph=graph)


if __name__ == "__main__":
    args = parse_args()
    app.config["input_path"] = args.input_path
    app.run(host="0.0.0.0")
