import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/models/group_decision.dart';
import 'package:popal_eats/models/group_vote.dart';

void main() {
  test('GroupVoteSummary parses API payload', () {
    final summary = GroupVoteSummary.fromJson({
      'likes': 2,
      'loves': 1,
      'dislikes': 0,
      'total_votes': 3,
      'consensus_score': 75.5,
      'final_score': 88.2,
    });

    expect(summary.likes, 2);
    expect(summary.loves, 1);
    expect(summary.totalVotes, 3);
    expect(summary.consensusPercent, 76);
    expect(summary.finalPercent, 88);
  });

  test('GroupVote parses vote response', () {
    final vote = GroupVote.fromJson({
      'id': 9,
      'recommendation_id': 12,
      'user_id': 3,
      'vote_type': 'LOVE',
      'created_at': '2026-06-05T12:00:00Z',
    });

    expect(vote.voteType, 'LOVE');
    expect(vote.recommendationId, 12);
  });

  test('GroupDecision parses decision response', () {
    final decision = GroupDecision.fromJson({
      'id': 1,
      'session_id': 5,
      'recommendation_id': 12,
      'status': 'agreed',
      'created_at': '2026-06-05T10:00:00Z',
      'updated_at': '2026-06-05T12:00:00Z',
      'consensus_score': 80,
      'final_score': 91,
      'dish_id': 44,
      'dish_name': 'Chicken Biryani',
      'restaurant_name': 'Student Biryani',
      'price': '850.00',
    });

    expect(decision.isAgreed, isTrue);
    expect(decision.bannerMessage, 'Group has agreed on a recommendation');
    expect(decision.dishName, 'Chicken Biryani');
    expect(decision.finalPercent, 91);
  });

  test('GroupDecision status messages', () {
    expect(
      GroupDecision.fromJson({'id': 1, 'session_id': 1, 'status': 'pending', 'created_at': '', 'updated_at': ''})
          .bannerMessage,
      'Waiting for members to vote',
    );
    expect(
      GroupDecision.fromJson({'id': 1, 'session_id': 1, 'status': 'considering', 'created_at': '', 'updated_at': ''})
          .bannerMessage,
      'Consensus is forming',
    );
    expect(
      GroupDecision.fromJson({'id': 1, 'session_id': 1, 'status': 'ordered', 'created_at': '', 'updated_at': ''})
          .bannerMessage,
      'Decision finalized',
    );
  });
}
