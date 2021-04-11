#!/usr/bin/env python3
from logger import Logger
import time
from flask import Flask, render_template, Response, request
import cv2
from camera import VideoCamera
import json
import time

logger_path = Path(app_config.log.path)
logger = Logger(path = logger_path / Path(__file__).stem, level = int(app_config.log.level))

class SecurityCamDaemon(Daemon):
    def atexit(self):
        logger.debug('Security camera daemon exiting. Cleaning up.')
        super().atexit()
        
    def get_encoded_frame(self, camera):
        while True:
            frame = self.camera.get_frame()
            yield(
                b'--frame\r\n'
                + b'Content-Type: image/jpeg\r\n\r\n'
                + frame
                + b'\r\n\r\n'
            )

    def run(self):
        while True:
            # initialize a websocket client and connect the proper callbacks
            logger.debug('Initializing the Pi Camera.')
            camera = VideoCamera(rotate = cv2.ROTATE_180)
            # prepare the Flask APP
            logger.debug('Initializing Flask API.')
            app = Flask(__name__, template_folder = app_config.template.path)
            # the main route
            @app.route('/')
            def index():
                return render_template('index.html')

            @app.route('/video')
            def video():
                return Response(
                        self.get_encoded_frame(camera),
                        mimetype = 'multipart/x-mixed-replace; boundary=frame'
                    )
            
            app.run(host = '0.0.0.0', port = int(app_config.main.port), debug = False)
            logger.warning('The Flask API exited. Waiting {respawn} seconds and trying to respawn.'.format(respawn = app_config.main.respawn))
            # but sometimes, the socket can close itself. so clean first
            del app
            del camera
            # then wait, and respawn
            sleep(int(app_config.main.respawn))
            
if __name__ == '__main__':
    chroot = Path(__file__).absolute().parent
    pidname = Path(__file__).stem + '.pid'
    daemon = SecurityCamDaemon(
            pidfile = str((chroot / 'run') / pidname),
            chroot = chroot
    )
    if len(sys.argv) >= 2:
        if sys.argv[-1] == 'start':
            daemon.start()
        elif sys.argv[-1] == 'stop':
            daemon.stop()
        elif sys.argv[-1] == 'restart':
            daemon.restart()
        else:
            print('Unknow command {command}.'.format(command = sys.argv[1]))
            sys.exit(2)
        sys.exit(0)
    else:
        print('Usage: {command} start|stop|restart'.format(command = sys.argv[0]))
        sys.exit(0)