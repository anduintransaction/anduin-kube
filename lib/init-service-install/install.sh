#!/bin/sh

sudo mkdir -p /var/lib/boot2docker/init.d && \
    sudo cp /home/docker/init-service-install/bootlocal.sh /var/lib/boot2docker/
