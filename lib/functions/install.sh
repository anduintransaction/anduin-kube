#!/usr/bin/env bash

function checkDeps {
    if which VBoxManage > /dev/null 2>&1; then
        return
    fi
    echo "VirtualBox not found. Please install Docker Toolbox: https://www.docker.com/products/docker-toolbox"
    exit 1
}

function installMinikube {
    if which minikube > /dev/null 2>&1; then
        version=`minikube version`
        if [ "$version" == "minikube version: $MINIKUBE_VERSION" ]; then
            return
        fi
    fi
    echo "Installing minikube $MINIKUBE_VERSION"
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/$MINIKUBE_VERSION/minikube-darwin-amd64 && \
        chmod +x minikube && \
        copyToUsrLocalBin minikube && \
        rm minikube
}

function installKubectl {
    if which kubectl > /dev/null 2>&1; then
        version=`kubectl version --client | grep -o 'GitVersion:"[^"]*"' | sed 's/GitVersion://' | sed 's/"//g'`
        if [ "$version" == "$KUBERNETES_VERSION" ]; then
            return
        fi
    fi
    echo "Installing kubectl $KUBERNETES_VERSION"
    curl -O https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/darwin/amd64/kubectl && \
        chmod 755 kubectl && \
        copyToUsrLocalBin kubectl && \
        rm kubectl
}

function installIfNeeded {
    checkDeps && \
        installMinikube && \
        installKubectl
}
