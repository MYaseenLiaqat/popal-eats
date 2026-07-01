import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant.dart';
import '../../models/social_user.dart';
import '../../providers/friends_provider.dart';
import '../../providers/restaurant_follow_provider.dart';
import '../../services/api_client.dart';
import '../../services/friends_service.dart';
import '../../services/restaurant_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/profile_image_url.dart';
import '../../utils/recommendation_copy.dart';
import '../widgets/social/restaurant_social_card.dart';
import '../widgets/social/social_user_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'restaurant_detail_screen.dart';

/// Instagram-style discover: search people & restaurants, follow in one place.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  final _friendsService = FriendsService();
  final _restaurantService = RestaurantService();
  Timer? _debounce;

  List<UserPublicProfile> _userResults = [];
  List<Restaurant> _restaurantResults = [];
  List<Restaurant> _suggestedRestaurants = [];
  bool _loading = false;
  bool _loadingSuggestions = false;
  String? _error;
  String _query = '';
  int _searchGeneration = 0;
  final Set<int> _recentlySent = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      _query = widget.initialQuery;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RestaurantFollowProvider>().load();
      context.read<FriendsProvider>().fetchSuggestions(force: true);
      _loadSuggestedRestaurants();
      if (widget.initialQuery.trim().length >= 2) {
        _runSearch(widget.initialQuery.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedRestaurants() async {
    setState(() => _loadingSuggestions = true);
    try {
      final raw = await _restaurantService.list(limit: 24);
      if (!mounted) return;
      setState(() {
        _suggestedRestaurants = raw
            .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((r) => r.approvalStatus == 'approved')
            .toList();
        _loadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSuggestions = false);
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    final normalized = query.trim().replaceFirst(RegExp(r'^@+'), '');
    final generation = ++_searchGeneration;

    if (normalized.isEmpty || normalized.length < 2) {
      setState(() {
        _userResults = [];
        _restaurantResults = [];
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
      final results = await Future.wait([
        if (ApiClient.instance.isAuthenticated)
          _friendsService.searchUsers(normalized)
        else
          Future.value(UserSearchResults(results: const [])),
        _restaurantService.list(search: normalized, limit: 20),
      ]);
      if (!mounted || generation != _searchGeneration) return;

      final users = results[0] as UserSearchResults;
      final restaurantsRaw = results[1] as List<dynamic>;

      setState(() {
        _userResults = users.results;
        _restaurantResults = restaurantsRaw
            .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
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

  Future<void> _sendFriendRequest(UserPublicProfile user) async {
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

  Future<void> _toggleRestaurantFollow(Restaurant restaurant) async {
    final provider = context.read<RestaurantFollowProvider>();
    final nowFollowing = await provider.toggle(restaurant.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowFollowing
              ? 'Following ${restaurant.name}'
              : 'Unfollowed ${restaurant.name}',
        ),
      ),
    );
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurantId: restaurant.id),
      ),
    );
  }

  Widget _userAction(UserPublicProfile user, FriendsProvider friends) {
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
      onPressed: friends.actionLoading ? null : () => _sendFriendRequest(user),
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

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }

  Widget _buildEmptyDiscover(FriendsProvider friends, RestaurantFollowProvider follows) {
    final people = friends.suggestions.take(8).toList();
    final restaurants = _suggestedRestaurants
        .where((r) => !follows.isFollowing(r.id))
        .take(10)
        .toList();

    if (friends.loadingSuggestions && _loadingSuggestions) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        if (people.isNotEmpty) ...[
          _sectionHeader('Suggested for you'),
          ...people.map((user) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SocialUserCard(
                  user: user,
                  trailing: _userAction(user, friends),
                ),
              )),
        ],
        if (restaurants.isNotEmpty) ...[
          _sectionHeader('Restaurants to follow'),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: restaurants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final r = restaurants[index];
                return SuggestedAccountTile(
                  name: r.name,
                  imageUrl: resolveProfileImageUrl(r.image),
                  subtitle: r.city,
                  isFollowing: follows.isFollowing(r.id),
                  onFollowToggle: () => _toggleRestaurantFollow(r),
                  onTap: () => _openRestaurant(r),
                );
              },
            ),
          ),
        ],
        if (restaurants.length > 4) ...[
          _sectionHeader('Popular restaurants'),
          ...restaurants.take(12).map((r) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: RestaurantSocialCard(
                  restaurant: r,
                  isFollowing: follows.isFollowing(r.id),
                  onFollowToggle: () => _toggleRestaurantFollow(r),
                  onTap: () => _openRestaurant(r),
                ),
              )),
        ],
        if (people.isEmpty && restaurants.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: EmptyState(
              icon: Icons.explore_outlined,
              title: 'Discover food & people',
              subtitle: 'Search above to find friends, chefs, and restaurants to follow.',
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSearchResults(FriendsProvider friends, RestaurantFollowProvider follows) {
    if (_query.trim().length < 2) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: Icons.search,
          title: 'Keep typing',
          subtitle: 'Enter at least 2 characters to search people and restaurants',
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(icon: Icons.cloud_off_outlined, title: 'Search failed', subtitle: _error),
            TextButton(onPressed: () => _runSearch(_searchController.text), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_userResults.isEmpty && _restaurantResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: 'No results',
          subtitle: 'Try a different name, username, or restaurant',
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        if (_userResults.isNotEmpty) ...[
          _sectionHeader('People'),
          ..._userResults.map((user) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SocialUserCard(
                  user: user,
                  trailing: _userAction(user, friends),
                ),
              )),
        ],
        if (_restaurantResults.isNotEmpty) ...[
          _sectionHeader('Restaurants'),
          ..._restaurantResults.map((r) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: RestaurantSocialCard(
                  restaurant: r,
                  isFollowing: follows.isFollowing(r.id),
                  onFollowToggle: () => _toggleRestaurantFollow(r),
                  onTap: () => _openRestaurant(r),
                ),
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final follows = context.watch<RestaurantFollowProvider>();
    final hasQuery = _query.trim().length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ModernCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: TextField(
                controller: _searchController,
                autofocus: widget.initialQuery.isEmpty,
                onChanged: _onQueryChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  _runSearch(v.trim());
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search people, restaurants, @username…',
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
          Expanded(
            child: hasQuery
                ? _buildSearchResults(friends, follows)
                : _buildEmptyDiscover(friends, follows),
          ),
        ],
      ),
    );
  }
}
