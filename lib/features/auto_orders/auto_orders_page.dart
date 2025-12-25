import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'auto_order_form_dialog.dart';
import 'auto_orders_notifier.dart';
import 'auto_orders_repository.dart';
import 'auto_orders_state.dart';
import 'models.dart';
import 'schedule_note_editor_page.dart';
import '../../core/api_client.dart';

class AutoOrdersPage extends ConsumerStatefulWidget {
  const AutoOrdersPage({super.key});

  @override
  ConsumerState<AutoOrdersPage> createState() => _AutoOrdersPageState();
}

class _AutoOrdersPageState extends ConsumerState<AutoOrdersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(autoOrdersNotifierProvider.notifier)
          .loadAutoOrders(page: 1);
      await ref.read(autoOrdersNotifierProvider.notifier).loadAuxData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(autoOrdersNotifierProvider);
    final notifier = ref.watch(autoOrdersNotifierProvider.notifier);
    final repository = ref.watch(autoOrdersRepositoryProvider);
    final formatter = DateFormat('yyyy-MM-dd');

    final items = state.statusFilter == null
        ? state.items
        : state.items.where((i) => i.status == state.statusFilter).toList();
    final totalPages = (state.meta.total / state.meta.pageSize).ceil().clamp(
      1,
      1000000,
    );
    final currentPage = state.meta.page;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auto Orders',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  DropdownButton<ScheduleStatus?>(
                    value: state.statusFilter,
                    hint: const Text('All statuses'),
                    onChanged: notifier.updateStatusFilter,
                    items: const [
                      DropdownMenuItem<ScheduleStatus?>(
                        value: null,
                        child: Text('All statuses'),
                      ),
                      DropdownMenuItem(
                        value: ScheduleStatus.active,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: ScheduleStatus.paused,
                        child: Text('Paused'),
                      ),
                      DropdownMenuItem(
                        value: ScheduleStatus.cancelled,
                        child: Text('Cancelled'),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New Auto Order'),
                    onPressed:
                        state.customers.isEmpty ||
                            state.deductionOptions.isEmpty
                        ? null
                        : () => _openForm(
                            context,
                            state,
                            notifier,
                            repository,
                            null,
                          ),
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
                  : items.isEmpty
                  ? const Center(child: Text('No auto orders'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Customer')),
                          DataColumn(label: Text('USANA ID')),
                          DataColumn(label: Text('Deduction Date')),
                          DataColumn(label: Text('Cycle')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: items.map((order) {
                          return DataRow(
                            cells: [
                              DataCell(Text(order.customerName)),
                              DataCell(Text(order.customerUsanaId)),
                              DataCell(
                                Text(formatter.format(order.deductionDate)),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CycleDot(
                                      color: _colorForCycle(order.cycleColor),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${order.cycleValue} • ${order.cycleColor.name}',
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(scheduleStatusLabel(order.status))),
                              DataCell(Text(order.note ?? '-')),
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _openForm(
                                          context,
                                          state,
                                          notifier,
                                          repository,
                                          order,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Pause/Resume',
                                        icon: Icon(
                                          order.status == ScheduleStatus.paused
                                              ? Icons.play_circle_outline
                                              : Icons.pause_circle_outline,
                                        ),
                                        onPressed: () =>
                                            _togglePauseResume(order, notifier),
                                      ),
                                      IconButton(
                                        tooltip: 'Cancel',
                                        icon: const Icon(Icons.cancel_outlined),
                                        onPressed:
                                            order.status ==
                                                ScheduleStatus.cancelled
                                            ? null
                                            : () => _changeStatus(
                                                order,
                                                ScheduleStatus.cancelled,
                                                notifier,
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Page $currentPage of $totalPages'),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Previous',
                onPressed: !state.isLoading && currentPage > 1
                    ? () => notifier.loadAutoOrders(page: currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: !state.isLoading && currentPage < totalPages
                    ? () => notifier.loadAutoOrders(page: currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    AutoOrdersState state,
    AutoOrdersNotifier notifier,
    AutoOrdersRepository repository,
    AutoOrder? existing,
  ) async {
    AutoOrderFormData initialData;
    if (existing != null) {
      try {
        final fresh = await repository.fetchAutoOrder(existing.id);
        initialData = AutoOrderFormData.fromAutoOrder(fresh);
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
            content: const Text('Failed to load auto order'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    } else {
      initialData = state.customers.isNotEmpty &&
              state.deductionOptions.isNotEmpty
          ? AutoOrderFormData(
              customerId: state.customers.first.id,
              customerName: state.customers.first.name,
              customerUsanaId: state.customers.first.customerUsanaId ?? '',
              deductionDate: state.deductionOptions.first.date,
              cycleValue: state.deductionOptions.first.cycleValue,
              cycleColor: state.deductionOptions.first.cycleColor,
              note: '',
            )
          : AutoOrderFormData(
              customerId: 0,
              customerName: '',
              customerUsanaId: '',
              deductionDate: DateTime.now(),
              cycleValue: 1,
              cycleColor: CycleColor.red,
              note: '',
            );
    }

    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AutoOrderFormDialog(
        initialData: initialData,
        customers: state.customers,
        deductionOptions: _ensureOptionWithCurrentDate(
          state.deductionOptions,
          initialData.deductionDate,
          initialData.cycleValue,
          initialData.cycleColor,
        ),
        onSubmit: (data) => notifier.saveAutoOrder(data),
      ),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  Future<void> _openNoteEditor(
    BuildContext context,
    AutoOrdersRepository repository,
    AutoOrdersNotifier notifier,
    AutoOrdersState state,
    AutoOrder order,
  ) async {
    try {
      final fresh = await repository.fetchAutoOrder(order.id);
      if (!context.mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ScheduleNoteEditorPage(
            scheduleId: fresh.id,
            initialNote: fresh.note,
            initialNoteMedia: fresh.noteMedia,
          ),
        ),
      );
      if (result == true && context.mounted) {
        await notifier.loadAutoOrders(page: state.meta.page);
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
          content: const Text('Failed to open schedule note'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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

  Future<void> _togglePauseResume(
    AutoOrder order,
    AutoOrdersNotifier notifier,
  ) async {
    final targetStatus = order.status == ScheduleStatus.paused
        ? ScheduleStatus.active
        : ScheduleStatus.paused;
    final error = await notifier.changeStatus(order.id, targetStatus);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _changeStatus(
    AutoOrder order,
    ScheduleStatus status,
    AutoOrdersNotifier notifier,
  ) async {
    final error = await notifier.changeStatus(order.id, status);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
