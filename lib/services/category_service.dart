import '../models/category.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '${AppConstants.apiUrl}/categories';

  Future<List<Category>> getAll() async {
    final resp = await _apiService.get(_baseUrl);
    if (resp is List) {
      return resp.map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }
}
