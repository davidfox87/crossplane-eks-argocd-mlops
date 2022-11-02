 kind create cluster --name seldon-cluster --image kindest/node:v1.24.4@sha256:adfaebada924a26c2c9308edd53c6e33b3d4e453782c0063dc0028bdebaddf98

 kubectl cluster-info --context kind-seldon-cluster

 kubectl version --short