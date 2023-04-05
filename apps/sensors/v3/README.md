# Application for Raspberry Pi 4 and Arduino to collect sensor data

## Description

The application is composed of four parts:
- a Python script that runs on the Raspberry Pi 4 and reads data from the Arduino via the serial port `arduino.py`;
- a Python script that checks the data received from the Arduino and creates charts that are displayed in a web interface `webserver.py`;
- a Python script that checks the data received, packs it in batches and uploads them to a Minio server `uploader.py`;
- a Python script that orchestrates the other three scripts `entrypoint.py`.

The components are communicating with each other through SIGUSR1 signals so that when one component needs to stop, it sends a SIGUSR1 signal to the orchestrator, which in turn sends a SIGQUIT signals to the other components to terminate them, after which it will exit.

## Build and Run

Building the application is pretty straight forward. The only thing that you need to chose is the name of the container - `arduino-rpi4-sensors` in the example below. To build the application, run the following command:

```sh
cd apps/sensors/v3
podman build -t arduino-rpi4-sensors .
```

Running the application requires a little understanding of how OCI images are run.

To enable automatic detection of the USB serial port in case it gets disconnected and reconnected, the `--mount type=bind,source=/dev,target=/dev,bind-propagation=rslave` option is used which bind-mounts the `/dev` filesystem for the container, with `bind-propagation=rslave` making sure that the host doesn't get any of the container devices in return.

SD cards have a limited number of reads and writes. To avoid the SD card from getting corrupted, the `--mount type=tmpfs,target=/opt/sensors/data` option is used to mount a temporary filesystem in the container. This filesystem is not persistent and will be lost when the container is stopped.

The `--annotation run.oci.keep_original_groups=1` option is used to keep the original group of the user that owns the devices inside the container, to allow scripts from within the container to access the devices.

The `-p 5000:5000` option is used to expose the web interface on port 5000.

Finally, the `-d` option is used to run the container in the background. If you want to see what happens inside the container, remove the `-d` option and replace it with `-it --rm`.

```sh
podman run \
    --mount type=bind,source=/dev,target=/dev,bind-propagation=rslave \
    --mount type=tmpfs,target=/opt/sensors/data \
    --annotation run.oci.keep_original_groups=1 \
    -p 5000:5000 \
    -d \
    arduino-rpi4-sensors
```

## Environment Variables

The application requires several environment variables to be set:
- `MINIO_HOST` - the host name of the Minio server, eg. `minio` or `192.168.1.1:9000`;
- `MINIO_ACCESS_KEY` - the access key of the Minio server;
- `MINIO_SECRET_KEY` - the secret key of the Minio server;
- `MINIO_BUCKET_NAME` - the Minio bucket where to upload the data;

These are environment variables that can be overridden:
- `UPLOAD_INTERVAL` - the interval in seconds between two uploads to the Minio server, default is 60 seconds;
- `WAITING_INTERVAL` - the interval in seconds between two checks for new data from Arduino, default is 5 seconds;

To specify the environment variables from the command line, add the following options to the `podman run` command:

```sh
podman run \
    --env-file vars.env \
    --mount type=bind,source=/dev,target=/dev,bind-propagation=rslave \
    --mount type=tmpfs,target=/opt/sensors/data \
    --annotation run.oci.keep_original_groups=1 \
    -p 5000:5000 \
    -d \
    arduino-rpi4-sensors
```

where `vars.env` is a file containing the environment variables, one per line, in the format `NAME=VALUE`, like the one already provided (which requires you to change the values to match your setup).

## Entry Point Options

The entry point script `entrypoint.py` can be run with the following options:
- `--rows-per-file` or `-r` - the number of rows to be written in a file before a new file is created, default is 100;
- `--files-per-upload` or `-f` - the number of files to be uploaded to the Minio server at a time, default is 60;
- `--files-to-keep` or `-k` - the number of files to be kept on the Raspberry Pi 4, for interactive visualization in the Web UI, default is 60;

To use those options, add them to the `podman run` command like this:

```sh
podman run \
    --env-file vars.env \
    --mount type=bind,source=/dev,target=/dev,bind-propagation=rslave \
    --mount type=tmpfs,target=/opt/sensors/data \
    --annotation run.oci.keep_original_groups=1 \
    -p 5000:5000 \
    -d \
    arduino-rpi4-sensors \
    --rows-per-file 100 \
    --files-per-upload 60 \
    --files-to-keep 60
```