#!/usr/bin/env bash

function fixKubeIP {
  ip=$(minikube ip)
  echo "Minikube ip: ${ip}"
  find $HOME/.anduin-kube -type f -exec sed -i "s/192.168.144.100/${ip}/g" {} \;
}
