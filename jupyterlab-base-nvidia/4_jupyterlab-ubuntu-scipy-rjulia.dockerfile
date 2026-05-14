FROM jupyterlab-ubuntu-base-nvidia-scipy-rjulia AS jupyterlab-ubuntu-base-nvidia-scipy-rjulia-gpu
############################################################################
########################## Dependency: gpulibs #############################
############################################################################

LABEL maintainer="Christoph Schranz <christoph.schranz@salzburgresearch.at>"

USER root

# Install Tensorflow, check compatibility here: https://www.tensorflow.org/install/gpu
RUN pip3 install --no-cache-dir tensorflow[and-cuda] && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install PyTorch with pip
RUN pip3 install torch torchvision torchaudio
# USER $NB_USER

# Install cudf
RUN pip install \
    --extra-index-url=https://pypi.nvidia.com \
    "cudf-cu12==25.4.*" "dask-cudf-cu12==25.4.*" "cuml-cu12==25.4.*" \
    "cugraph-cu12==25.4.*" "nx-cugraph-cu12==25.4.*" "cuspatial-cu12==25.4.*" \
    "cuproj-cu12==25.4.*" "cuxfilter-cu12==25.4.*" "cucim-cu12==25.4.*" \
    "pylibraft-cu12==25.4.*" "raft-dask-cu12==25.4.*" "cuvs-cu12==25.4.*" \
    "nx-cugraph-cu12==25.4.*"

# Set environment variables for Numba
ENV NUMBAPRO_NVVM=/usr/local/cuda/nvvm/lib64/libnvvm.so
ENV NUMBAPRO_LIBDEVICE=/usr/local/cuda/nvvm/libdevice
ENV LD_LIBRARY_PATH=/usr/local/cuda/nvvm/lib64:$LD_LIBRARY_PATH

# let's check to make sure this works...
RUN python3 -c 'import tensorflow as tf'
