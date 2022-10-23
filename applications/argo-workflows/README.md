## install argo workflows with artifact repository configured
```kustomize build  base | kubectl apply -f -```


# Create a Secret based on existing credentials
https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

kubectl create secret generic regcred \ 
--from-file=.dockerconfigjson=/home/david/.docker/config.json \
--type=kubernetes.io/dockerconfigjson - n workflows