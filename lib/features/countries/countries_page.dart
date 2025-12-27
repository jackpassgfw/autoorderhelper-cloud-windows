import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../customers/models.dart';
import 'countries_notifier.dart';
import 'country_form_dialog.dart';

class CountriesPage extends ConsumerStatefulWidget {
  const CountriesPage({super.key});

  @override
  ConsumerState<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends ConsumerState<CountriesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(countriesNotifierProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(countriesNotifierProvider);
    final notifier = ref.watch(countriesNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Countries',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: state.isLoading ? null : () => notifier.load(),
                    icon: const Icon(Icons.refresh),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New Country'),
                    onPressed: () => _openForm(context, null),
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
                  : state.items.isEmpty
                  ? const Center(child: Text('No countries found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: state.items
                            .map((country) => _buildRow(country))
                            .toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(Country country) {
    return DataRow(
      cells: [
        DataCell(Text(country.id.toString())),
        DataCell(Text(country.name)),
        DataCell(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openForm(context, country),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, country),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, Country? country) async {
    final notifier = ref.read(countriesNotifierProvider.notifier);
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => CountryFormDialog(
        initialName: country?.name,
        onSubmit: (name) => notifier.save(id: country?.id, name: name),
      ),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Country country) async {
    final notifier = ref.read(countriesNotifierProvider.notifier);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete country'),
        content: Text('Are you sure you want to delete "${country.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final error = await notifier.delete(country.id);
    if (context.mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${country.name}')),
        );
      }
    }
  }
}
