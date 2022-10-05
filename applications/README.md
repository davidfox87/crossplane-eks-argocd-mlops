
# create a local K8s cluster
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

and this for minikube
https://istio.io/latest/docs/setup/platform-setup/minikube/
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

However, we need to customize our installation of the standard Istio demo install manifest files. 

## Patching the output manifests
The IstioOperator CR, input to istioctl, is used to generate the output manifest containing the Kubernetes resources to be applied to the cluster. The output manifest can be further customized to add, modify or delete resources through the IstioOperator overlays API, after it is generated but before it is applied to the cluster. This is similar to using Kustomize to apply patchest to existing manifest files.
 
In the ```applications/istio``` folder run:
```
 istioctl manifest generate -f patch.yaml > test-istio-ingressgateway-patch.yaml
```

Here we change the istio-ingressgateway service to type NodePort and add some annotations to the service, in particular, we add the following:
```
    alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
    alb.ingress.kubernetes.io/healthcheck-port: "30218"
```

Now, the alb ingress object will get a readinessProbe from the deployment, whcih creates pods with the istio-ingress-gateway. When the Ingress is created, our ALB ingress controller will find the service specified in the backend.serviceName of the Ingress manifest, will read its annotations, and will apply the to a TargetGroup attached to the ALB.


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
```
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout certs/key.pem -out certs/cert.pem -subj "/CN=test.com" \
  -addext "subjectAltName=DNS:test.com"


kubectl create secret generic tls-secret -n staging \
--from-file=key=certs/key.pem \
--from-file=cert=certs/cert.pem

kubectl get secret tls-secret -n staging -o yaml | kubeseal --controller-namespace kube-system \
                                                 --controller-name sealed-secrets \
                                                 --format yaml tls-secret.yaml

```
Add to the ingresss the following:
```
  tls:
    - hosts:
      - test.com
      secretName: tls-secret
```

follow this resource:
https://aws.amazon.com/blogs/containers/secure-end-to-end-traffic-on-amazon-eks-using-tls-certificate-in-acm-alb-and-istio/


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
```

# delete cluster
```kind delete cluster --name istio```



Checkout the awesome Grafana and Kiali dashboards! Try running the [google microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo) and visualizing the graph in Kiali.

# Create a DNS record in Amazon Route 53

Create a record in Route53 to bind your domain with ALB. Make sure you are creating a DNS record in the corresponding hosting zone, matching the domain name. I have compiled a list of useful resources to learn more about DNS records and hosting zones in AWS.

- [Registering domain names using Amazon Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar.html)
- [Working with public hosted zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html)
- [Working with records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/rrsets-working-with.html)
- [Routing traffic to an ELB load balancer](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html)

domain name is www.mlops-playground.com (bought from domains.google.com)

# for info on AWS load balancer controller
Insanely useful
https://blog.sivamuthukumar.com/aws-load-balancer-controller-on-eks-cluster





# Testing

 - Installing AWS Ingress controller
 - Setting Domain and TLS certificate
 - Configuring the external DNS
 - Testing DNS creation on Route53
 - Debugging External DNS and Route53
 - Testing Ingress resource and External DNS
 - propagating self-signed tls to istio service mesh services



