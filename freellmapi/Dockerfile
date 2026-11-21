# FreeLLMAPI service for Railway
# One OpenAI-compatible endpoint in front of many free LLM providers.
# Data (SQLite database + encrypted provider keys) lives on the Railway volume at /data.

FROM node:22-bookworm

ARG FREELLMAPI_VERSION=latest

RUN npm install -g "freellmapi@${FREELLMAPI_VERSION}" --engine-strict=false \
    && npm cache clean --force

COPY start.sh /usr/local/bin/start-freellmapi
RUN chmod +x /usr/local/bin/start-freellmapi

ENV NODE_ENV=production \
    PORT=3001 \
    FREELLMAPI_DATA_DIR=/data

EXPOSE 3001

CMD ["start-freellmapi"]
