import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../auto_orders/models.dart' show NoteMedia;
import '../customers/customer_sort.dart';
import '../customers/customers_repository.dart';
import '../customers/models.dart';
import 'deliveries_repository.dart';
import 'models.dart';

class DeliveryFormPage extends ConsumerStatefulWidget {
  const DeliveryFormPage({super.key, required this.initialData});

  final DeliveryFormData initialData;

  @override
  ConsumerState<DeliveryFormPage> createState() => _DeliveryFormPageState();
}

class _DeliveryFormPageState extends ConsumerState<DeliveryFormPage> {
  late DateTime _pickupDate;
  late bool _delivered;
  late bool _backorder;
  late TextEditingController _pickupPeopleController;
  late TextEditingController _noteController;
  final List<_CustomerEntry> _customers = [];
  late List<NoteMedia> _attachments;
  List<Customer> _availableCustomers = [];
  bool _isLoadingCustomers = false;
  String? _customerLoadError;
  bool _isUploadingAttachments = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _pickupDate = data.pickupDate;
    _delivered = data.delivered;
    _backorder = data.backorder;
    _pickupPeopleController = TextEditingController(text: data.pickupPeople);
    _noteController = TextEditingController(text: data.note ?? '');
    _attachments = List<NoteMedia>.from(data.attachments);
    for (final customer in data.customers) {
      _customers.add(_CustomerEntry.fromCustomer(customer));
    }
    if (_customers.isEmpty) {
      _customers.add(_CustomerEntry.empty());
    }
    Future.microtask(_loadCustomers);
  }

  @override
  void dispose() {
    _pickupPeopleController.dispose();
    _noteController.dispose();
    for (final customer in _customers) {
      customer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');
    final isEdit = widget.initialData.id != null;
    final colorScheme = Theme.of(context).colorScheme;
    final totalOrders = _customers.fold<int>(
      0,
      (total, entry) => total + entry.orders.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Delivery' : 'New Delivery'),
        actions: [
          TextButton.icon(
            onPressed: () => _handleSave(context),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Info',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          _StatusChip(
                            label: _delivered ? 'Delivered' : 'Pending',
                            color: _delivered
                                ? colorScheme.primary
                                : colorScheme.outline,
                          ),
                          _StatusChip(
                            label: _backorder ? 'Backorder' : 'In stock',
                            color: _backorder
                                ? colorScheme.tertiary
                                : colorScheme.outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pickup details and delivery status.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _fieldWidth(
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _pickupDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _pickupDate = picked);
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: Text(formatter.format(_pickupDate)),
                        ),
                        maxWidth: 220,
                      ),
                      const SizedBox(width: 12),
                      _fieldWidth(
                        TextField(
                          controller: _pickupPeopleController,
                          decoration: const InputDecoration(
                            labelText: 'Pickup people',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        maxWidth: 320,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _fieldWidth(
                    TextField(
                      controller: _noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    maxWidth: 520,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _delivered,
                    onChanged: (value) =>
                        setState(() => _delivered = value ?? false),
                    title: const Text('Delivered'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _backorder,
                    onChanged: (value) =>
                        setState(() => _backorder = value ?? false),
                    title: const Text('Backorder'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      FilledButton.icon(
                        onPressed:
                            _isUploadingAttachments ? null : _pickAttachments,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _isUploadingAttachments
                              ? 'Uploading...'
                              : 'Add Attachment',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_attachments.isEmpty)
                    const Text('No attachments'),
                  if (_isUploadingAttachments)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_attachments.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _attachments
                          .map((attachment) => _buildAttachmentThumb(attachment))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Customers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Chip(
                    label: Text('${_customers.length} customers'),
                    backgroundColor: colorScheme.surfaceVariant,
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  Chip(
                    label: Text('$totalOrders orders'),
                    backgroundColor: colorScheme.surfaceVariant,
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _addCustomer,
                icon: const Icon(Icons.add),
                label: const Text('Add Customer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingCustomers) const LinearProgressIndicator(),
          if (_customerLoadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _customerLoadError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          for (var index = 0; index < _customers.length; index++)
            _buildCustomerCard(index, _customers[index]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(int index, _CustomerEntry entry) {
    final hasSelected = entry.selectedCustomerId != null &&
        _availableCustomers.any((c) => c.id == entry.selectedCustomerId);
    final selectedCustomer = hasSelected
        ? _availableCustomers.firstWhere(
            (customer) => customer.id == entry.selectedCustomerId,
          )
        : null;
    final displayName = formatCustomerDisplayName(
      selectedCustomer?.name ?? entry.fallbackName,
    );
    final displayPhone = selectedCustomer?.phone ?? entry.fallbackPhone;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Customer ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${entry.orders.length} orders'),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceVariant,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove customer',
                  onPressed: _customers.length == 1
                      ? null
                      : () => _removeCustomer(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _fieldWidth(
              _CustomerAutocompleteField(
                key: ValueKey('customer-$index'),
                controller: entry.searchController,
                customers: _availableCustomers,
                enabled: _availableCustomers.isNotEmpty,
                onSelected: (customer) {
                  setState(() {
                    entry.selectedCustomerId = customer.id;
                    entry.fallbackName = customer.name;
                    entry.fallbackPhone = customer.phone;
                  });
                },
                onCleared: () {
                  setState(() {
                    entry.selectedCustomerId = null;
                    entry.fallbackName = '';
                    entry.fallbackPhone = '';
                  });
                },
              ),
              maxWidth: 520,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName.isEmpty ? 'Name: -' : 'Name: $displayName',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    displayPhone.isEmpty ? 'Phone: -' : 'Phone: $displayPhone',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orders',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () => _addOrder(entry),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Order'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            for (var orderIndex = 0;
                orderIndex < entry.orders.length;
                orderIndex++)
              _buildOrderRow(entry, orderIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(_CustomerEntry entry, int orderIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _fieldWidth(
            TextField(
              controller: entry.orders[orderIndex],
              decoration: InputDecoration(
                labelText: 'Order ${orderIndex + 1}',
                border: const OutlineInputBorder(),
              ),
            ),
            maxWidth: 320,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remove order',
            onPressed: entry.orders.length == 1
                ? null
                : () => _removeOrder(entry, orderIndex),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  void _addCustomer() {
    setState(() => _customers.add(_CustomerEntry.empty()));
  }

  void _removeCustomer(int index) {
    setState(() {
      final removed = _customers.removeAt(index);
      removed.dispose();
    });
  }

  void _addOrder(_CustomerEntry entry) {
    setState(() => entry.orders.add(TextEditingController()));
  }

  void _removeOrder(_CustomerEntry entry, int index) {
    setState(() {
      final controller = entry.orders.removeAt(index);
      controller.dispose();
    });
  }

  void _handleSave(BuildContext context) {
    final customerMap = {for (final c in _availableCustomers) c.id: c};
    final customers = _customers
        .map(
          (entry) => DeliveryFormCustomer(
            customerId: entry.selectedCustomerId,
            customerName: _resolveCustomerName(entry, customerMap),
            customerPhone: _resolveCustomerPhone(entry, customerMap),
            orders: entry.orders
                .map((controller) => controller.text.trim())
                .where((value) => value.isNotEmpty)
                .map((orderNo) => DeliveryFormOrder(orderNo: orderNo))
                .toList(),
          ),
        )
        .toList();

    final data = DeliveryFormData(
      id: widget.initialData.id,
      pickupDate: _pickupDate,
      pickupPeople: _pickupPeopleController.text.trim(),
      delivered: _delivered,
      backorder: _backorder,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      attachments: List<NoteMedia>.from(_attachments),
      customers: customers,
    );
    Navigator.pop(context, data);
  }

  Widget _buildAttachmentThumb(NoteMedia attachment) {
    final isImage = attachment.mimeType.toLowerCase().startsWith('image/');
    return InkWell(
      onTap: () => _openAttachment(attachment),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: isImage
                ? Image.network(
                    attachment.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.insert_drive_file_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              attachment.originalName.isEmpty
                  ? 'Attachment'
                  : attachment.originalName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _removeAttachment(attachment),
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.9),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttachment(NoteMedia attachment) async {
    final isImage = attachment.mimeType.toLowerCase().startsWith('image/');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          attachment.originalName.isEmpty ? 'Attachment' : attachment.originalName,
        ),
        content: SizedBox(
          width: 520,
          child: isImage
              ? InteractiveViewer(
                  child: Image.network(
                    attachment.url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${attachment.mimeType}'),
                    const SizedBox(height: 6),
                    Text('Size: ${_formatBytes(attachment.sizeBytes)}'),
                    const SizedBox(height: 12),
                    const Text('Preview not available for this file type.'),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _removeAttachment(NoteMedia attachment) {
    setState(() => _attachments.remove(attachment));
  }

  String _formatBytes(int size) {
    if (size <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var sizeValue = size.toDouble();
    var unitIndex = 0;
    while (sizeValue >= 1024 && unitIndex < units.length - 1) {
      sizeValue /= 1024;
      unitIndex++;
    }
    return '${sizeValue.toStringAsFixed(sizeValue < 10 ? 1 : 0)} ${units[unitIndex]}';
  }

  Future<void> _pickAttachments() async {
    final files = await openFiles();
    if (files.isEmpty) return;
    setState(() => _isUploadingAttachments = true);
    final repository = ref.read(deliveriesRepositoryProvider);
    for (final file in files) {
      try {
        final uploaded = await repository.uploadAttachment(File(file.path));
        if (!mounted) return;
        setState(() => _attachments.add(uploaded));
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
            content: const Text('Failed to upload attachment'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isUploadingAttachments = false);
    }
  }

  Widget _fieldWidth(Widget child, {required double maxWidth}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
      _customerLoadError = null;
    });
    try {
      final repository = ref.read(customersRepositoryProvider);
      final customers = await repository.fetchAllCustomers(pageSize: 200);
      if (!mounted) return;
      setState(() {
        _availableCustomers = _mergeMissingCustomers(customers);
        _isLoadingCustomers = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingCustomers = false;
        _customerLoadError = normalizeErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCustomers = false;
        _customerLoadError = 'Failed to load customers';
      });
    }
  }

  Customer? _findCustomer(int id) {
    for (final customer in _availableCustomers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  List<Customer> _mergeMissingCustomers(List<Customer> customers) {
    final byId = {for (final customer in customers) customer.id: customer};
    for (final entry in _customers) {
      final id = entry.selectedCustomerId;
      if (id == null || id == 0) continue;
      if (byId.containsKey(id)) continue;
      byId[id] = Customer(
        id: id,
        name: entry.fallbackName.isEmpty ? 'Customer #$id' : entry.fallbackName,
        phone: entry.fallbackPhone,
        memberStatus: MemberStatus.unknown,
        businessCenterSide: BusinessCenterSide.unknown,
      );
    }
    return byId.values.toList()
      ..sort(
        (a, b) => compareCustomerNamesAsc(a.name, b.name),
      );
  }

  String _resolveCustomerName(
    _CustomerEntry entry,
    Map<int, Customer> customerMap,
  ) {
    final id = entry.selectedCustomerId;
    if (id == null) return entry.fallbackName;
    return customerMap[id]?.name ?? entry.fallbackName;
  }

  String _resolveCustomerPhone(
    _CustomerEntry entry,
    Map<int, Customer> customerMap,
  ) {
    final id = entry.selectedCustomerId;
    if (id == null) return entry.fallbackPhone;
    return customerMap[id]?.phone ?? entry.fallbackPhone;
  }
}

class _CustomerEntry {
  _CustomerEntry({
    required this.selectedCustomerId,
    required this.fallbackName,
    required this.fallbackPhone,
    required this.searchController,
    required this.orders,
  });

  int? selectedCustomerId;
  String fallbackName;
  String fallbackPhone;
  final TextEditingController searchController;
  final List<TextEditingController> orders;

  factory _CustomerEntry.empty() {
    return _CustomerEntry(
      selectedCustomerId: null,
      fallbackName: '',
      fallbackPhone: '',
      searchController: TextEditingController(),
      orders: [TextEditingController()],
    );
  }

  factory _CustomerEntry.fromCustomer(DeliveryFormCustomer customer) {
    final label = customer.customerName.isEmpty
        ? ''
        : '${customer.customerName} (${customer.customerPhone})';
    return _CustomerEntry(
      selectedCustomerId: customer.customerId,
      fallbackName: customer.customerName,
      fallbackPhone: customer.customerPhone,
      searchController: TextEditingController(text: label),
      orders: customer.orders.isEmpty
          ? [TextEditingController()]
          : customer.orders
              .map((order) => TextEditingController(text: order.orderNo))
              .toList(),
    );
  }

  void dispose() {
    searchController.dispose();
    for (final controller in orders) {
      controller.dispose();
    }
  }
}

class _CustomerAutocompleteField extends StatefulWidget {
  const _CustomerAutocompleteField({
    super.key,
    required this.controller,
    required this.customers,
    required this.enabled,
    required this.onSelected,
    required this.onCleared,
  });

  final TextEditingController controller;
  final List<Customer> customers;
  final bool enabled;
  final void Function(Customer customer) onSelected;
  final VoidCallback onCleared;

  @override
  State<_CustomerAutocompleteField> createState() =>
      _CustomerAutocompleteFieldState();
}

class _CustomerAutocompleteFieldState extends State<_CustomerAutocompleteField> {
  static const _debounceDuration = Duration(milliseconds: 250);

  Timer? _debounceTimer;
  TextEditingController? _fieldController;
  String _debouncedQuery = '';
  String _currentQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fieldController?.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);
    return Autocomplete<Customer>(
      displayStringForOption: (option) =>
          '${formatCustomerDisplayName(option.name)} (${option.phone})',
      optionsBuilder: (value) {
        final query = _debouncedQuery;
        if (query.trim().isEmpty) {
          return widget.customers;
        }
        return widget.customers.where((customer) {
          final haystack =
              '${customer.name} ${customer.phone} ${customer.id}'.toLowerCase();
          return _matchesTokens(haystack, _tokenizeQuery(query));
        });
      },
      onSelected: (selection) {
        widget.controller.text =
            '${formatCustomerDisplayName(selection.name)} (${selection.phone})';
        widget.onSelected(selection);
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        _attachController(textController);
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Customer',
            border: const OutlineInputBorder(),
            suffixIcon: textController.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textController.clear();
                      widget.onCleared();
                    },
                  ),
          ),
          enabled: widget.enabled,
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 520),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: _buildHighlightedText(
                      formatCustomerDisplayName(option.name),
                      _currentQuery,
                      Theme.of(context).textTheme.bodyLarge,
                      highlightColor,
                    ),
                    subtitle: _buildHighlightedText(
                      option.phone,
                      _currentQuery,
                      Theme.of(context).textTheme.bodySmall,
                      highlightColor,
                    ),
                    trailing: Text('#${option.id}'),
                    onTap: () => onSelectedOption(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _attachController(TextEditingController textController) {
    if (_fieldController == textController) return;
    if (_fieldController != null) {
      _fieldController!.removeListener(_onTextChanged);
    }
    _fieldController = textController;
    if (textController.text != widget.controller.text) {
      textController.text = widget.controller.text;
      textController.selection = TextSelection.collapsed(
        offset: textController.text.length,
      );
    }
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final controller = _fieldController;
    if (controller == null) return;
    if (widget.controller.text != controller.text) {
      widget.controller.text = controller.text;
    }
    _currentQuery = controller.text;
    _debounceTimer?.cancel();
    if (_currentQuery.trim().isEmpty) {
      _debouncedQuery = '';
      widget.onCleared();
      if (mounted) {
        setState(() {});
      }
      controller.value = controller.value;
      return;
    }
    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted) return;
      setState(() {
        _debouncedQuery = _currentQuery.trim();
      });
      // Trigger Autocomplete to rebuild suggestions after debounce.
      controller.value = controller.value;
    });
  }

  List<String> _tokenizeQuery(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _matchesTokens(String text, List<String> tokens) {
    for (final token in tokens) {
      if (text.contains(token)) continue;
      if (!_isSubsequence(token, text)) return false;
    }
    return true;
  }

  bool _isSubsequence(String pattern, String text) {
    var patternIndex = 0;
    for (var textIndex = 0; textIndex < text.length; textIndex++) {
      if (patternIndex >= pattern.length) return true;
      if (text[textIndex] == pattern[patternIndex]) {
        patternIndex++;
      }
    }
    return patternIndex >= pattern.length;
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
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end);

  final int start;
  final int end;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
    );
  }
}
