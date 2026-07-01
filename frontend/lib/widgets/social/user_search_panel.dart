import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/social_user.dart';
import '../../providers/friends_provider.dart';
import '../../services/api_client.dart';
import '../../services/friends_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/recommendation_copy.dart';
import '../social/social_user_card.dart';
import '../ui/app_ui_widgets.dart';

/// Debounced user search with friend-request actions and suggested users.
class UserSearchPanel extends StatefulWidget {
  const UserSearchPanel({
    super.key,
    this.autofocus = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppColors.screenPadding,
      AppColors.screenPadding,
      AppColors.screenPadding,
      8,
    ),
  });

  final bool autofocus;
  final EdgeInsets padding;

  @override
  State<UserSearchPanel> createState() => _UserSearchPanelState();
}

class _UserSearchPanelState extends State<UserSearchPanel> {
  final _searchController = TextEditingController();
  final _service = FriendsService();
  Timer? _debounce;

  List<UserPublicProfile> _results = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  final Set<int> _recentlySent = {};
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendsProvider>().fetchSuggestions(force: false);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _normalizedQuery(String raw) =>
      raw.trim().replaceFirst(RegExp(r'^@+'), '');

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    final normalized = _normalizedQuery(query);
    final generation = ++_searchGeneration;

    if (normalized.isEmpty || normalized.length < 2) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _service
          .searchUsers(normalized)
          .timeout(const Duration(seconds: 20));
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = response.results;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _error = RecommendationCopy.friendlyError(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _error = RecommendationCopy.friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _sendRequest(UserPublicProfile user) async {
    final provider = context.read<FriendsProvider>();
    final ok = await provider.sendRequest(user.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _recentlySent.add(user.id));
      await context.read<FriendsProvider>().fetchRequests(force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${user.fullName}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not send request')),
      );
    }
  }

  Widget _buildActionButton(UserPublicProfile user, FriendsProvider friends) {
    if (friends.isFriend(user.id)) {
      return Text(
        'Friends',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
      );
    }
    if (friends.hasOutgoingRequestTo(user.id) || _recentlySent.contains(user.id)) {
      return const PendingBadge();
    }

    return FilledButton(
      onPressed: friends.actionLoading ? null : () => _sendRequest(user),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Follow'),
    );
  }

  Widget _buildSuggestions(FriendsProvider friends) {
    if (friends.loadingSuggestions) {
      return _centeredChild(
        const CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (friends.suggestionsError != null && friends.suggestions.isEmpty) {
      return _centeredChild(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load suggestions',
              subtitle: friends.suggestionsError,
            ),
            TextButton(
              onPressed: () => friends.fetchSuggestions(force: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (friends.suggestions.isEmpty) {
      return _centeredChild(
        const EmptyState(
          icon: Icons.person_search_outlined,
          title: 'Find people',
          subtitle: 'Search by name or @username above',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppColors.screenPadding,
        0,
        AppColors.screenPadding,
        AppColors.screenPadding,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Suggested for you',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        ...friends.suggestions.map((user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SocialUserCard(
                user: user,
                trailing: _buildActionButton(user, friends),
              ),
            )),
      ],
    );
  }

  Widget _centeredChild(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  Widget _buildResults() {
    if (_normalizedQuery(_query).isEmpty) {
      return _buildSuggestions(context.watch<FriendsProvider>());
    }

    if (_normalizedQuery(_query).length < 2) {
      return _centeredChild(
        const EmptyState(
          icon: Icons.person_search_outlined,
          title: 'Keep typing',
          subtitle: 'Enter at least 2 characters to search by name or username',
        ),
      );
    }

    if (_loading) {
      return _centeredChild(
        const CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return _centeredChild(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Search failed',
              subtitle: _error,
            ),
            TextButton(
              onPressed: () => _runSearch(_searchController.text.trim()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return _centeredChild(
        const EmptyState(
          icon: Icons.search_off_outlined,
          title: 'No users found',
          subtitle: 'Try a different name or username',
        ),
      );
    }

    final friends = context.watch<FriendsProvider>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppColors.screenPadding,
        0,
        AppColors.screenPadding,
        AppColors.screenPadding,
      ),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _results[index];
        return SocialUserCard(
          user: user,
          trailing: _buildActionButton(user, friends),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: widget.padding,
          child: ModernCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                _runSearch(value.trim());
              },
              textInputAction: TextInputAction.search,
              autofocus: widget.autofocus,
              decoration: InputDecoration(
                hintText: 'Search name, @username, or role',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        Expanded(child: _buildResults()),
      ],
    );
  }
}
