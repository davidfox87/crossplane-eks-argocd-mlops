# install argo-events
Go into ```argo-events/overlays/production``` and run ```kustomize build | kubectl apply -f -``` to install argo-events

# info on creating the github token
For information on generating your token on Github, see this ![link](https://cloud.redhat.com/blog/how-to-use-argocd-deployments-with-github-tokens)

https://docs.triggermesh.io/cloud/sources/github/#deploying-an-instance-of-the-source


kubectl create secret generic github-access -n argo-events \
                --dry-run=client \
                --from-file=token=.env -o yaml | kubeseal   --controller-namespace kubeseal \
                                                            --controller-name sealed-secrets \
                                                            --format yaml > github-access-sealedsecret.yaml

we could apply here, but instead commit and push the change to github and let Argo CD deploy the secret to our cluster

kubectl apply -f github-access-sealedsecret.json -n argo-events


## start ngrok server
1. take forwarding url and put it in the webhook url in the argo-events events-source url
2. port forward to the webhook service

kubectl -n argo-events port-forward $(kubectl -n argo-events get pod -l eventsource-name=github -o name) 12000:12000 &

kubectl -n argo-events port-forward svc/github-eventsource-svc 12000:12000 &

# Trigger sources
Git trigger source refers to K8s trigger refers to the K8s resource stored in Git. 
https://argoproj.github.io/argo-events/tutorials/03-trigger-sources/

kubectl -n argo-events create secret generic git-ssh --from-file=key=.ssh/<YOUR_SSH_KEY_FILE_NAME>

kubectl -n argo-events create secret generic git-known-hosts --from-file=ssh_known_hosts=/home/david/.ssh/known_hosts
