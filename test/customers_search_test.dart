import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/customers_notifier.dart';
import 'package:app/features/customers/customers_repository.dart';
import 'package:app/features/customers/models.dart';

class _FakeCustomersRepository extends CustomersRepository {
  _FakeCustomersRepository(this._customers) : super(Dio());

  final List<Customer> _customers;

  @override
  Future<List<Customer>> fetchAllCustomers({
    int pageSize = 200,
    MemberStatus? memberStatus,
    int? businessCenterId,
    String? ordering,
  }) async => [..._customers];
}

Customer _customer(
  int id,
  String name, {
  String phone = '0400000000',
  String? sponsor,
  String? email,
}) {
  return Customer(
    id: id,
    name: name,
    phone: phone,
    memberStatus: MemberStatus.unknown,
    businessCenterSide: BusinessCenterSide.unknown,
    sponsor: sponsor,
    email: email,
  );
}

void main() {
  late CustomersNotifier notifier;

  setUp(() {
    notifier = CustomersNotifier(
      _FakeCustomersRepository([
        _customer(1, 'Alice Shi', phone: '0424296601', sponsor: 'Jack'),
        // Letters of "alice" appear in order across this record, so the old
        // subsequence matching wrongly returned it.
        _customer(
          2,
          'Angela Lin Chen',
          phone: '0414818119',
          sponsor: 'wang li',
          email: 'x@example.com',
        ),
        _customer(3, 'Bob Jiang', phone: '0417211278', sponsor: 'Wang Li'),
      ]),
    );
  });

  tearDown(() => notifier.dispose());

  List<String> names() => notifier.state.items.map((e) => e.name).toList();

  test('search only returns customers that contain the search text', () async {
    notifier.updateSearch('alice');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(names(), ['Alice Shi']);
    expect(notifier.state.meta.total, 1);
  });

  test('search with no match returns an empty list', () async {
    notifier.updateSearch('zzz');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(names(), isEmpty);
    expect(notifier.state.meta.total, 0);
  });

  test('every search word must match, case-insensitively', () async {
    notifier.updateSearch('ANGELA chen');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(names(), ['Angela Lin Chen']);

    notifier.updateSearch('angela jiang');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(names(), isEmpty);
  });

  test('sponsor filter is a strict substring match', () async {
    notifier.updateSponsorFilter('wang');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(names(), ['Angela Lin Chen', 'Bob Jiang']);

    // "wnl" is a subsequence of "wang li" but not a substring.
    notifier.updateSponsorFilter('wnl');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(names(), isEmpty);
  });
}
