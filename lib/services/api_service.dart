import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${AppConstants.apiUrl}$url';
  }

  Future<dynamic> get(String url) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse(_normalizeUrl(url)), headers: headers);
    return _processResponse(response);
  }

  Future<dynamic> post(String url, dynamic body) async {
    print('ApiService: POST request to $url');
    print('ApiService: AppConstants.apiUrl = ${AppConstants.apiUrl}');
    final normalizedUrl = _normalizeUrl(url);
    print('ApiService: Normalized URL = $normalizedUrl');
    
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse(normalizedUrl),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String url, dynamic body) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> postMultipart(String url, Map<String, String> fields, {http.MultipartFile? file}) async {
    print('ApiService: POST MULTIPART request to $url');
    final normalizedUrl = _normalizeUrl(url);
    
    final request = http.MultipartRequest('POST', Uri.parse(normalizedUrl));
    
    // Add headers (Authorization)
    final headers = await getHeaders();
    if (headers.containsKey('Authorization')) {
      request.headers['Authorization'] = headers['Authorization']!;
    }
    // Content-Type is set automatically to multipart/form-data by MultipartRequest

    request.fields.addAll(fields);
    if (file != null) {
      request.files.add(file);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  Future<dynamic> delete(String url) async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP Error: ${response.statusCode} ${response.body}');
    }
  }
}
