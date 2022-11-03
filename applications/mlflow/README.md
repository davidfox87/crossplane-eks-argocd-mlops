# Installing MLflow
[MLflow](https://mlflow.org/) is an open source platform to manage the ML lifecycle, including experimentation, reproducibility, deployment, and a central model registry. It offers the following features:
- it allows you to store models artifacts in a central repository
- record and query the results of machine learning modeling experiments: code, data, config, results
- package DS code to reproduce any run on any platform

In ```applications/mlflow```, we run the MLflow tracking server from a containerized service and deploy through a kubernetes deployment manifest. The DB metadata connection parameters and artifact store are mounted to the container as environment variables through secrets and configmaps.


Port forward to mlflow tracking server
```
kubectl port-forward service/mlflow-tracking-server 5555:5000 -n mlflow
```


