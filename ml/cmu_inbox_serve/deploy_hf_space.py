"""Deploy the CMU binary scam detector to a Hugging Face Docker Space.

Small scikit-learn model (~0.35 MB), no torch, so the Space cold-starts instantly.
Reads HF_TOKEN from the env.

Usage (from ml/):
    HF_TOKEN=hf_xxx python cmu_inbox_serve/deploy_hf_space.py [space-name]
"""

from __future__ import annotations

import io
import os
import sys
from pathlib import Path

from huggingface_hub import HfApi

ROOT = Path(__file__).resolve().parent.parent          # ml/
SPACE_NAME = sys.argv[1] if len(sys.argv) > 1 else "cmu-scam-inbox-guard"

token = os.environ.get("HF_TOKEN")
if not token:
    sys.exit("HF_TOKEN env var not set.")

api = HfApi(token=token)
user = api.whoami()["name"]
repo_id = f"{user}/{SPACE_NAME}"
print(f"user: {user}  ->  space: {repo_id}")

api.create_repo(repo_id, repo_type="space", space_sdk="docker", exist_ok=True)

readme = f"""---
title: CMU Scam Inbox Guard
emoji: 🛡️
colorFrom: green
colorTo: red
sdk: docker
app_port: 7860
pinned: false
---

# CMU Honeynet Scam Detector (binary)

First-pass SMS inbox scan: is this message a scam or not? Trained only on real
scam text captured by the CMU-Africa Upanzi smishing honeynet, in English,
Kinyarwanda and Swahili. Small scikit-learn pipeline, so there is no cold-start
model download. Applies a recall-tuned threshold.

`POST /predict` with `{{"text": "..."}}` -> `{{is_scam, scam_probability, verdict, threshold}}`.
Docs at `/docs`.
"""

uploads = {
    "Dockerfile": ROOT / "cmu_inbox_serve" / "Dockerfile",
    "cmu_inbox_serve/app.py": ROOT / "cmu_inbox_serve" / "app.py",
    "cmu_inbox_serve/requirements.txt": ROOT / "cmu_inbox_serve" / "requirements.txt",
    # the model lives with its notebook; upload it into cmu_inbox_serve/ in the Space
    "cmu_inbox_serve/cmu_scam_binary.joblib":
        ROOT / "notebooks" / "cmu_binary" / "cmu_scam_binary.joblib",
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
