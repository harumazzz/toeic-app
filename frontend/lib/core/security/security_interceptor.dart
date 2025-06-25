import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../injection_container.dart';
import '../storage/secure_storage_service.dart';
import 'advanced_security_client.dart';

part 'security_interceptor.g.dart';

@Riverpod(keepAlive: true)
SecurityInterceptor securityInterceptor(final Ref ref) {
  final secureStorageService = InjectionContainer.get<SecureStorageService>();
  return SecurityInterceptor(secureStorageService);
}

class SecurityInterceptor extends Interceptor {
  const SecurityInterceptor(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  @override
  Future<void> onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) async {
    try {
      debugPrint('[SecurityInterceptor] Checking path: ${options.path}');
      if (_shouldBypassSecurity(options.path)) {
        debugPrint(
          '[SecurityInterceptor] Bypassing security for: ${options.path}',
        );
        return super.onRequest(options, handler);
      }

      debugPrint(
        '[SecurityInterceptor] Adding security headers for: ${options.path}',
      );
      options.headers['Origin'] = 'flutter-app://toeic-app';
      options.headers['Referer'] = 'flutter-app://toeic-app/';
      final secretKey = await _getSecretKey();
      if (secretKey != null && secretKey.isNotEmpty) {
        final securityClient = AdvancedSecurityClient(
          secretKey: secretKey,
          debug: true,
        );

        final securityHeaders = await securityClient.generateSecurityHeaders(
          options.method,
          options.path,
          additionalData: _getAdditionalData(options),
        );

        options.headers.addAll(securityHeaders);
        debugPrint(
          '[SecurityInterceptor] Add ${securityHeaders.length} security header',
        );
      } else {
        debugPrint('[SecurityInterceptor] No security key available');
      }
    } catch (error) {
      debugPrint('[SecurityInterceptor] Error adding security headers: $error');
    }

    return super.onRequest(options, handler);
  }

  bool _shouldBypassSecurity(final String path) {
    const bypassPaths = [
      '/health',
      '/metrics',
      '/api/auth/login',
      '/api/auth/register',
      '/swagger',
      '/api/v1/grammars',
      '/api/v1/performance',
    ];
    for (final bypassPath in bypassPaths) {
      if (path.startsWith(bypassPath)) {
        return true;
      }
    }
    return false;
  }

  Future<String?> _getSecretKey() async {
    try {
      return await _secureStorageService.getSecurityKey();
    } catch (error) {
      debugPrint('[SecurityInterceptor] Error getting security key: $error');
      return null;
    }
  }

  Map<String, dynamic> _getAdditionalData(final RequestOptions options) {
    final additionalData = <String, dynamic>{};
    if (_isSensitiveEndpoint(options.path)) {
      additionalData['sensitive'] = true;
    }
    additionalData['method'] = options.method;
    if (options.contentType != null) {
      additionalData['contentType'] = options.contentType;
    }
    return additionalData;
  }

  bool _isSensitiveEndpoint(final String path) {
    const sensitiveEndpoints = [
      '/api/auth/',
      '/api/v1/users/me',
      '/api/v1/admin/',
      '/api/v1/backups/',
    ];

    for (final sensitiveEndpoint in sensitiveEndpoints) {
      if (path.contains(sensitiveEndpoint)) {
        return true;
      }
    }
    return false;
  }
}
