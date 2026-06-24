"""Deploy the v2 (TF-IDF, lightweight) scam-classifier API to a HF Docker Space.

Pure scikit-learn model (~1.5 MB) — no torch, no e5 download — so the Space cold
-starts instantly (no heuristic fallback). Reads HF_TOKEN from the env.

Usage (from ml/):
    HF_TOKEN=hf_xxx python serve_v2/deploy_hf_space_v2.py [space-name]
"""

from __future__ import annotations

import io
import os
import sys
from pathlib import Path

from huggingface_hub import HfApi

ROOT = Path(__file__).resolve().parent.parent          # ml/
SPACE_NAME = sys.argv[1] if len(sys.argv) > 1 else "scam-classifier-api-v2"

token = os.environ.get("HF_TOKEN")
if not token:
    sys.exit("HF_TOKEN env var not set.")

api = HfApi(token=token)
user = api.whoami()["name"]
repo_id = f"{user}/{SPACE_NAME}"
print(f"user: {user}  ->  space: {repo_id}")

api.create_repo(repo_id, repo_type="space", space_sdk="docker", exist_ok=True)

readme = f"""---
title: Scam Classifier API v2
emoji: 🛡️
colorFrom: indigo
colorTo: green
sdk: docker
app_port: 7860
pinned: false
---

# Scam Classifier API (v2)

TF-IDF + Logistic Regression, the best model on the expanded multilingual corpus
(English / Portuguese / Swahili, 9,623 messages). Test macro-F1 0.946. Pure
scikit-learn: no embedder, so there is no cold-start model download.

`POST /predict` with `{{"text": "..."}}` -> `{{predicted_category, confidence, scores}}`.
Classes: advance_fee_fraud, mobile_money_fraud, phishing, not_a_scam. Docs at `/docs`.
"""

uploads = {
    "Dockerfile": ROOT / "serve_v2" / "Dockerfile",
    "serve_v2/app.py": ROOT / "serve_v2" / "app.py",
    "serve_v2/requirements.txt": ROOT / "serve_v2" / "requirements.txt",
    "models/scam_tfidf_v2.joblib": ROOT / "models" / "scam_tfidf_v2.joblib",
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
