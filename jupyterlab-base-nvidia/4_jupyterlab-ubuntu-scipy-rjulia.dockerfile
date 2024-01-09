FROM jupyterlab-ubuntu-base-nvidia-scipy-rjulia as jupyterlab-ubuntu-base-nvidia-scipy-rjulia-gpu
############################################################################
########################## Dependency: gpulibs #############################
############################################################################

LABEL maintainer="Christoph Schranz <christoph.schranz@salzburgresearch.at>"

USER root

# Install Tensorflow, check compatibility here: https://www.tensorflow.org/install/gpu
RUN pip install --no-cache-dir tensorflow && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install PyTorch with pip
RUN pip3 install torch torchvision torchaudio
# USER $NB_USER

# let's check to make sure this works...
RUN python3 -c 'import tensorflow as tf'
