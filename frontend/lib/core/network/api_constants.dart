class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'http://192.168.31.37:8000/v1';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String logout = '/auth/logout';
  static const String user = '/user';
  static const String changePassword = '/user/change-password';
}
