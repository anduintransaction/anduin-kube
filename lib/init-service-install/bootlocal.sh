#!/bin/sh

for initFile in `ls /var/lib/boot2docker/init.d/*.sh`; do
    $initFile start
done
