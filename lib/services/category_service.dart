import '../models/category.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '${AppConstants.apiUrl}/categories';

  Future<List<Category>> getAll() async {
    final resp = await _apiService.get('$_baseUrl/all');
    if (resp is List) {
      return resp.map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  Future<Category> create(Map<String, dynamic> payload) async {
    final resp = await _apiService.post('$_baseUrl/create', payload);
    return Category.fromJson(Map<String, dynamic>.from(resp as Map));
  }

  Future<Category> update(int id, Map<String, dynamic> payload) async {
    final resp = await _apiService.put('$_baseUrl/update/$id', payload);
    return Category.fromJson(Map<String, dynamic>.from(resp as Map));
  }

  Future<void> delete(int id) async {
    await _apiService.delete('$_baseUrl/delete/$id');
  }
}
