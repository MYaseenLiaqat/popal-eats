import 'json_parse.dart';

class GroupDecisionStatus {
  GroupDecisionStatus._();

  static const pending = 'pending';
  static const considering = 'considering';
  static const agreed = 'agreed';
  static const ordered = 'ordered';
}

class GroupDecision {
  const GroupDecision({
    required this.id,
    required this.sessionId,
    this.recommendationId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.consensusScore,
    this.finalScore,
    this.dishId,
    this.dishName,
    this.restaurantName,
    this.price,
  });

  final int id;
  final int sessionId;
  final int? recommendationId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? consensusScore;
  final double? finalScore;
  final int? dishId;
  final String? dishName;
  final String? restaurantName;
  final double? price;

  bool get isPending => status == GroupDecisionStatus.pending;
  bool get isConsidering => status == GroupDecisionStatus.considering;
  bool get isAgreed => status == GroupDecisionStatus.agreed;
  bool get isOrdered => status == GroupDecisionStatus.ordered;

  int? get consensusPercent =>
      consensusScore != null ? consensusScore!.round().clamp(0, 100) : null;
  int? get finalPercent => finalScore != null ? finalScore!.round().clamp(0, 100) : null;

  String get bannerMessage {
    switch (status) {
      case GroupDecisionStatus.pending:
        return 'Waiting for members to vote';
      case GroupDecisionStatus.considering:
        return 'Consensus is forming';
      case GroupDecisionStatus.agreed:
        return 'Group has agreed on a recommendation';
      case GroupDecisionStatus.ordered:
        return 'Decision finalized';
      default:
        return 'Group decision in progress';
    }
  }

  factory GroupDecision.fromJson(Map<String, dynamic> json) {
    return GroupDecision(
      id: parseInt(json['id'], field: 'id'),
      sessionId: parseInt(json['session_id'], field: 'session_id'),
      recommendationId: parseIntOrNull(json['recommendation_id']),
      status: parseString(json['status']).toLowerCase(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      consensusScore: parseDoubleOrNull(json['consensus_score']),
      finalScore: parseDoubleOrNull(json['final_score']),
      dishId: parseIntOrNull(json['dish_id']),
      dishName: _optionalString(json['dish_name']),
      restaurantName: _optionalString(json['restaurant_name']),
      price: parseDoubleOrNull(json['price']),
    );
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
