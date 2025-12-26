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
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(customersNotifierProvider.notifier).loadBusinessCenters();
      await ref.read(customersNotifierProvider.notifier).loadCustomers(page: 1);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersNotifierProvider);
    final notifier = ref.watch(customersNotifierProvider.notifier);
    final repository = ref.watch(customersRepositoryProvider);

    final currentPage = state.meta.page;
    final hasKnownTotal = state.meta.total > 0;
    final hasMore = state.items.length == state.meta.pageSize;
    final totalPages = hasKnownTotal
        ? (state.meta.total / state.meta.pageSize).ceil().clamp(1, 1000000)
        : (hasMore ? currentPage + 1 : currentPage);

    final centerMap = {for (final c in state.businessCenters) c.id: c.name};

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
              FilledButton.icon(
                onPressed: () =>
                    _openCustomerForm(context, centerMap, repository, null),
                icon: const Icon(Icons.add),
                label: const Text('New Customer'),
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

                          return DataRow(
                            cells: [
                              DataCell(Text(customer.name)),
                              DataCell(Text(customer.phone)),
                              DataCell(
                                Text(memberStatusLabel(customer.memberStatus)),
                              ),
                              DataCell(Text(centerAndSide)),
                              DataCell(Text(customer.customerUsanaId ?? '-')),
                              DataCell(Text(customer.sponsor ?? '-')),
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
          const SizedBox(height: 8),
          _buildPagination(
            context,
            notifier,
            currentPage,
            totalPages,
            state.isLoading,
          ),
        ],
      ),
    );
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
              labelText: 'Search (name or phone)',
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
        DropdownButton<MemberStatus?>(
          value: state.memberStatusFilter,
          hint: const Text('Member status'),
          onChanged: notifier.updateMemberStatus,
          items: const [
            DropdownMenuItem<MemberStatus?>(
              value: null,
              child: Text('All statuses'),
            ),
            DropdownMenuItem<MemberStatus?>(
              value: MemberStatus.unknown,
              child: Text('Unknown'),
            ),
            DropdownMenuItem<MemberStatus?>(
              value: MemberStatus.notMember,
              child: Text('Not Member'),
            ),
            DropdownMenuItem<MemberStatus?>(
              value: MemberStatus.member,
              child: Text('Member'),
            ),
          ],
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
