"""Deploy the v3 (honeynet-enriched, TF-IDF) four-class classifier to a HF Space.

Pure scikit-learn model (~2 MB), no embedder, so the Space cold-starts instantly.
Reads HF_TOKEN from the env.

Usage (from ml/):
    HF_TOKEN=hf_xxx python cmu_v3_serve/deploy_hf_space.py [space-name]
"""

from __future__ import annotations

import io
import os
import sys
from pathlib import Path

from huggingface_hub import HfApi

ROOT = Path(__file__).resolve().parent.parent          # ml/
SPACE_NAME = sys.argv[1] if len(sys.argv) > 1 else "scam-classifier-api-v3"

token = os.environ.get("HF_TOKEN")
if not token:
    sys.exit("HF_TOKEN env var not set.")

api = HfApi(token=token)
user = api.whoami()["name"]
repo_id = f"{user}/{SPACE_NAME}"
print(f"user: {user}  ->  space: {repo_id}")

api.create_repo(repo_id, repo_type="space", space_sdk="docker", exist_ok=True)

readme = f"""---
title: Scam Classifier API v3
emoji: 🛡️
colorFrom: indigo
colorTo: green
sdk: docker
app_port: 7860
pinned: false
---

# Scam Classifier API (v3)

TF-IDF + Logistic Regression, retrained on the corpus after folding in the
CMU-Africa Upanzi smishing honeynet capture. Four classes: advance_fee_fraud,
mobile_money_fraud, phishing, not_a_scam. Languages: English, Portuguese, Swahili,
Kinyarwanda. Pure scikit-learn: no embedder, so there is no cold-start download.

`POST /predict` with `{{"text": "..."}}` -> `{{predicted_category, confidence, scores}}`.
Docs at `/docs`.
"""

uploads = {
    "Dockerfile": ROOT / "cmu_v3_serve" / "Dockerfile",
    "cmu_v3_serve/app.py": ROOT / "cmu_v3_serve" / "app.py",
    "cmu_v3_serve/requirements.txt": ROOT / "cmu_v3_serve" / "requirements.txt",
    "cmu_v3_serve/scam_tfidf_v3.joblib":
        ROOT / "notebooks" / "cmu_corpus_v3" / "scam_tfidf_v3.joblib",
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
