# Serving image for the INITIAL demo classifier (TF-IDF, no embedder).
# Build context MUST be the ml/ directory:
#     docker build -f initial_serve/Dockerfile -t scam-api-initial .
#     docker run -p 7860:7860 scam-api-initial
FROM python:3.11-slim

WORKDIR /app

COPY initial_serve/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Code + the model produced by the initial_demo notebook (the deploy script copies
# the model into initial_serve/ before upload; locally the app falls back to the notebook folder).
COPY initial_serve ./initial_serve

EXPOSE 7860
CMD ["python", "-m", "uvicorn", "initial_serve.app:app", "--host", "0.0.0.0", "--port", "7860"]
