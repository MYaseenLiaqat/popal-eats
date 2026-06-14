import 'json_parse.dart';

/// Vote types accepted by POST /groups/recommendations/{id}/vote.
class GroupVoteType {
  GroupVoteType._();

  static const like = 'LIKE';
  static const love = 'LOVE';
  static const dislike = 'DISLIKE';

  static const all = [like, love, dislike];
}

class GroupVote {
  const GroupVote({
    required this.id,
    required this.recommendationId,
    required this.userId,
    required this.voteType,
    required this.createdAt,
  });

  final int id;
  final int recommendationId;
  final int userId;
  final String voteType;
  final DateTime createdAt;

  factory GroupVote.fromJson(Map<String, dynamic> json) {
    return GroupVote(
      id: parseInt(json['id'], field: 'id'),
      recommendationId: parseInt(json['recommendation_id'], field: 'recommendation_id'),
      userId: parseInt(json['user_id'], field: 'user_id'),
      voteType: parseString(json['vote_type']).toUpperCase(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class GroupVoteSummary {
  const GroupVoteSummary({
    this.likes = 0,
    this.loves = 0,
    this.dislikes = 0,
    this.totalVotes = 0,
    this.consensusScore = 0,
    this.finalScore = 0,
  });

  final int likes;
  final int loves;
  final int dislikes;
  final int totalVotes;
  final double consensusScore;
  final double finalScore;

  int get consensusPercent => consensusScore.round().clamp(0, 100);
  int get finalPercent => finalScore.round().clamp(0, 100);

  factory GroupVoteSummary.fromJson(Map<String, dynamic> json) {
    return GroupVoteSummary(
      likes: parseIntOrNull(json['likes']) ?? 0,
      loves: parseIntOrNull(json['loves']) ?? 0,
      dislikes: parseIntOrNull(json['dislikes']) ?? 0,
      totalVotes: parseIntOrNull(json['total_votes']) ?? 0,
      consensusScore: parseDoubleOrNull(json['consensus_score']) ?? 0,
      finalScore: parseDoubleOrNull(json['final_score']) ?? 0,
    );
  }
}
