# In local stack
In base don't define a namespace because we will specify it in overlays/production/kustomization.yaml for our prod env
```
kubectl create namespace kustomize-dev
kustomize build task-tracker-app/base | kubectl --namespace kustomize-dev apply --filename -
```

