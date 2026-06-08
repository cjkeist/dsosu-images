#!/bin/bash
# Runs at container startup (before JupyterLab launches) via
# /usr/local/bin/before-notebook.d/ — executes as root.
#
# Writes a default Jupyter AI config when the file is absent or when
# model_provider_id is null. All file operations run as NB_USER via sudo
# to avoid NFS root squash (root cannot write to NFS home directories).
#
# Config location: ~/.local/share/jupyter/jupyter_ai/config.json

# Run file operations as NB_USER so NFS root squash doesn't block writes.
sudo -u "${NB_USER}" python3 - << PYEOF
import json, os, sys

ai_dir    = "/home/${NB_USER}/.local/share/jupyter/jupyter_ai"
ai_config = ai_dir + "/config.json"

os.makedirs(ai_dir, exist_ok=True)

should_write = False
if not os.path.exists(ai_config):
    should_write = True
else:
    try:
        with open(ai_config) as f:
            cfg = json.load(f)
        if cfg.get("model_provider_id") is None:
            should_write = True
    except Exception:
        should_write = True

if should_write:
    default = {
        "model_provider_id": "anthropic-chat:claude-sonnet-4-6",
        "embeddings_provider_id": None,
        "completions_model_provider_id": None,
        "api_keys": {},
        "send_with_shift_enter": False,
        "fields": {},
        "embeddings_fields": {},
        "completions_fields": {}
    }
    with open(ai_config, "w") as f:
        json.dump(default, f, indent=4)
    print("Jupyter AI: wrote default model config (Claude Sonnet 4.6 via Azure AI Foundry APIM) to", ai_config)
PYEOF
