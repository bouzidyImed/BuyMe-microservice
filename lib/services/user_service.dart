import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '${AppConstants.apiUrl}/auth';

  Future<UserProfile> getCurrentUser() async {
    final response = await _apiService.get('$_baseUrl/me');
    return UserProfile.fromJson(response);
  }

  String resolveProfileImage(String? filename) {
    if (filename == null || filename.isEmpty) {
      return 'assets/img/default-avatar.png'; // Make sure to add this asset
    }
    return '${AppConstants.profilePicBaseUrl}/$filename';
  }
}
