import 'dart:async';

import 'package:flutter/material.dart';

import '../services/review_service.dart';

/// Polls GET /reviews/{id}/processing for AI pipeline status.
class ReviewStatusScreen extends StatefulWidget {
  const ReviewStatusScreen({super.key, required this.reviewId});

  final int reviewId;

  @override
  State<ReviewStatusScreen> createState() => _ReviewStatusScreenState();
}

class _ReviewStatusScreenState extends State<ReviewStatusScreen> {
  final _reviews = ReviewService();
  Map<String, dynamic>? status;
  String? error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final data = await _reviews.getProcessingStatus(widget.reviewId);
      if (!mounted) return;
      setState(() {
        status = data;
        error = null;
      });
      final s = data['processing_status'] as String?;
      if (s == 'completed' || s == 'failed') {
        _timer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review #${widget.reviewId} AI Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: error != null
            ? Text(error!)
            : status == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Status', status!['processing_status']),
                      _row('Language', status!['detected_language']),
                      _row('Sentiment', status!['sentiment']),
                      _row('Score', status!['sentiment_score']?.toString()),
                      _row('Processed', status!['processed_at']?.toString()),
                    ],
                  ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value?.toString() ?? '—')),
        ],
      ),
    );
  }
}
