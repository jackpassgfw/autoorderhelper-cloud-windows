import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/foundation.dart';

import '../config/providers.dart';

/// ===== Token Store =====
class TokenStore {
  const TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'access_token';

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  Future<void> clear() => _storage.delete(key: _kAccessToken);
}

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(const FlutterSecureStorage());
});

/// ===== Session expired event (decoupled) =====
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// ===== Dio Client =====
final apiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readAccessToken();
        final hasToken = token != null && token.isNotEmpty;

        if (hasToken) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }

        // debugPrint('onRequest: ➡️ ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        final code = error.response?.statusCode;
        final loc = error.response?.headers.value('location');
        debugPrint(
          '[ERR] $code ${error.requestOptions.uri} location=${loc ?? "-"}',
        );

        if (code == 401 || code == 403) {
          ref.read(sessionExpiredProvider.notifier).state++;
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});

String normalizeErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['detail'] is String) {
    return data['detail'] as String;
  }
  if (data is Map && data['detail'] is List) {
    final details = data['detail'] as List;
    if (details.isNotEmpty) {
      final first = details.first;
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
      return details.first.toString();
    }
  }
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  if (data is String && data.trim().isNotEmpty) {
    return data;
  }
  final code = error.response?.statusCode;
  if (code != null) {
    return 'Request failed (HTTP $code)';
  }
  return error.message ?? 'Unexpected error';
}
