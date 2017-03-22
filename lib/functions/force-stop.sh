#!/usr/bin/env bash

function forceStop {
    VBoxManage controlvm minikube poweroff
    sudo anduin-kube cleanup
}
