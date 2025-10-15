#!/bin/bash
set -exuo pipefail

# Requirements:
# - Run as non-root user
# - The JULIA_PKGDIR environment variable is set
# - Julia is already set up

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

# ADDED: Make sure the Julia kernel is properly installed
julia -e 'using IJulia; IJulia.installkernel("Julia")'

# ADDED: Find the kernel spec directory  
JULIA_KERNELSPEC=$(find ${HOME}/.local/share/jupyter/kernels -name "julia*" -type d || echo "")

# ADDED: Create wrapper script with environment variable
if [ -n "$JULIA_KERNELSPEC" ]; then
  echo "Creating Julia kernel wrapper at $JULIA_KERNELSPEC"
  cat > $JULIA_KERNELSPEC/julia_wrapper.sh << 'EOF'
#!/bin/bash
export JULIA_DEPOT_PATH=$HOME/.julia:/opt/julia
exec julia "$@"
EOF
  chmod +x $JULIA_KERNELSPEC/julia_wrapper.sh
  
  # Update kernel.json to use the wrapper
  sed -i 's|"julia"|"'$JULIA_KERNELSPEC'/julia_wrapper.sh"|g' $JULIA_KERNELSPEC/kernel.json
fi

# Move the kernelspec to a shared location (keep this part of your original script)
if compgen -G "${HOME}/.local/share/jupyter/kernels/julia*" > /dev/null; then
    mv "${HOME}/.local/share/jupyter/kernels/julia"* "${CONDA_DIR}/share/jupyter/kernels/"
fi

# ADDED: Also update the wrapper path in the moved kernel spec
MOVED_KERNELSPEC=$(find ${CONDA_DIR}/share/jupyter/kernels -name "julia*" -type d || echo "")
if [ -n "$MOVED_KERNELSPEC" ]; then
  sed -i 's|"'$JULIA_KERNELSPEC'/julia_wrapper.sh"|"'$MOVED_KERNELSPEC'/julia_wrapper.sh"|g' $MOVED_KERNELSPEC/kernel.json
fi

chmod -R go+rx "${CONDA_DIR}/share/jupyter"
rm -rf "${HOME}/.local"

# Fix permissions
fix-permissions "${JULIA_PKGDIR}" "${CONDA_DIR}/share/jupyter"
