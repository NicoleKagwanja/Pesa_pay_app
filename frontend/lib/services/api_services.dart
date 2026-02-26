// ignore_for_file: library_prefixes, no_leading_underscores_for_library_prefixes
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as _httpClient;
import 'package:intl/intl.dart';

class APIService {
  static String get baseURL {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else {
      return 'http://10.0.2.2:8000/api/v1';
    }
  }

  APIService._();
  static final APIService _instance = APIService._();
  factory APIService() => _instance;

  static const Duration _timeout = Duration(seconds: 10);
  Map<String, String> get headers => {'Content-Type': 'application/json'};

  Future<T> _makeRequest<T>(
    Future<http.Response> requestFuture,
    T Function(Map<String, dynamic>) onSuccess, {
    T Function(dynamic error)? onError,
  }) async {
    try {
      final response = await requestFuture.timeout(_timeout);
      final body = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return onSuccess(body);
      } else {
        final message =
            body['message'] ??
            body['error'] ??
            (body['detail'] is String
                ? body['detail']
                : 'Check request data') ??
            'Request failed';
        throw Exception('HTTP ${response.statusCode}: $message');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException {
      throw Exception('Invalid data format received. Server error.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Failed to parse response: Invalid JSON');
    } on TypeError {
      throw Exception('Failed to parse response: Unexpected data type');
    }
  }

  Future<void> registerUser(Map<String, dynamic> userData) async {
    final uri = Uri.parse('$baseURL/signup');
    await _makeRequest<void>(
      http.post(uri, headers: headers, body: jsonEncode(userData)),
      (_) {},
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseURL/login');
    return _makeRequest<Map<String, dynamic>>(
      http.post(
        uri,
        headers: headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
      (body) => body,
    );
  }

  Future<Map<String, dynamic>> getEmployeeByEmail(String email) async {
    final uri = Uri.parse('$baseURL/employee/$email');
    return _makeRequest<Map<String, dynamic>>(
      http.get(uri, headers: headers),
      (body) => body,
    );
  }

  @Deprecated('Use getEmployeeByEmail instead')
  Future<Map<String, dynamic>> getProfile(String email) =>
      getEmployeeByEmail(email);

  Future<Map<String, dynamic>> logAttendance({
    required String email,
    String? timeIn,
    String? timeOut,
  }) async {
    final uri = Uri.parse('$baseURL/attendance/log');
    return _makeRequest<Map<String, dynamic>>(
      http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          "employee_email": email,
          if (timeIn != null) "time_in": timeIn,
          if (timeOut != null) "time_out": timeOut,
        }),
      ),
      (body) => body,
    );
  }

  Future<Map<String, dynamic>> getAttendance(String email) async {
    final uri = Uri.parse('$baseURL/attendance/$email');
    return _makeRequest<Map<String, dynamic>>(
      http.get(uri, headers: headers),
      (body) => body,
    );
  }

  Future<Map<String, dynamic>> getAttendanceSummary(String email) async {
    final uri = Uri.parse('$baseURL/attendance/summary/$email');
    return _makeRequest<Map<String, dynamic>>(
      http.get(uri, headers: headers),
      (body) => body,
      onError: (error) {
        if (error.toString().contains('404')) {
          return {
            "employee_email": email,
            "total_hours": 0,
            "days_worked": 0,
            "summary": "No attendance records found.",
          };
        }
        throw error;
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final uri = Uri.parse('$baseURL/admin/employees');
    return _makeRequest<List<Map<String, dynamic>>>(
      http.get(uri, headers: headers),
      (body) => (body as List).map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getAttendanceReport() async {
    final uri = Uri.parse('$baseURL/admin/attendance/report');
    return _makeRequest<List<Map<String, dynamic>>>(
      http.get(uri, headers: headers),
      (body) => (body as List).map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    final uri = Uri.parse('$baseURL/admin/calendar/events');
    return _makeRequest<List<Map<String, dynamic>>>(
      http.get(uri, headers: headers),
      (body) => (body as List).map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  Future<Map<String, dynamic>> addCalendarEvent({
    required String title,
    required String date,
    required String type,
    String? description,
  }) async {
    final uri = Uri.parse('$baseURL/admin/calendar/events');
    return _makeRequest<Map<String, dynamic>>(
      http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'title': title,
          'date': date,
          'type': type,
          if (description != null) 'description': description,
        }),
      ),
      (body) => body,
    );
  }

  Future<List<dynamic>> getAttendanceRecords(String email) async {
    final response = await _httpClient.get(
      Uri.parse('/attendance/records/$email'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load attendance records');
  }

  Future<Map<String, dynamic>> disburseSalaries() async {
    final uri = Uri.parse('$baseURL/payments/disburse');
    return _makeRequest<Map<String, dynamic>>(
      http.post(uri, headers: headers),
      (body) => body,
    );
  }

  Future<List<dynamic>> getPublicHolidays() async {
    final response = await http.get(Uri.parse('$baseURL/holidays'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load holidays');
    }
  }

  Future<Map<String, dynamic>> getAttendanceDayDetails(
    String email,
    String dateStr,
  ) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseURL/attendance/day/$email/$dateStr'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load day details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> calculateSalary({
    required String email,
    required String month,
    required double hourlyRate,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseURL/salary/calculate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_email': email,
        'month': month,
        'hourly_rate': hourlyRate,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to calculate salary: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getSalaryHistory(String email) async {
    final response = await _httpClient.get(
      Uri.parse('$baseURL/salary/history/$email'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load salary history: ${response.statusCode}');
  }

  Future<List<dynamic>> getAdminEmployees() async {
    final response = await _httpClient.get(
      Uri.parse('$baseURL/admin/employees'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load employees: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAdminAttendanceOverview() async {
    final response = await _httpClient.get(
      Uri.parse('$baseURL/admin/attendance/overview'),
    );

    if (response.statusCode == 00) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load overview: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAdminEmployeeAttendance(
    String email, {
    String? date,
  }) async {
    final uri = date != null
        ? Uri.parse('$baseURL/admin/employees/$email/attendance?date=$date')
        : Uri.parse('$baseURL/admin/employees/$email/attendance');

    final response = await _httpClient.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load attendance: ${response.statusCode}');
  }

  Future<List<dynamic>> getSharedEvents({
    String? month,
    String? department,
  }) async {
    final params = <String, String>{};
    if (month != null) params['month'] = month;
    if (department != null) params['department'] = department;

    final uri = Uri.parse(
      '$baseURL/admin/events',
    ).replace(queryParameters: params);
    final response = await _httpClient.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load events: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createSharedEvent({
    required String adminEmail,
    required String title,
    String? description,
    required DateTime eventDate,
    required String eventType,
    String? targetDepartment,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseURL/admin/events?admin_email=$adminEmail'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'event_date': DateFormat('yyyy-MM-dd').format(eventDate),
        'event_type': eventType,
        'target_department': targetDepartment,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create event: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> deleteSharedEvent(
    int eventId,
    String adminEmail,
  ) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseURL/admin/events/$eventId?admin_email=$adminEmail'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to delete event: ${response.statusCode}');
  }
}
