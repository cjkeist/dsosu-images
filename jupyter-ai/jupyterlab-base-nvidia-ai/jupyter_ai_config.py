# Jupyter AI server-side configuration (jupyter-ai 2.x).
# Copied into the image at /etc/jupyter/jupyter_ai_config.py
#
# Sets Claude Sonnet 4.6 as the default model for all users via the Azure
# AI Foundry APIM proxy. Users can override in Settings > AI Settings.
#
# Credentials are injected at runtime via ANTHROPIC_API_KEY and
# ANTHROPIC_BASE_URL environment variables (Kubernetes Secret).

c = get_config()  # noqa

c.AiExtension.default_language_model = "anthropic-chat:claude-sonnet-4-6"
