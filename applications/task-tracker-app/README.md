# In local stack
In base don't define a namespace because we will specify it in overlays/production/kustomization.yaml for our prod env
```
kubectl create namespace kustomize-dev
kustomize build task-tracker-app/base | kubectl --namespace kustomize-dev apply --filename -
```

# get the istio-ingress gateway 
kubectl get svc -l istio=ingressgateway -n istio-system

we will refer to the ingressgateway in our gateway yaml by specifying the selector above istio:ingressgateway





Cool Kustomize trick 
```kustomize edit set image foxy7887/task-tracker-app=foxy7887/task-tracker-app:v2```

then a new entry will get added to kustomization.yaml
```
images:
- name: foxy7887/task-tracker-app
  newName: foxy7887/task-tracker-app
  newTag: v2
```

