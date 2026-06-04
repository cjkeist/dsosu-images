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

# Ensure /usr/local/lib/R/site-library is in .libPaths() even when the hub
# injects R_LIBS_SITE=/home/.hub_local/R_libs (which otherwise replaces, not
# extends, the default). Prepends the system site-lib while preserving the
# hub's NFS user-lib path.
RUN echo 'R_LIBS_SITE=/usr/local/lib/R/site-library:${R_LIBS_SITE}:/usr/lib/R/site-library' >> /etc/R/Renviron.site

# Install IRkernel in R
RUN R -e "install.packages('IRkernel', repos='https://cloud.r-project.org/')" \
  && R -e "IRkernel::installspec(user = FALSE)" \
  && python3 -c "import json; p='/usr/local/share/jupyter/kernels/ir/kernel.json'; \
  k=json.load(open(p)); \
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

