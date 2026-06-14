"""Tests for group member location schema validation."""

from decimal import Decimal

import pytest
from pydantic import ValidationError

from app.schemas.group_location import GroupMemberLocationUpdate


def test_location_update_accepts_valid_coordinates():
    payload = GroupMemberLocationUpdate(
        latitude=Decimal("31.5204"),
        longitude=Decimal("74.3587"),
    )
    assert payload.latitude == Decimal("31.5204")
    assert payload.longitude == Decimal("74.3587")


def test_location_update_rejects_invalid_latitude():
    with pytest.raises(ValidationError):
        GroupMemberLocationUpdate(latitude=Decimal("91"), longitude=Decimal("0"))


def test_location_update_rejects_invalid_longitude():
    with pytest.raises(ValidationError):
        GroupMemberLocationUpdate(latitude=Decimal("0"), longitude=Decimal("181"))
