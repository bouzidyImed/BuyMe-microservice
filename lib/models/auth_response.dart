class LoginResponse {
  final String? token;
  final List<String>? roles;
  final String message;

  LoginResponse({
    this.token,
    this.roles,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
      message: json['message'] ?? '',
    );
  }
}

class RegisterResponse {
  final List<String>? roles;
  final String message;

  RegisterResponse({
    this.roles,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
      message: json['message'] ?? '',
    );
  }
}
