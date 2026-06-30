import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/post.dart';
import '../models/story.dart';
import 'api_client.dart';

class ContentService {
  ContentService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Post>> fetchHomeFeed({int page = 1, int limit = 20}) async {
    final r = await _api.get('/feed/home', query: {
      'page': '$page',
      'limit': '$limit',
    });
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    final items = data['items'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Post> createPost(Map<String, dynamic> body) async {
    final r = await _api.post('/posts', body: body);
    _api.throwIfError(r);
    return Post.fromJson(_api.decodeJson(r));
  }

  Future<void> deletePost(int postId) async {
    final r = await _api.delete('/posts/$postId');
    _api.throwIfError(r);
  }

  Future<Post> uploadPostImage({
    required int postId,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/posts/$postId/image');
    final request = http.MultipartRequest('POST', uri);
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _api.throwIfError(response);
    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Post> uploadPostVideo({
    required int postId,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/posts/$postId/video');
    final request = http.MultipartRequest('POST', uri);
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _api.throwIfError(response);
    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> likePost(int postId) async {
    final r = await _api.post('/posts/$postId/like');
    _api.throwIfError(r);
  }

  Future<void> unlikePost(int postId) async {
    final r = await _api.delete('/posts/$postId/like');
    _api.throwIfError(r);
  }

  Future<void> savePost(int postId) async {
    final r = await _api.post('/posts/$postId/save');
    _api.throwIfError(r);
  }

  Future<void> unsavePost(int postId) async {
    final r = await _api.delete('/posts/$postId/save');
    _api.throwIfError(r);
  }

  Future<List<PostComment>> fetchComments(int postId) async {
    final r = await _api.get('/posts/$postId/comments', auth: false);
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    final items = data['items'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => PostComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PostComment> addComment(int postId, String body) async {
    final r = await _api.post('/posts/$postId/comments', body: {'body': body});
    _api.throwIfError(r);
    return PostComment.fromJson(_api.decodeJson(r));
  }

  Future<List<StoryGroup>> fetchStories() async {
    final r = await _api.get('/stories');
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    final groups = data['groups'];
    if (groups is! List) return [];
    return groups
        .whereType<Map>()
        .map((e) => StoryGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<StoryItem> createStory({
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/stories');
    final request = http.MultipartRequest('POST', uri);
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _api.throwIfError(response);
    return StoryItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> markStoryViewed(int storyId) async {
    final r = await _api.post('/stories/$storyId/view');
    _api.throwIfError(r);
  }

  Future<List<Map<String, dynamic>>> fetchDiscoverReels({int limit = 30}) async {
    final r = await _api.get('/discover/reels', query: {'limit': '$limit'}, auth: false);
    _api.throwIfError(r);
    final data = _api.decodeJson(r);
    final items = data['items'];
    if (items is! List) return [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
