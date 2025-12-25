import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../auto_orders/models.dart';
import '../auto_orders/note_media_preview.dart';
import 'models.dart';
import 'customers_repository.dart';

class CustomerFormDialog extends StatefulWidget {
  const CustomerFormDialog({
    super.key,
    required this.initialData,
    required this.businessCenters,
    required this.repository,
    required this.onSubmit,
  });

  final CustomerFormData initialData;
  final List<BusinessCenter> businessCenters;
  final CustomersRepository repository;
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
  late List<NoteMedia> _attachments;
  bool _isUploading = false;

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
      media: widget.initialData.media,
    );

    _nameController = TextEditingController(text: _data.name);
    _phoneController = TextEditingController(text: _data.phone);
    _emailController = TextEditingController(text: _data.email);
    _addressController = TextEditingController(text: _data.address);
    _noteController = TextEditingController(text: _data.note);
    _usanaIdController = TextEditingController(text: _data.customerUsanaId);
    _usanaUsernameController = TextEditingController(text: _data.usanaUsername);
    _sponsorController = TextEditingController(text: _data.sponsor);
    _attachments = List<NoteMedia>.from(_data.media);
    _syncSortOrder();
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
          : _sponsorController.text.trim()
      ..media = _attachments;

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
                if (_attachments.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachments.map((media) {
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
                                    errorBuilder: (_, __, ___) =>
                                        const Center(
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
                                    _attachments = [
                                      for (final item in _attachments)
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

  Future<void> _pickAndUploadFiles() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final files = await openFiles();
      if (files.isEmpty) return;
      for (final picked in files) {
        final uploaded = await _uploadPickedFile(picked);
        if (uploaded != null) {
          setState(() {
            _attachments = [..._attachments, uploaded];
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

  Future<NoteMedia?> _uploadPickedFile(XFile picked) async {
    final path = picked.path;
    if (path.isEmpty) return null;
    final file = File(path);
    try {
      return await widget.repository.uploadMedia(file);
    } catch (_) {
      _showSnack('Failed to upload ${picked.name}');
      return null;
    }
  }

  void _syncSortOrder() {
    _attachments = [
      for (var i = 0; i < _attachments.length; i++)
        NoteMedia(
          id: _attachments[i].id,
          url: _attachments[i].url,
          mimeType: _attachments[i].mimeType,
          sizeBytes: _attachments[i].sizeBytes,
          originalName: _attachments[i].originalName,
          sortOrder: i,
        ),
    ];
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
