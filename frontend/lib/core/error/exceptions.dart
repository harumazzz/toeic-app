class ServerException implements Exception {
  const ServerException({this.message = 'Server Error'});
  final String message;
}

class CacheException implements Exception {
  const CacheException({this.message = 'Cache Error'});
  final String message;
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'Network Error'});
  final String message;
}

class AuthenticationException implements Exception {
  const AuthenticationException({this.message = 'Authentication Error'});
  final String message;
}
