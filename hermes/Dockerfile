# Hermes Agent service for Railway

# Uses the official image unchanged and adds a small wrapper that points Hermes at the

# FreeLLMAPI service over Railway's private network. All state lives on the volume at /opt/data.

ARG HERMES\_VERSION=latest
FROM nousresearch/hermes-agent:${HERMES\_VERSION}

USER root

COPY entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

# Dashboard (public Railway domain points here)

ENV HERMES\_DASHBOARD=1   
    HERMES\_DASHBOARD\_HOST=0.0.0.0   
    HERMES\_DASHBOARD\_PORT=9119

# OpenAI-compatible API server (reachable inside the Railway project)

ENV API\_SERVER\_ENABLED=true   
    API\_SERVER\_HOST=0.0.0.0   
    API\_SERVER\_PORT=8642

# Secrets (API\_SERVER\_KEY, dashboard password, FREELLMAPI\_KEY) come only from Railway variables.

EXPOSE 9119 8642

ENTRYPOINT \["/railway-entrypoint.sh"\]