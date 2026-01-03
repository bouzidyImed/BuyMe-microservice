import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (includeAuth && token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
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

  Future<dynamic> post(String url, dynamic body, {bool includeAuth = true}) async {
    print('ApiService: POST request to $url');
    print('ApiService: AppConstants.apiUrl = ${AppConstants.apiUrl}');
    final normalizedUrl = _normalizeUrl(url);
    print('ApiService: Normalized URL = $normalizedUrl');
    
    final headers = await getHeaders(includeAuth: includeAuth);
    headers['Content-Type'] = 'application/json';
    print('ApiService: Request headers: $headers');
    print('ApiService: Request body: ${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(normalizedUrl),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String url, dynamic body, {bool includeAuth = true}) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    headers['Content-Type'] = 'application/json';
    final normalizedUrl = _normalizeUrl(url);
    print('ApiService: PUT $normalizedUrl');
    print('ApiService: Request headers: $headers');
    print('ApiService: Request body: ${jsonEncode(body)}');
    final response = await http.put(
      Uri.parse(normalizedUrl),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> postMultipart(String url, Map<String, String> fields, {http.MultipartFile? file, List<http.MultipartFile>? files, String? fileFieldName, bool includeAuth = true}) async {
    print('ApiService: POST MULTIPART request to $url');
    final normalizedUrl = _normalizeUrl(url);
    final request = http.MultipartRequest('POST', Uri.parse(normalizedUrl));

    // Add headers (Authorization + others)
    final headers = await getHeaders(includeAuth: includeAuth);
    request.headers.addAll(headers);
    // MultipartRequest will set proper Content-Type including boundary

    request.fields.addAll(fields);
    
    // Support multiple files with custom field name (e.g., 'images')
    if (files != null && files.isNotEmpty) {
      // Files created with MultipartFile.fromBytes already have the field name set
      // If fileFieldName is provided and different, we need to recreate them
      if (fileFieldName != null) {
        for (var f in files) {
          // For files created with fromBytes, we can read the bytes directly
          // But we need to get them from the stream - this is complex
          // Instead, we'll rely on the caller to create files with correct field name
          // For now, add them directly - the field name should be set when created
          request.files.add(f);
        }
      } else {
        // Add files directly - they should have correct field name from creation
        request.files.addAll(files);
      }
    } else if (file != null) {
      // Single file support (backward compatibility)
      request.files.add(file);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('ApiService: Multipart response status: ${response.statusCode}');
    print('ApiService: Multipart response body: ${response.body}');
    return _processResponse(response);
  }

  Future<dynamic> delete(String url, {bool includeAuth = true}) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    final normalizedUrl = _normalizeUrl(url);
    final response = await http.delete(Uri.parse(normalizedUrl), headers: headers);
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
