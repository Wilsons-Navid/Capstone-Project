"""Deploy the INITIAL demo classifier API to a Hugging Face Docker Space.

Pure scikit-learn TF-IDF model (no embedder) so the Space cold-starts instantly.
Reads HF_TOKEN from the env.

Usage (from ml/):
    HF_TOKEN=hf_xxx python initial_serve/deploy_hf_space.py [space-name]
"""

from __future__ import annotations

import io
import os
import sys
from pathlib import Path

from huggingface_hub import HfApi

ROOT = Path(__file__).resolve().parent.parent          # ml/
SPACE_NAME = sys.argv[1] if len(sys.argv) > 1 else "scam-classifier-api-initial"

token = os.environ.get("HF_TOKEN")
if not token:
    sys.exit("HF_TOKEN env var not set.")

api = HfApi(token=token)
user = api.whoami()["name"]
repo_id = f"{user}/{SPACE_NAME}"
print(f"user: {user}  ->  space: {repo_id}")

api.create_repo(repo_id, repo_type="space", space_sdk="docker", exist_ok=True)

readme = f"""---
title: Scam Classifier API (initial)
emoji: 🛡️
colorFrom: gray
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# Scam Classifier API (initial demo)

The initial baseline: TF-IDF + Logistic Regression on the v1 English / Portuguese
corpus. Pure scikit-learn, no embedder.

`POST /predict` with `{{"text": "..."}}` -> `{{predicted_category, confidence, scores}}`.
Classes: advance_fee_fraud, mobile_money_fraud, phishing, not_a_scam. Docs at `/docs`.
"""

uploads = {
    "Dockerfile": ROOT / "initial_serve" / "Dockerfile",
    "initial_serve/app.py": ROOT / "initial_serve" / "app.py",
    "initial_serve/requirements.txt": ROOT / "initial_serve" / "requirements.txt",
    # the model lives with its notebook; upload it into initial_serve/ in the Space
    "initial_serve/scam_classifier.joblib": ROOT / "notebooks" / "initial_demo" / "scam_classifier.joblib",
}

api.upload_file(path_or_fileobj=io.BytesIO(readme.encode()), path_in_repo="README.md",
                repo_id=repo_id, repo_type="space")
for path_in_repo, local in uploads.items():
    if not local.exists():
        sys.exit(f"missing {local}")
    print(f"  uploading {path_in_repo} ({local.stat().st_size/1e6:.2f} MB)")
    api.upload_file(path_or_fileobj=str(local), path_in_repo=path_in_repo,
                    repo_id=repo_id, repo_type="space")

url = f"https://{user}-{SPACE_NAME}.hf.space".lower()
print(f"\nDeployed. Space: https://huggingface.co/spaces/{repo_id}")
print(f"API base URL: {url}")
print("Build runs on HF (~2-4 min); first /predict is instant (no model download).")
