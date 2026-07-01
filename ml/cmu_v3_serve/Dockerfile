# Serving image for the v3 four-class scam classifier (TF-IDF, no embedder).
# Build context MUST be the ml/ directory:
#     docker build -f cmu_v3_serve/Dockerfile -t scam-api-v3 .
#     docker run -p 7860:7860 scam-api-v3
FROM python:3.11-slim

WORKDIR /app

COPY cmu_v3_serve/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Code + the self-contained model (the deploy script copies the model into
# cmu_v3_serve/ before upload; locally the app falls back to the notebook folder).
COPY cmu_v3_serve ./cmu_v3_serve

EXPOSE 7860
CMD ["python", "-m", "uvicorn", "cmu_v3_serve.app:app", "--host", "0.0.0.0", "--port", "7860"]
