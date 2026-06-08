/// Mock community data (UI-only, no backend).
class MockFriendRequest {
  const MockFriendRequest({
    required this.id,
    required this.name,
    required this.mutualFriends,
  });

  final String id;
  final String name;
  final int mutualFriends;
}

class MockFriend {
  const MockFriend({
    required this.id,
    required this.name,
    required this.lastActive,
  });

  final String id;
  final String name;
  final String lastActive;
}

class MockCommunityActivity {
  const MockCommunityActivity({
    required this.message,
    required this.icon,
    this.accent = 0,
  });

  final String message;
  final String icon;
  final int accent;
}

const mockFriendRequests = [
  MockFriendRequest(id: '1', name: 'Ahmed Khan', mutualFriends: 3),
  MockFriendRequest(id: '2', name: 'Sara Ali', mutualFriends: 5),
  MockFriendRequest(id: '3', name: 'Usman Raza', mutualFriends: 2),
];

const mockFriends = [
  MockFriend(id: '1', name: 'Ali Hassan', lastActive: 'Active now'),
  MockFriend(id: '2', name: 'Fatima Noor', lastActive: '2h ago'),
  MockFriend(id: '3', name: 'Hassan Mahmood', lastActive: 'Yesterday'),
  MockFriend(id: '4', name: 'Ayesha Malik', lastActive: '3d ago'),
];

const mockCommunityActivity = [
  MockCommunityActivity(
    message: 'Ahmed liked Healthy Chicken Bowl',
    icon: 'favorite',
  ),
  MockCommunityActivity(
    message: 'Sara completed nutrition goal',
    icon: 'flag',
    accent: 1,
  ),
  MockCommunityActivity(
    message: 'Ali tried Chef Special Pizza',
    icon: 'restaurant',
  ),
  MockCommunityActivity(
    message: 'Fatima shared a new recipe',
    icon: 'share',
    accent: 1,
  ),
];
