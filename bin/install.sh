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
    case `uname` in
        Darwin)
            downloadLink=https://github.com/anduintransaction/imladris/releases/download/$IMLADRIS_VERSION/imladris-$IMLADRIS_VERSION-darwin-amd64.tar.gz
            ;;
        Linux)
            downloadLink=https://github.com/anduintransaction/imladris/releases/download/$IMLADRIS_VERSION/imladris-$IMLADRIS_VERSION-linux-amd64.tar.gz
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
    wget -O imladris.tar.gz $downloadLink &&
        tar xzf imladris.tar.gz &&
        rm imladris.tar.gz &&
        copyToUsrLocalBin imladris &&
        rm imladris
}

function installDockerCommandline {
    if which docker > /dev/null 2>&1; then
        version=`docker version --format '{{.Client.Version}}' 2>/dev/null`
        if [ "$version" == "$DOCKER_VERSION" ]; then
            return
        fi
    fi
    case `uname` in
        Darwin)
            downloadLink=https://download.docker.com/mac/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz
            ;;
        Linux)
            downloadLink=https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
    wget $downloadLink &&
        tar xzf docker-${DOCKER_VERSION}.tgz &&
        rm docker-${DOCKER_VERSION}.tgz &&
        copyToUsrLocalBin docker/docker &&
        rm -rf docker
}

copyToUsrLocalBin $root/bin/anduin-kube && \
    mkdir -p $HOME/.anduin-kube && \
    rm -rf $HOME/.anduin-kube/lib && \
    cp -r $root/lib $HOME/.anduin-kube/ && \
    installDockerCommandline && \
    installImladris
