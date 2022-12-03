```
# Create a management Kubernetes cluster manually (e.g., minikube, Kind, EKS, etc.)

helm repo add crossplane-stable \
    https://charts.crossplane.io/stable

helm repo update

helm upgrade --install \
    crossplane crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace \
    --wait


./setup.sh --profile default


# install EKS package
echo "
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: crossplane-k8s
spec:
  package: foxy7887/crossplane-aws-platform:0.0.19

---

apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: crossplane-provider-aws
spec:
  package: crossplane/provider-aws:v0.24.1
" | kubectl apply --filename -

kubectl get pkgrev

# Wait until all the packages are healthy

echo "
apiVersion: aws.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-creds
      key: creds
" | kubectl apply --filename -

kubectl create namespace team-foxy

```


# Create a cluster
```
echo "
apiVersion: devopstoolkitseries.com/v1alpha1
kind: ClusterClaim
metadata:
  name: a-team-eks
spec:
  id: a-team-eks
  compositionSelector:
    matchLabels:
      provider: aws
      cluster: eks
  parameters:
    nodeSize: medium
    minNodeCount: 3
  writeConnectionSecretToRef:
    name: a-team-eks
" | kubectl --namespace a-team apply --filename -

kubectl get managed

kubectl --namespace a-team get clusterclaims

# Wait until the cluster is ready

```

# Use the cluster
```
kubectl --namespace a-team \
    get secret a-team-eks \
    --output jsonpath="{.data.kubeconfig}" \
    | base64 -d \
    | tee kubeconfig.yaml

# The credentials in `kubeconfig.yaml` are temporary for security reasons

kubectl --kubeconfig kubeconfig.yaml \
    get nodes
```

# Destroy the cluster

```
kubectl --namespace a-team \
    delete clusterclaim a-team-eks

kubectl get managed

# Wait until all managed AWS resources are removed
```


# To build the package
```
docker login

# Build the package

kubectl crossplane build configuration 


Push the package:

VERSION=v0.0.15
kubectl crossplane push configuration foxy7887/crossplane-aws-platform:${VERSION} 


#Install the configuration
 
kubectl crossplane install configuration foxy7887/crossplane-aws-platform:0.0.16  
```

This will automatically install the most up-to-date versions of the aws-, helm-, and kubernetes-provider and the CRDs so that users can go ahead and create claims.

To check the installation was successful:
```
kubectl get providers 


kubectl get crd | grep mlops 
ekscluster.eks.mlops-playground.com                             2022-11-25T18:21:32Z
xeksclusters.eks.mlops-playground.com                           2022-11-25T18:21:30Z

```
