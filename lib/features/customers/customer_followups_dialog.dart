import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'customer_followups_notifier.dart';
import 'models.dart';

class CustomerFollowupsDialog extends ConsumerStatefulWidget {
  const CustomerFollowupsDialog({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<CustomerFollowupsDialog> createState() =>
      _CustomerFollowupsDialogState();
}

class _CustomerFollowupsDialogState
    extends ConsumerState<CustomerFollowupsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customerFollowupsProvider(widget.customer.id).notifier).load();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerFollowupsProvider(widget.customer.id));
    final notifier = ref.watch(
      customerFollowupsProvider(widget.customer.id).notifier,
    );
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final usanaId = widget.customer.customerUsanaId ?? '-';

    return AlertDialog(
      title: Text('Follow-ups ${widget.customer.name} (USANA ID: $usanaId)'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.followups.isEmpty
                  ? const Center(child: Text('No follow-ups yet'))
                  : ListView.builder(
                      itemCount: state.followups.length,
                      itemBuilder: (context, index) {
                        final f = state.followups[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.history_toggle_off),
                          title: Text(f.content),
                          subtitle: Text(formatter.format(f.timestamp)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openEditDialog(f, notifier),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final error = await notifier.deleteFollowup(
                                    f.id,
                                  );
                                  if (error != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Add follow-up',
                  prefixIcon: Icon(Icons.add_comment_outlined),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Content is required'
                    : null,
                onFieldSubmitted: (_) => _submit(notifier),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: state.isSubmitting ? null : () => _submit(notifier),
          child: state.isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _submit(CustomerFollowupsNotifier notifier) async {
    if (!_formKey.currentState!.validate()) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final error = await notifier.addFollowup(content);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    _contentController.clear();
  }

  Future<void> _openEditDialog(
    Followup followup,
    CustomerFollowupsNotifier notifier,
  ) async {
    final controller = TextEditingController(text: followup.content);
    final formKey = GlobalKey<FormState>();
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit follow-up'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Content *',
                        ),
                        maxLines: 3,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Content is required'
                            : null,
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
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final updated = controller.text.trim();
                    final error = await notifier.updateFollowup(
                      followupId: followup.id,
                      content: updated,
                    );
                    if (error != null) {
                      if (context.mounted) {
                        setState(() => errorMessage = error);
                      }
                      return;
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
