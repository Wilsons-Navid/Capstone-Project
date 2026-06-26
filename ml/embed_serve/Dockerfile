# Serving image for the embedding-ensemble scam-classifier API.
# Build context MUST be the ml/ directory:
#     docker build -f embed_serve/Dockerfile -t scam-api-embed .
#     docker run -p 7860:7860 scam-api-embed
FROM python:3.11-slim

WORKDIR /app

# System deps kept minimal; sentence-transformers/torch ship manylinux wheels.
COPY embed_serve/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Code + the self-contained trained ensemble (the deploy script copies the bundle
# into embed_serve/ before upload; locally the app falls back to the notebook folder).
COPY embed_serve ./embed_serve

# Writable HF cache for the e5 weights downloaded on first request.
ENV HF_HOME=/app/.hf_cache
RUN mkdir -p /app/.hf_cache && chmod -R 777 /app/.hf_cache

EXPOSE 7860
CMD ["python", "-m", "uvicorn", "embed_serve.app:app", "--host", "0.0.0.0", "--port", "7860"]
