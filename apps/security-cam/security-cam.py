#!/usr/bin/env python3
import sys
import time
from pathlib import Path

import cv2
from camera import VideoCamera
from config import app_config
from daemon import Daemon
from flask import Flask, Response, render_template, request
from logger import Logger

logger_path = Path(app_config.log.path)
logger = Logger(path=logger_path / Path(__file__).stem, level=int(app_config.log.level))


class SecurityCamDaemon(Daemon):
    def atexit(self):
        logger.debug("Security camera daemon exiting. Cleaning up.")
        super().atexit()

    def get_encoded_frame(self, camera):
        while True:
            frame = camera.get_frame()
            yield (b"--frame\r\n" + b"Content-Type: image/jpeg\r\n\r\n" + frame + b"\r\n\r\n")

    def run(self):
        while True:
            # initialize a websocket client and connect the proper callbacks
            logger.debug("Initializing the Pi Camera.")
            camera = VideoCamera(rotate=cv2.ROTATE_180)
            # prepare the Flask APP
            logger.debug("Initializing Flask API.")
            app = Flask(__name__, template_folder=app_config.template.path)
            self._logged_in = False

            # the main route
            @app.route("/", methods=["GET", "POST"])
            def index():
                logger.debug(str(request.form))
                if request.form.get("logout") is not None:
                    self._logged_in = False
                if request.form.get("pin") == app_config.security.pin:
                    self._logged_in = True

                if self._logged_in:
                    return render_template("index.html")
                else:
                    return render_template("login.html")

            @app.route("/video")
            def video():
                if self._logged_in:
                    return Response(
                        self.get_encoded_frame(camera), mimetype="multipart/x-mixed-replace; boundary=frame"
                    )
                else:
                    return "401 Unauthorized (RFC 7235)", 401

            app.run(host="0.0.0.0", port=int(app_config.main.port), debug=False)
            logger.warning(
                "The Flask API exited. Waiting {respawn} seconds and trying to respawn.".format(
                    respawn=app_config.main.respawn
                )
            )
            # but sometimes, the socket can close itself. so clean first
            del app
            del camera
            # then wait, and respawn
            time.sleep(int(app_config.main.respawn))


if __name__ == "__main__":
    chroot = Path(__file__).absolute().parent
    pidname = Path(__file__).stem + ".pid"
    daemon = SecurityCamDaemon(
        pidfile=str((chroot / "run") / pidname),
        chroot=chroot
        # stdout = logger_path / (Path(__file__).stem + '.stdout'),
        # stderr = logger_path / (Path(__file__).stem + '.stderr')
    )
    if len(sys.argv) >= 2:
        if sys.argv[-1] == "start":
            daemon.start()
        elif sys.argv[-1] == "stop":
            daemon.stop()
        elif sys.argv[-1] == "restart":
            daemon.restart()
        else:
            print("Unknow command {command}.".format(command=sys.argv[1]))
            sys.exit(2)
        sys.exit(0)
    else:
        print("Usage: {command} start|stop|restart".format(command=sys.argv[0]))
        sys.exit(0)
