import time
from threading import Thread
from typing import Tuple

import cv2
from picamera2 import Picamera2


class PiVideoStream:
    def __init__(self, resolution: Tuple[int, int] = (640, 480)) -> None:
        self.camera = Picamera2()

        self.config = self.camera.create_preview_configuration(main={"size": resolution})
        self.camera.configure(self.config)
        self.frame = None
        self.stopped = False

    def start(self) -> "PiVideoStream":
        self.camera.start()
        t = Thread(target=self.update, args=())
        t.daemon = True
        t.start()
        return self

    def read(self) -> cv2.Mat:
        return cv2.cvtColor(self.frame, cv2.COLOR_BGR2RGB)

    def update(self) -> None:
        while True:
            self.frame = self.camera.capture_array("main")
            if self.stopped:
                self.camera.stop()
                break

    def stop(self) -> None:
        self.stopped = True


class VideoCamera(object):
    def __init__(self, rotate=None):
        self.video_stream = PiVideoStream().start()
        self.rotate = rotate
        time.sleep(2.0)

    def __del__(self):
        self.video_stream.stop()

    def rotate_if_needed(self, frame):
        if self.rotate is not None:
            return cv2.rotate(frame, self.rotate)
        return frame

    def get_frame(self):
        frame = self.video_stream.read()
        frame = self.rotate_if_needed(frame)
        _, jpeg = cv2.imencode(".jpg", frame)
        return jpeg.tobytes()
