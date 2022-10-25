## install argo workflows with artifact repository configured
```kustomize build  base | kubectl apply -f -```

# Open a port-forward so you can access the UI:
kubectl -n argo port-forward deployment/argo-server 2746:2746

This will serve the UI on https://localhost:2746. Due to the self-signed certificate, you will receive a TLS error which you will need to manually approve.

# Create a Secret based on existing credentials
https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/david/.docker/config.json --type=kubernetes.io/dockerconfigjson -n workflows


# configure argo artifacts minio storage

