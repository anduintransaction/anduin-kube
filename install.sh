#!/usr/bin/env bash

here=`cd $(dirname $BASH_SOURCE); pwd`
. $here/lib/common.sh

function installAnduinMinikubeDeploy {
    if which anduin-minikube-deploy > /dev/null 2>&1; then
        version=`anduin-minikube-deploy version`
        if [ "$version" == "$ANDUIN_MINIKUBE_DEPLOY_VERSION" ]; then
            return
        fi
    fi
    wget https://github.com/anduintransaction/anduin-minikube-deploy/releases/download/$ANDUIN_MINIKUBE_DEPLOY_VERSION/anduin-minikube-deploy-$ANDUIN_MINIKUBE_DEPLOY_VERSION-darwin-amd64.tar.gz && \
        tar xzf anduin-minikube-deploy-$ANDUIN_MINIKUBE_DEPLOY_VERSION-darwin-amd64.tar.gz && \
        rm anduin-minikube-deploy-$ANDUIN_MINIKUBE_DEPLOY_VERSION-darwin-amd64.tar.gz && \
        copyToUsrLocalBin anduin-minikube-deploy && \
        rm anduin-minikube-deploy
}

function installDockerCommandline {
    if which docker > /dev/null 2>&1; then
        version=`docker version 2>/dev/null | grep Version | head -1 | awk '{print $2}' | sed 's/\s*//g'`
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

copyToUsrLocalBin $here/bin/anduin-kube && \
    mkdir -p $HOME/.anduin-kube && \
    rm -rf $HOME/.anduin-kube/lib && \
    cp -r $here/lib $HOME/.anduin-kube/ && \
    installDockerCommandline && \
    installAnduinMinikubeDeploy
