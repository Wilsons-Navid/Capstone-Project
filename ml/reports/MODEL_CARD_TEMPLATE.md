# Model card — <model_name>

**Date:** YYYY-MM-DD
**Author:** Wilsons Navid Wado Tiwa
**Version:** v0.x

## Intended use

What this model is for. What it is not for.

## Training data

| Source | Records | Languages | Label distribution |
| --- | --- | --- | --- |
|  |  |  |  |

Known biases:

- 

## Architecture

Vectoriser + classifier (or pretrained model name + head). Hyperparameters.

## Training procedure

- Splits: 70 / 15 / 15 stratified by label
- Cross-validation: stratified 5-fold on train+val
- Random seed: 42

## Evaluation

| Metric | Value |
| --- | --- |
| Accuracy |  |
| Macro F1 |  |

### Per-class

| Label | Precision | Recall | F1 | Support |
| --- | --- | --- | --- | --- |
| advance_fee_fraud |  |  |  |  |
| mobile_money_fraud |  |  |  |  |
| phishing |  |  |  |  |
| romance_scam |  |  |  |  |
| identity_theft |  |  |  |  |
| none |  |  |  |  |

### Per-language

| Language | Macro F1 | Support |
| --- | --- | --- |
| en |  |  |
| fr |  |  |
| pcm |  |  |

Confusion matrix: see `confusion_<model>.png`.

## Cost / latency (LLM models only)

| Metric | Value |
| --- | --- |
| Median latency | ms |
| p95 latency | ms |
| Cost per 1k inferences | USD |

## Limitations

- 

## Ethical considerations

- 
