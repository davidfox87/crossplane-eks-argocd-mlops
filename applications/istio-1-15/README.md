# End-to-end traffic encryption using a TLS certificate from ACM, ALB, and Istio in the Amazon EKS.
In the following steps, I implement end-to-end encryption using a TLS certificate in AWS Certificate Manager (ACM), Application Load Balancer (ALB), and Istio gateway and service mesh in an AWS EKS environment. Istio generates detailed telemetry for all service communications within a service mesh. This telemetry provides full observability of traffic in and out of the mesh and between services inside the mesh. Istio integrates extremely well with Prometheus and Grafana, which we will also install using ArgoCD.
![tls](SecureEndtoEndTrafficOnEKS2.jpg)


## Upgrade Istio Manifests using Istioctl
Istio ships with an installer called istioctl, which is a deployment / debugging / configuration management tool for Istio all in one package. In this section, we explain how to upgrade our istio kustomize packages by leveraging istioctl. For more info see the ![istio docs](https://istio.io/latest/docs/setup/additional-setup/customize-installation/)

1. Download istioctl for version X.Y.Z:
```
$ ISTIO_VERSION="X.Y.Z"
$ wget "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux.tar.gz"
$ tar xvfz istio-${ISTIO_VERSION}-linux.tar.gz
$ sudo mv istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/istioctl
```

2. Use istioctl to generate an IstioOperator resource, the CustomResource used to describe the Istio Control Plane:
```
$ cd istio-$ISTIO_VERSION
$ istioctl profile dump demo > profile.yaml
```
3. Generate manifests and add them to their respective packages. We will generate manifests using istioctl, the profile.yaml file from upstream and the profile-overlay.yaml file that contains our desired changes:
```
$ cd istio-$ISTIO_VERSION
$ istioctl manifest generate -f profile.yaml -f profile-overlay.yaml > dump.yaml
$ split-istio-packages -f dump.yaml
$ mv crd.yaml istio-crds/base
$ mv install.yaml istio-install/base
$ mv cluster-local-gateway.yaml cluster-local-gateway/base
```

4. Note that we use kustomize patches to modify the standard ingressgateway service but we could just generate those manifests using the istioctl and applying a profile overlay to customize the demo profile:
```
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    tcpKeepalive:
      time: 10s
      interval: 5s
      probes: 3
  components:
    ingressGateways:
      # Cluster-local gateway for KFServing
      - enabled: true
        name: cluster-local-gateway

```
Note that we can specify the annotations and the service type, as well as add the nodeport to the status-port so that AWS ALB health checks will pass. For now, we stick with Kustomize, but we will revisit using istioctl to generate the overlay on top of the demo profile. It seems simple enough.

Another gateway could be added for kubeflow model serving in the future.


## configure healthcheck path for alb
We installed istio using Kustomize, which allowed us to define overlays and apply patches to the existing istio install. Specifically, we added annotations for the aws alb ingress controller health check, hardcoded the nodeport value for the 'status-port' and changed the service to NodePort

```
- op: replace
  path: "/metadata/annotations"
  value: 
    alb.ingress.kubernetes.io/healthcheck-port: '30621'
    alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
    
- op: add
  path: "/spec/ports/0/nodePort"
  value: 30621

- op: add
  path: "/spec/type"
  value: NodePort

```


## adding self-signed tls certificates to secure traffic inside the mesh
Note the tls-secret needs to go in the istio-system namespace because the istio-ingressgateway needs to access it (didn't see that from the docs).
I put the gateway and tls-secret in the istio-system namespace and the istio virtual services go in their own namespaces. The virtual services will reference the gateway using svc.namespace.svc.cluster.local naming convention to reference services in other namespaces. This is done in the following way:

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: task-tracker-app-ui # name of the k8s service
spec:
  hosts:
  - staging.mlops-playground.com
  - task-tracker-app-ui
  gateways:
  - public-gateway.istio-system.svc.cluster.local
```


### Generate the tls-secret and then use sealed-secrets to encode it. 
If we use sealed secrets, we can then store everything in github (without getting fired) and then argocd can manage the deployment using manifests stored in github (which is our source of truth)
```
kubectl create secret generic tls-secret -n staging \
--from-file=key=certs/key.pem \
--from-file=cert=certs/cert.pem

kubectl get secret tls-secret -n staging -o yaml | kubeseal --controller-namespace kube-system \
                                                 --controller-name sealed-secrets \
                                                 --format yaml tls-secret.yaml > base/tls-secret.yaml
kubectl delete secret tls-secret -n staging


kubectl create secret generic tls-secret -n istio-system \
--from-file=key=certs/key.pem \
--from-file=cert=certs/cert.pem
```






# explanation of Routing TLS traffic locally using minikube and nginx ingress.
## Configure an ingress gateway
Define a Gateway with a server section for port 443. Note the SIMPLE TLS mode which instructs the gateway to terminate TLS traffic before routing it to the service.

## Generate client and server certificates and keys
For this task you can use your favorite tool to generate certificates and keys. The commands below use openssl
1. Create a root certificate and private key to sign the certificates for your services
```
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=mlops-playground.com' -keyout mlops-playground.com.key -out mlops-playground.com.crt
```
2. Create a certificate and a private key for staging.mlops-playground.com
```
openssl req -out staging.mlops-playground.com.csr -newkey rsa:2048 -nodes -keyout staging.mlops-playground.com.key -subj "/CN=staging.mlops-playground.com/O=my organization"


openssl x509 -req -sha256 -days 365 -CA mlops-playground.com.crt -CAkey mlops-playground.com.key -set_serial 0 -in staging.mlops-playground.com.csr -out staging.mlops-playground.com.crt
```

3. inspect with:
```
openssl x509 -in certs/tls.crt -noout -text
```
## configure a TLS ingress gateway for a single host
1. Make sure the task-tracker-app service has been deployed
2. Create a secret for the ingress gateway:
```
kubectl create -n istio-system secret tls tlscert --key=staging.mlops-playground.com.key --cert=staging.mlops-playground.com.crt
```
3. Define a gateway with a servers: section for port 443, and specify values for credentialName to be tls-cert. The values are the same as the secret’s name. The TLS mode should have the value of SIMPLE.

4. Configure the gateway’s ingress traffic routes. Define the corresponding virtual service and reference the gateway within the virtual service.


In local minikube env:
```
minikube addons enable ingress
minikube tunnel
```

add an entry to ```/etc/hosts```
```
172.17.0.2  staging.mlops-playground.com
```

Send an HTTPS request to access the task-tracker-app service through HTTPS:
```
curl -k "https://staging.mlops-playground.com"

```
