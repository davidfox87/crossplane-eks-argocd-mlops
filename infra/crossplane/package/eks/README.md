
docker login

Assuming you already installed crossplane in the crossplane-system namespace

Build the package
kubectl crossplane build configuration 

Push the package:
```
VERSION=v0.0.15
kubectl crossplane push configuration foxy7887/crossplane-aws-platform:${VERSION} 
```
Install the configuration
 
```
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