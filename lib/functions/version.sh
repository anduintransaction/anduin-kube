#!/usr/bin/env bash

ANDUIN_KUBE_VERSION=0.12.11

function version {
    echo "anduin-kube version: $ANDUIN_KUBE_VERSION"
    minikube version
}
