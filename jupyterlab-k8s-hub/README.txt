Build Do:
    DOCKER_BUILDKIT=1 docker build -t cjkeist/jupyterlab-k8s-hub:v1.7.0 .
Then login to docker hub:
    docker login
    docker push cjkeist/jupyterlab-k8s-hub:v1.7.0
