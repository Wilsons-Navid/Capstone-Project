"""Deploy the scam-classifier ensemble API to a Hugging Face Docker Space.

Reads the HF token from the HF_TOKEN env var (never hard-code it). Creates (or
updates) a public Docker Space and uploads the serving code + the trained
self-contained ensemble. HF builds the image; first request pulls the e5 weights.

Usage:
    HF_TOKEN=hf_xxx python embed_serve/deploy_hf_space.py            # from ml/
    HF_TOKEN=hf_xxx python embed_serve/deploy_hf_space.py my-space-name
"""

from __future__ import annotations

import io
import os
import sys
from pathlib import Path

from huggingface_hub import HfApi

ROOT = Path(__file__).resolve().parent.parent          # ml/
SPACE_NAME = sys.argv[1] if len(sys.argv) > 1 else "scam-classifier-api"

token = os.environ.get("HF_TOKEN")
if not token:
    sys.exit("HF_TOKEN env var not set.")

api = HfApi(token=token)
user = api.whoami()["name"]
repo_id = f"{user}/{SPACE_NAME}"
print(f"user: {user}  ->  space: {repo_id}")

api.create_repo(repo_id, repo_type="space", space_sdk="docker", exist_ok=True)

readme = f"""---
title: Scam Classifier API
emoji: 🛡️
colorFrom: indigo
colorTo: blue
sdk: docker
app_port: 7860
pinned: false
---

# Scam Classifier API

Soft-voting ensemble (TF-IDF + multilingual-e5-small) that classifies a short
message as advance_fee_fraud, mobile_money_fraud, phishing, or not_a_scam.
Test macro-F1 0.955. Multilingual (English / Portuguese / French + more).

`POST /predict` with `{{"text": "..."}}` -> `{{predicted_category, confidence, scores}}`.
Interactive docs at `/docs`.
"""

uploads = {
    "Dockerfile": ROOT / "embed_serve" / "Dockerfile",
    "embed_serve/app.py": ROOT / "embed_serve" / "app.py",
    "embed_serve/requirements.txt": ROOT / "embed_serve" / "requirements.txt",
    # the bundle lives with its notebook; upload it into embed_serve/ in the Space
    "embed_serve/embed_models.joblib": ROOT / "notebooks" / "embed_demo" / "embed_models.joblib",
}

api.upload_file(path_or_fileobj=io.BytesIO(readme.encode()), path_in_repo="README.md",
                repo_id=repo_id, repo_type="space")
for path_in_repo, local in uploads.items():
    if not local.exists():
        sys.exit(f"missing {local}")
    print(f"  uploading {path_in_repo} ({local.stat().st_size/1e6:.1f} MB)")
    api.upload_file(path_or_fileobj=str(local), path_in_repo=path_in_repo,
                    repo_id=repo_id, repo_type="space")

url = f"https://{user}-{SPACE_NAME}.hf.space".lower()
print(f"\nDeployed. Space: https://huggingface.co/spaces/{repo_id}")
print(f"API base URL: {url}")
print("Build runs on HF (a few min); first /predict pulls the e5 weights.")
