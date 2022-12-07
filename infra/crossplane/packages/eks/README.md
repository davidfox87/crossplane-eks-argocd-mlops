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


# install EKS package (crossplane will install package dependencies)
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: crossplane-k8s
spec:
  package: foxy7887/crossplane-aws-platform:v0.0.36
EOF

cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: crossplane/provider-aws:v0.32.0
EOF


kubectl get pkgrev

# Wait until all the packages are healthy
cat <<EOF | kubectl apply -f -
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
EOF

kubectl create namespace team-foxy

```


# Create a cluster
```
cat <<EOF | kubectl apply  -n team-foxy -f -
apiVersion: eks.mlops-playground.com/v1alpha1
kind: ClusterClaim
metadata:
  name: team-foxy-eks
spec:
  id: team-foxy-eks
  compositionSelector:
    matchLabels:
      provider: default
      service: eks
  parameters:
    nodeSize: small
  writeConnectionSecretToRef:
    name: team-foxy-eks
EOF

kubectl get managed

kubectl --namespace team-foxy get clusterclaims


# Wait until the cluster is ready

```


# For an in-cluster install in AWS
```
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1alpha1
kind: ControllerConfig
metadata:
  name: aws-config
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::880572800141:user/foxy1987
spec:
  podSecurityContext:
    fsGroup: 2000
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: crossplane/provider-aws:v0.29.0
  controllerConfigRef:
    name: aws-config

---
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: crossplane-k8s
spec:
  package: foxy7887/crossplane-aws-platform:0.0.20

EOF
```

# Use the cluster
```
kubectl --namespace team-foxy \
    get secret aws-kubeconfig \
    --output jsonpath="{.data.kubeconfig}" \
    | base64 -d \
    | tee kubeconfig.yaml

# The credentials in `kubeconfig.yaml` are temporary for security reasons

kubectl --kubeconfig kubeconfig.yaml \
    get nodes
```

# Destroy the cluster

```
kubectl delete clusterclaims team-foxy-eks -n team-foxy

kubectl get managed

# Wait until all managed AWS resources are removed
```


# To build the package
```
docker login

# Build the package

kubectl crossplane build configuration 


Push the package:

VERSION=v0.0.3
kubectl crossplane push configuration foxy7887/crossplane-aws-platform:${VERSION} 


#Install the configuration
 
kubectl crossplane install configuration foxy7887/crossplane-aws-platform:${VERSION} 
```

This will automatically install the most up-to-date versions of the aws-, helm-, and kubernetes-provider and the CRDs so that users can go ahead and create claims.

To check the installation was successful:
```
kubectl get providers 


kubectl get crd | grep mlops 
ekscluster.eks.mlops-playground.com                             2022-11-25T18:21:32Z
xeksclusters.eks.mlops-playground.com                           2022-11-25T18:21:30Z

```
