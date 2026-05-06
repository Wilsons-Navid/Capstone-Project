"""Zero-shot / few-shot LLM baselines (Gemini, OpenAI) for scam classification."""
from __future__ import annotations

from dataclasses import dataclass

SYSTEM_PROMPT = """You classify a message into exactly one of these scam categories or "none":
- advance_fee_fraud
- mobile_money_fraud
- phishing
- romance_scam
- identity_theft
- none

Respond with only the category label, nothing else."""


@dataclass
class LLMPrediction:
    label: str
    raw: str
    latency_ms: float


def classify_openai(text: str, model: str = "gpt-4o-mini") -> LLMPrediction:
    """Call OpenAI Chat Completions for a single classification.

    Requires OPENAI_API_KEY. Wire up in Phase 1 week 6.
    """
    raise NotImplementedError("wire up openai SDK in phase 1")


def classify_gemini(text: str, model: str = "gemini-1.5-flash") -> LLMPrediction:
    """Call Vertex AI Gemini for a single classification.

    Requires GOOGLE_APPLICATION_CREDENTIALS. Mirror the pipeline in
    rethicsai/functions/src/wilsonAIVertexModel.ts so production and research
    measure the same model.
    """
    raise NotImplementedError("wire up vertex SDK in phase 1")
