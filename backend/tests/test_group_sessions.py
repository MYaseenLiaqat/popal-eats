"""Tests for group session validation rules."""

import pytest

from app.services.group_session_service import GroupSessionError, validate_group_invite


def test_validate_group_invite_rejects_self_invite():
    with pytest.raises(GroupSessionError, match="yourself"):
        validate_group_invite(
            sender_id=1,
            receiver_id=1,
            is_friend=True,
            is_member=False,
            pending_invitation=False,
            session_active=True,
        )


def test_validate_group_invite_requires_friend():
    with pytest.raises(GroupSessionError, match="only invite friends"):
        validate_group_invite(
            sender_id=1,
            receiver_id=2,
            is_friend=False,
            is_member=False,
            pending_invitation=False,
            session_active=True,
        )


def test_validate_group_invite_rejects_existing_member():
    with pytest.raises(GroupSessionError, match="already a member"):
        validate_group_invite(
            sender_id=1,
            receiver_id=2,
            is_friend=True,
            is_member=True,
            pending_invitation=False,
            session_active=True,
        )


def test_validate_group_invite_rejects_duplicate_pending():
    with pytest.raises(GroupSessionError, match="pending invitation"):
        validate_group_invite(
            sender_id=1,
            receiver_id=2,
            is_friend=True,
            is_member=False,
            pending_invitation=True,
            session_active=True,
        )


def test_validate_group_invite_requires_active_session():
    with pytest.raises(GroupSessionError, match="active group sessions"):
        validate_group_invite(
            sender_id=1,
            receiver_id=2,
            is_friend=True,
            is_member=False,
            pending_invitation=False,
            session_active=False,
        )


def test_validate_group_invite_allows_valid_invite():
    validate_group_invite(
        sender_id=1,
        receiver_id=2,
        is_friend=True,
        is_member=False,
        pending_invitation=False,
        session_active=True,
    )
