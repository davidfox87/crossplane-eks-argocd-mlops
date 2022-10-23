# to test github webhook events locally in minikube use ngrok service
```
ngrok start --config=ngrok.yml webhook
```

Use the forwarding address in the github argo eventsource so that github webhook can reach the event-source service. In production, the webhook would reach the argo eventsource service via a kubernetes ingress.
