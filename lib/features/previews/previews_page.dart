import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../auto_orders/auto_order_form_dialog.dart';
import '../auto_orders/auto_orders_repository.dart';
import '../auto_orders/models.dart';
import '../customers/models.dart';
import 'models.dart';
import 'previews_notifier.dart';

class PreviewsPage extends ConsumerStatefulWidget {
  const PreviewsPage({super.key});

  @override
  ConsumerState<PreviewsPage> createState() => _PreviewsPageState();
}

class _PreviewsPageState extends ConsumerState<PreviewsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(previewsNotifierProvider.notifier).loadNextWeek();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(previewsNotifierProvider);
    final notifier = ref.watch(previewsNotifierProvider.notifier);
    final autoOrdersRepository = ref.watch(autoOrdersRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Previews', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Upcoming occurrences for active schedules.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Next Week',
            action: TextButton.icon(
              onPressed: notifier.loadNextWeek,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            child: SizedBox(
              height: 320,
              child: _PreviewList(
                title: 'Next Week',
                occurrences: state.nextWeek,
                isLoading: state.isLoadingNextWeek,
                errorMessage: state.errorNextWeek,
                onRetry: notifier.loadNextWeek,
                onEdit: (occurrence) =>
                    _openEditDialog(context, occurrence, autoOrdersRepository),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    PreviewOccurrence occurrence,
    AutoOrdersRepository repository,
  ) async {
    try {
      final order = await repository.fetchAutoOrder(occurrence.scheduleId);
      final customers = await repository.fetchCustomersForSelect();
      final options = await repository.fetchDeductionOptions();
      if (!context.mounted) return;
      final result = await showDialog<String?>(
        context: context,
        builder: (_) => AutoOrderFormDialog(
          initialData: AutoOrderFormData.fromAutoOrder(order),
          customers: _ensureCustomerIncluded(customers, order),
          deductionOptions: _ensureOptionWithCurrentDate(
            options,
            order.deductionDate,
            order.cycleValue,
            order.cycleColor,
          ),
          onSubmit: (data) async {
            try {
              await repository.updateAutoOrder(data);
              return null;
            } on DioException catch (error) {
              return normalizeErrorMessage(error);
            } catch (_) {
              return 'Failed to save auto order';
            }
          },
        ),
      );
      if (!context.mounted) return;
      if (result != null) {
        await ref.read(previewsNotifierProvider.notifier).loadNextWeek();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto order saved')),
        );
      }
    } on DioException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(normalizeErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to open auto order'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  List<Customer> _ensureCustomerIncluded(List<Customer> customers, AutoOrder order) {
    final exists = customers.any((c) => c.id == order.customerId);
    if (exists) return customers;
    return [
      Customer(
        id: order.customerId,
        name: order.customerName,
        phone: '',
        memberStatus: MemberStatus.unknown,
        businessCenterSide: BusinessCenterSide.unknown,
        customerUsanaId: order.customerUsanaId,
      ),
      ...customers,
    ];
  }

  List<DeductionOption> _ensureOptionWithCurrentDate(
    List<DeductionOption> options,
    DateTime date,
    int cycleValue,
    CycleColor cycleColor,
  ) {
    final exists = options.any((o) => o.date == date);
    if (exists) return options;
    return [
      DeductionOption(
        date: date,
        cycleValue: cycleValue,
        cycleColor: cycleColor,
      ),
      ...options,
    ];
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({
    required this.title,
    required this.occurrences,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onEdit,
  });

  final String title;
  final List<PreviewOccurrence> occurrences;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final void Function(PreviewOccurrence occurrence) onEdit;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(occurrences);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (grouped.isEmpty) {
      return Center(child: Text('No preview data'));
    }

    return ListView(
      children: grouped.entries.map((entry) {
        final day = entry.key;
        final items = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${items.length} schedules',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(),
                ...items.map((occ) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 0,
                    ),
                    leading: _CycleDot(color: _colorForCycle(occ.cycleColor)),
                    title: Text(occ.customerName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('USANA: ${occ.customerUsanaId}'),
                        Text(
                          'Cycle ${occ.cycleValue} • ${occ.cycleColor.name}',
                        ),
                        if (occ.note != null && occ.note!.isNotEmpty)
                          Text('Note: ${occ.note}'),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Edit auto order',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => onEdit(occ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<PreviewOccurrence>> _groupByDate(
    List<PreviewOccurrence> occurrences,
  ) {
    final map = <String, List<PreviewOccurrence>>{};
    final formatter = DateFormat('yyyy-MM-dd');
    for (final occ in occurrences) {
      final day = formatter.format(occ.date);
      map.putIfAbsent(day, () => []).add(occ);
    }
    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }

  Color _colorForCycle(CycleColor color) {
    switch (color) {
      case CycleColor.red:
        return Colors.red;
      case CycleColor.green:
        return Colors.green;
      case CycleColor.blue:
        return Colors.blue;
      case CycleColor.yellow:
        return Colors.orange;
    }
  }
}

class _CycleDot extends StatelessWidget {
  const _CycleDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
