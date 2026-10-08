import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password.trim(),
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 401) {
        final m = jsonDecode(response.body) as Map<String, dynamic>;
        if (m['parent_id'] != null && m['parent_id'] is num) {
          m['parent_id'] = (m['parent_id'] as num).toInt();
        }
        return m;
      } else {
        return {
          'success': false,
          'message': 'خطأ في الاتصال: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالخادم. تأكد من تشغيل Backend على http://localhost:5000',
      };
    }
  }
  
  static Future<Map<String, dynamic>> analyzeText(
    String text,
    int userId, {
    int? childId,
    String? childName,
    bool saveOnly = false,
    String? sourceApp,
  }) async {
    try {
      final body = <String, dynamic>{
        'text': text,
        'user_id': userId,
        'child_id': childId,
        'child_name': childName ?? '',
        'save_only': saveOnly,
      };
      if (sourceApp != null && sourceApp.isNotEmpty) {
        body['source_app'] = sourceApp;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getAlerts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getContentLogs(int userId, {int? childId, String? childName}) async {
    try {
      String url = '$baseUrl/content_logs?user_id=$userId';
      if (childId != null) {
        url += '&child_id=$childId';
      } else if (childName != null && childName.isNotEmpty) {
        url += '&child_name=$childName';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> deleteContentLog(int logId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/content_logs/$logId?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getChildren(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> updateAlertStatus(int alertId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/alerts/$alertId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> addChild(int userId, String name, {int? age}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/children'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'age': age,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> deleteChild(int childId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/children/$childId?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getStatistics(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/statistics?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getMonitoringStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/monitoring/status?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile(int userId,
      {String? displayName, String? email, String? phone}) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> analyzeMedia(String url, int userId,
      {String mediaType = 'video', int? childId, String? childName, bool saveOnly = false, String? sourceApp}) async {
    try {
      final body = <String, dynamic>{
        'url': url,
        'media_type': mediaType,
        'user_id': userId,
        'child_id': childId,
        'child_name': childName ?? '',
        'save_only': saveOnly,
      };
      if (sourceApp != null && sourceApp.isNotEmpty) {
        body['source_app'] = sourceApp;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_media'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> reportFalsePositive(int logId, int userId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/false_positives'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'log_id': logId,
          'user_id': userId,
          'reason': reason,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
}
