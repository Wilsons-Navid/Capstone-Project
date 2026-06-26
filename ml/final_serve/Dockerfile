# Serving image for the FINAL scam-classifier API (TF-IDF, no embedder).
# Build context MUST be the ml/ directory:
#     docker build -f final_serve/Dockerfile -t scam-api-final .
#     docker run -p 7860:7860 scam-api-final
FROM python:3.11-slim

WORKDIR /app

COPY final_serve/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Code + the self-contained ~1.5 MB model (the deploy script copies the model
# into final_serve/ before upload; locally the app falls back to the notebook folder).
COPY final_serve ./final_serve

EXPOSE 7860
CMD ["python", "-m", "uvicorn", "final_serve.app:app", "--host", "0.0.0.0", "--port", "7860"]
