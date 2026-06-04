import 'package:flutter/material.dart';
import 'package:popal_eats_mobile/models/recommendation.dart';
import 'package:popal_eats_mobile/services/api_service.dart';

enum _ScreenState { loading, data, empty, error }

/// Fetches and displays hybrid recommendations from Engine V2.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final ApiService _api = ApiService();

  _ScreenState _state = _ScreenState.loading;
  List<Recommendation> _items = [];
  String? _errorMessage;
  String? _statusLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  void _setScreenState({
    required _ScreenState state,
    List<Recommendation>? items,
    String? error,
    String? status,
  }) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _items = items ?? _items;
      _errorMessage = error;
      _statusLine = status;
    });
  }

  Future<void> _fetchRecommendations() async {
    _setScreenState(
      state: _ScreenState.loading,
      items: [],
      error: null,
      status: 'Connecting to ${ApiService.baseUrl}…',
    );

    try {
      await _api.ensureAuthenticated();
      _setScreenState(
        state: _ScreenState.loading,
        status: 'Loading hybrid recommendations…',
      );

      final items = await _api.getRecommendations();

      if (!mounted) return;
      if (items.isEmpty) {
        _setScreenState(
          state: _ScreenState.empty,
          items: [],
          status: 'API returned 0 items',
        );
      } else {
        _setScreenState(
          state: _ScreenState.data,
          items: items,
          status: '${items.length} recommendations loaded',
        );
      }
    } on ApiException catch (e, st) {
      debugPrint('[RecommendationsScreen] ApiException: $e\n$st');
      _setScreenState(
        state: _ScreenState.error,
        error: e.toString(),
        status: 'Request failed',
      );
    } catch (e, st) {
      debugPrint('[RecommendationsScreen] Unexpected error: $e\n$st');
      _setScreenState(
        state: _ScreenState.error,
        error: 'Unexpected error:\n$e',
        status: 'Unhandled exception',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _state == _ScreenState.loading ? null : _fetchRecommendations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_statusLine != null) _buildStatusBanner(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          _statusLine!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _ScreenState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading recommendations…'),
            ],
          ),
        );
      case _ScreenState.error:
        return _buildErrorCard();
      case _ScreenState.empty:
        return _buildEmptyState();
      case _ScreenState.data:
        return _buildList();
    }
  }

  Widget _buildErrorCard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _errorMessage ?? 'Unknown error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _fetchRecommendations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 48),
            const SizedBox(height: 16),
            Text(
              'No recommendations available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _fetchRecommendations,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dishName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  item.restaurantName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: ${item.score.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.explanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
