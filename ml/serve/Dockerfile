# Serving image for the scam-classifier ensemble API.
# Build context MUST be the ml/ directory:
#     docker build -f serve/Dockerfile -t scam-api .
#     docker run -p 7860:7860 scam-api
FROM python:3.11-slim

WORKDIR /app

# System deps kept minimal; sentence-transformers/torch ship manylinux wheels.
COPY serve/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Code + the self-contained trained ensemble (no corpus needed at serve time).
COPY src ./src
COPY serve ./serve
COPY models/embed_models.joblib ./models/embed_models.joblib

# Writable HF cache for the e5 weights downloaded on first request.
ENV HF_HOME=/app/.hf_cache
RUN mkdir -p /app/.hf_cache && chmod -R 777 /app/.hf_cache

EXPOSE 7860
CMD ["python", "-m", "uvicorn", "serve.app:app", "--host", "0.0.0.0", "--port", "7860"]
