## install argo workflows with artifact repository configured
```kustomize build  base | kubectl apply -f -```

# Create a Secret based on existing credentials
The workflows require a number of secrets to function properly:
1. argo-artifacts
2. git-known-hosts
3. git-ssh
4. github-access
5. regcred

## apply docker reg credentials
kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/david/.docker/config.json --type=kubernetes.io/dockerconfigjson -n workflows

## apply git-ssh secret
kubectl -n workflows create secret generic git-ssh --from-file=key=/home/david/.ssh/id_ed25519

kubectl -n workflows create secret generic git-known-hosts --from-file=ssh_known_hosts=/home/david/.ssh/known_hosts

## configure argo artifacts minio storage
kubectl -n workflows create secret generic argo-artifacts --from-literal=username=minio --from-literal=password=minio123

## apply github-access secret that encode the personal access token
kubectl create secret generic github-access -n workflows --dry-run=client --from-file=token=.env -o json > github-access.json

kubeseal --controller-namespace kubeseal \
         --controller-name sealed-secrets \
        < github-access.json  > github-access-sealedsecret.json

kubectl apply -f github-access-sealedsecret.json -n workflows

# Open a port-forward so you can access the UI:
kubectl -n argo port-forward deployment/argo-server 2746:2746

This will serve the UI on https://localhost:2746. Due to the self-signed certificate, you will receive a TLS error which you will need to manually approve.