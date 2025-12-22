import 'package:flutter/material.dart';

import 'models.dart';

class CustomerFormDialog extends StatefulWidget {
  const CustomerFormDialog({
    super.key,
    required this.initialData,
    required this.businessCenters,
    required this.onSubmit,
  });

  final CustomerFormData initialData;
  final List<BusinessCenter> businessCenters;
  final Future<String?> Function(CustomerFormData data) onSubmit;

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late CustomerFormData _data;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;
  late final TextEditingController _usanaIdController;
  late final TextEditingController _usanaUsernameController;
  late final TextEditingController _sponsorController;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _data = CustomerFormData(
      id: widget.initialData.id,
      name: widget.initialData.name,
      phone: widget.initialData.phone,
      email: widget.initialData.email,
      address: widget.initialData.address,
      note: widget.initialData.note,
      customerUsanaId: widget.initialData.customerUsanaId,
      usanaUsername: widget.initialData.usanaUsername,
      sponsor: widget.initialData.sponsor,
      businessCenterId: widget.initialData.businessCenterId,
      memberStatus: widget.initialData.memberStatus,
      businessCenterSide: widget.initialData.businessCenterSide,
    );

    _nameController = TextEditingController(text: _data.name);
    _phoneController = TextEditingController(text: _data.phone);
    _emailController = TextEditingController(text: _data.email);
    _addressController = TextEditingController(text: _data.address);
    _noteController = TextEditingController(text: _data.note);
    _usanaIdController = TextEditingController(text: _data.customerUsanaId);
    _usanaUsernameController = TextEditingController(text: _data.usanaUsername);
    _sponsorController = TextEditingController(text: _data.sponsor);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _usanaIdController.dispose();
    _usanaUsernameController.dispose();
    _sponsorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    _data
      ..name = _nameController.text.trim()
      ..phone = _phoneController.text.trim()
      ..address = _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim()
      ..email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim()
      ..note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim()
      ..customerUsanaId = _usanaIdController.text.trim().isEmpty
          ? null
          : _usanaIdController.text.trim()
      ..usanaUsername = _usanaUsernameController.text.trim().isEmpty
          ? null
          : _usanaUsernameController.text.trim()
      ..sponsor = _sponsorController.text.trim().isEmpty
          ? null
          : _sponsorController.text.trim();

    final error = await widget.onSubmit(_data);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
    } else {
      Navigator.of(context).pop('Customer saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialData.id == null ? 'New Customer' : 'Edit Customer',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone *'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Phone is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                    // const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MemberStatus>(
                        initialValue: _data.memberStatus,
                        decoration: const InputDecoration(
                          labelText: 'Member status',
                        ),
                        items: MemberStatus.values
                            .map(
                              (s) => DropdownMenuItem<MemberStatus>(
                                value: s,
                                child: Text(memberStatusLabel(s)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _data.memberStatus = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _data.businessCenterId,
                        decoration: const InputDecoration(
                          labelText: 'Business center',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...widget.businessCenters.map(
                            (bc) => DropdownMenuItem<int?>(
                              value: bc.id,
                              child: Text(bc.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _data.businessCenterId = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonFormField<BusinessCenterSide>(
                    initialValue: _data.businessCenterSide,
                    decoration: const InputDecoration(
                      labelText: 'Business center side',
                    ),
                    items: BusinessCenterSide.values
                        .map(
                          (side) => DropdownMenuItem<BusinessCenterSide>(
                            value: side,
                            child: Text(businessCenterSideLabel(side)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _data.businessCenterSide = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usanaIdController,
                  decoration: const InputDecoration(labelText: 'USANA ID'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usanaUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'USANA Username',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sponsorController,
                  decoration: const InputDecoration(labelText: 'Sponsor'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
