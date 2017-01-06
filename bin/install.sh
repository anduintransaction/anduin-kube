#!/usr/bin/env bash

here=`cd $(dirname $BASH_SOURCE); pwd`
root=$here/..
. $root/lib/common.sh

function installAnduinKubeDeploy {
    if which anduin-kube-deploy > /dev/null 2>&1; then
        version=`anduin-kube-deploy version`
        if [ "$version" == "$ANDUIN_KUBE_DEPLOY_VERSION" ]; then
            return
        fi
    fi
    wget https://github.com/anduintransaction/anduin-kube-deploy/releases/download/$ANDUIN_KUBE_DEPLOY_VERSION/anduin-kube-deploy-$ANDUIN_KUBE_DEPLOY_VERSION-darwin-amd64.tar.gz && \
        tar xzf anduin-kube-deploy-$ANDUIN_KUBE_DEPLOY_VERSION-darwin-amd64.tar.gz && \
        rm anduin-kube-deploy-$ANDUIN_KUBE_DEPLOY_VERSION-darwin-amd64.tar.gz && \
        copyToUsrLocalBin anduin-kube-deploy && \
        rm anduin-kube-deploy
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
    installAnduinKubeDeploy
