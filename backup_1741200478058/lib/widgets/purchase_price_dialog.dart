import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';

class PurchasePriceDialog extends StatefulWidget {
  final double? initialPrice;

  const PurchasePriceDialog({
    super.key,
    this.initialPrice,
  });

  @override
  State<PurchasePriceDialog> createState() => _PurchasePriceDialogState();
}

class _PurchasePriceDialogState extends State<PurchasePriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPrice?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    
    // Convert initial price TO display currency
    final displayPrice = widget.initialPrice != null 
        ? currencyProvider.convertTo(widget.initialPrice!)
        : null;

    _controller.text = displayPrice?.toStringAsFixed(2) ?? '';

    return AlertDialog(
      title: const Text('Edit Purchase Price'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixText: currencyProvider.symbol,
              hintText: '0.00',
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the price you paid for this card',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final inputPrice = double.tryParse(_controller.text);
            // Convert input price FROM display currency back to base currency
            final basePrice = inputPrice != null 
                ? currencyProvider.convertFrom(inputPrice)
                : null;
            Navigator.pop(context, basePrice);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
