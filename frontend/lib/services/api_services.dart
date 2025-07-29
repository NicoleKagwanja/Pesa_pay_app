import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';

class APIService {
  static const String baseURL = "http://10.0.2.2:8000/api";

  APIService._();

  static final APIService _instance = APIService._();

  factory APIService() => _instance;

  static const Duration _timeout = Duration(seconds: 60);

  Map<String, String> get headers => {'Content-Type': 'application/json'};

  Future<T> _makeRequest<T>(
    Future<http.Response> request,
    T Function(Map<String, dynamic>) onSuccess,
  ) async {
    try {
      final response = await request.timeout(_timeout);

      developer.log(
        'API Response: ${response.statusCode} - ${response.body}',
        name: 'APIService',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        return onSuccess(body);
      } else if (response.statusCode == 404) {
        throw Exception('Request failed: Resource not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Check your credentials');
      } else {
        throw Exception(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid data received. Please try again.');
    } on Exception catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> registerUser(Map<String, dynamic> userData) async {
    final uri = Uri.parse('$baseURL/signup');
    await _makeRequest<void>(
      http.post(uri, headers: headers, body: json.encode(userData)),
      (_) {},
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseURL/login');
    return _makeRequest<Map<String, dynamic>>(
      http.post(
        uri,
        headers: headers,
        body: json.encode({"email": email, "password": password}),
      ),
      (body) => body,
    );
  }

  Future<Map<String, dynamic>> getEmployeeByEmail(String email) async {
    final uri = Uri.parse('$baseURL/employee/$email');
    return _makeRequest<Map<String, dynamic>>(http.get(uri), (body) => body);
  }

  Future<Map<String, dynamic>> calculateSalary(String email) async {
    final uri = Uri.parse('$baseURL/salary/calculate/$email');
    return _makeRequest<Map<String, dynamic>>(http.get(uri), (body) => body);
  }

  Future<Map<String, dynamic>> getAttendance(String email) async {
    final uri = Uri.parse('$baseURL/attendance/$email');
    return _makeRequest<Map<String, dynamic>>(http.get(uri), (body) => body);
  }

  Future<Map<String, dynamic>> getActivityCalendar(String email) async {
    final uri = Uri.parse('$baseURL/activity/calendar/$email');
    return _makeRequest<Map<String, dynamic>>(http.get(uri), (body) => body);
  }

  Future<void> requestOffWeek(
    String email,
    String startDate,
    String endDate,
  ) async {
    final uri = Uri.parse('$baseURL/off-week/request');
    await _makeRequest<void>(
      http.post(
        uri,
        headers: headers,
        body: json.encode({
          "employee_email": email,
          "start_date": startDate,
          "end_date": endDate,
        }),
      ),
      (_) {},
    );
  }
}
