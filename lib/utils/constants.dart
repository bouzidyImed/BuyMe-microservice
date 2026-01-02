import 'package:flutter/foundation.dart';

class AppConstants {
  // Use 10.0.2.2 for Android emulator to access host localhost
  // Use localhost for Web or iOS simulator
  static String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:8081/api';
    }
    return 'http://10.0.2.2:8081/api';
  }
  
  static String get profilePicBaseUrl => '$apiUrl/uploads/profiles-pics';

  // Product images are served from the backend uploads location.
  // This produces e.g. http://localhost:8081/api/uploads/products
  static String get productImageBaseUrl => '$apiUrl/uploads/products';
}
