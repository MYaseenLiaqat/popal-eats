import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_client.dart';

class MenuService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> importMenu({
    required int restaurantId,
    required int defaultCategoryId,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/menu/import?restaurant_id=$restaurantId&default_category_id=$defaultCategoryId',
    );
    final request = http.MultipartRequest('POST', uri);
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
    );

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _api.throwIfError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
