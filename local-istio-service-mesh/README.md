
# create a local K8s cluster
```kind create cluster --name istio --image kindest/node:v1.21.14```


# ingress controller
```
kubectl create ns ingress-nginx
kubectl apply -f kubernetes/servicemesh/applications/ingress-nginx/
```
# applications
```
cd applications/kustomize/overlays/production
kustomize build .
```

Confirm application and nginx-ingress controller are running
```
kubectl get pods -n task-tracker-app
kubectl get pods -n ingress-nginx
```


create a fake DNS name servicemesh.demo by adding an entry in our /etc/hosts file

```
127.0.0.1       servicemesh.demo
```



## install Istio
```
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.15.1
export PATH=$PWD/bin:$PATH
istioctl install --set profile=default -y```
kubectl label namespace default istio-injection=enabled
```


To inject the istio sidecar proxy into all pods running in a given namespace
add the label to the namespace
```
labels: 
    istio-injection: enabled
```

Kill all pods that have not been given this istio injection label so K8s will restart with the sidecar
```kubectl delete --all pods -n task-tracker-app```
```kubectl get po -n task-tracker-app```


## install grafana and prometheus addons
```
kubectl apply -f istio-1.15.1/samples/addons/prometheus.yaml 
kubectl apply -n istio-system -f istio-1.15.1/samples/addons/grafana.yaml 
kubectl -n istio-system get pods

kubectl apply -f istio-1.15.1/samples/addons/kiali.yaml
kubectl get po -n istio-system
kubectl -n istio-system port-forward svc/kiali 20001
```


# Mesh our services
```
kubectl label namespace/default istio-injection=enabled

# restart all pods to get sidecar injected
kubectl delete pods --all

kubectl -n ingress-nginx get deploy nginx-ingress-controller  -o yaml | istioctl kube-inject -f - | kubectl apply -f -


# delete cluster
```kind delete cluster --name istio```



Checkout the awesome Grafana and Kiali dashboards! Try running the [google microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo) and visualizing the graph in Kiali.

