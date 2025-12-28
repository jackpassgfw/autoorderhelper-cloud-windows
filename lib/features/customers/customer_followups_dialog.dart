import 'dart:async';

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
  final _filterController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

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
    _filterController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerFollowupsProvider(widget.customer.id));
    final notifier = ref.watch(
      customerFollowupsProvider(widget.customer.id).notifier,
    );
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final usanaId = widget.customer.customerUsanaId ?? '-';

    var followups = state.followups;
    final matchMap = <int, List<int>>{};
    final filterText = _searchQuery.trim().toLowerCase();
    if (filterText.isNotEmpty) {
      followups = followups.where((f) {
        final match = _fuzzyMatchIndices(f.content, filterText);
        if (match == null) return false;
        matchMap[f.id] = match;
        return true;
      }).toList();
    }
    if (_startDate != null || _endDate != null) {
      final start = _startDate;
      final end = _endDate;
      followups = followups
          .where((f) => _isWithinRange(f.timestamp, start, end))
          .toList();
    }

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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filterController,
                    decoration: InputDecoration(
                      labelText: 'Search follow-ups',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: filterText.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _filterController.clear();
                                _searchDebounce?.cancel();
                                setState(() => _searchQuery = '');
                              },
                            ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(
                    _startDate == null
                        ? 'Start date'
                        : dateFormatter.format(_startDate!),
                  ),
                  onPressed: () => _selectDate(
                    context,
                    initialDate: _startDate,
                    onSelected: (date) {
                      setState(() => _startDate = date);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(
                    _endDate == null
                        ? 'End date'
                        : dateFormatter.format(_endDate!),
                  ),
                  onPressed: () => _selectDate(
                    context,
                    initialDate: _endDate ?? _startDate,
                    onSelected: (date) {
                      setState(() => _endDate = date);
                    },
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    tooltip: 'Clear date filter',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.followups.isEmpty
                  ? const Center(child: Text('No follow-ups yet'))
                  : followups.isEmpty
                  ? const Center(child: Text('No follow-ups match filters'))
                  : ListView.builder(
                      itemCount: followups.length,
                      itemBuilder: (context, index) {
                        final f = followups[index];
                        final matches = matchMap[f.id] ?? const <int>[];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.history_toggle_off),
                          title: filterText.isEmpty
                              ? Text(f.content)
                              : _buildHighlightedText(
                                  context,
                                  f.content,
                                  matches,
                                ),
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

  bool _isWithinRange(DateTime value, DateTime? start, DateTime? end) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    if (start != null) {
      final startOnly = DateTime(start.year, start.month, start.day);
      if (dateOnly.isBefore(startOnly)) return false;
    }
    if (end != null) {
      final endOnly = DateTime(end.year, end.month, end.day);
      if (dateOnly.isAfter(endOnly)) return false;
    }
    return true;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  List<int>? _fuzzyMatchIndices(String text, String query) {
    if (query.isEmpty) return const <int>[];
    final lowerText = text.toLowerCase();
    var queryIndex = 0;
    final matched = <int>[];

    for (var i = 0; i < lowerText.length; i++) {
      if (lowerText[i] == query[queryIndex]) {
        matched.add(i);
        queryIndex++;
        if (queryIndex == query.length) {
          return matched;
        }
      }
    }

    return null;
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    List<int> matches,
  ) {
    if (matches.isEmpty) {
      return Text(text);
    }

    final matchSet = matches.toSet();
    final spans = <TextSpan>[];
    final baseStyle = DefaultTextStyle.of(context).style;
    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      backgroundColor: Colors.yellow,
    );

    var start = 0;
    var isMatch = matchSet.contains(0);
    for (var i = 1; i <= text.length; i++) {
      final currentMatch = i < text.length && matchSet.contains(i);
      if (currentMatch == isMatch && i < text.length) continue;
      final segment = text.substring(start, i);
      spans.add(
        TextSpan(text: segment, style: isMatch ? highlightStyle : baseStyle),
      );
      start = i;
      isMatch = currentMatch;
    }

    return RichText(text: TextSpan(text: '', style: baseStyle, children: spans));
  }

  Future<void> _selectDate(
    BuildContext context, {
    required ValueChanged<DateTime> onSelected,
    DateTime? initialDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (!mounted) return;
    onSelected(picked);
  }
}
