#!/bin/bash -e

docker login --username=foxy7887 -p MGSGiw550!

image_name=foxy7887/xgb_train
image_tag=v17
full_image_name=${image_name}:${image_tag}

cd "$(dirname "$0")" 
docker build -t "${full_image_name}" .
docker push "$full_image_name"

# Output the strict image name, which contains the sha256 image digest
docker inspect --format="{{index .RepoDigests 0}}" "${full_image_name}"

docker image rm "${full_image_name}"