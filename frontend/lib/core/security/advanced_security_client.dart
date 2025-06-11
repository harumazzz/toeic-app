import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class AdvancedSecurityClient {
  AdvancedSecurityClient({
    required final String secretKey,
    final int securityLevel = 2,
    final bool wasmEnabled = true,
    final bool webWorkerEnabled = true,
    final bool debug = false,
  }) : _secretKey = secretKey,
       _securityLevel = securityLevel,
       _wasmEnabled = wasmEnabled,
       _webWorkerEnabled = webWorkerEnabled,
       _debug = debug {
    if (_debug) {
      debugPrint('[AdvancedSecurity] Using secret key: $_secretKey');
      debugPrint('[AdvancedSecurity] Secret key length: ${_secretKey.length}');
    }
  }
  final String _secretKey;
  final int _securityLevel;
  final bool _wasmEnabled;
  final bool _webWorkerEnabled;
  final bool _debug;

  Future<Map<String, String>> generateSecurityHeaders(
    final String method,
    final String path, {
    final Map<String, dynamic> additionalData = const {},
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final nonce = _generateNonce();
    final headers = <String, String>{};
    try {
      headers['X-Request-Timestamp'] = timestamp.toString();
      headers['X-Request-Nonce'] = nonce;
      headers['X-Security-Token'] = await _generateSecurityToken(
        timestamp,
        nonce,
      );
      headers['X-Client-Signature'] = await _generateClientSignature(
        method,
        path,
        timestamp,
      );
      headers['X-Security-Level'] = _securityLevel.toString();
      headers['X-Browser-Fingerprint'] = await _generateBrowserFingerprint();
      headers['X-Origin-Validation'] = await _generateOriginValidation();
      if (_wasmEnabled) {
        headers['X-WASM-Mode'] = await _generateWasmModeHeader();
      }

      if (_webWorkerEnabled) {
        headers['X-Worker-Context'] = await _generateWorkerContextHeader();
      }
      if (additionalData['sensitive'] == true) {
        headers['X-Encrypted-Payload'] = 'true';
      }
      if (_debug) {
        debugPrint(
          '[AdvancedSecurity] Generated headers: ${headers.keys.toList()}',
        );
      }
      return headers;
    } catch (error) {
      if (_debug) {
        debugPrint('[AdvancedSecurity] Error generating headers: $error');
      }
      throw Exception('Failed to generate security headers: $error');
    }
  }

  Future<String> _generateSecurityToken(
    final int timestamp,
    final String nonce,
  ) async {
    final message = '$timestamp.$nonce';
    final signature = await _generateHMACSignature(message);
    return '$message.$signature';
  }

  Future<String> _generateClientSignature(
    final String method,
    final String path,
    final int timestamp,
  ) async {
    final userAgent = _getUserAgent();
    final message = '$method|$path|$timestamp|$userAgent';
    return _generateHMACSignature(message);
  }

  Future<String> _generateBrowserFingerprint() async {
    final components = <String>[];
    try {
      components
        ..add('platform:${defaultTargetPlatform.name}')
        ..add('lang:en-US')
        ..add(kIsWeb ? 'screen:web' : 'screen:mobile')
        ..add('timestamp:${DateTime.now().millisecondsSinceEpoch}');

      final deviceFingerprint = await _generateDeviceFingerprint();
      if (deviceFingerprint.isNotEmpty) {
        components.add('device:$deviceFingerprint');
      }
    } catch (error) {
      if (_debug) {
        debugPrint(
          '[AdvancedSecurity] Error generating fingerprint component: $error',
        );
      }
    }

    final fingerprint = components.join('|');
    return _generateHMACSignature(fingerprint);
  }

  Future<String> _generateDeviceFingerprint() async {
    try {
      final platformInfo =
          '${defaultTargetPlatform.name}_${kDebugMode ? 'debug' : 'release'}';
      return await _simpleHash(platformInfo);
    } catch (error) {
      return 'device-error';
    }
  }

  Future<String> _generateOriginValidation() async {
    String origin = 'flutter-app';

    try {
      if (kIsWeb) {
        origin = 'web-flutter';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        origin = 'android-flutter';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        origin = 'ios-flutter';
      } else {
        origin = 'desktop-flutter';
      }
    } catch (error) {
      origin = 'detection-error';
    }

    final payload = 'origin:$origin:${DateTime.now().millisecondsSinceEpoch}';
    final signature = await _generateHMACSignature(payload);
    if (_debug) {
      debugPrint('[AdvancedSecurity] HMAC payload: $payload');
      debugPrint('[AdvancedSecurity] HMAC signature: $signature');
    }
    return '$payload.$signature';
  }

  Future<String> _generateWasmModeHeader() async {
    final wasmInfo = {
      'version': '1.0',
      'context': 'flutter-wasm',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'features': _getWasmFeatures(),
    };

    final payload = jsonEncode(wasmInfo);
    final base64Payload = base64Encode(utf8.encode(payload));
    final signature = await _generateHMACSignature(base64Payload);

    if (_debug) {
      debugPrint('[AdvancedSecurity] WASM JSON: $payload');
      debugPrint('[AdvancedSecurity] WASM base64: $base64Payload');
      debugPrint('[AdvancedSecurity] WASM signature: $signature');
    }

    return '$base64Payload.$signature';
  }

  Future<String> _generateWorkerContextHeader() async {
    final workerInfo = {
      'type': 'flutter-isolate',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'scope': 'flutter-context',
    };

    final payload = jsonEncode(workerInfo);
    final base64Payload = base64Encode(utf8.encode(payload));
    final signature = await _generateHMACSignature(base64Payload);

    if (_debug) {
      debugPrint('[AdvancedSecurity] Worker JSON: $payload');
      debugPrint('[AdvancedSecurity] Worker base64: $base64Payload');
      debugPrint('[AdvancedSecurity] Worker signature: $signature');
      debugPrint('[AdvancedSecurity] Worker secret key: $_secretKey');
      debugPrint(
        '[AdvancedSecurity] Worker secret key length: ${_secretKey.length}',
      );
    }

    return '$base64Payload.$signature';
  }

  List<String> _getWasmFeatures() {
    final features = <String>[];

    if (kIsWeb) {
      features.add('web-support');
    }
    features
      ..add('dart-runtime')
      ..add('flutter-framework');

    return features;
  }

  Future<String> _generateHMACSignature(final String message) async {
    try {
      final key = utf8.encode(_secretKey);
      final messageBytes = utf8.encode(message);

      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(messageBytes);

      return digest.toString();
    } catch (error) {
      if (_debug) {
        debugPrint('[AdvancedSecurity] HMAC generation error: $error');
      }

      return _simpleHash(_secretKey + message);
    }
  }

  Future<String> _simpleHash(final String str) async {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      final char = str.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & 0xFFFFFFFF;
    }
    return hash.abs().toRadixString(16);
  }

  String _generateNonce() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes
        .map((final byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _getUserAgent() => 'Dart/3.8 (dart:io)';
}
