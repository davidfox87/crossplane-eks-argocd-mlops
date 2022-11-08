curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh


kubectl crossplane install provider crossplane/provider-aws

AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > aws_creds.conf

kubectl create secret generic aws-creds -n crossplane-system --from-file=creds=./aws_creds.conf

Alternatively, do 
```
./setup.sh --profile default
```

kubectl crossplane install configuration registry.upbound.io/xp/getting-started-with-aws:v1.10.1
kubectl apply -f provider-config.yaml 

Reference for deleting claims, resources and packages
https://crossplane.io/docs/v1.9/reference/uninstall.html