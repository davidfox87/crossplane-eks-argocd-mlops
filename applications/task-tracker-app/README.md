Cool Kustomize trick 
```kustomize edit set image foxy7887/task-tracker-app=foxy7887/task-tracker-app:v2```

then a new entry will get added to kustomization.yaml
```
images:
- name: foxy7887/task-tracker-app
  newName: foxy7887/task-tracker-app
  newTag: v2
```


# Follow this 
https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports


kubectl patch svc istio-ingressgateway -n istio-system --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'
curl -s -I -HHost:demo.local.me "http://$INGRESS_HOST:$INGRESS_PORT/task-tracker-app-ui/"


kubectl get pod -l app=task-tracker-app-ui -o jsonpath='{.items[0].metadata.name}')




istioctl install --set profile=demo -y
kubectl label namespace prod istio-injection=enabled

echo "http://$GATEWAY_URL/task-tracker-app"