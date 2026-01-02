import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../cart/cart_notifier.dart';
import '../categories/models.dart';
import 'models.dart';
import 'product_form_dialog.dart';
import 'products_notifier.dart';
import 'products_repository.dart';
import 'products_state.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() => ref.read(productsNotifierProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsNotifierProvider);
    final notifier = ref.watch(productsNotifierProvider.notifier);
    final repository = ref.watch(productsRepositoryProvider);
    final filteredItems = _filterProducts(
      state.items,
      state.categories,
      _searchQuery,
    );
    final groups = _buildGroups(filteredItems, state.categories);
    final cartState = ref.watch(cartNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final headingStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final dataTextStyle = Theme.of(context).textTheme.bodyMedium;
    final headingRowColor = colorScheme.surfaceVariant.withOpacity(0.6);
    final oddRowColor = colorScheme.surfaceVariant.withOpacity(0.25);
    final highlightColor = colorScheme.primary.withOpacity(0.2);

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
                      'Products',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text(
                        _searchQuery.isEmpty
                            ? '${state.items.length} items'
                            : '${filteredItems.length} of ${state.items.length} items',
                      ),
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
                    OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: Text('Cart (${cartState.itemCount})'),
                      onPressed: () => context.go('/cart'),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New Product'),
                      onPressed: () =>
                          _openForm(context, state, notifier, repository, null),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search products by name, code, or category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchDebounce?.cancel();
                          setState(() => _searchQuery = '');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
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
                    : groups.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No products'
                              : 'No products match your search',
                        ),
                      )
                    : ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            for (final group in groups)
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
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildHighlightedText(
                                            group.title,
                                            _searchQuery,
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                            highlightColor,
                                          ),
                                          Text(
                                            ' (${group.totalCount})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (final subgroup in group.subgroups) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildHighlightedText(
                                              subgroup.title,
                                              _searchQuery,
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                              highlightColor,
                                            ),
                                            Text(
                                              ' (${subgroup.items.length})',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                          ],
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
                                            const codeWidth = 40.0;
                                            const nameWidth = 280.0;
                                            const priceWidth = 80.0;
                                            const autoorderWidth = 80.0;
                                            const spWidth = 40.0;
                                            const actionsWidth = 180.0;
                                            final tableWidth =
                                                horizontalMargin * 2 +
                                                codeWidth +
                                                nameWidth +
                                                priceWidth +
                                                autoorderWidth +
                                                spWidth +
                                                actionsWidth +
                                                columnSpacing * 5;
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
                                                      width: codeWidth,
                                                      child: Text('Code'),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: SizedBox(
                                                      width: nameWidth,
                                                      child: Text('Name'),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: SizedBox(
                                                      width: priceWidth,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          'Price (AU\$)',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: SizedBox(
                                                      width: autoorderWidth,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          'Auto (AU\$)',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: SizedBox(
                                                      width: spWidth,
                                                      child: Text('SP'),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: SizedBox(
                                                      width: actionsWidth,
                                                      child: Text('Actions'),
                                                    ),
                                                  ),
                                                ],
                                                rows: subgroup.items
                                                    .asMap()
                                                    .entries
                                                    .map(
                                                      (
                                                        entry,
                                                      ) => DataRow.byIndex(
                                                        index: entry.key,
                                                        color: MaterialStatePropertyAll(
                                                          entry.key.isEven
                                                              ? Colors
                                                                    .transparent
                                                              : oddRowColor,
                                                        ),
                                                        cells: [
                                                          DataCell(
                                                            SizedBox(
                                                              width: codeWidth,
                                                              child: _buildHighlightedText(
                                                                entry
                                                                        .value
                                                                        .code ??
                                                                    '-',
                                                                _searchQuery,
                                                                dataTextStyle,
                                                                highlightColor,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            SizedBox(
                                                              width: nameWidth,
                                                              child: _buildHighlightedText(
                                                                entry
                                                                    .value
                                                                    .name,
                                                                _searchQuery,
                                                                dataTextStyle,
                                                                highlightColor,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            SizedBox(
                                                              width: priceWidth,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Text(
                                                                  _formatPrice(
                                                                    entry
                                                                        .value
                                                                        .distributorPriceAud,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            SizedBox(
                                                              width:
                                                                  autoorderWidth,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Text(
                                                                  _formatPrice(
                                                                    _autoorderPrice(
                                                                      entry
                                                                          .value
                                                                          .distributorPriceAud,
                                                                    ),
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            SizedBox(
                                                              width: spWidth,
                                                              child: Text(
                                                                entry.value.sp
                                                                        ?.toString() ??
                                                                    '-',
                                                              ),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            SizedBox(
                                                              width:
                                                                  actionsWidth,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceEvenly,
                                                                children: [
                                                                  IconButton(
                                                                    tooltip:
                                                                        'Add to cart',
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .add_shopping_cart_outlined,
                                                                    ),
                                                                    onPressed: () {
                                                                      ref
                                                                          .read(
                                                                            cartNotifierProvider.notifier,
                                                                          )
                                                                          .addProduct(
                                                                            entry.value,
                                                                          );
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                            'Added ${entry.value.name}',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                  IconButton(
                                                                    tooltip:
                                                                        'Edit',
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .edit_outlined,
                                                                    ),
                                                                    onPressed: () => _openForm(
                                                                      context,
                                                                      state,
                                                                      notifier,
                                                                      repository,
                                                                      entry
                                                                          .value,
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    tooltip:
                                                                        'Delete',
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .delete_outline,
                                                                    ),
                                                                    onPressed: () => _confirmDelete(
                                                                      context,
                                                                      entry
                                                                          .value,
                                                                      notifier,
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
                                  ],
                                ),
                              ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      final trimmed = value.trim();
      if (!mounted || trimmed == _searchQuery) return;
      setState(() => _searchQuery = trimmed);
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
    Color highlightColor, {
    TextOverflow? overflow,
  }) {
    final tokens = _tokenizeQuery(query);
    if (tokens.isEmpty) {
      return Text(text, style: style, overflow: overflow);
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
      return Text(text, style: style, overflow: overflow);
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
    return Text.rich(
      TextSpan(style: style, children: spans),
      overflow: overflow,
    );
  }

  List<_ProductCategoryGroup> _buildGroups(
    List<Product> products,
    List<Category> categories,
  ) {
    final categoryLookup = {
      for (final category in categories) category.id: category,
    };
    const fixedOrder = ['营养补充品', '皮肤护理', '畅活营养', '套装'];
    final topCategoryName = _resolveTopCategory(categories);
    final topCategoryOrder = topCategoryName == null
        ? fixedOrder
        : [
            topCategoryName,
            ...fixedOrder.where((name) => name != topCategoryName),
          ];
    final normalizedOrder = {
      for (var i = 0; i < topCategoryOrder.length; i++)
        _normalizeCategoryKey(topCategoryOrder[i]): i,
    };
    final grouped = <String, Map<String, List<Product>>>{};
    for (final product in products) {
      final resolved = _resolveGroupNames(product, categoryLookup);
      grouped
          .putIfAbsent(resolved.categoryTitle, () => <String, List<Product>>{})
          .putIfAbsent(resolved.subgroupTitle, () => [])
          .add(product);
    }

    final keys = grouped.keys.toList();
    keys.sort((a, b) {
      final aIndex = normalizedOrder[_normalizeCategoryKey(a)];
      final bIndex = normalizedOrder[_normalizeCategoryKey(b)];
      if (aIndex != null || bIndex != null) {
        if (aIndex == null) return 1;
        if (bIndex == null) return -1;
        return aIndex.compareTo(bIndex);
      }
      if (a == 'Uncategorized') return 1;
      if (b == 'Uncategorized') return -1;
      return a.compareTo(b);
    });

    return [
      for (final key in keys)
        _ProductCategoryGroup(key, _buildSubgroups(key, grouped[key]!)),
    ];
  }

  _ResolvedGroupNames _resolveGroupNames(
    Product product,
    Map<int, Category> categoryLookup,
  ) {
    if (product.categoryId != null) {
      final category = categoryLookup[product.categoryId!];
      if (category != null) {
        final parent = category.parentId != null
            ? categoryLookup[category.parentId!]
            : null;
        if (parent != null) {
          return _ResolvedGroupNames(parent.name, category.name);
        }
        return _ResolvedGroupNames(category.name, category.name);
      }
    }
    if (product.categoryName != null && product.categoryName!.isNotEmpty) {
      return _ResolvedGroupNames(product.categoryName!, product.categoryName!);
    }
    return const _ResolvedGroupNames('Uncategorized', 'Uncategorized');
  }

  String? _resolveTopCategory(List<Category> categories) {
    final topCategories =
        categories.where((category) => category.parentId == null).toList()
          ..sort((a, b) {
            final orderCompare = a.sortOrder.compareTo(b.sortOrder);
            if (orderCompare != 0) return orderCompare;
            return a.name.compareTo(b.name);
          });
    if (topCategories.isEmpty) return null;
    return topCategories.first.name;
  }

  String _normalizeCategoryKey(String value) {
    return value.trim();
  }

  List<Product> _filterProducts(
    List<Product> products,
    List<Category> categories,
    String query,
  ) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return products;
    final tokens = _tokenizeQuery(trimmed);
    final categoryLookup = {
      for (final category in categories) category.id: category,
    };
    return products.where((product) {
      final resolved = _resolveGroupNames(product, categoryLookup);
      final haystack = [
        product.name,
        product.code ?? '',
        product.categoryName ?? '',
        resolved.categoryTitle,
        resolved.subgroupTitle,
      ].join(' ').toLowerCase();
      return _matchesTokens(haystack, tokens);
    }).toList();
  }

  List<_ProductSubgroup> _buildSubgroups(
    String categoryTitle,
    Map<String, List<Product>> subgroupMap,
  ) {
    for (final items in subgroupMap.values) {
      items.sort((a, b) {
        final aCode = a.code ?? '';
        final bCode = b.code ?? '';
        if (aCode.isEmpty && bCode.isEmpty) return 0;
        if (aCode.isEmpty) return 1;
        if (bCode.isEmpty) return -1;
        return aCode.compareTo(bCode);
      });
    }
    final subgroupKeys = subgroupMap.keys.toList()..sort();
    if (categoryTitle == '皮肤护理') {
      const preferred = ['清洁', '爽肤', '修护', '保湿'];
      final normalizedPreferred = {
        for (var i = 0; i < preferred.length; i++)
          _normalizeCategoryKey(preferred[i]): i,
      };
      subgroupKeys.sort((a, b) {
        final aIndex = normalizedPreferred[_normalizeCategoryKey(a)];
        final bIndex = normalizedPreferred[_normalizeCategoryKey(b)];
        if (aIndex != null || bIndex != null) {
          if (aIndex == null) return 1;
          if (bIndex == null) return -1;
          return aIndex.compareTo(bIndex);
        }
        return a.compareTo(b);
      });
    } else if (categoryTitle == '畅活营养') {
      const preferred = ['消化健康 畅活', '畅活代餐 & 蛋白奶昔', '体重管理支持'];
      final normalizedPreferred = {
        for (var i = 0; i < preferred.length; i++)
          _normalizeCategoryKey(preferred[i]): i,
      };
      subgroupKeys.sort((a, b) {
        final aIndex = normalizedPreferred[_normalizeCategoryKey(a)];
        final bIndex = normalizedPreferred[_normalizeCategoryKey(b)];
        if (aIndex != null || bIndex != null) {
          if (aIndex == null) return 1;
          if (bIndex == null) return -1;
          return aIndex.compareTo(bIndex);
        }
        return a.compareTo(b);
      });
    }
    if (categoryTitle == '营养补充品' && subgroupKeys.contains('基础营养素')) {
      subgroupKeys
        ..remove('基础营养素')
        ..insert(0, '基础营养素');
    }
    if (subgroupKeys.contains('Uncategorized')) {
      subgroupKeys
        ..remove('Uncategorized')
        ..add('Uncategorized');
    }
    return [
      for (final key in subgroupKeys) _ProductSubgroup(key, subgroupMap[key]!),
    ];
  }

  Future<void> _openForm(
    BuildContext context,
    ProductsState state,
    ProductsNotifier notifier,
    ProductsRepository repository,
    Product? existing,
  ) async {
    ProductFormData initialData;
    if (existing != null) {
      try {
        final fresh = await repository.fetchProduct(existing.id);
        initialData = ProductFormData.fromProduct(fresh);
      } on DioException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(normalizeErrorMessage(error)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load product'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    } else {
      initialData = ProductFormData(
        categoryId: state.categories.isNotEmpty
            ? state.categories.first.id
            : null,
      );
    }

    final result = await showDialog<String?>(
      context: context,
      builder: (_) => ProductFormDialog(
        initialData: initialData,
        categories: state.categories,
        repository: repository,
        onSubmit: notifier.save,
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
    Product product,
    ProductsNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
    final error = await notifier.delete(product.id);
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
        ).showSnackBar(SnackBar(content: Text('Deleted ${product.name}')));
      }
    }
  }

  String _formatPrice(double? price) {
    if (price == null) return '-';
    return price.toStringAsFixed(2);
  }

  double? _autoorderPrice(double? price) {
    if (price == null) return null;
    return price * 0.9;
  }
}

class _ResolvedGroupNames {
  const _ResolvedGroupNames(this.categoryTitle, this.subgroupTitle);

  final String categoryTitle;
  final String subgroupTitle;
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end);

  final int start;
  final int end;
}

class _ProductCategoryGroup {
  _ProductCategoryGroup(this.title, this.subgroups);

  final String title;
  final List<_ProductSubgroup> subgroups;

  int get totalCount =>
      subgroups.fold(0, (total, subgroup) => total + subgroup.items.length);
}

class _ProductSubgroup {
  _ProductSubgroup(this.title, this.items);

  final String title;
  final List<Product> items;
}
