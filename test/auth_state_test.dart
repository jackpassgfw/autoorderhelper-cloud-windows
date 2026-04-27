import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/auth/auth_state.dart';

void main() {
  test('AuthState.copyWith can clear token', () {
    final state = AuthState.initial().copyWith(token: 'token');

    final cleared = state.copyWith(token: null);

    expect(cleared.token, isNull);
    expect(cleared.isAuthenticated, isFalse);
  });

  test('AuthState.copyWith keeps token when omitted', () {
    final state = AuthState.initial().copyWith(token: 'token');

    final unchanged = state.copyWith(isLoading: true);

    expect(unchanged.token, 'token');
    expect(unchanged.isAuthenticated, isTrue);
  });
}
