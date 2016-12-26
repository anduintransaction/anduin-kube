#!/usr/bin/env bash

function usage {
    cat <<EOF
anduin-kube is a CLI tool that provisions and manages single-node Kubernetes clusters optimized for development workflows.

Usage:
  anduin-kube [command]

Available Commands:
  addons           Modify anduin-kube's kubernetes addons
  completion       Outputs anduin-kube shell completion for the given shell (bash)
  config           Modify anduin-kube config
  dashboard        Opens/displays the kubernetes dashboard URL for your local cluster
  delete           Deletes a local kubernetes cluster.
  docker-env       sets up docker env variables; similar to '$(docker-machine env)'
  get-k8s-versions Gets the list of available kubernetes versions available for anduin-kube.
  ip               Retrieve the IP address of the running cluster.
  logs             Gets the logs of the running localkube instance, used for debugging anduin-kube, not user code.
  service          Gets the kubernetes URL(s) for the specified service in your local cluster
  ssh              Log into or run a command on a machine with SSH; similar to 'docker-machine ssh'
  start            Starts a local kubernetes cluster.
  status           Gets the status of a local kubernetes cluster.
  stop             Stops a running local kubernetes cluster.
  version          Print the version of anduin-kube
EOF
}
