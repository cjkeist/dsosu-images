FROM jupyterlab-ubuntu-base-scipy-rjulia:v1.1.4 as jupyterlab-ubuntu-base-scipy-rjulia-gpu

# 1.1.1: upgrade sudo to address root exploit https://ubuntu.com/security/notices/USN-4705-1

############################################################################
########################## Dependency: gpulibs #############################
############################################################################

LABEL maintainer="Christoph Schranz <christoph.schranz@salzburgresearch.at>"

USER root

#COPY cuda-keyring_1.1-1_all.deb /tmp/cuda-keyring_1.1-1_all.deb
#COPY  cuda-ubuntu2204.pin /tmp/cuda-ubuntu2204.pin
#RUN dpkg -i /tmp/cuda-keyring_1.1-1_all.deb
#RUN echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" | tee /etc/apt/sources.list.d/cuda-ubuntu2204-x86_64.list
#RUN mv /tmp/cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
#RUN apt-get update --yes && \
#    apt-get install --yes cuda-toolkit && \
#    apt-get install --yes nvidia-gds
#RUN rm -f /tmp/cuda-keyring_1.1-1_all.deb
# Install Tensorflow, check compatibility here: https://www.tensorflow.org/install/gpu 
RUN pip install --no-cache-dir tensorflow && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install PyTorch with pip
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
# USER $NB_USER

# let's check to make sure this works...
RUN python3 -c 'import tensorflow as tf'


