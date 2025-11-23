import '../models/product.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '${AppConstants.apiUrl}/products';

  Future<List<Product>> getAll() async {
    final response = await _apiService.get(_baseUrl);
    if (response is List) {
      return response.map((json) => Product.fromJson(json)).toList();
    }
    return [];
  }

  Future<Product> getById(int id) async {
    final response = await _apiService.get('$_baseUrl/$id');
    return Product.fromJson(response);
  }
}
