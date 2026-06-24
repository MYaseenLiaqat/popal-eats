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

/// Debounced user search with friend-request actions.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().fetchAll(force: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.length < 2) {
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
      final response = await _service.searchUsers(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _results = response.results;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || _searchController.text.trim() != query) return;
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
              color: AppColors.green,
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
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF1A1400),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: const Text('Add'),
    );
  }

  Widget _buildResults() {
    if (_query.trim().length < 2) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Find friends',
        subtitle: 'Type at least 2 characters to search by name or username',
      );
    }

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Search failed',
            subtitle: _error,
          ),
          TextButton(
            onPressed: () => _runSearch(_query.trim()),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No users found',
        subtitle: 'Try a different name or username',
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
              textInputAction: TextInputAction.search,
              autofocus: widget.autofocus,
              decoration: InputDecoration(
                hintText: 'Search by name or username',
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
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
