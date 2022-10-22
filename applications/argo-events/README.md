echo -n 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 | base64

kubectl -n argo-events port-forward $(kubectl -n argo-events get pod -l eventsource-name=github -o name) 12000:12000 &