import 'dart:async';

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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(autoOrdersNotifierProvider);
    final notifier = ref.watch(autoOrdersNotifierProvider.notifier);
    final repository = ref.watch(autoOrdersRepositoryProvider);
    final formatter = DateFormat('yyyy-MM-dd');

    var items = state.items;
    final searchQuery = _searchQuery.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      items = items.where((i) => _fuzzyMatchAutoOrder(i, searchQuery)).toList();
    }
    if (state.statusFilter != null) {
      items = items.where((i) => i.status == state.statusFilter).toList();
    }
    if (state.cycleFilter != null) {
      final cycleFilter = state.cycleFilter!;
      items =
          items
              .where(
                (i) =>
                    i.cycleValue == cycleFilter.value &&
                    i.cycleColor == cycleFilter.color,
              )
              .toList();
    }
    if (state.dateRangeFilter != null) {
      final range = state.dateRangeFilter!;
      items = items
          .where((i) => _isWithinDateRange(i.deductionDate, range))
          .toList();
    }
    final cycleOptions = _buildCycleOptions(state);
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
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchDebounce?.cancel();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
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
                  DropdownButton<CycleFilter?>(
                    value: state.cycleFilter,
                    hint: const Text('All cycles'),
                    onChanged: notifier.updateCycleFilter,
                    items: [
                      const DropdownMenuItem<CycleFilter?>(
                        value: null,
                        child: Text('All cycles'),
                      ),
                      ...cycleOptions.map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option.label()),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      state.dateRangeFilter == null
                          ? 'All dates'
                          : _formatDateRange(state.dateRangeFilter!, formatter),
                    ),
                    onPressed: () => _selectDateRange(context, notifier, state),
                  ),
                  if (state.dateRangeFilter != null)
                    IconButton(
                      tooltip: 'Clear date range',
                      icon: const Icon(Icons.clear),
                      onPressed: () => notifier.updateDateRangeFilter(null),
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
                              DataCell(
                                _buildHighlightedText(
                                  context,
                                  order.customerName,
                                  searchQuery,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  context,
                                  order.customerUsanaId,
                                  searchQuery,
                                ),
                              ),
                              DataCell(
                                _buildHighlightedText(
                                  context,
                                  formatter.format(order.deductionDate),
                                  searchQuery,
                                ),
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  bool _fuzzyMatchAutoOrder(AutoOrder order, String query) {
    final haystack = [
      order.customerName,
      order.customerUsanaId,
      DateFormat('yyyy-MM-dd').format(order.deductionDate),
    ].join(' ').toLowerCase();
    return _fuzzyMatch(haystack, query);
  }

  bool _fuzzyMatch(String text, String query) {
    if (query.isEmpty) return true;
    var queryIndex = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == query[queryIndex]) {
        queryIndex++;
        if (queryIndex == query.length) {
          return true;
        }
      }
    }
    return false;
  }

  List<int>? _fuzzyMatchIndices(String text, String query) {
    if (query.isEmpty) return const <int>[];
    final lowerText = text.toLowerCase();
    var queryIndex = 0;
    final matched = <int>[];

    for (var i = 0; i < lowerText.length; i++) {
      if (lowerText[i] == query[queryIndex]) {
        matched.add(i);
        queryIndex++;
        if (queryIndex == query.length) {
          return matched;
        }
      }
    }

    return null;
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
  ) {
    if (query.isEmpty) {
      return Text(text);
    }

    final matches = _fuzzyMatchIndices(text, query);
    if (matches == null || matches.isEmpty) {
      return Text(text);
    }

    final matchSet = matches.toSet();
    final spans = <TextSpan>[];
    final baseStyle = DefaultTextStyle.of(context).style;
    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      backgroundColor: Colors.yellow,
    );

    var start = 0;
    var isMatch = matchSet.contains(0);
    for (var i = 1; i <= text.length; i++) {
      final currentMatch = i < text.length && matchSet.contains(i);
      if (currentMatch == isMatch && i < text.length) continue;
      final segment = text.substring(start, i);
      spans.add(
        TextSpan(text: segment, style: isMatch ? highlightStyle : baseStyle),
      );
      start = i;
      isMatch = currentMatch;
    }

    return RichText(text: TextSpan(text: '', style: baseStyle, children: spans));
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
    final exists = options.any((o) => DateUtils.isSameDay(o.date, date));
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

  bool _isWithinDateRange(DateTime date, DateTimeRange range) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !dateOnly.isBefore(start) && !dateOnly.isAfter(end);
  }

  String _formatDateRange(DateTimeRange range, DateFormat formatter) {
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  Future<void> _selectDateRange(
    BuildContext context,
    AutoOrdersNotifier notifier,
    AutoOrdersState state,
  ) async {
    final picked = await _showDateRangeDialog(
      context,
      initialRange: state.dateRangeFilter,
    );
    if (picked == null) return;
    notifier.updateDateRangeFilter(picked);
  }

  Future<DateTimeRange?> _showDateRangeDialog(
    BuildContext context, {
    DateTimeRange? initialRange,
  }) {
    final today = DateTime.now();
    final start =
        initialRange?.start ?? DateTime(today.year, today.month, today.day);
    final end = initialRange?.end ?? start;

    return showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) {
        final formatter = DateFormat('yyyy-MM-dd');
        final startController = TextEditingController(
          text: formatter.format(start),
        );
        final endController = TextEditingController(
          text: formatter.format(end),
        );
        var tempStart = start;
        var tempEnd = end;
        String? rangeError;

        Future<void> pickStartDate() async {
          final picked = await showDatePicker(
            context: dialogContext,
            initialDate: tempStart,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked == null) return;
          tempStart = picked;
          if (tempEnd.isBefore(tempStart)) {
            tempEnd = tempStart;
          }
          startController.text = formatter.format(tempStart);
          endController.text = formatter.format(tempEnd);
          rangeError = null;
        }

        Future<void> pickEndDate() async {
          final picked = await showDatePicker(
            context: dialogContext,
            initialDate: tempEnd,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked == null) return;
          tempEnd = picked;
          if (tempEnd.isBefore(tempStart)) {
            tempStart = tempEnd;
          }
          startController.text = formatter.format(tempStart);
          endController.text = formatter.format(tempEnd);
          rangeError = null;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select date range'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rangeError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          rangeError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: startController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Start date',
                        suffixIcon: IconButton(
                          tooltip: 'Pick start date',
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            await pickStartDate();
                            setState(() {});
                          },
                        ),
                      ),
                      onTap: () async {
                        await pickStartDate();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: endController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'End date',
                        suffixIcon: IconButton(
                          tooltip: 'Pick end date',
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            await pickEndDate();
                            setState(() {});
                          },
                        ),
                      ),
                      onTap: () async {
                        await pickEndDate();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (tempEnd.isBefore(tempStart)) {
                      setState(() {
                        rangeError = 'End date must be on or after start date.';
                      });
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      DateTimeRange(start: tempStart, end: tempEnd),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _cycleKey(int value, CycleColor color) => '$value|${color.name}';

  List<CycleFilter> _buildCycleOptions(AutoOrdersState state) {
    final optionsByKey = <String, CycleFilter>{};

    void addOption(CycleFilter option) {
      optionsByKey.putIfAbsent(_cycleKey(option.value, option.color), () {
        return option;
      });
    }

    for (final item in state.items) {
      addOption(CycleFilter(value: item.cycleValue, color: item.cycleColor));
    }
    for (final option in state.deductionOptions) {
      addOption(
        CycleFilter(value: option.cycleValue, color: option.cycleColor),
      );
    }
    if (state.cycleFilter != null) {
      addOption(state.cycleFilter!);
    }

    final options = optionsByKey.values.toList()
      ..sort((a, b) {
        final byValue = a.value.compareTo(b.value);
        if (byValue != 0) return byValue;
        return a.color.name.compareTo(b.color.name);
      });
    return options;
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
