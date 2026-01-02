import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../customers/models.dart';
import '../customers/customer_form_dialog.dart';
import '../customers/customers_notifier.dart';
import '../customers/customers_repository.dart';
import 'auto_orders_repository.dart';
import 'models.dart';
import 'note_media_preview.dart';

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
  bool _isUploading = false;

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
        (opt) => DateUtils.isSameDay(opt.date, _data.deductionDate),
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
    _syncSortOrder();
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
              if (_data.id == null)
                DropdownButtonFormField<Customer>(
                  initialValue: selectedCustomer,
                  decoration: const InputDecoration(labelText: 'Customer'),
                  items: widget.customers
                      .map(
                        (c) => DropdownMenuItem<Customer>(
                          value: c,
                          child: Text(
                            '${c.name} (${c.customerUsanaId ?? '-'})',
                          ),
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
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Customer'),
                        child: Text(
                          selectedCustomer == null
                              ? '-'
                              : '${selectedCustomer!.name} (${selectedCustomer!.customerUsanaId ?? '-'})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: selectedCustomer == null
                          ? null
                          : () => _openCustomerForm(
                                context,
                                selectedCustomer!,
                              ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Show customer'),
                    ),
                  ],
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
              Row(
                children: [
                  Text(
                    'Attachments',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: 8),
                  if (_isUploading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadFiles,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add file'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_data.noteMedia.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _data.noteMedia.map((media) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => showNoteMediaPreview(context, media),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 72,
                                height: 72,
                                color: Colors.black12,
                                child: Image.network(
                                  media.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _data.noteMedia = [
                                    for (final item in _data.noteMedia)
                                      if (item.url != media.url) item,
                                  ];
                                  _syncSortOrder();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
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

  Future<void> _pickAndUploadFiles() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final files = await openFiles();
      if (files.isEmpty) return;
      final repository = ref.read(autoOrdersRepositoryProvider);
      for (final picked in files) {
        final uploaded = await _uploadPickedFile(picked, repository);
        if (uploaded != null) {
          setState(() {
            _data.noteMedia = [..._data.noteMedia, uploaded];
          });
        }
      }
      _syncSortOrder();
    } catch (_) {
      _showSnack('Failed to upload file');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<NoteMedia?> _uploadPickedFile(
    XFile picked,
    AutoOrdersRepository repository,
  ) async {
    final path = picked.path;
    if (path.isEmpty) return null;
    final file = File(path);
    try {
      return await repository.uploadNoteMedia(file);
    } catch (_) {
      _showSnack('Failed to upload ${picked.name}');
      return null;
    }
  }

  void _syncSortOrder() {
    _data.noteMedia = [
      for (var i = 0; i < _data.noteMedia.length; i++)
        NoteMedia(
          id: _data.noteMedia[i].id,
          url: _data.noteMedia[i].url,
          mimeType: _data.noteMedia[i].mimeType,
          sizeBytes: _data.noteMedia[i].sizeBytes,
          originalName: _data.noteMedia[i].originalName,
          sortOrder: i,
        ),
    ];
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openCustomerForm(BuildContext context, Customer customer) async {
    final repository = ref.read(customersRepositoryProvider);
    final notifier = ref.read(customersNotifierProvider.notifier);
    CustomerFormData formData;
    try {
      final fresh = await repository.fetchCustomer(customer.id);
      formData = CustomerFormData.fromCustomer(fresh);
    } on DioException catch (error) {
      if (!mounted) return;
      _showSnack(normalizeErrorMessage(error));
      return;
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to load customer');
      return;
    }

    var centers = ref.read(customersNotifierProvider).businessCenters;
    if (centers.isEmpty) {
      await notifier.loadBusinessCenters();
      centers = ref.read(customersNotifierProvider).businessCenters;
    }
    var countries = ref.read(customersNotifierProvider).countries;
    if (countries.isEmpty) {
      await notifier.loadCountries();
      countries = ref.read(customersNotifierProvider).countries;
    }
    final result = await showDialog<String?>(
      context: context,
      builder: (_) {
        return CustomerFormDialog(
          initialData: formData,
          businessCenters: centers,
          countries: countries,
          repository: repository,
          onSubmit: (data) => notifier.saveCustomer(data),
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      _showSnack(result);
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
