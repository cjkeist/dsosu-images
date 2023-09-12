FROM jupyterlab-ubuntu-base-collab-scipy as jupyterlab-ubuntu-base-collab-scipy-rjulia
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
RUN /opt/setup-scripts/setup-julia-packages.bash

USER root

# R pre-requisites
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#USER ${NB_UID}
USER root

# R packages including IRKernel which gets installed globally.
# r-e1071: dependency of the caret R package
RUN mamba install --yes \
    'r-base' \
    'r-caret' \
    'r-crayon' \
    'r-devtools' \
    'r-e1071' \
    'r-forecast' \
    'r-hexbin' \
    'r-htmltools' \
    'r-htmlwidgets' \
    'r-irkernel' \
    'r-nycflights13' \
    'r-randomforest' \
    'r-rcurl' \
    'r-tidyverse' \
    'r-rmarkdown' \
    'r-rodbc' \
    'r-rsqlite' \
    'r-shiny' \
    'r-tidymodels' \
    'unixodbc' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Rstudio - based on https://github.com/jupyterhub/jupyter-server-proxy/blob/master/contrib/rstudio/Dockerfile
RUN apt-get update && \
        apt-get install -y --no-install-recommends \
                libapparmor1 \
                libclang-dev \
                libedit2 \
                lsb-release \
                psmisc \
# and texlive for Rstudio PDF explorts
                texlive-xetex \
                lmodern \
                libpq-dev \
                libxkbcommon-x11-0 \
                texlive-fonts-recommended \
                ;

# You can use rsession from rstudio's desktop package as well.
ENV RSTUDIO_PKG=rstudio-server-2023.06.2-561-amd64.deb
ENV RSTUDIO_URL=https://download2.rstudio.org/server/jammy/amd64
RUN wget -q ${RSTUDIO_URL}/${RSTUDIO_PKG}
RUN dpkg -i ${RSTUDIO_PKG}
RUN rm ${RSTUDIO_PKG}

# Shiny
ENV SHINY_PKG=shiny-server-1.5.20.1002-amd64.deb
ENV SHINY_URL=https://download3.rstudio.org/ubuntu-18.04/x86_64
RUN wget -q ${SHINY_URL}/${SHINY_PKG}
RUN dpkg -i ${SHINY_PKG}
RUN rm ${SHINY_PKG}

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Jupyter proxy
# rather than RUN pip install git+https://github.com/jupyterhub/jupyter-rsession-proxy
# use the pypi version to avoid a recent bug RE https://github.com/jupyterhub/jupyter-rsession-proxy/issues/71#issuecomment-523630103
RUN pip install 'jupyter-rsession-proxy'

# fixup for shiny-server bookmarks (don't want to make adjustment in the jupyter-rsession-proxy where the shiny config is generated from)
RUN chmod o+w /var/lib/shiny-server

# Items from R jupyter docker-stack image
RUN apt-get update && \
     apt-get install -y --no-install-recommends \
     fonts-dejavu \
     unixodbc \
     unixodbc-dev \
     r-cran-rodbc \
     gfortran \
     gcc && \
     rm -rf /var/lib/apt/lists/*

# Fix for devtools https://github.com/conda-forge/r-devtools-feedstock/issues/4
RUN ln -s /bin/tar /bin/gtar

#IMAGE oneilsh/jupyterlab-ubuntu-scipy-rjulia
#TAG v1.1.3
# changelog:
# 1.1.3: more libs; libbz2-dev, liblzma, libcurl4, libssl
# 1.1.2: added zlib1g-dev and ncurses dev libraries
# 1.1.1: upgrade sudo to address root exploit https://ubuntu.com/security/notices/USN-4705-1

