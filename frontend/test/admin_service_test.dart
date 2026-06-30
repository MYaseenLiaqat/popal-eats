import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:popal_eats/services/api_client.dart';

void main() {
  group('Admin pending accounts parsing', () {
    test('decodeList parses JSON array from pending endpoint', () {
      final client = ApiClient.instance;
      final response = http.Response(
        jsonEncode([
          {'user_id': 1, 'role': 'restaurant', 'email': 'a@example.com'},
          {'user_id': 2, 'role': 'home_chef', 'email': 'b@example.com'},
        ]),
        200,
      );

      final list = client.decodeList(response);
      expect(list, hasLength(2));
      expect(list.first['user_id'], 1);
    });

    test('decodeJson fails on array (documents the original bug)', () {
      final client = ApiClient.instance;
      final response = http.Response('[{"user_id":1}]', 200);
      expect(() => client.decodeJson(response), throwsA(isA<TypeError>()));
    });
  });
}
