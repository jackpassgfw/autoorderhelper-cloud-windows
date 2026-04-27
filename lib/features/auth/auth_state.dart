class AuthState {
  const AuthState({
    required this.token,
    required this.userId,
    required this.isLoading,
    required this.errorMessage,
  });

  final String? token;
  final int? userId;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  static const _unset = Object();

  AuthState copyWith({
    Object? token = _unset,
    Object? userId = _unset,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      token: token == _unset ? this.token : token as String?,
      userId: userId == _unset ? this.userId : userId as int?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.initial() {
    return const AuthState(
      token: null,
      userId: null,
      isLoading: false,
      errorMessage: null,
    );
  }
}
