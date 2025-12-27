import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/customers_state.dart';

void main() {
  test('CustomersState.copyWith can clear businessCenterFilter', () {
    final state = CustomersState.initial().copyWith(businessCenterFilter: 12);

    final cleared = state.copyWith(businessCenterFilter: null);

    expect(cleared.businessCenterFilter, isNull);
  });

  test('CustomersState.copyWith keeps businessCenterFilter when omitted', () {
    final state = CustomersState.initial().copyWith(businessCenterFilter: 7);

    final unchanged = state.copyWith(search: 'abc');

    expect(unchanged.businessCenterFilter, 7);
  });
}
