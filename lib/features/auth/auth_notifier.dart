import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final dio = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  final notifier = AuthNotifier(
    repository: AuthRepository(dio),
    tokenStore: tokenStore,
  );

  // 监听 session 过期事件（解耦）
  ref.listen<int>(sessionExpiredProvider, (prev, next) async {
    if (prev != null && next != prev) {
      await notifier.handleUnauthorized();
    }
  });

  notifier.restoreSession();
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required AuthRepository repository,
    required TokenStore tokenStore,
  }) : _repository = repository,
       _tokenStore = tokenStore,
       super(AuthState.initial());

  final AuthRepository _repository;
  final TokenStore _tokenStore;

  Future<void> restoreSession() async {
    final token = await _tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(token: token);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repository.login(email: email, password: password);

      await _tokenStore.writeAccessToken(session.accessToken);

      state = state.copyWith(token: session.accessToken, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(e),
      );
    }
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    state = AuthState.initial();
  }

  Future<void> handleUnauthorized() async {
    await _tokenStore.clear();
    state = state.copyWith(
      token: null,
      errorMessage: 'Session expired. Please log in again.',
    );
  }
}
