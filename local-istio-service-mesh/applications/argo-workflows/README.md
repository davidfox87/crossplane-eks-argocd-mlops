## install argo workflows with artifact repository configured
kustomize build  base | kubectl apply -f -

kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.0/install.yaml
