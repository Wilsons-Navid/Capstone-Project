# Serving image for the CMU honeynet binary scam detector.
# Build context MUST be the ml/ directory:
#     docker build -f cmu_inbox_serve/Dockerfile -t cmu-inbox-scan .
#     docker run -p 7860:7860 cmu-inbox-scan
FROM python:3.11-slim

WORKDIR /app

COPY cmu_inbox_serve/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Code + the self-contained model (the deploy script copies the model into
# cmu_inbox_serve/ before upload; locally the app falls back to the notebook folder).
COPY cmu_inbox_serve ./cmu_inbox_serve

EXPOSE 7860
CMD ["python", "-m", "uvicorn", "cmu_inbox_serve.app:app", "--host", "0.0.0.0", "--port", "7860"]
