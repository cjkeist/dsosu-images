# TARGET jupyterlab-ubuntu-base-ai v1.0.6

# 1.0.0: Initial AI image - JupyterLab 4 + jupyter-ai + anthropic-chat (Claude) support
#         Built on top of jupyterlab-ubuntu-base-scipy-rjulia v1.2.0
# 1.0.1: Fix HOME->NB_USER in before-notebook-ai-defaults.sh; patch config_manager.py
#         _validate_provider_authn and _provider_params to accept ANTHROPIC_API_KEY from env
# 1.0.2: Rewrite before-notebook-ai-defaults.sh to run as NB_USER via sudo to bypass NFS root squash
# 1.0.3: Patch ConfigManager.__init__ to write default model when model_provider_id is null;
#         ConfigManager runs as NB_USER so NFS writes succeed (root squash workaround)
# 1.0.4: Fix patch 2c to write JSON directly instead of _write_config (avoids AuthError during init)
# 1.0.5: Pin base image to jupyterlab-ubuntu-base-scipy-rjulia:v1.2.1
# 1.0.5: Pin base image to jupyterlab-ubuntu-base-scipy-rjulia:v1.2.2
