# Serving image for the v2 scam-classifier API (TF-IDF, no embedder).
# Build context MUST be the ml/ directory:
#     docker build -f serve_v2/Dockerfile -t scam-api-v2 .
#     docker run -p 7860:7860 scam-api-v2
FROM python:3.11-slim

WORKDIR /app

COPY serve_v2/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Code + the self-contained ~1.5 MB model. No corpus, no torch, no network at serve time.
COPY serve_v2 ./serve_v2
COPY models/scam_tfidf_v2.joblib ./models/scam_tfidf_v2.joblib

EXPOSE 7860
CMD ["python", "-m", "uvicorn", "serve_v2.app:app", "--host", "0.0.0.0", "--port", "7860"]
