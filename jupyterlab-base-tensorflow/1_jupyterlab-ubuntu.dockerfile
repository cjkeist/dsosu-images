# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM jupyterlab-ubuntu-base-scipy-rjulia:v1.1.0-dev as jupyterlab-ubuntu-base-scipy-rjulia-tensorflow
############################################################################
#################### Dependency: jupyter/base-image ########################
############################################################################

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Tensorflow with pip
RUN pip install --no-cache-dir tensorflow && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"
