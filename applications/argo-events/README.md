# install argo-events
Go into ```argo-events/overlays/production``` and run ```kustomize build | kubectl apply -f -``` to install argo-events

# info on creating the github token
https://docs.triggermesh.io/cloud/sources/github/#deploying-an-instance-of-the-source


kubectl create secret generic github-access -n argo-events --dry-run=client --from-file=token=.env -o json > github-access.json

kubeseal --controller-namespace kube-system \
         --controller-name sealed-secrets \
        < github-access.json  > github-access-sealedsecret.json

kubectl apply -f github-access-sealedsecret.json -n argo-events





kubectl -n argo-events port-forward $(kubectl -n argo-events get pod -l eventsource-name=github -o name) 12000:12000 &

# Trigger sources
Git trigger source refers to K8s trigger refers to the K8s resource stored in Git. 
https://argoproj.github.io/argo-events/tutorials/03-trigger-sources/

kubectl -n argo-events create secret generic git-ssh --from-file=key=.ssh/<YOUR_SSH_KEY_FILE_NAME>

kubectl -n argo-events create secret generic git-known-hosts --from-file=ssh_known_hosts=/home/david/.ssh/known_hosts
