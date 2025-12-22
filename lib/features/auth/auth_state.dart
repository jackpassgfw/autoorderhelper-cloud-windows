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

  AuthState copyWith({
    String? token,
    int? userId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      token: token ?? this.token,
      userId: userId ?? this.userId,
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
