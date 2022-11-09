AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > creds.conf

kubectl create secret generic aws-creds -n crossplane-system \
                --dry-run=client \
                --from-file=creds=./creds.conf \
            | kubeseal  --controller-namespace kubeseal \
                            --controller-name sealed-secrets \
                            --format yaml > aws-creds-sealedsecret.yaml