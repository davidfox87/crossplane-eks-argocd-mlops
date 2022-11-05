curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh


kubectl crossplane install provider crossplane/provider-aws

AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > aws_creds.conf

kubectl create secret generic aws-creds -n crossplane-system --from-file=creds=./creds.conf

kubectl apply -f https://raw.githubusercontent.com/crossplane/crossplane/release-1.9/docs/snippets/configure/aws/providerconfig.yaml