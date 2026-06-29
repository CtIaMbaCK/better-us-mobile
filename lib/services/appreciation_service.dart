import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/services/auth_service.dart';

class AppreciationService {
  final String baseUrl =
      "https://frettiest-ariella-unnationally.ngrok-free.dev/api/v1";
  final AuthService _authService = AuthService();

  /// Gửi lời cảm ơn cho tình nguyện viên
  Future<bool> sendAppreciation(String activityId, String targetId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        print('❌ Không có token');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/feedback/appreciation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'activityId': activityId,
          'targetId': targetId,
        }),
      );

      print('Gửi cảm ơn cho activity: $activityId, target: $targetId');
      print('Response: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Response body: ${response.body}');
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi gửi appreciation: $e');
      return false;
    }
  }

  /// Kiểm tra đã gửi cảm ơn chưa bằng cách thử lấy danh sách appreciation của user
  Future<bool> hasAppreciated(String activityId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return false;

      // Backend không có endpoint check riêng, nên ta lấy danh sách và tìm
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/my-appreciations'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List appreciations = jsonDecode(response.body);
        return appreciations.any((item) =>
          item['activity'] != null && item['activity']['id'] == activityId
        );
      }
      return false;
    } catch (e) {
      print('Lỗi kiểm tra appreciation: $e');
      return false;
    }
  }
}
