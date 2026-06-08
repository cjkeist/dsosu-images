#!/bin/bash

cat *.dockerfile > Dockerfile
../../dsosuk8s/scripts/docker_chain_build.sh .
