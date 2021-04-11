import cv2
from imutils.video.pivideostream import PiVideoStream
import time

class VideoCamera(object):
    def __init__(self, rotate = None):
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
        _, jpeg = cv2.imencode('.jpg', frame)
        return jpeg.tobytes()