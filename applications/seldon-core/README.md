s2i build . seldonio/seldon-core-s2i-python3:0.4 my-model-image
docker run --name "test_predictor" -p 5555:5000 my-model-image

curl  -d 'json={"data":{"ndarray":[[1.0,2.0]]}}' http://0.0.0.0:5000/predict