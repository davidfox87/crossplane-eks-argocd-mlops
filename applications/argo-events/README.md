# info on creating the github token
https://docs.triggermesh.io/cloud/sources/github/#deploying-an-instance-of-the-source

echo -n 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 | base64

kubectl -n argo-events port-forward $(kubectl -n argo-events get pod -l eventsource-name=github -o name) 12000:12000 &