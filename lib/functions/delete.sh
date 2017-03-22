#!/usr/bin/env bash

function removeMinikube {
    if [ $(minikubeStatus) != "NA" ]; then
        echo "Deleting minikube machine"
        minikube delete
    fi
    if kubectl config get-contexts | grep minikube > /dev/null 2>&1; then
        echo "Deleting minikube context"
        kubectl config delete-context minikube
    fi
    echo "Deleting minikube configs"
    rm -rf ~/.minikube
}

function cleanupVBox {
    deleteVBoxNetwork $MINIKUBE_CIDR
}

function delete {
    removeMinikube && \
        cleanupVBox && \
        sudo anduin-kube cleanup
}
