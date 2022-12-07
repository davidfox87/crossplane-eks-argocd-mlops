Install crossplane plugin for kubernetes
```
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
```

If not installing the package foxy7887/crossplane-aws-platform, then install aws provider:
```
kubectl crossplane install provider crossplane/provider-aws
```

Save your AWS credentials in a Kubernetes secrets called aws_creds
```
./setup.sh --profile default
```

If you want to extend the existing package in infra/crossplane/package, then you will need to build and push the image to the docker repo:
```
kubectl crossplane build configuration 
kubectl crossplane push configuration foxy7887/crossplane-aws-platform:0.0.14
```

Install our package
```
kubectl crossplane install configuration foxy7887/crossplane-aws-platform:0.0.14
```

The aws-provider will automatically be installed because our package specifies crossplane/provider-aws as a dependency.

Apply the provider config to associate the credentials secret with the provider:
```
kubectl apply -f provider-config.yaml 
```


Validate the install by inspecting the provider and configuration packages:
```
kubectl get providers,providerrevision
```


When you install this package, Crossplane will automatically resolve any package dependencies. For example,
```
kubectl get configurations,configurationrevisions
```



Application developers can now use the platform to request resources which then will provisioned in AWS. This would usually done by bundling a claim as part of the application code. In our example here we simply create the claims directly:
Create a custom defined database:
```
cd example
kubectl apply -f example/dbclaim-aws-example.yaml
```


After creating the PostgreSQLInstance Crossplane will begin provisioning a database instance on your provider of choice. Once provisioning is complete, you should see READY: True in the output when you run:

```
kubectl get postgresqlinstance my-db
```

The following commands will allow you to view groups of Crossplane resources:
```
    kubectl get claim: get all resources of all claim kinds, like PostgreSQLInstance.
    kubectl get composite: get all resources that are of composite kind, like XPostgreSQLInstance.
    kubectl get managed: get all resources that represent a unit of external infrastructure.
    kubectl get <name-of-provider>: get all resources related to <provider>.
    kubectl get crossplane: get all resources related to Crossplane.
```


You can verify status by inspecting the claims, composites and managed resources:
```
kubectl get claim,composite,managed
kubectl get managed

kubectl get postgresqlinstance my-db

kubectl describe secrets db-conn
```

To get the DB connection parameters, use the following:
```
kubectl get secrets db-conn -o yaml
echo bXktZGItdDd2aGwtNW5tczguY294emhmemp4bjFlLnVzLXdlc3QtMS5yZHMuYW1hem9uYXdzLmNvbQ== | base64 --decode
```

for more info on aws crds:
https://doc.crds.dev/github.com/crossplane/provider-aws


To delete the provisioned resources you would simply delete the claims again:
```
kubectl delete pod see-db
kubectl delete -f dbclaim-aws-example.yaml
```

Reference for deleting claims, resources and packages
https://crossplane.io/docs/v1.9/reference/uninstall.html


https://doc.crds.dev/github.com/crossplane/provider-aws/database.aws.crossplane.io/RDSInstance/v1beta1@v0.33.0



# deploying EKS cluster
Put cluster-claim-aws.yaml in the team-foxy folder

commit and push to github. ArgoCD will be deploy the manifest to the management cluster and then Crossplane will detect the claim on the EKSCluster resource. Crossplane will then deploy the VPC network, EKS Cluster and Nodegroup.

Once everything is up we can retrieve the kubconfig from the secret
```
kubectl -n crossplane-system get secret 2b06f037-1204-453e-9862-52f456d3426c-ekscluster --output jsonpath="{.data.kubeconfig}" | base64 -d > kubeconfig.yaml
```

Then we can interact with our EKS cluster
```
kubectl --kubeconfig kubeconfig.yaml  get namespaces
```





# Steps for combining crossplane with argocd for deploying EKS cluster

1. Spawn management Kind cluster
```
kind create cluster --name kind-cluster --config kind.yaml --wait 5m
```

2. Install argo-cd
Go to ```/Users/david.fox/Documents/crossplane-eks-argocd-mlops/applications/argo-cd/overlays/staging``` and run:
```
kustomize build | kubectl apply -f -
```

3. Log into Argocd UI
```
kubectl port-forward svc/argocd-server -n argocd 9444:443
```

The API server can then be accessed using https://localhost:9444

Get the initial admin password and login
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

4. Use argocd to deploy applications to our Kubernetes cluster 
In a different project folder, clone the repo which has our ArgoCD project and application manifests 
```
git clone git@github.com:davidfox87/argocd-production.git
```
Install projects and apps
```
kubectl apply -f projects.yaml
kubectl apply -f apps.yaml
```
5. generate the sealed-secrets manifest for the aws-creds and push to github. Navigate to ```/Users/david.fox/Documents/crossplane-eks-argocd-mlops/infra/crossplane/crossplane-config``` and run 
``` 
./deploy-secret.sh 
git commit -am 'deploy aws-creds sealed-secret'
git push
```

refresh argocd apps to pull and deploy the latest manifests

6. Push EKS claims to team-foxy-infra
