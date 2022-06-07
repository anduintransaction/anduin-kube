#!/usr/bin/env bash

function setupNetwork {
    if [ `whoami` != "root" ]; then
        echo "Must be root"
        exit 1
    fi
    cleanupRoute && modifyRoute && startHealthz
}
