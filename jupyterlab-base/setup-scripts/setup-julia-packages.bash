#!/bin/bash
set -exuo pipefail

# Requirements:
# - Run as non-root user
# - The JULIA_PKGDIR environment variable is set
# - Julia is already set up

# Use a writable depot path layered over the read-only system depot

# Install base Julia packages
julia -e '
import Pkg;
Pkg.update();
Pkg.add([
    "HDF5",
    "IJulia"
]);
Pkg.precompile();
'

# Move the kernelspec to a shared location
if compgen -G "${HOME}/.local/share/jupyter/kernels/julia*" > /dev/null; then
    mv "${HOME}/.local/share/jupyter/kernels/julia"* "${CONDA_DIR}/share/jupyter/kernels/"
fi
chmod -R go+rx "${CONDA_DIR}/share/jupyter"
rm -rf "${HOME}/.local"

# Fix permissions
fix-permissions "${JULIA_PKGDIR}" "${CONDA_DIR}/share/jupyter"

# Install jupyter-pluto-proxy for JupyterHub integration
#mamba install --yes \
    #'jupyter-pluto-proxy' && \
    #mamba clean --all -f -y && \
    #fix-permissions "${CONDA_DIR}" && \
    #fix-permissions "/home/${NB_USER}"
