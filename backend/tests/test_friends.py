"""Tests for friends service validation and schemas."""

import pytest
from pydantic import ValidationError

from app.schemas.friend import FriendRequestCreate
from app.services.friends_service import (
    FriendRequestError,
    can_send_friend_request,
    validate_friend_request_pair,
)


def test_validate_friend_request_pair_rejects_self():
    with pytest.raises(FriendRequestError, match="yourself"):
        validate_friend_request_pair(sender_id=1, receiver_id=1)


def test_can_send_friend_request_rejects_existing_friendship():
    with pytest.raises(FriendRequestError, match="already friends"):
        can_send_friend_request(
            sender_id=1,
            receiver_id=2,
            are_friends=True,
            pending_exists=False,
        )


def test_can_send_friend_request_rejects_duplicate_pending():
    with pytest.raises(FriendRequestError, match="pending friend request"):
        can_send_friend_request(
            sender_id=1,
            receiver_id=2,
            are_friends=False,
            pending_exists=True,
        )


def test_can_send_friend_request_allows_valid_request():
    can_send_friend_request(
        sender_id=1,
        receiver_id=2,
        are_friends=False,
        pending_exists=False,
    )


def test_friend_request_create_schema_validation():
    payload = FriendRequestCreate(receiver_id=42)
    assert payload.receiver_id == 42

    with pytest.raises(ValidationError):
        FriendRequestCreate(receiver_id=0)
