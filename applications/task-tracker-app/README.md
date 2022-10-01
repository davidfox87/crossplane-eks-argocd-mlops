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







istioctl install --set profile=demo -y
kubectl label namespace prod istio-injection=enabled

minikube tunnel
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo "http://$GATEWAY_URL/productpage"

curl -s -I -HHost:task-tracker-app-ui.default.svc.cluster.local "http://$GATEWAY_URL"
echo "http://$GATEWAY_URL/task-tracker-app"