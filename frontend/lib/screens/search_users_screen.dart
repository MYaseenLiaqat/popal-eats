import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_provider.dart';
import '../widgets/social/user_search_panel.dart';

/// Search users and send friend requests.
class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final friends = context.read<FriendsProvider>();
      friends.fetchFriends(force: true);
      friends.fetchRequests(force: true);
      friends.fetchSuggestions(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find People')),
      body: UserSearchPanel(autofocus: true),
    );
  }
}
