
# create a local K8s cluster
```kind create cluster --name istio --image kindest/node:v1.21.14```

or minikube 
```
docker network create --subnet 192.168.57.0/16 --driver bridge minikube
minikube start
minikube addons enable ingress
minikube tunnel
```
or

# ingress controller
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.1/deploy/static/provider/cloud/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

  kubectl get pods --namespace=ingress-nginx

```

# follow this 
https://aws.amazon.com/blogs/containers/secure-end-to-end-traffic-on-amazon-eks-using-tls-certificate-in-acm-alb-and-istio/

## install Istio
Note that argocd will take care of installing istio-related helm charts in production cluster
```
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.15.1
export PATH=$PWD/bin:$PATH
istioctl install \
--set profile=demo \
--set values.gateways.istio-ingressgateway.type=NodePort
kubectl label namespace default istio-injection=enabled
```

Verify Istio installation is properly enabled by using ```kubectl get po -n istio-system```

# applications
Install our application into the default namespace - which has been labeled with istio-injection=enabled - using kustomize
```
cd applications
kustomize build task-tracker-app/base | kubectl apply -f -
```

Confirm application and nginx-ingress controller are running and there are 2 containers running in each pod (because we have the istio proxy sidecar)
```
kubectl get pods -o wide
kubectl get pods -n ingress-nginx

kubectl get svc -n ingress-nginx
```
Once Ingress is installed, it will provision AWS Application Load Balancer, bind it with the ACM certificate for HTTPS traffic and forward traffic to Istio resources inside the EKS cluster. You can get a generated manifest of Ingress resource using
```
kubectl get ingress istio-ingressgateway-alb  -o yaml
```
Note the values corresponding to ```alb.ingress.kubernetes.io/backend-protocol``` and ```host``` fields
Get ALB load balancer DNS and make a note of it.
```
echo $(kubectl get ingress istio-ingressgateway-alb  \
-o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

We should get an output that looks like this:
```k8s-istiosys-xxxxxxxxxxxxxxxxxxx.us-east-1.elb.amazonaws.com```


## in local mode
see pod nginx.conf for nginx ingress controller (this will allow us to debug)
```kubectl exec -it -n ingress-nginx ingress-nginx-controller-7989d7f7f4-mjnch -- cat /etc/nginx/nginx.conf```

Do ```minikube service list``` to get the address of the istio-ingressgateway url:port

you will see the following


|   NAMESPACE   |                NAME                |    TARGET PORT    |           URL           |
|---------------|------------------------------------|-------------------|-------------------------|
| default       | kubernetes                         | No node port      |
| default       | task-tracker-app-ui                | http/9080         | http://172.17.0.2:30929 |
| ingress-nginx | ingress-nginx-controller           | http/80           | http://172.17.0.2:30025 |
|               |                                    | https/443         | http://172.17.0.2:30281 |
| ingress-nginx | ingress-nginx-controller-admission | No node port      |
| istio-system  | istio-egressgateway                | No node port      |
| istio-system  | istio-ingressgateway               | status-port/15021 | http://172.17.0.2:32326 |
|               |                                    | http2/80          | http://172.17.0.2:31147 |

Now we can hit our virtualservice and ultimately the service through the istio-gateway
```curl -k http://172.17.0.2:31147/task-tracker-app-ui```

create a fake DNS name servicemesh.demo by adding an entry in our /etc/hosts file
Use the IP address of our ingress
```
172.17.0.2:31147       test.com
```

Now we can do ```curl -k http://test.com/task-tracker-app-ui```

# generate self-signed TLS certificates 
Generate self-signed certificates. We will use a key/pair to encrypt traffic from ALB to Istio Gateway.





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


kubectl -n istio-system port-forward svc/grafana 3000
```


# Mesh our services
```
kubectl label namespace/default istio-injection=enabled

# restart all pods to get sidecar injected
kubectl delete pods --all

kubectl -n ingress-nginx get deploy ingress-nginx-controller  -o yaml | istioctl kube-inject -f - | kubectl apply -f -


# delete cluster
```kind delete cluster --name istio```



Checkout the awesome Grafana and Kiali dashboards! Try running the [google microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo) and visualizing the graph in Kiali.






kubectl get secret argo-artifacts --namespace=default -o yaml | grep -v '^\s*namespace:\s' | kubectl apply --namespace=argo -f -



kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "NodePort"}}'


curl -v -H "host: task-tracker-app-ui.default.svc.cluster.local " 10.98.95.225/
