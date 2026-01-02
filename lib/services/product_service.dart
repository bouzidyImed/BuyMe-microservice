import '../models/product.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '${AppConstants.apiUrl}/products';

  String _buildImageUrl(String? img) {
    if (img == null || img.isEmpty) return '';
    final lower = img.toLowerCase();
    // If already an absolute URL or data URI, return as-is
    if (lower.startsWith('http') || lower.startsWith('data:')) return img;

    // Otherwise build a URL pointing to backend uploads. AppConstants.productImageBaseUrl
    return '${AppConstants.productImageBaseUrl}/$img';
  }

  Future<List<Product>> getAll() async {
    final response = await _apiService.get(_baseUrl);
    if (response is List) {
      return response.map((json) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(json as Map);
        String preview = '';
        if (m.containsKey('image') && (m['image'] as String?)?.isNotEmpty == true) {
          preview = m['image'] as String;
        } else if (m.containsKey('images') && m['images'] is List && (m['images'] as List).isNotEmpty) {
          final first = (m['images'] as List).first;
          preview = first is String ? first : (first?.toString() ?? '');
        }
        m['image'] = _buildImageUrl(preview);
        return Product.fromJson(m);
      }).toList();
    }
    return [];
  }

  Future<Product> getById(int id) async {
    final response = await _apiService.get('$_baseUrl/$id');
    final Map<String, dynamic> m = Map<String, dynamic>.from(response as Map);
    String preview = '';
    if (m.containsKey('image') && (m['image'] as String?)?.isNotEmpty == true) {
      preview = m['image'] as String;
    } else if (m.containsKey('images') && m['images'] is List && (m['images'] as List).isNotEmpty) {
      final first = (m['images'] as List).first;
      preview = first is String ? first : (first?.toString() ?? '');
    }
    m['image'] = _buildImageUrl(preview);
    return Product.fromJson(m);
  }

  Future<Product> create(Map<String, String> fields, {String? filePath, String? fileFieldName}) async {
    // fileFieldName default to 'file' used by backend
    final Map<String, String> f = Map.from(fields);
    final resp = await _apiService.postMultipart(_baseUrl, f, file: null);
    final Map<String, dynamic> m = Map<String, dynamic>.from(resp as Map);
    m['image'] = _buildImageUrl(m['image'] as String?);
    return Product.fromJson(m);
  }

  Future<Product> createWithFile(Map<String, String> fields, dynamic multipartFile) async {
    // multipartFile should be an instance of http.MultipartFile
    final resp = await _apiService.postMultipart(_baseUrl, fields, file: multipartFile);
    final Map<String, dynamic> m = Map<String, dynamic>.from(resp as Map);
    m['image'] = _buildImageUrl(m['image'] as String?);
    return Product.fromJson(m);
  }

  Future<Product> update(int id, Map<String, dynamic> payload) async {
    final resp = await _apiService.put('$_baseUrl/$id', payload);
    final Map<String, dynamic> m = Map<String, dynamic>.from(resp as Map);
    m['image'] = _buildImageUrl(m['image'] as String?);
    return Product.fromJson(m);
  }

  Future<void> delete(int id) async {
    await _apiService.delete('$_baseUrl/$id');
  }
}
