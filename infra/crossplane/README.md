curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh

if not installing the package foxy7887/crossplane-aws-platform, then install aws provider:
```
kubectl crossplane install provider crossplane/provider-aws
```

Alternatively, do 
```
./setup.sh --profile default
```


kubectl crossplane build configuration 
kubectl crossplane push configuration foxy7887/crossplane-aws-platform:0.0.12
kubectl crossplane install configuration foxy7887/crossplane-aws-platform:0.0.12

kubectl apply -f provider-config.yaml 


Validate the install by inspecting the provider and configuration packages:
```
kubectl get providers,providerrevision
kubectl get configurations,configurationrevisions
```


When you install this package, Crossplane will automatically resolve any package dependencies. For example,
```
kubectl get configurations,configurationrevisions


NAME                                                 INSTALLED   HEALTHY   PACKAGE                                        AGE
provider.pkg.crossplane.io/crossplane-provider-aws                         crossplane/provider-aws                        23h
provider.pkg.crossplane.io/upbound-provider-aws      True        True      xpkg.upbound.io/upbound/provider-aws:v0.19.0   158m
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

kubectl get secrets db-conn -o yaml
echo bXktZGItZzZnajctbHo5dmMuY294emhmemp4bjFlLnVzLXdlc3QtMS5yZHMuYW1hem9uYXdzLmNvbQ== | base64 --decode


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