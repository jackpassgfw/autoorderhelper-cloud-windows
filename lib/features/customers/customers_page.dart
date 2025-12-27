import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'customer_followups_dialog.dart';
import 'customer_form_dialog.dart';
import 'customers_notifier.dart';
import 'customers_repository.dart';
import 'customers_state.dart';
import 'models.dart';
import 'customer_auto_orders_dialog.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _searchController = TextEditingController();
  final _sponsorController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _sponsorDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(customersNotifierProvider.notifier).loadBusinessCenters();
      await ref.read(customersNotifierProvider.notifier).loadCountries();
      await ref.read(customersNotifierProvider.notifier).loadCustomers(page: 1);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _sponsorDebounce?.cancel();
    _sponsorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersNotifierProvider);
    final notifier = ref.watch(customersNotifierProvider.notifier);
    final repository = ref.watch(customersRepositoryProvider);
    final highlightColor = Theme.of(
      context,
    ).colorScheme.primary.withOpacity(0.2);
    final dataTextStyle = Theme.of(context).textTheme.bodyMedium;

    final currentPage = state.meta.page;
    final hasKnownTotal = state.meta.total > 0;
    final hasMore = state.items.length == state.meta.pageSize;
    final totalPages = hasKnownTotal
        ? (state.meta.total / state.meta.pageSize).ceil().clamp(1, 1000000)
        : (hasMore ? currentPage + 1 : currentPage);

    final centerMap = {for (final c in state.businessCenters) c.id: c.name};
    final countryMap = {for (final c in state.countries) c.id: c.name};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customers',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPagination(
                    context,
                    notifier,
                    currentPage,
                    totalPages,
                    state.isLoading,
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        _openCustomerForm(context, centerMap, repository, null),
                    icon: const Icon(Icons.add),
                    label: const Text('New Customer'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilters(context, state, notifier, centerMap),
          const SizedBox(height: 12),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Card(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Country')),
                          DataColumn(label: Text('Member Status')),
                          DataColumn(label: Text('Business Center / Side')),
                          DataColumn(label: Text('USANA ID')),
                          DataColumn(label: Text('Sponsor')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: state.items.map((customer) {
                          final centerAndSide = [
                            centerMap[customer.businessCenterId] ?? '-',
                            businessCenterSideLabel(
                              customer.businessCenterSide,
                            ),
                          ].join('. ');
                          final countryLabel = customer.countryId == null
                              ? '-'
                              : (countryMap[customer.countryId] ??
                                    customer.countryId.toString());
                          final memberStatus = memberStatusLabel(
                            customer.memberStatus,
                          );
                          final sponsorQuery = _mergeQueries(
                            state.search,
                            state.sponsorFilter,
                          );

                          return DataRow(
                            cells: [
                              DataCell(
                                _buildHighlightedText(
                                  customer.name,
                                  state.search,
                                  dataTextStyle,
                                  highlightColor,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  customer.phone,
                                  state.search,
                                  dataTextStyle,
                                  highlightColor,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  countryLabel,
                                  state.search,
                                  dataTextStyle,
                                  highlightColor,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  memberStatus,
                                  state.search,
                                  dataTextStyle,
                                  highlightColor,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  centerAndSide,
                                  state.search,
                                  dataTextStyle,
                                  highlightColor,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  customer.customerUsanaId ?? '-',
                                  state.search,
                                  dataTextStyle,
                                  highlightColor,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  customer.sponsor ?? '-',
                                  sponsorQuery,
                                  dataTextStyle,
                                  highlightColor,
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 190,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        tooltip: 'Follow-ups',
                                        icon: const Icon(
                                          Icons.chat_bubble_outline,
                                        ),
                                        onPressed: () =>
                                            _openFollowups(context, customer),
                                      ),
                                      IconButton(
                                        tooltip: 'View schedules',
                                        icon: const Icon(
                                          Icons.list_alt_outlined,
                                        ),
                                        onPressed: () =>
                                            _openAutoOrders(context, customer),
                                      ),
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _openCustomerForm(
                                          context,
                                          centerMap,
                                          repository,
                                          customer,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () =>
                                            _confirmDelete(context, customer),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _tokenizeQuery(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  String _mergeQueries(String first, String second) {
    final parts = [
      first.trim(),
      second.trim(),
    ].where((value) => value.isNotEmpty).toList();
    return parts.join(' ');
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle? style,
    Color highlightColor,
  ) {
    final tokens = _tokenizeQuery(query);
    if (tokens.isEmpty) {
      return Text(text, style: style);
    }
    final lowerText = text.toLowerCase();
    final ranges = <_HighlightRange>[];
    for (final token in tokens) {
      var start = 0;
      while (start < lowerText.length) {
        final index = lowerText.indexOf(token, start);
        if (index == -1) break;
        ranges.add(_HighlightRange(index, index + token.length));
        start = index + token.length;
      }
    }
    if (ranges.isEmpty) {
      return Text(text, style: style);
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_HighlightRange>[];
    var current = ranges.first;
    for (var i = 1; i < ranges.length; i++) {
      final next = ranges[i];
      if (next.start <= current.end) {
        current = _HighlightRange(
          current.start,
          next.end > current.end ? next.end : current.end,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    final spans = <TextSpan>[];
    var cursor = 0;
    final highlightStyle = (style ?? const TextStyle()).copyWith(
      backgroundColor: highlightColor,
    );
    for (final range in merged) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: highlightStyle,
        ),
      );
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }

  Widget _buildFilters(
    BuildContext context,
    CustomersState state,
    CustomersNotifier notifier,
    Map<int, String> centerMap,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search (name, phone, sponsor, ID, center, country)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        notifier.updateSearch('');
                      },
                    )
                  : null,
            ),
            onSubmitted: (value) {
              _searchDebounce?.cancel();
              notifier.updateSearch(value);
            },
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 300),
                () => notifier.updateSearch(value),
              );
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: TextField(
            controller: _sponsorController,
            decoration: InputDecoration(
              labelText: 'Sponsor',
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: state.sponsorFilter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _sponsorController.clear();
                        notifier.updateSponsorFilter('');
                      },
                    )
                  : null,
            ),
            onSubmitted: (value) {
              _sponsorDebounce?.cancel();
              notifier.updateSponsorFilter(value);
            },
            onChanged: (value) {
              _sponsorDebounce?.cancel();
              _sponsorDebounce = Timer(
                const Duration(milliseconds: 300),
                () => notifier.updateSponsorFilter(value),
              );
            },
          ),
        ),
        DropdownButton<int?>(
          value: state.businessCenterFilter,
          hint: const Text('Business center'),
          onChanged: notifier.updateBusinessCenter,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All centers'),
            ),
            ...state.businessCenters.map(
              (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
            ),
          ],
        ),
        DropdownButton<int?>(
          value: state.countryFilter,
          hint: const Text('Country'),
          onChanged: notifier.updateCountry,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All countries'),
            ),
            const DropdownMenuItem<int?>(
              value: kNotChinaFilterValue,
              child: Text('Not China'),
            ),
            ...state.countries.map(
              (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPagination(
    BuildContext context,
    CustomersNotifier notifier,
    int currentPage,
    int totalPages,
    bool isLoading,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Page $currentPage of $totalPages'),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Previous page',
          onPressed: !isLoading && currentPage > 1
              ? () => notifier.loadCustomers(page: currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: !isLoading && currentPage < totalPages
              ? () => notifier.loadCustomers(page: currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _openCustomerForm(
    BuildContext context,
    Map<int, String> centerMap,
    CustomersRepository repository,
    Customer? existing,
  ) async {
    final notifier = ref.read(customersNotifierProvider.notifier);
    var countries = ref.read(customersNotifierProvider).countries;
    if (countries.isEmpty) {
      await notifier.loadCountries();
      countries = ref.read(customersNotifierProvider).countries;
    }
    CustomerFormData formData;
    if (existing != null) {
      try {
        final fresh = await repository.fetchCustomer(existing.id);
        formData = CustomerFormData.fromCustomer(fresh);
      } on DioException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(normalizeErrorMessage(error)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load customer'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    } else {
      formData = CustomerFormData();
    }

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return CustomerFormDialog(
          initialData: formData,
          businessCenters: ref.read(customersNotifierProvider).businessCenters,
          countries: countries,
          repository: repository,
          onSubmit: (data) => notifier.saveCustomer(data),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    final notifier = ref.read(customersNotifierProvider.notifier);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final error = await notifier.deleteCustomer(customer.id);
    if (context.mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted ${customer.name}')));
      }
    }
  }

  Future<void> _openFollowups(BuildContext context, Customer customer) async {
    await showDialog(
      context: context,
      builder: (_) => CustomerFollowupsDialog(customer: customer),
    );
  }

  Future<void> _openAutoOrders(BuildContext context, Customer customer) async {
    await showDialog(
      context: context,
      builder: (_) => CustomerAutoOrdersDialog(customer: customer),
    );
  }
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end);

  final int start;
  final int end;
}
