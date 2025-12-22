import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../customers/models.dart';
import 'business_center_form_dialog.dart';
import 'business_centers_notifier.dart';

class BusinessCentersPage extends ConsumerStatefulWidget {
  const BusinessCentersPage({super.key});

  @override
  ConsumerState<BusinessCentersPage> createState() =>
      _BusinessCentersPageState();
}

class _BusinessCentersPageState extends ConsumerState<BusinessCentersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(businessCentersNotifierProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessCentersNotifierProvider);
    final notifier = ref.watch(businessCentersNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Business Centers',
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
                    label: const Text('New Center'),
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
                  ? const Center(child: Text('No business centers'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: state.items
                            .map(
                              (bc) => DataRow(
                                cells: [
                                  DataCell(Text(bc.name)),
                                  DataCell(Text(bc.description ?? '-')),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () =>
                                                _openForm(context, bc),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () =>
                                                _confirmDelete(context, bc),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, BusinessCenter? center) async {
    final notifier = ref.read(businessCentersNotifierProvider.notifier);
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => BusinessCenterFormDialog(
        initialName: center?.name,
        initialDescription: center?.description,
        onSubmit: (name, description) =>
            notifier.save(id: center?.id, name: name, description: description),
      ),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BusinessCenter center,
  ) async {
    final notifier = ref.read(businessCentersNotifierProvider.notifier);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete business center'),
        content: Text('Are you sure you want to delete "${center.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final error = await notifier.delete(center.id);
    if (context.mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted ${center.name}')));
      }
    }
  }
}
