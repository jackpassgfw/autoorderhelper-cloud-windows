import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../auto_orders/auto_order_form_dialog.dart';
import '../auto_orders/auto_orders_repository.dart';
import 'customer_auto_orders_notifier.dart';
import 'models.dart';
import '../auto_orders/models.dart';

class CustomerAutoOrdersDialog extends ConsumerStatefulWidget {
  const CustomerAutoOrdersDialog({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<CustomerAutoOrdersDialog> createState() =>
      _CustomerAutoOrdersDialogState();
}

class _CustomerAutoOrdersDialogState
    extends ConsumerState<CustomerAutoOrdersDialog> {
  AutoOrder? _selectedOrder;
  int? _filterCustomerId;
  List<Customer> _customers = const [];
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _filterCustomerId = widget.customer.id;
    Future.microtask(() async {
      await _loadCustomers();
      _loadSchedulesForCustomer(_filterCustomerId ?? widget.customer.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCustomerId = _filterCustomerId ?? widget.customer.id;
    final activeCustomer = _resolveCustomer(activeCustomerId);
    final state = ref.watch(customerAutoOrdersProvider(activeCustomerId));
    final formatter = DateFormat('yyyy-MM-dd');
    final usanaId = activeCustomer.customerUsanaId ?? '-';
    final schedules = state.schedules
        .where((order) => order.customerId == activeCustomerId)
        .toList();

    return AlertDialog(
      title: Text('Auto Orders  ${activeCustomer.name} (USANA ID: $usanaId)'),
      content: SizedBox(
        width: 900,
        height: 420,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const widths = _TableWidths(
              deduction: 120,
              cycle: 120,
              memberPrice: 110,
              autoOrderPrice: 120,
              points: 90,
              freightFee: 110,
              discount: 80,
            );
            final isWide = constraints.maxWidth >= 800;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _filterCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                        ),
                        items: _customers
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(
                                  '${c.name} (${c.customerUsanaId ?? '-'})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoadingCustomers
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _filterCustomerId = value;
                                  _selectedOrder = null;
                                });
                                _loadSchedulesForCustomer(value);
                              },
                      ),
                    ),
                    if (_isLoadingCustomers) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : schedules.isEmpty
                      ? const Center(
                          child: Text(
                            'No auto-order schedules for this customer yet',
                          ),
                        )
                      : isWide
                      ? _WideTable(
                          schedules: schedules,
                          formatter: formatter,
                          selected: _selectedOrder,
                          onSelect: _handleOrderTap,
                          widths: widths,
                        )
                      : _NarrowCards(
                          schedules: schedules,
                          formatter: formatter,
                          selected: _selectedOrder,
                          onSelect: _handleOrderTap,
                        ),
                ),
                const SizedBox(height: 8),
                Text('Note', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 80,
                    maxHeight: 110,
                  ),
                  child: TextField(
                    controller: TextEditingController(
                      text: _selectedOrder?.note?.trim().isNotEmpty == true
                          ? _selectedOrder!.note
                          : 'Select a schedule to view the full note.',
                    ),
                    readOnly: true,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _handleOrderTap(AutoOrder order) {
    setState(() => _selectedOrder = order);
    _openEditForm(order);
  }

  Future<void> _openEditForm(AutoOrder order) async {
    final activeCustomerId = _filterCustomerId ?? widget.customer.id;
    final activeCustomer = _resolveCustomer(activeCustomerId);
    final repository = ref.read(autoOrdersRepositoryProvider);
    try {
      final customers = await repository.fetchCustomersForSelect();
      final options = await repository.fetchDeductionOptions();
      if (!mounted) return;
      final dialogResult = await showDialog<String?>(
        context: context,
        builder: (_) => AutoOrderFormDialog(
          initialData: AutoOrderFormData.fromAutoOrder(order),
          customers: _ensureCustomerIncluded(customers, activeCustomer),
          deductionOptions: _ensureOptionWithCurrentDate(
            options,
            order.deductionDate,
            order.cycleValue,
            order.cycleColor,
          ),
          onSubmit: (data) => ref
              .read(customerAutoOrdersProvider(activeCustomer.id).notifier)
              .save(data),
        ),
      );
      if (!mounted) return;
      if (dialogResult != null) {
        final refreshed = _findOrderById(order.id);
        setState(() => _selectedOrder = refreshed);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-order saved')),
        );
      }
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(normalizeErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to open auto-order'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  AutoOrder? _findOrderById(int id) {
    final activeCustomerId = _filterCustomerId ?? widget.customer.id;
    final state = ref.read(customerAutoOrdersProvider(activeCustomerId));
    for (final order in state.schedules) {
      if (order.id == id) return order;
    }
    return null;
  }

  List<Customer> _ensureCustomerIncluded(
    List<Customer> customers,
    Customer current,
  ) {
    final exists = customers.any((c) => c.id == current.id);
    if (exists) return customers;
    return [current, ...customers];
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

  Future<void> _loadCustomers() async {
    if (_isLoadingCustomers) return;
    setState(() => _isLoadingCustomers = true);
    try {
      final repository = ref.read(autoOrdersRepositoryProvider);
      final customers = await repository.fetchCustomersForSelect();
      if (!mounted) return;
      final current = widget.customer;
      final unique = <int, Customer>{};
      for (final customer in customers) {
        unique[customer.id] = customer;
      }
      unique[current.id] = current;
      setState(() {
        _customers = unique.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _isLoadingCustomers = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(normalizeErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to load customers'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _loadSchedulesForCustomer(int customerId) {
    ref.read(customerAutoOrdersProvider(customerId).notifier).load();
  }

  Customer _resolveCustomer(int customerId) {
    for (final customer in _customers) {
      if (customer.id == customerId) return customer;
    }
    return widget.customer;
  }
}

class _TableWidths {
  const _TableWidths({
    required this.deduction,
    required this.cycle,
    required this.memberPrice,
    required this.autoOrderPrice,
    required this.points,
    required this.freightFee,
    required this.discount,
  });

  final double deduction;
  final double cycle;
  final double memberPrice;
  final double autoOrderPrice;
  final double points;
  final double freightFee;
  final double discount;
}

class _WideTable extends StatelessWidget {
  const _WideTable({
    required this.schedules,
    required this.formatter,
    required this.selected,
    required this.onSelect,
    required this.widths,
  });

  final List<AutoOrder> schedules;
  final DateFormat formatter;
  final AutoOrder? selected;
  final ValueChanged<AutoOrder> onSelect;
  final _TableWidths widths;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _header('Deduction Date', widths.deduction, context),
            _header('Cycle', widths.cycle, context),
            _header('Member Price', widths.memberPrice, context),
            _header('AutoOrder Price', widths.autoOrderPrice, context),
            _header('Points', widths.points, context),
            _header('Freight Fee', widths.freightFee, context),
            _header('Discount', widths.discount, context),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final order in schedules) ...[
                  _WideRow(
                    order: order,
                    formatter: formatter,
                    widths: widths,
                    isSelected: selected?.id == order.id,
                    onTap: () => onSelect(order),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(String text, double width, BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({
    required this.order,
    required this.formatter,
    required this.widths,
    required this.isSelected,
    required this.onTap,
  });

  final AutoOrder order;
  final DateFormat formatter;
  final _TableWidths widths;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: widths.deduction,
              child: Text(formatter.format(order.deductionDate)),
            ),
            SizedBox(
              width: widths.cycle,
              child: Text(
                'Cycle ${order.cycleValue}  ${order.cycleColor.name}',
              ),
            ),
            SizedBox(
              width: widths.memberPrice,
              child: Text(_formatNumber(order.memberPrice)),
            ),
            SizedBox(
              width: widths.autoOrderPrice,
              child: Text(_formatNumber(order.autoorderPrice)),
            ),
            SizedBox(
              width: widths.points,
              child: Text(order.points?.toString() ?? '-'),
            ),
            SizedBox(
              width: widths.freightFee,
              child: Text(_formatNumber(order.freightFee)),
            ),
            SizedBox(
              width: widths.discount,
              child: Text(_formatNumber(order.discount)),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  String _formatNumber(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(2);
  }
}

class _NarrowCards extends StatelessWidget {
  const _NarrowCards({
    required this.schedules,
    required this.formatter,
    required this.selected,
    required this.onSelect,
  });

  final List<AutoOrder> schedules;
  final DateFormat formatter;
  final AutoOrder? selected;
  final ValueChanged<AutoOrder> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: schedules.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = schedules[index];
        final isSelected = selected?.id == order.id;
        return InkWell(
          onTap: () => onSelect(order),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                  : Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatter.format(order.deductionDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                _row(
                  'Cycle',
                  'Cycle ${order.cycleValue}  ${order.cycleColor.name}',
                ),
                _row('Member Price', _formatNumber(order.memberPrice)),
                _row('AutoOrder Price', _formatNumber(order.autoorderPrice)),
                _row('Points', order.points?.toString() ?? '-'),
                _row('Freight Fee', _formatNumber(order.freightFee)),
                _row('Discount', _formatNumber(order.discount)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatNumber(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(2);
  }
}
