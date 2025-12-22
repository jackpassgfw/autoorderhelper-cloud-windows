import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'categories_notifier.dart';
import 'category_form_dialog.dart';
import 'models.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(categoriesNotifierProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesNotifierProvider);
    final notifier = ref.watch(categoriesNotifierProvider.notifier);
    final categoryNames = {
      for (final category in state.items) category.id: category.name,
    };
    final grouped = _buildGroups(state.items, categoryNames);
    final colorScheme = Theme.of(context).colorScheme;
    final headingStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(fontWeight: FontWeight.w600);
    final dataTextStyle = Theme.of(context).textTheme.bodyMedium;
    final headingRowColor = colorScheme.surfaceVariant.withOpacity(0.6);
    final oddRowColor = colorScheme.surfaceVariant.withOpacity(0.25);

    return SelectableRegion(
      focusNode: FocusNode(),
      selectionControls: materialTextSelectionControls,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text('${state.items.length} items'),
                    backgroundColor: colorScheme.surfaceVariant,
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ],
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
                    label: const Text('New Category'),
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
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                      ? const Center(child: Text('No categories'))
                      : SelectionContainer.disabled(
                          child: ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                            for (final group in grouped)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        '${group.title} (${group.items.length})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        right: 8,
                                        bottom: 8,
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final columnSpacing = 20.0;
                                          final horizontalMargin = 12.0;
                                          const nameWidth = 120.0;
                                          const parentWidth = 120.0;
                                          const sortWidth = 40.0;
                                          const activeWidth = 40.0;
                                          const actionsWidth = 140.0;
                                          final tableWidth =
                                              horizontalMargin * 2 +
                                                  nameWidth +
                                                  parentWidth +
                                                  sortWidth +
                                                  activeWidth +
                                                  actionsWidth +
                                                  columnSpacing * 4;
                                          return ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: tableWidth,
                                            ),
                                            child: DataTable(
                                              headingRowColor:
                                                  MaterialStatePropertyAll(
                                                headingRowColor,
                                              ),
                                              headingTextStyle: headingStyle,
                                              dataTextStyle: dataTextStyle,
                                              columnSpacing: columnSpacing,
                                              horizontalMargin:
                                                  horizontalMargin,
                                              headingRowHeight: 44,
                                              dataRowMinHeight: 44,
                                              dataRowMaxHeight: 56,
                                              dividerThickness: 0,
                                              columns: const [
                                                DataColumn(
                                                  label: SizedBox(
                                                    width: nameWidth,
                                                    child: Text('Name'),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: SizedBox(
                                                    width: parentWidth,
                                                    child: Text('Parent'),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: SizedBox(
                                                    width: sortWidth,
                                                    child: Text('Sort'),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: SizedBox(
                                                    width: activeWidth,
                                                    child: Center(
                                                      child: Text('Active'),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: SizedBox(
                                                    width: actionsWidth,
                                                    child: Text('Actions'),
                                                  ),
                                                ),
                                              ],
                                              rows: group.items
                                                  .asMap()
                                                  .entries
                                                  .map(
                                                    (entry) =>
                                                        DataRow.byIndex(
                                                      index: entry.key,
                                                      color:
                                                          MaterialStatePropertyAll(
                                                        entry.key.isEven
                                                            ? Colors.transparent
                                                            : oddRowColor,
                                                      ),
                                                      cells: [
                                                        DataCell(
                                                          SizedBox(
                                                            width: nameWidth,
                                                            child: Text(
                                                              entry.value.name,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          SizedBox(
                                                            width: parentWidth,
                                                            child: Text(
                                                              entry.value.parentId ==
                                                                      null
                                                                  ? '-'
                                                                  : categoryNames[
                                                                          entry
                                                                              .value
                                                                              .parentId
                                                                        ] ??
                                                                        'Category ${entry.value.parentId}',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          SizedBox(
                                                            width: sortWidth,
                                                            child: Text(
                                                              entry
                                                                  .value
                                                                  .sortOrder
                                                                  .toString(),
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          SizedBox(
                                                            width: activeWidth,
                                                            child: Center(
                                                              child: Icon(
                                                                entry.value
                                                                        .isActive
                                                                    ? Icons
                                                                        .check_circle_outline
                                                                    : Icons
                                                                        .cancel_outlined,
                                                                color: entry
                                                                        .value
                                                                        .isActive
                                                                    ? Theme.of(
                                                                        context,
                                                                      )
                                                                        .colorScheme
                                                                        .primary
                                                                    : Theme.of(
                                                                        context,
                                                                      )
                                                                        .colorScheme
                                                                        .error,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          SizedBox(
                                                            width: actionsWidth,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                IconButton(
                                                                  tooltip:
                                                                      'Edit',
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .edit_outlined,
                                                                  ),
                                                                  onPressed: () =>
                                                                      _openForm(
                                                                    context,
                                                                    entry.value,
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  tooltip:
                                                                      'Delete',
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                  ),
                                                                  onPressed: () =>
                                                                      _confirmDelete(
                                                                    context,
                                                                    entry.value,
                                                                  ),
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
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, Category? category) async {
    final notifier = ref.read(categoriesNotifierProvider.notifier);
    final categories = ref
        .read(categoriesNotifierProvider)
        .items
        .where((item) => item.id != category?.id)
        .toList();
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => CategoryFormDialog(
        initialName: category?.name,
        initialParentId: category?.parentId,
        initialSortOrder: category?.sortOrder ?? 0,
        initialIsActive: category?.isActive ?? true,
        categories: categories,
        onSubmit: (name, parentId, sortOrder, isActive) => notifier.save(
          id: category?.id,
          name: name,
          parentId: parentId,
          sortOrder: sortOrder,
          isActive: isActive,
        ),
      ),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final notifier = ref.read(categoriesNotifierProvider.notifier);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final error = await notifier.delete(category.id);
    if (context.mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Deleted ${category.name}')));
      }
    }
  }

  List<_CategoryGroup> _buildGroups(
    List<Category> categories,
    Map<int, String> categoryNames,
  ) {
    final grouped = <String, List<Category>>{};
    for (final category in categories) {
      final parentTitle = category.parentId == null
          ? 'Top category'
          : categoryNames[category.parentId] ??
              'Category ${category.parentId}';
      grouped.putIfAbsent(parentTitle, () => []).add(category);
    }

    for (final items in grouped.values) {
      items.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });
    }

    final keys = grouped.keys.toList();
    keys.sort((a, b) {
      const preferredOrder = [
        'Top category',
        '营养补充品',
        '皮肤护理',
        '畅活营养',
        '套装',
      ];
      final aIndex = preferredOrder.indexOf(a);
      final bIndex = preferredOrder.indexOf(b);
      if (aIndex != -1 || bIndex != -1) {
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      }
      return a.compareTo(b);
    });

    return [
      for (final key in keys) _CategoryGroup(key, grouped[key]!),
    ];
  }
}

class _CategoryGroup {
  _CategoryGroup(this.title, this.items);

  final String title;
  final List<Category> items;
}
