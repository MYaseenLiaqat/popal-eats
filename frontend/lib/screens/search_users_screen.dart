import 'package:flutter/material.dart';

import '../widgets/social/user_search_panel.dart';

/// Search users and send friend requests.
class SearchUsersScreen extends StatelessWidget {
  const SearchUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Users')),
      body: const UserSearchPanel(autofocus: true),
    );
  }
}
