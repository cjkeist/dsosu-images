# syntax = docker/dockerfile:1.3

# The build stage
# ---------------
FROM python:3.9.22-slim-bullseye as stage

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG HOME=/home/jovyan
ENV DEBIAN_FRONTEND=noninteractive

# Add a user
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    --home ${HOME} \
    --force-badname \
    ${NB_USER}

# Install necessary packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    dnsutils \
    git \
    less \
    vim \
    sudo \
    libcurl4 \
    sqlite3 \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Set pip's cache directory using ARG
ARG PIP_CACHE_DIR=/tmp/pip-cache

# Install Python packages
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    pip install \
    py-spy \
    pycurl \
    jupyterhub==4.1.6 \
    jupyterhub-kubespawner

WORKDIR /srv/jupyterhub
RUN chown ${NB_USER}:${NB_USER} /srv/jupyterhub
USER ${NB_USER}
EXPOSE 8081
ENTRYPOINT ["tini", "--"]
CMD ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]

# Final stage
FROM stage as final-stage
USER root

# Install Kubernetes Python client
RUN pip install kubernetes

# Clone and install NativeAuthenticator
WORKDIR /usr/local/bin
RUN git clone https://github.com/jupyterhub/nativeauthenticator.git
WORKDIR /usr/local/bin/nativeauthenticator
RUN pip3 install .

# Install LTIAuthenticator
WORKDIR /root
RUN pip3 install jupyterhub-ltiauthenticator
RUN pip3 install git+https://github.com/oneilsh/ltiauthenticator.git@multi-key

WORKDIR /srv/jupyterhub

