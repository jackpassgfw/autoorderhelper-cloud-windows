import 'package:dio/dio.dart';

class AuthSession {
  AuthSession({required this.accessToken, required this.userId});

  final String accessToken;
  final int? userId;
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    // ⚠️ 路径按你后端实际 auth 路由为准
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = res.data;

    // 兼容常见返回结构：{"access_token": "...", "user_id": 1}
    final accessToken = (data['access_token'] ?? data['token']) as String?;
    final userId = data['user_id'] as int?;

    if (accessToken == null || accessToken.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'Login response missing access_token',
        type: DioExceptionType.badResponse,
      );
    }

    return AuthSession(accessToken: accessToken, userId: userId);
  }
}
