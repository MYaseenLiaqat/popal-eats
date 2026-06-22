# Nutrition Goal — Recommendation Engine Impact

## Overview

`nutrition_goal` is stored on `user_preferences` (migration `004_user_preferences`) and exposed via `GET/PUT /preferences`. The content-based scorer in `v2_content.py` adjusts dish ranking through `_score_nutrition()`.

## Goals and scoring behavior

| Goal | Ranking emphasis |
|------|------------------|
| **maintain** | Balanced 300–750 kcal range; moderate protein bonus |
| **weight_loss** | Lower calories (≤450 ideal, tiered fallbacks); protein ≥15g preferred |
| **bulking** | Higher calories (≥600 ideal); protein ≥20g preferred |
| **muscle_gain** | Protein thresholds (28g / 22g / 18g tiers) |
| **high_protein** | Protein density (g per 100 kcal) plus absolute protein |

## Signal surfacing

- Nutrition score contributes to hybrid/content recommendations.
- User-facing copy maps nutrition signals to **"Fits your nutrition goals"** via `RecommendationCopy`.
- Nutrition preferences screen lets users set goal alongside diet type and cuisines.

## API

- `GET /preferences` → `nutrition_goal`: `maintain` \| `weight_loss` \| `bulking` \| `muscle_gain` \| `high_protein`
- `PUT /preferences` → same field with validation and aliases (`balanced` → `maintain`, etc.)

## Migration

- `019_nutrition_goal_api` documents API exposure (no new column; column exists from `004`).

## Verification

1. Set goal to **Weight Loss** in Nutrition Preferences → save.
2. Call `GET /preferences` → confirm `nutrition_goal: weight_loss`.
3. Refresh Discover → dishes with lower calories and higher protein should rank higher vs **Bulking** goal on same account.
