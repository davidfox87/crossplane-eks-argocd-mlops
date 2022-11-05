#!/bin/bash

kubectl create secret generic git-ssh -n workflows \
                --dry-run=client \
                --from-file=key=/home/david/.ssh/id_ed25519  -o yaml \
                | kubeseal  --controller-namespace kubeseal \
                            --controller-name sealed-secrets \
                            --format yaml > git-ssh-sealedsecret.yaml

kubectl create secret generic git-known-hosts -n workflows \
                --dry-run=client \
                --from-file=ssh_known_hosts=/home/david/.ssh/known_hosts -o yaml \
                | kubeseal  --controller-namespace kubeseal \
                            --controller-name sealed-secrets \
                            --format yaml > git-known-hosts-sealedsecret.yaml


kubectl create secret generic argo-artifacts -n workflows \
                --dry-run=client \
                --from-literal=accesskey=minio \
                --from-literal=secretkey=minio123 -o yaml \
                | kubeseal  --controller-namespace kubeseal \
                            --controller-name sealed-secrets \
                            --format yaml > argo-artifacts-sealedsecret.yaml


# write sealedsecret so that argo-cd can manage secrets from github
kubectl create secret generic github-access -n workflows \
                --dry-run=client \
                --from-file=token=.env -o yaml \
                | kubeseal  --controller-namespace kubeseal \
                            --controller-name sealed-secrets \
                            --format yaml > github-access-sealedsecret.yaml


kubectl create secret generic regcred -n workflows \
                --dry-run=client \
                --from-file=.dockerconfigjson=/home/david/.docker/config.json \
                --type=kubernetes.io/dockerconfigjson -o yaml \
                | kubeseal  --controller-namespace kubeseal \
                            --controller-name sealed-secrets \
                            --format yaml > dockerreg-sealedsecret.yaml


mv *sealedsecret.yaml secrets