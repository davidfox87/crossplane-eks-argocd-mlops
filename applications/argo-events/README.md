# install argo-events
Go into ```argo-events/overlays/production``` and run ```kustomize build | kubectl apply -f -``` to install argo-events

# info on creating the github token
https://docs.triggermesh.io/cloud/sources/github/#deploying-an-instance-of-the-source

echo -n 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 | base64

when you make the github personal access token, make sure to check the following boxes:



kubectl -n argo-events port-forward $(kubectl -n argo-events get pod -l eventsource-name=github -o name) 12000:12000 &

# Trigger sources
Git trigger source refers to K8s trigger refers to the K8s resource stored in Git. 
https://argoproj.github.io/argo-events/tutorials/03-trigger-sources/

kubectl -n argo-events create secret generic git-ssh --from-file=key=.ssh/<YOUR_SSH_KEY_FILE_NAME>

kubectl -n argo-events create secret generic git-known-hosts --from-file=ssh_known_hosts=/home/david/.ssh/known_hosts
