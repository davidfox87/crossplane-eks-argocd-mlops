#!/bin/bash

while true; 
    do curl -s -o /dev/null -X POST    \
            -H 'Content-Type: application/json'  \
            -d '{"data": { "ndarray": [[1,2,3,4,5]]}}'   \
            "http://localhost:8080/seldon/workflows/seldon-deployment-deploy-wine-clf-j6wp2/api/v1.0/predictions";
done