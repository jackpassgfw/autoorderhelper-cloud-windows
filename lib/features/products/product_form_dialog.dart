import 'package:flutter/material.dart';

import '../categories/models.dart';
import 'models.dart';

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    required this.initialData,
    required this.categories,
    required this.onSubmit,
  });

  final ProductFormData initialData;
  final List<Category> categories;
  final Future<String?> Function(ProductFormData data) onSubmit;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _packagingController;
  late final TextEditingController _spController;
  late final TextEditingController _englishController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _currencyController;
  int? _categoryId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData.name);
    _codeController = TextEditingController(text: widget.initialData.code ?? '');
    _packagingController = TextEditingController(
      text: widget.initialData.packaging ?? '',
    );
    _spController = TextEditingController(
      text: widget.initialData.sp?.toString() ?? '',
    );
    _englishController = TextEditingController(
      text: widget.initialData.english ?? '',
    );
    _priceController = TextEditingController(
      text: widget.initialData.distributorPriceAud?.toStringAsFixed(2) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialData.notes ?? '',
    );
    _currencyController = TextEditingController(
      text: widget.initialData.currency ?? 'AUD',
    );
    _categoryId = widget.initialData.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _packagingController.dispose();
    _spController.dispose();
    _englishController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final priceText = _priceController.text.trim();
    double? price;
    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText);
      if (price == null) {
        setState(() {
          _errorMessage = 'Price must be a number';
        });
        return;
      }
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final data = ProductFormData(
      id: widget.initialData.id,
      name: _nameController.text.trim(),
      code: _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      packaging: _packagingController.text.trim().isEmpty
          ? null
          : _packagingController.text.trim(),
      sp: _spController.text.trim().isEmpty
          ? null
          : int.tryParse(_spController.text.trim()),
      english: _englishController.text.trim().isEmpty
          ? null
          : _englishController.text.trim(),
      notes: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      distributorPriceAud: price,
      currency: _currencyController.text.trim().isEmpty
          ? null
          : _currencyController.text.trim(),
      categoryId: _categoryId,
    );

    final error = await widget.onSubmit(data);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
    } else {
      Navigator.of(context).pop('Saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Uncategorized'),
      ),
      ...widget.categories.map(
        (category) => DropdownMenuItem<int?>(
          value: category.id,
          child: Text(category.name),
        ),
      ),
    ];

    final hasSelectedCategory =
        _categoryId == null || widget.categories.any((c) => c.id == _categoryId);
    if (!hasSelectedCategory) {
      categoryItems.insert(
        1,
        DropdownMenuItem<int?>(
          value: _categoryId,
          child: Text('Category #$_categoryId'),
        ),
      );
    }

    return AlertDialog(
      title: Text(widget.initialData.id == null ? 'New Product' : 'Edit Product'),
      content: SizedBox(
        width: 460,
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
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _packagingController,
                decoration: const InputDecoration(labelText: 'Packaging'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _spController,
                decoration: const InputDecoration(labelText: 'SP'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _englishController,
                decoration: const InputDecoration(labelText: 'English Name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (AUD)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(labelText: 'Currency'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                items: categoryItems,
                onChanged: (value) => setState(() => _categoryId = value),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
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
