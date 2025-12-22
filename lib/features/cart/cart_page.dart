import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_notifier.dart';
import 'cart_state.dart';
import '../products/products_notifier.dart';
import 'models.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productsNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final notifier = ref.watch(cartNotifierProvider.notifier);
    final productsState = ref.watch(productsNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final headingStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final dataTextStyle = Theme.of(context).textTheme.bodyMedium;
    final headingRowColor = colorScheme.surfaceVariant.withOpacity(0.6);
    final oddRowColor = colorScheme.surfaceVariant.withOpacity(0.25);
    final totalSp = cartState.items.fold<int>(
      0,
      (total, item) =>
          total + ((item.product.sp ?? 0) * item.quantity),
    );

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
                    'Cart',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text('${cartState.itemCount} items'),
                    backgroundColor: colorScheme.surfaceVariant,
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Cart'),
                    onPressed: cartState.items.isEmpty
                        ? null
                        : () => _showSaveDialog(context, notifier),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear Cart'),
                    onPressed: cartState.items.isEmpty
                        ? null
                        : () => notifier.clearCart(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: cartState.items.isEmpty
                  ? const Center(child: Text('Cart is empty'))
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Expanded(
                            child: SelectionContainer.disabled(
                              child: ListView(
                                children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final columnSpacing = 20.0;
                                      final horizontalMargin = 12.0;
                                      const codeWidth = 40.0;
                                      const nameWidth = 200.0;
                                      const qtyWidth = 60.0;
                                      const unitWidth = 80.0;
                                      const autoorderWidth = 120.0;
                                      const spWidth = 40.0;
                                      const lineWidth = 80.0;
                                      const actionsWidth = 80.0;
                                      final tableWidth =
                                          horizontalMargin * 2 +
                                          codeWidth +
                                          nameWidth +
                                          qtyWidth +
                                          unitWidth +
                                          autoorderWidth +
                                          spWidth +
                                          lineWidth +
                                          actionsWidth +
                                          columnSpacing * 7;
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
                                          horizontalMargin: horizontalMargin,
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
                                                width: qtyWidth,
                                                child: Center(
                                                  child: Text('Qty'),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: SizedBox(
                                                width: unitWidth,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    'Unit (AU\$)',
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: SizedBox(
                                                width: autoorderWidth,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    'Autoorder (AU\$)',
                                                    textAlign: TextAlign.right,
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
                                                width: lineWidth,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    'Line (AU\$)',
                                                    textAlign: TextAlign.right,
                                                  ),
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
                                          rows: cartState.items
                                              .asMap()
                                              .entries
                                              .map(
                                                (entry) => DataRow.byIndex(
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
                                                        width: codeWidth,
                                                        child: Text(
                                                          entry
                                                                  .value
                                                                  .product
                                                                  .code ??
                                                              '-',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: nameWidth,
                                                        child: Text(
                                                          entry
                                                              .value
                                                              .product
                                                              .name,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: qtyWidth,
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              IconButton(
                                                                tooltip:
                                                                    'Decrease',
                                                                icon: const Icon(
                                                                  Icons.remove,
                                                                ),
                                                                iconSize: 14,
                                                                visualDensity:
                                                                    VisualDensity
                                                                        .compact,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                constraints:
                                                                    const BoxConstraints(
                                                                      minWidth:
                                                                          24,
                                                                      minHeight:
                                                                          24,
                                                                    ),
                                                                onPressed: () =>
                                                                    notifier.updateQuantity(
                                                                      entry
                                                                          .value
                                                                          .product
                                                                          .id,
                                                                      entry.value.quantity -
                                                                          1,
                                                                    ),
                                                              ),
                                                              Text(
                                                                entry
                                                                    .value
                                                                    .quantity
                                                                    .toString(),
                                                              ),
                                                              IconButton(
                                                                tooltip:
                                                                    'Increase',
                                                                icon:
                                                                    const Icon(
                                                                      Icons.add,
                                                                    ),
                                                                iconSize: 14,
                                                                visualDensity:
                                                                    VisualDensity
                                                                        .compact,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                constraints:
                                                                    const BoxConstraints(
                                                                      minWidth:
                                                                          24,
                                                                      minHeight:
                                                                          24,
                                                                    ),
                                                                onPressed: () =>
                                                                    notifier.updateQuantity(
                                                                      entry
                                                                          .value
                                                                          .product
                                                                          .id,
                                                                      entry.value.quantity +
                                                                          1,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: unitWidth,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            _formatCurrency(
                                                              entry
                                                                  .value
                                                                  .unitPrice,
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: autoorderWidth,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            _formatCurrency(
                                                              entry
                                                                      .value
                                                                      .unitPrice *
                                                                  0.9,
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: spWidth,
                                                        child: Align(
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            entry.value.product
                                                                        .sp ==
                                                                    null
                                                                ? '-'
                                                                : (entry.value
                                                                            .product
                                                                            .sp! *
                                                                        entry
                                                                            .value
                                                                            .quantity)
                                                                    .toString(),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: lineWidth,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            _formatCurrency(
                                                              cartState
                                                                      .applyItemDiscount
                                                                  ? entry
                                                                      .value
                                                                      .lineTotalAfterDiscount
                                                                  : entry
                                                                      .value
                                                                      .lineTotal,
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: actionsWidth,
                                                        child: Center(
                                                          child: IconButton(
                                                            tooltip: 'Remove',
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                            ),
                                                            onPressed: () => notifier
                                                                .removeProduct(
                                                                  entry
                                                                      .value
                                                                      .product
                                                                      .id,
                                                                ),
                                                          ),
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
                          ),
                          const Divider(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 360,
                              child: Column(
                                children: [
                                  _SummaryRow(
                                    label: 'Subtotal (AU\$)',
                                    value: _formatCurrency(cartState.subtotal),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Switch.adaptive(
                                        value: cartState.applyItemDiscount,
                                        onChanged:
                                            notifier.setItemDiscountEnabled,
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Auto order discount 10% (AU\$)',
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(
                                          cartState.itemDiscountTotal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text('Freight (AU\$)'),
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: DropdownButtonFormField<double>(
                                          value: _dropdownValue(
                                            cartState.discountAmount,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 0,
                                              child: Text('0.00'),
                                            ),
                                            DropdownMenuItem(
                                              value: 11,
                                              child: Text('11.00'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          alignment: Alignment.centerRight,
                                          onChanged: (value) {
                                            notifier.setDiscountAmount(
                                              value ?? 0,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _SummaryRow(
                                    label: 'Total (AU\$)',
                                    value: _formatCurrency(cartState.total),
                                    isEmphasis: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _SummaryRow(
                                    label: 'Total Sale Points',
                                    value: totalSp.toString(),
                                    isEmphasis: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _SavedCartsSection(
            savedCarts: cartState.savedCarts,
            onLoad: (savedCart) {
              final productsById = {
                for (final product in productsState.items)
                  product.id: product,
              };
              if (productsById.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Products not loaded yet.'),
                  ),
                );
                return;
              }
              final missing = notifier.loadSavedCart(
                savedCart,
                productsById,
              );
              final message = missing == 0
                  ? 'Loaded "${savedCart.name}"'
                  : 'Loaded "${savedCart.name}" (${missing} missing)';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            onRename: (savedCart) => _showRenameDialog(
              context,
              notifier,
              savedCart.name,
            ),
            onDelete: (savedCart) => notifier.deleteSavedCart(savedCart.name),
          ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }

  double? _dropdownValue(double value) {
    if (value == 0 || value == 11) {
      return value;
    }
    return null;
  }

  Future<void> _showSaveDialog(
    BuildContext context,
    CartNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save cart'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cart name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    await notifier.saveCurrentCart(result);
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    CartNotifier notifier,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename cart'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cart name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    await notifier.renameSavedCart(currentName, result);
  }
}

class _SavedCartsSection extends StatelessWidget {
  const _SavedCartsSection({
    required this.savedCarts,
    required this.onLoad,
    required this.onRename,
    required this.onDelete,
  });

  final List<SavedCart> savedCarts;
  final void Function(SavedCart savedCart) onLoad;
  final void Function(SavedCart savedCart) onRename;
  final void Function(SavedCart savedCart) onDelete;

  @override
  Widget build(BuildContext context) {
    if (savedCarts.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('No saved carts yet.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saved carts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: savedCarts.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final cart = savedCarts[index];
              return Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      '${cart.name} (${cart.totalQuantity} items)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onLoad(cart),
                    child: const Text('Load'),
                  ),
                  TextButton(
                    onPressed: () => onRename(cart),
                    child: const Text('Rename'),
                  ),
                  TextButton(
                    onPressed: () => onDelete(cart),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final emphasisStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      children: [
        Expanded(child: Text(label, style: isEmphasis ? emphasisStyle : style)),
        Text(value, style: isEmphasis ? emphasisStyle : style),
      ],
    );
  }
}
