#!/bin/bash
# Small script to build and push the jupyterhub-kubespawner image to quay.io

podman build -t jupyterhub-kubespawner .
podman tag jupyterhub-kubespawner quay.io/bdobrica/jupyterhub-kubespawner
podman push quay.io/bdobrica/jupyterhub-kubespawner
