FROM python:3.9-slim-buster

RUN mkdir -p /opt/sensors
WORKDIR /opt/sensors
ADD templates ./templates
ADD arduino.py ./arduino.py
ADD uplader.py ./uplader.py
ADD webserver.py ./webserver.py
ADD requirements.txt ./requirements.txt

RUN pip install -r requirements.txt

ENTRYPOINT [ "/opt/sensors/entrypoint.sh" ]