This is based on https://github.com/jupyterhub/zero-to-jupyterhub-k8s
Build Do:
    docker build -t jupyterlab-k8s-hub:v1.7.2 .
    docker tag jupyterlab-k8s-hub:v1.7.2 cjkeist/jupyterlab-k8s-hub:v1.7.2
Then login to docker hub:
    docker login
    docker push cjkeist/jupyterlab-k8s-hub:v1.7.2
