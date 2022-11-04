curl -X POST      -H 'Content-Type: application/json'  \
    -d '{"data": { "ndarray": [[1,2,3,4,5]]}}'   \
        http://localhost:8080/seldon/seldon/minio-mlflow/api/v1.0/predictions