class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://localhost:8001';

  // Auth endpoints
  static const String login = '/api/auth/login/';
  static const String register = '/api/auth/register/';
  static const String profile = '/api/auth/profile/';
  static const String passwordReset = '/api/auth/password-reset/';
  static const String refreshToken = '/api/auth/token/refresh/';
  static const String validateToken = '/api/auth/token/validate/';
  static const String logout = '/api/auth/logout/';

  
}
