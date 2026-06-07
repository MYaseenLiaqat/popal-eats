import 'package:flutter/material.dart';

import '../models/recommendation.dart';
import '../services/recommendation_service.dart';
import 'dish_detail_screen.dart';

/// Recommendation Engine V2 — personalized, trending, and popular dishes.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _recommendations = RecommendationService();

  List<Recommendation> personalized = [];
  List<Recommendation> trending = [];
  List<Recommendation> popular = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        _recommendations.list(),
        _recommendations.trending(),
        _recommendations.popular(),
      ]);
      if (!mounted) return;
      setState(() {
        personalized = results[0];
        trending = results[1];
        popular = results[2];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _openDish(Recommendation rec) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DishDetailScreen(dishId: rec.dishId),
      ),
    );
  }

  Widget _section(String title, List<Recommendation> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text('$title (0)', style: Theme.of(context).textTheme.titleMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${items.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...items.map((rec) => Card(
              child: ListTile(
                title: Text(rec.dishName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rec.restaurantName.isNotEmpty)
                      Text(rec.restaurantName),
                    if (rec.score > 0)
                      Text('Score: ${rec.score.toStringAsFixed(1)}'),
                    if (rec.explanation.isNotEmpty) Text(rec.explanation),
                  ],
                ),
                isThreeLine: true,
                trailing: Text('\$${rec.price.toStringAsFixed(2)}'),
                onTap: () => _openDish(rec),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error!),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _section('For you', personalized),
                      _section('Trending', trending),
                      _section('Popular', popular),
                    ],
                  ),
                ),
    );
  }
}
