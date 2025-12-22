import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../customers/models.dart';
import 'models.dart';

class AutoOrderFormDialog extends ConsumerStatefulWidget {
  const AutoOrderFormDialog({
    super.key,
    required this.initialData,
    required this.customers,
    required this.deductionOptions,
    required this.onSubmit,
  });

  final AutoOrderFormData initialData;
  final List<Customer> customers;
  final List<DeductionOption> deductionOptions;
  final Future<String?> Function(AutoOrderFormData data) onSubmit;

  @override
  ConsumerState<AutoOrderFormDialog> createState() =>
      _AutoOrderFormDialogState();
}

class _AutoOrderFormDialogState extends ConsumerState<AutoOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late AutoOrderFormData _data;
  late final TextEditingController _noteController;
  late final TextEditingController _memberPriceController;
  late final TextEditingController _autoorderPriceController;
  late final TextEditingController _pointsController;
  late final TextEditingController _freightFeeController;
  late final TextEditingController _discountController;
  String? _errorMessage;

  DeductionOption? selectedOption;
  Customer? selectedCustomer;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _noteController = TextEditingController(text: _data.note);
    _memberPriceController = TextEditingController(
      text: _data.memberPrice?.toString() ?? '',
    );
    _autoorderPriceController = TextEditingController(
      text: _data.autoorderPrice?.toString() ?? '',
    );
    _pointsController = TextEditingController(
      text: _data.points?.toString() ?? '',
    );
    _freightFeeController = TextEditingController(
      text: _data.freightFee?.toString() ?? '',
    );
    _discountController = TextEditingController(
      text: _data.discount?.toString() ?? '',
    );
    if (widget.customers.isNotEmpty) {
      selectedCustomer = widget.customers.firstWhere(
        (c) => c.id == _data.customerId,
        orElse: () => widget.customers.first,
      );
    }

    if (widget.deductionOptions.isNotEmpty) {
      selectedOption = widget.deductionOptions.firstWhere(
        (opt) => opt.date == _data.deductionDate,
        orElse: () => widget.deductionOptions.first,
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _memberPriceController.dispose();
    _autoorderPriceController.dispose();
    _pointsController.dispose();
    _freightFeeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
    });
    _data.note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    _data.memberPrice = _parseDouble(_memberPriceController.text);
    _data.autoorderPrice = _parseDouble(_autoorderPriceController.text);
    _data.points = _parseInt(_pointsController.text);
    _data.freightFee = _parseDouble(_freightFeeController.text);
    _data.discount = _parseDouble(_discountController.text);
    if (selectedOption != null) {
      _data.deductionDate = selectedOption!.date;
      _data.cycleValue = selectedOption!.cycleValue;
      _data.cycleColor = selectedOption!.cycleColor;
    }
    if (selectedCustomer != null) {
      _data.customerId = selectedCustomer!.id;
      _data.customerName = selectedCustomer!.name;
      _data.customerUsanaId = selectedCustomer!.customerUsanaId ?? '';
    }
    if (_data.customerUsanaId.isEmpty) {
      setState(() {
        _errorMessage =
            'Customer USANA ID is required to create an auto-order.';
      });
      return;
    }
    final error = await widget.onSubmit(_data);
    if (error != null) {
      if (mounted) {
        setState(() => _errorMessage = error);
      }
      return;
    }
    if (mounted) Navigator.pop(context, 'Saved');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final statuses = ScheduleStatus.values;

    return AlertDialog(
      title: Text(_data.id == null ? 'New Auto Order' : 'Edit Auto Order'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              DropdownButtonFormField<Customer>(
                initialValue: selectedCustomer,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: widget.customers
                    .map(
                      (c) => DropdownMenuItem<Customer>(
                        value: c,
                        child: Text('${c.name} (${c.customerUsanaId ?? '-'})'),
                      ),
                    )
                    .toList(),
                onChanged: (c) {
                  setState(() {
                    selectedCustomer = c;
                    if (c != null) {
                      _data.customerName = c.name;
                      _data.customerUsanaId = c.customerUsanaId ?? '';
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Select a customer' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DeductionOption>(
                initialValue: selectedOption,
                decoration: const InputDecoration(labelText: 'Deduction date'),
                items: widget.deductionOptions
                    .map(
                      (o) => DropdownMenuItem<DeductionOption>(
                        value: o,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CycleDot(color: _colorForCycle(o.cycleColor)),
                            const SizedBox(width: 6),
                            Text(o.label()),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (context) {
                  return widget.deductionOptions
                      .map(
                        (o) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CycleDot(color: _colorForCycle(o.cycleColor)),
                            const SizedBox(width: 6),
                            Text(o.label()),
                          ],
                        ),
                      )
                      .toList();
                },
                onChanged: (value) => setState(() {
                  selectedOption = value;
                }),
                validator: (value) =>
                    value == null ? 'Select a deduction date' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ScheduleStatus>(
                initialValue: _data.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: statuses
                    .map(
                      (s) => DropdownMenuItem<ScheduleStatus>(
                        value: s,
                        child: Text(scheduleStatusLabel(s)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _data.status = value);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      controller: _memberPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Member Price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      controller: _autoorderPriceController,
                      decoration: const InputDecoration(
                        labelText: 'AutoOrder Price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(labelText: 'Points'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      controller: _freightFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Freight Fee',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Discount'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (selectedOption != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CycleDot(
                        color: _colorForCycle(selectedOption!.cycleColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cycle ${selectedOption!.cycleValue} • ${selectedOption!.cycleColor.name} • ${dateFormatter.format(selectedOption!.date)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
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

  double? _parseDouble(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    return double.tryParse(input.trim());
  }

  int? _parseInt(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    return int.tryParse(input.trim());
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
