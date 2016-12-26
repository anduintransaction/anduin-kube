#!/usr/bin/env bash

function install {
    which git > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "git not found"
        exit 1
    fi
    rm -rf anduin-kube && \
        git clone https://github.com/anduintransaction/anduin-kube && \
        ./anduin-kube/bin/install.sh
    rm -rf anduin-kube
}

install
