import '../utils/constants.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '${AppConstants.apiUrl}/payments';

  // Match Angular: catch errors and return null instead of throwing
  Future<Map<String, dynamic>?> createPayment(Map<String, dynamic> paymentDto) async {
    try {
      final resp = await _apiService.post(_baseUrl, paymentDto);
      return Map<String, dynamic>.from(resp as Map);
    } catch (err) {
      print('[PaymentService] createPayment error: $err');
      return null; // Return null like Angular does
    }
  }

  // Match Angular: catch errors and return null instead of throwing
  Future<Map<String, dynamic>?> createPaymentWithCard(
    Map<String, dynamic> paymentDto,
    Map<String, dynamic> cardDto,
  ) async {
    try {
      final body = {
        'payment': paymentDto,
        'card': cardDto,
      };
      final resp = await _apiService.post('$_baseUrl/card', body);
      return Map<String, dynamic>.from(resp as Map);
    } catch (err) {
      print('[PaymentService] createPaymentWithCard error: $err');
      return null; // Return null like Angular does
    }
  }

  Future<bool> validateCard(Map<String, dynamic> cardDto) async {
    try {
      await _apiService.post('$_baseUrl/validate-card', cardDto);
      return true;
    } catch (err) {
      print('[PaymentService] validateCard error: $err');
      return false;
    }
  }

  Future<Map<String, dynamic>?> confirmCodPayment(int orderId) async {
    try {
      final resp = await _apiService.post('$_baseUrl/confirm-cod/$orderId', {});
      return Map<String, dynamic>.from(resp as Map);
    } catch (err) {
      print('[PaymentService] confirmCodPayment error: $err');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPayment(int id) async {
    try {
      final resp = await _apiService.get('$_baseUrl/$id');
      return Map<String, dynamic>.from(resp as Map);
    } catch (err) {
      return null;
    }
  }
}

