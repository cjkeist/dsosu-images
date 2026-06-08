# TARGET jupyterlab-ubuntu-base-nvidia-ai v1.0.2

# 1.0.2: RAPIDS package downgraded JupyterLab version. Reinstalling JupterLab 4.x before Jupyter-ai install. Pin base
#        image to jupyterlab-ubuntu-base-nvidia-scipy-rjulia-gpu:v1.2.2
# 1.0.1: Adding Jupyter-ai to Nvidia image. Pin base image to jupyterlab-ubuntu-base-nvidia-scipy-rjulia-gpu:v1.2.2
FROM jupyterlab-ubuntu-base-nvidia-scipy-rjulia-gpu:v1.1.8 AS jupyterlab-ubuntu-base-nvidia-ai
############################################################################
#################### DS@OSU: Jupyter AI (Claude) Layer ####################
############################################################################
# Adds jupyter-ai + langchain-anthropic + Azure AI Foundry (Claude) support
# on top of the standard jupyterlab-ubuntu-base-scipy-rjulia image.
# JupyterLab 4 is provided by the base image (jupyterlab-ubuntu-base-scipy).
#
# Requirements:
#   - ANTHROPIC_API_KEY and ANTHROPIC_BASE_URL must be provided as environment
#     variables at runtime (via Kubernetes Secret in the hub profile config).
#     ANTHROPIC_BASE_URL points to the Azure AI Foundry APIM proxy endpoint.

LABEL maintainer="DS@OSU Infrastructure Team"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# RAPIDS pip installs (cuxfilter in particular) downgrade JupyterLab to 3.x.
# Reinstall JupyterLab 4 before adding jupyter-ai, which requires JupyterLab 4.
RUN pip install --no-cache-dir \
    'jupyterlab>=4.0,<5.0' \
    'notebook>=7.0,<8.0' \
    'jupyterhub>=4.0,<5.0' && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install jupyter-ai 2.x (stable) with the anthropic-chat provider.
# Pinned to <3.0 — jupyter-ai 3.0.0 has a broken send_message() API.
# langchain-anthropic<0.3.0 is the last series compatible with langchain 0.3.x
# (langchain-core<1.0.0). The [litellm] extra has no provider entry point and
# is unused; anthropic-chat via langchain-anthropic is the correct path.
# Running as root because the rjulia base layer has root-owned files in CONDA_DIR
# (jupyter-rsession-proxy), so fix-permissions must run as root.
RUN pip install --no-cache-dir \
    'jupyter-ai[jupyternaut]>=2.0,<3.0' \
    'langchain-anthropic>=0.1,<0.3' \
    'langchain-core>=0.3.73,<1.0.0' && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install server-side traitlets config for default model (v2 compat layer).
COPY jupyter_ai_config.py /etc/jupyter/

# Install before-notebook startup script to write per-user defaults on first launch.
COPY before-notebook-ai-defaults.sh /usr/local/bin/before-notebook.d/before-notebook-ai-defaults.sh
RUN chmod +x /usr/local/bin/before-notebook.d/before-notebook-ai-defaults.sh

# Add Azure AI Foundry deployment model names to the anthropic-chat provider.
# These names match the Azure deployments (claude-sonnet-4-6, etc.) and must
# appear in the provider's models list so ConfigManager accepts them as valid.
RUN python - << 'PYEOF'
import importlib.util
import inspect
import os
import jupyter_ai_magics.partner_providers.anthropic as m
fpath = inspect.getfile(m)
with open(fpath) as f:
    content = f.read()
azure_models = '        "claude-haiku-4-5",\n        "claude-sonnet-4-6",\n        "claude-opus-4-7",'
content = content.replace(
    '"claude-3-5-sonnet-20241022",\n    ]',
    '"claude-3-5-sonnet-20241022",\n' + azure_models + '\n    ]'
)
with open(fpath, "w") as f:
    f.write(content)
cache_path = importlib.util.cache_from_source(fpath)
if os.path.exists(cache_path):
    os.remove(cache_path)
print("Patched anthropic-chat provider with Azure deployment model names")
PYEOF

# Patch _validate_provider_authn to also accept credentials from os.environ.
# The upstream function only checks config.api_keys (the JSON file), so env vars
# injected by Kubernetes Secrets (ANTHROPIC_API_KEY) are silently ignored and
# the extension raises AuthError even when the key is present in the environment.
RUN python - << 'PYEOF'
import importlib.util
import inspect
import os
import jupyter_ai.config_manager as cm
fpath = inspect.getfile(cm)
with open(fpath) as f:
    content = f.read()
old = (
    "    if provider.auth_strategy.name not in config.api_keys:\n"
    "        raise AuthError(\n"
    "            f\"Missing API key for '{provider.auth_strategy.name}' in the config.\"\n"
    "        )"
)
new = (
    "    if (\n"
    "        provider.auth_strategy.name not in config.api_keys\n"
    "        and provider.auth_strategy.name not in os.environ\n"
    "    ):\n"
    "        raise AuthError(\n"
    "            f\"Missing API key for '{provider.auth_strategy.name}' in the config.\"\n"
    "        )"
)
if old not in content:
    raise RuntimeError("Patch target not found in config_manager.py (_validate_provider_authn) — upstream may have changed")
content = content.replace(old, new)
# Patch 2b: _provider_params also reads config.api_keys directly when building
# LLM constructor kwargs — same KeyError at message-send time if key is only in env.
old2 = (
    "            key_name = Provider.auth_strategy.name\n"
    "            authn_fields[keyword_param] = config.api_keys[key_name]"
)
new2 = (
    "            key_name = Provider.auth_strategy.name\n"
    "            authn_fields[keyword_param] = (\n"
    "                config.api_keys.get(key_name) or os.environ.get(key_name)\n"
    "            )"
)
if old2 not in content:
    raise RuntimeError("Patch target not found in config_manager.py (_provider_params) — upstream may have changed")
content = content.replace(old2, new2)
# Patch 2c: After __init__ calls _init_config(), if model_provider_id is still null
# (e.g. stale NFS config from a prior unconfigured session), write the server-side
# default. ConfigManager runs as NB_USER so NFS writes succeed here, unlike the
# before-notebook.d startup script which runs as root and hits NFS root squash.
old3 = "        self._init_config()\n"
new3 = (
    "        self._init_config()\n"
    "        # Write default model directly as JSON — bypasses _write_config so we\n"
    "        # avoid triggering _validate_provider_authn before env vars are available.\n"
    "        # ConfigManager runs as NB_USER so NFS home writes succeed here.\n"
    "        try:\n"
    "            import json as _json, os as _os\n"
    "            _p = _os.path.join(_os.path.expanduser('~'), '.local', 'share', 'jupyter', 'jupyter_ai', 'config.json')\n"
    "            if _os.path.exists(_p):\n"
    "                with open(_p) as _f:\n"
    "                    _d = _json.load(_f)\n"
    "                if _d.get('model_provider_id') is None:\n"
    "                    _d['model_provider_id'] = 'anthropic-chat:claude-sonnet-4-6'\n"
    "                    with open(_p, 'w') as _f:\n"
    "                        _json.dump(_d, _f, indent=4)\n"
    "        except Exception:\n"
    "            pass\n"
)
if old3 not in content:
    raise RuntimeError("Patch target not found in config_manager.py (__init__) — upstream may have changed")
content = content.replace(old3, new3, 1)
# Ensure os is imported
if "import os\n" not in content:
    content = "import os\n" + content
with open(fpath, "w") as f:
    f.write(content)
# Invalidate the bytecode cache so the patched .py is used at runtime
cache_path = importlib.util.cache_from_source(fpath)
if os.path.exists(cache_path):
    os.remove(cache_path)
print("Patched _validate_provider_authn and _provider_params to accept ANTHROPIC_API_KEY from os.environ")
PYEOF

RUN fix-permissions /etc/jupyter/

WORKDIR "${HOME}"
