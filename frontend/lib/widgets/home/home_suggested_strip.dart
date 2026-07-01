import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant.dart';
import '../../models/social_user.dart';
import '../../providers/friends_provider.dart';
import '../../providers/restaurant_follow_provider.dart';
import '../../services/restaurant_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/profile_image_url.dart';
import '../social/restaurant_social_card.dart';
import '../../screens/discover_screen.dart';
import '../../screens/restaurant_detail_screen.dart';

/// Instagram-style horizontal strip: suggested people + restaurants to follow.
class HomeSuggestedStrip extends StatefulWidget {
  const HomeSuggestedStrip({super.key});

  @override
  State<HomeSuggestedStrip> createState() => _HomeSuggestedStripState();
}

class _HomeSuggestedStripState extends State<HomeSuggestedStrip> {
  final _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  bool _loadingRestaurants = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendsProvider>().fetchSuggestions(force: false);
      context.read<RestaurantFollowProvider>().load();
      _loadRestaurants();
    });
  }

  Future<void> _loadRestaurants() async {
    setState(() => _loadingRestaurants = true);
    try {
      final raw = await _restaurantService.list(limit: 16);
      if (!mounted) return;
      setState(() {
        _restaurants = raw
            .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((r) => r.approvalStatus == 'approved')
            .toList();
        _loadingRestaurants = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRestaurants = false);
    }
  }

  void _openDiscover() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiscoverScreen()),
    );
  }

  Future<void> _sendFriendRequest(UserPublicProfile user) async {
    final provider = context.read<FriendsProvider>();
    final ok = await provider.sendRequest(user.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${user.fullName}')),
      );
    }
  }

  Future<void> _toggleRestaurant(Restaurant restaurant) async {
    final provider = context.read<RestaurantFollowProvider>();
    final nowFollowing = await provider.toggle(restaurant.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowFollowing ? 'Following ${restaurant.name}' : 'Unfollowed ${restaurant.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final follows = context.watch<RestaurantFollowProvider>();

    final people = friends.suggestions
        .where((u) => !friends.isFriend(u.id) && !friends.hasOutgoingRequestTo(u.id))
        .take(6)
        .toList();
    final restaurants = _restaurants
        .where((r) => !follows.isFollowing(r.id))
        .take(8)
        .toList();

    if (people.isEmpty && restaurants.isEmpty && !friends.loadingSuggestions && !_loadingRestaurants) {
      return const SizedBox.shrink();
    }

    if (friends.loadingSuggestions && _loadingRestaurants && people.isEmpty && restaurants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Suggested for you',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton(onPressed: _openDiscover, child: const Text('See all')),
            ],
          ),
        ),
        SizedBox(
          height: 148,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              ...people.map((user) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SuggestedAccountTile(
                      name: user.fullName.split(' ').first,
                      imageUrl: user.profileImage,
                      subtitle: user.roleLabel,
                      isFollowing: false,
                      onFollowToggle: () => _sendFriendRequest(user),
                    ),
                  )),
              ...restaurants.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SuggestedAccountTile(
                      name: r.name,
                      imageUrl: resolveProfileImageUrl(r.image),
                      subtitle: r.city ?? 'Restaurant',
                      isFollowing: follows.isFollowing(r.id),
                      onFollowToggle: () => _toggleRestaurant(r),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailScreen(restaurantId: r.id),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
