#!/usr/bin/env bash

here=`cd $(dirname $BASH_SOURCE); pwd`
root=$here/..
. $root/lib/common.sh

function installImladris {
    if which imladris > /dev/null 2>&1; then
        version=`imladris version`
        if [ "$version" == "$IMLADRIS_VERSION" ]; then
            return
        fi
    fi
    wget https://github.com/anduintransaction/imladris/releases/download/$IMLADRIS_VERSION/imladris-$IMLADRIS_VERSION-darwin-amd64.tar.gz && \
        tar xzf imladris-$IMLADRIS_VERSION-darwin-amd64.tar.gz && \
        rm imladris-$IMLADRIS_VERSION-darwin-amd64.tar.gz && \
        copyToUsrLocalBin imladris && \
        rm imladris
}

function installDockerCommandline {
    if which docker > /dev/null 2>&1; then
        version=`docker version --format '{{.Client.Version}}' 2>/dev/null`
        if [ "$version" == "$DOCKER_VERSION" ]; then
            return
        fi
    fi
    wget https://get.docker.com/builds/Darwin/x86_64/docker-${DOCKER_VERSION}.tgz && \
        tar xzf docker-${DOCKER_VERSION}.tgz && \
        rm docker-${DOCKER_VERSION}.tgz && \
        copyToUsrLocalBin docker/docker && \
        rm -rf docker
}

copyToUsrLocalBin $root/bin/anduin-kube && \
    mkdir -p $HOME/.anduin-kube && \
    rm -rf $HOME/.anduin-kube/lib && \
    cp -r $root/lib $HOME/.anduin-kube/ && \
    installDockerCommandline && \
    installImladris
