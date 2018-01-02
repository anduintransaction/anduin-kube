#!/usr/bin/env bash

function forceStop {
    VBoxManage controlvm minikube poweroff
    sudo -E anduin-kube cleanup
}
