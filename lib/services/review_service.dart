import '../utils/constants.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '${AppConstants.apiUrl}/reviews';

  Future<List<Map<String, dynamic>>> getByProduct(int productId) async {
    try {
      final resp = await _apiService.get('$_baseUrl/product/$productId');
      if (resp is List) {
        return resp.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addReview(int productId, Map<String, dynamic> payload) async {
    final resp = await _apiService.post('$_baseUrl/product/$productId', payload);
    return Map<String, dynamic>.from(resp as Map);
  }
}

