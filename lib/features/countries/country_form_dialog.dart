import 'package:flutter/material.dart';

class CountryFormDialog extends StatefulWidget {
  const CountryFormDialog({
    super.key,
    required this.initialName,
    required this.onSubmit,
  });

  final String? initialName;
  final Future<String?> Function(String name) onSubmit;

  @override
  State<CountryFormDialog> createState() => _CountryFormDialogState();
}

class _CountryFormDialogState extends State<CountryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final result = await widget.onSubmit(_nameController.text.trim());
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result == null) {
      Navigator.of(context).pop('Saved country');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'New Country' : 'Edit Country'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Name is required'
              : null,
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
