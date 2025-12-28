import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'deliveries_notifier.dart';
import 'deliveries_state.dart';
import 'delivery_form_page.dart';
import 'models.dart';

class DeliveriesPage extends ConsumerStatefulWidget {
  const DeliveriesPage({super.key});

  @override
  ConsumerState<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends ConsumerState<DeliveriesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(deliveriesNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveriesNotifierProvider);
    final notifier = ref.watch(deliveriesNotifierProvider.notifier);
    final dateFormatter = DateFormat('yyyy-MM-dd');

    final currentPage = state.meta.page;
    final hasKnownTotal = state.meta.total > 0;
    final hasMore = state.items.length == state.meta.pageSize;
    final totalPages = hasKnownTotal
        ? (state.meta.total / state.meta.pageSize).ceil().clamp(1, 1000000)
        : (hasMore ? currentPage + 1 : currentPage);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Deliveries',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text('${state.items.length} items'),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildPagination(
                    notifier,
                    currentPage,
                    totalPages,
                    state.isLoading,
                  ),
                  FilledButton.icon(
                    onPressed: state.isSubmitting
                        ? null
                        : () => _openFormPage(context, notifier, null),
                    icon: const Icon(Icons.add),
                    label: const Text('New Delivery'),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: state.isLoading ? null : () => notifier.load(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
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
                  ? const Center(child: Text('No deliveries found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Pickup Date')),
                          DataColumn(label: Text('Pickup People')),
                          DataColumn(label: Text('Delivered')),
                          DataColumn(label: Text('Customers')),
                          DataColumn(label: Text('Orders')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: state.items.map((delivery) {
                          final customerCount = delivery.itemsByCustomer.length;
                          final orderCount = delivery.itemsByCustomer.fold<int>(
                            0,
                            (total, group) => total + group.items.length,
                          );

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(_formatDate(delivery.pickupDate, dateFormatter)),
                              ),
                              DataCell(
                                Text(delivery.pickupPeople.isEmpty
                                    ? '-'
                                    : delivery.pickupPeople),
                              ),
                              DataCell(
                                _buildDeliveredChip(context, delivery.delivered),
                              ),
                              DataCell(
                                Text(customerCount.toString()),
                              ),
                              DataCell(
                                Text(orderCount.toString()),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 140,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () => _openEditDialog(
                                                  context,
                                                  notifier,
                                                  state,
                                                  delivery,
                                                ),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () => _confirmDelete(
                                                  context,
                                                  notifier,
                                                  delivery,
                                                ),
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

  String _formatDate(DateTime? value, DateFormat formatter) {
    if (value == null) return '-';
    return formatter.format(value);
  }

  String _summarizeNames(List<String> values, {int maxItems = 3}) {
    if (values.isEmpty) return '';
    final trimmed = values.map((value) => value.trim()).where((v) => v.isNotEmpty);
    final unique = <String>[];
    for (final value in trimmed) {
      if (!unique.contains(value)) {
        unique.add(value);
      }
    }
    if (unique.isEmpty) return '';
    if (unique.length <= maxItems) {
      return unique.join(', ');
    }
    final sample = unique.take(maxItems).join(', ');
    return '$sample +${unique.length - maxItems}';
  }

  Widget _buildDeliveredChip(BuildContext context, bool delivered) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = delivered ? 'Yes' : 'No';
    final background = delivered
        ? colorScheme.primary.withOpacity(0.12)
        : colorScheme.surfaceVariant;
    final foreground = delivered ? colorScheme.primary : colorScheme.onSurface;

    return Chip(
      label: Text(label),
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPagination(
    DeliveriesNotifier notifier,
    int currentPage,
    int totalPages,
    bool isLoading,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Page $currentPage of $totalPages'),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Previous page',
          onPressed: !isLoading && currentPage > 1
              ? () => notifier.load(page: currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: !isLoading && currentPage < totalPages
              ? () => notifier.load(page: currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }


  Future<void> _openEditDialog(
    BuildContext context,
    DeliveriesNotifier notifier,
    DeliveriesState state,
    Delivery delivery,
  ) async {
    await _openFormPage(context, notifier, delivery);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DeliveriesNotifier notifier,
    Delivery delivery,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete delivery'),
        content: Text('Are you sure you want to delete #${delivery.id}?'),
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
    final error = await notifier.delete(delivery.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery deleted')),
      );
    }
  }

  Future<void> _openFormPage(
    BuildContext context,
    DeliveriesNotifier notifier,
    Delivery? delivery,
  ) async {
    final initialData = delivery == null
        ? DeliveryFormData.newDelivery()
        : DeliveryFormData.fromDelivery(delivery);
    final result = await Navigator.of(context).push<DeliveryFormData>(
      MaterialPageRoute(
        builder: (_) => DeliveryFormPage(initialData: initialData),
      ),
    );
    if (result == null || !context.mounted) return;
    final error = result.id == null
        ? await notifier.create(result.toCreateData())
        : await notifier.update(result.toUpdateData());
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.id == null ? 'Delivery created' : 'Delivery updated'),
        ),
      );
    }
  }
}
