# start from the python 3.9 slim buster base image
FROM python:3.9-slim-buster

# create the working directory (-p creates all parent directories)
RUN mkdir -p /opt/sensors/templates
# set the working directory
WORKDIR /opt/sensors
# copy the requirements.txt file and install the dependencies
COPY requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

# copy the rest of the application files
COPY logger.py ./logger.py
COPY arduino.py ./arduino.py
COPY webserver.py ./webserver.py
COPY templates/index.html ./templates/index.html
COPY uploader.py ./uploader.py
COPY entrypoint.py ./entrypoint.py

# define the startup command
ENTRYPOINT [ "/opt/sensors/entrypoint.py" ]
