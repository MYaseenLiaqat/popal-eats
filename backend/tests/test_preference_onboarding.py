"""Tests for preference onboarding schemas and service rules."""

import pytest
from pydantic import ValidationError

from app.schemas.preference_onboarding import (
    FOOD_INTEREST_KEYS,
    OnboardingCompleteRequest,
)
from app.services.preference_onboarding_service import (
    OnboardingError,
    get_onboarding_options,
    onboarding_already_completed,
)


class _User:
    def __init__(self, *, onboarding_completed: bool = False):
        self.onboarding_completed = onboarding_completed


def test_onboarding_options_include_food_interests_and_allergies():
    options = get_onboarding_options()
    keys = {item.key for item in options.food_interests}
    assert "burger" in keys
    assert "pizza" in keys
    assert len(options.food_interests) == len(FOOD_INTEREST_KEYS)
    assert len(options.allergies) >= 10
    assert all(item.display_name for item in options.allergies)


def test_onboarding_complete_request_validation():
    payload = OnboardingCompleteRequest(
        favorite_cuisines=["burger", "pizza", "biryani"],
        allergies=["peanuts"],
    )
    assert payload.favorite_cuisines == ["burger", "pizza", "biryani"]
    assert payload.allergies == ["peanuts"]


def test_onboarding_rejects_too_many_cuisines():
    with pytest.raises(ValidationError):
        OnboardingCompleteRequest(
            favorite_cuisines=sorted(FOOD_INTEREST_KEYS),
            allergies=[],
        )


def test_onboarding_rejects_invalid_food_interest():
    with pytest.raises(ValidationError):
        OnboardingCompleteRequest(favorite_cuisines=["sushi_roll"], allergies=[])


def test_onboarding_rejects_invalid_allergy():
    with pytest.raises(ValidationError):
        OnboardingCompleteRequest(favorite_cuisines=[], allergies=["shellfishs"])


def test_onboarding_allows_empty_selections():
    payload = OnboardingCompleteRequest(favorite_cuisines=[], allergies=[])
    assert payload.favorite_cuisines == []
    assert payload.allergies == []


def test_onboarding_already_completed_detection():
    assert onboarding_already_completed(_User(onboarding_completed=False)) is False
    assert onboarding_already_completed(_User(onboarding_completed=True)) is True


def test_onboarding_error_for_repeat_completion():
    with pytest.raises(OnboardingError):
        from app.services.preference_onboarding_service import _ensure_not_completed

        _ensure_not_completed(_User(onboarding_completed=True))
