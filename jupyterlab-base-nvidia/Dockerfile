# TARGET jupyterlab-ubuntu-base-nvidia v1.1.8
# TARGET jupyterlab-ubuntu-base-nvidia-scipy v1.1.8
# TARGET jupyterlab-ubuntu-base-nvidia-scipy-rjulia v1.1.8
# TARGET jupyterlab-ubuntu-base-nvidia-scipy-rjulia-gpu v1.1.8

# 1.1.8: General update
# 1.1.7: Final NVIDIA Support General update
# 1.1.6: Final NVIDIA Support General update
# 1.1.5: Final NVIDIA Support added nglview
# 1.1.4: Final NVIDIA Support 
# 1.1.4-dev: Building NVIDIA Support 
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG ROOT_CONTAINER=nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04
FROM $ROOT_CONTAINER as jupyterlab-ubuntu-base-nvidia
############################################################################
#################### Dependency: jupyter/base-image ########################
############################################################################

# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Ubuntu 22.04 (Jammy Jellyfish)
# https://hub.docker.com/_/ubuntu/?tab=tags&name=focal

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
ARG NB_USER="jovyan"
ARG NB_UID="1001"
ARG NB_GID="100"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for Server that starts
# but lacks all features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    build-essential \
    bzip2 \
    git \
    curl \
    nano-tiny \
    unzip \
    vim \
    emacs \
    emacs-common \
    openssh-client \
    tree \
    cmake \
    htop \
    cpio \
    less \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    ca-certificates \
    locales \
    sudo \
    zlib1g-dev \
    default-jre \
    default-jdk \
    dnsutils \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libssl-dev \
    libbz2-dev \
    libvcflib-tools \
    libncurses5-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libtiff5-dev \
    libopenblas-dev \
    libgsl-dev \
    screen \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    wget \
    # Add packages needed for later stages to avoid reinstallation
    fonts-dejavu \
    fonts-liberation \
    pandoc \
    run-one \
    # NFS tools for shared storage
    nfs-common \
    nfs-kernel-server \
    # Install packages needed for R and RStudio later
    gfortran \
    gcc \
    unixodbc \
    unixodbc-dev \
    libgdal-dev \
    gdal-bin \
    libudunits2-dev \
    libproj-dev \
    software-properties-common \
    dirmngr \
    gnupg2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

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

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --no-user-group "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

USER ${NB_UID}

# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.12

# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work" && \
    mkdir -p "/home/jovyan/.mamba/pkgs" && \
    fix-permissions "/home/${NB_USER}"

# Download and install Micromamba, and initialize Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba and jupyter_core
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp
RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    wget --progress=dot:giga -O /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
        'jupyter_core' && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | sed 's/^ *//' | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start.sh"]

# Copy local files as late as possible to avoid cache busting
COPY run-hooks.sh start.sh /usr/local/bin/

USER root

# Create dirs for startup hooks
RUN mkdir /usr/local/bin/start-notebook.d && \
    mkdir /usr/local/bin/before-notebook.d

# Install Rust and Cargo in /usr/local, needed for jupyterlab-topbar
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal --no-modify-path
RUN chown -R root:root /usr/local/cargo
RUN chown -R root:root /usr/local/rustup
RUN chmod -R 777 /usr/local/cargo
ENV PATH="/usr/local/cargo/bin:${PATH}"
ENV PATH="/usr/local/rustup/bin:${PATH}"

#RUN rustup default stable

USER ${NB_UID}

# Install JupyterLab, Jupyter Notebook, JupyterHub and NBClassic
# Generate a Jupyter Server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
WORKDIR /tmp
RUN mamba install --yes \
    'jupyterlab' \
    'notebook' \
    'jupyterhub' \
    'jupyter-resource-usage' && \
    jupyter server --generate-config && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

#RUN pip install nbresuse
RUN pip install jupyterlab-topbar jupyterlab-system-monitor

# Configure container startup
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start-notebook.sh start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py docker_healthcheck.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root
RUN fix-permissions /etc/jupyter/

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1

# Switch back to jovyan to avoid accidental container runs as root
#USER ${NB_UID}
USER root

WORKDIR "${HOME}"
FROM jupyterlab-ubuntu-base-nvidia AS jupyterlab-ubuntu-base-nvidia-scipy

############################################################################
################# Dependency: jupyter/scipy-notebook #######################
############################################################################

# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# mamba downgrades these packages to previous major versions, which causes issues
#RUN echo 'jupyterlab >=4.0.4' >> "${CONDA_DIR}/conda-meta/pinned" && \
#    echo 'notebook >=7.0.2' >> "${CONDA_DIR}/conda-meta/pinned"

USER ${NB_UID}

# Install Python 3 packages
RUN mamba install --yes \
    'altair' \
    'beautifulsoup4' \
    'bokeh' \
    'bottleneck' \
    'cloudpickle' \
    'conda-forge::blas=*=openblas' \
    'cython' \
    'dask' \
    'dill' \
    'h5py' \
    'ipympl'\
    'ipywidgets' \
    'jupyterlab-git' \
    'matplotlib-base' \
    'numba' \
    'numexpr' \
    'openpyxl' \
    'pandas' \
    'patsy' \
    'plotly' \
    'protobuf' \
    'pytables' \
    'scikit-image' \
    'scikit-learn' \
    'scipy' \
    'seaborn' \
    'sqlalchemy' \
    'statsmodels' \
    'sympy' \
    'widgetsnbextension'\
    'nglview' \
    'xlrd' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install facets which does not have a pip or conda package at the moment
WORKDIR /tmp
RUN git clone https://github.com/PAIR-code/facets && \
    jupyter nbclassic-extension install facets/facets-dist/ --sys-prefix && \
    rm -rf /tmp/facets && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"

RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${NB_USER}"

USER root

WORKDIR "${HOME}"

# Add R mimetype option to specify how the plot returns from R to the browser
COPY --chown=${NB_UID}:${NB_GID} Rprofile.site /opt/conda/lib/R/etc/

# Add setup scripts that may be used by downstream images or inherited images
COPY setup-scripts/ /opt/setup-scripts/

#IMAGE oneilsh/jupyterlab-ubuntu-scipy
#TAG v1.1.1
# changelog:
# 1.1.1: upgrade sudo to address root exploit https://ubuntu.com/security/notices/USN-4705-1

FROM jupyterlab-ubuntu-base-nvidia-scipy AS jupyterlab-ubuntu-base-nvidia-scipy-rjulia

############################################################################
################ Dependency: jupyter/datascience-notebook ##################
############################################################################

# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Julia dependencies
# install Julia packages in /opt/julia instead of ${HOME}
ENV JULIA_DEPOT_PATH=/opt/julia \
    JULIA_PKGDIR=/opt/julia

# Setup Julia
RUN /opt/setup-scripts/setup-julia.bash

USER ${NB_UID}

# Setup IJulia kernel & other packages
#RUN /opt/setup-scripts/setup-julia-packages.bash

USER root

# Add the CRAN repository to the sources list
RUN curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" | tee /etc/apt/sources.list.d/cran.list

# Install R base code
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    r-base \
    r-base-dev \
    libapparmor1 \
    libclang-dev \
    libedit2 \
    libuv1-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    unixodbc-dev \
    lsb-release \
    psmisc \
    libpq-dev \
    libxkbcommon-x11-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install IRkernel in R
RUN R -e "install.packages('IRkernel', repos='https://cloud.r-project.org/')" \
  && R -e "IRkernel::installspec(user = FALSE)" \
  && python3 -c "import json; p='/usr/local/share/jupyter/kernels/ir/kernel.json'; \
  k=json.load(open(p)); \
  k.setdefault('env', {})['R_LIBS_SITE'] = '/usr/local/lib/R/site-library:/usr/lib/R/site-library'; \
  json.dump(k, open(p, 'w'), indent=2)"

# Install R packages
RUN R -e "\
  options(warn=1); \
  pkgs <- c('digest','RODBC','caret','crayon','devtools','e1071','forecast','hexbin','htmltools','htmlwidgets','randomForest','tidyverse','rmarkdown','RSQLite','shiny','viridis','terra','sf'); \
  install.packages(pkgs, repos='http://cran.rstudio.com/'); \
  missing <- pkgs[!(pkgs %in% installed.packages()[,'Package'])]; \
  if (length(missing) > 0) stop(paste('R packages failed to install:', paste(missing, collapse=', ')))"

# You can use rsession from rstudio's desktop package as well.
# https://posit.co/downloads
ENV RSTUDIO_PKG=rstudio-server-2026.04.0-526-amd64.deb
ENV RSTUDIO_URL=https://download2.rstudio.org/server/jammy/amd64
RUN wget -q ${RSTUDIO_URL}/${RSTUDIO_PKG} && \
    dpkg -i ${RSTUDIO_PKG} && \
    rm ${RSTUDIO_PKG}

# Shiny
ENV SHINY_PKG=shiny-server-1.5.24.1035-amd64.deb
ENV SHINY_URL=https://download3.rstudio.org/ubuntu-20.04/x86_64
RUN wget -q ${SHINY_URL}/${SHINY_PKG} && \
    dpkg -i ${SHINY_PKG} && \
    rm ${SHINY_PKG}

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Jupyter proxy
# rather than RUN pip install git+https://github.com/jupyterhub/jupyter-rsession-proxy
# use the pypi version to avoid a recent bug RE https://github.com/jupyterhub/jupyter-rsession-proxy/issues/71#issuecomment-523630103
RUN pip install 'jupyter-rsession-proxy'

# fixup for shiny-server bookmarks (don't want to make adjustment in the jupyter-rsession-proxy where the shiny config is generated from)
RUN chmod o+w /var/lib/shiny-server

# Fix for devtools https://github.com/conda-forge/r-devtools-feedstock/issues/4
RUN ln -s /bin/tar /bin/gtar
# Below lines are a brute force hack to fix RStuido
#RUN echo 'options(download.file.method = "wget")' | tee -a /etc/R/Rprofile.site
#RUN echo 'options(download.file.method = "wget")' | tee -a /opt/conda/lib/R/etc/Rprofile.site

#IMAGE oneilsh/jupyterlab-ubuntu-scipy-rjulia
#TAG v1.1.3
# changelog:
# 1.1.3: more libs; libbz2-dev, liblzma, libssl
# 1.1.2: added zlib1g-dev and ncurses dev libraries
# 1.1.1: upgrade sudo to address root exploit https://ubuntu.com/security/notices/USN-4705-1

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
