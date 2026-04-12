import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuoteBuilderScreen extends StatefulWidget {
  const QuoteBuilderScreen({super.key});

  @override
  State<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _LineItem {
  String description;
  String unit;
  double quantity;
  double rate;

  _LineItem({this.description = '', this.unit = 'm²', this.quantity = 0, this.rate = 0});

  double get total => quantity * rate;
}

class _QuoteBuilderScreenState extends State<QuoteBuilderScreen> {
  final _jobController = TextEditingController(text: 'J001 – Parnell Residential');
  final _notesController = TextEditingController();
  final _exclusionsController = TextEditingController();

  final List<_LineItem> _lineItems = [_LineItem()];

  double get _subtotal => _lineItems.fold(0, (sum, item) => sum + item.total);
  double get _gst => _subtotal * 0.1;
  double get _total => _subtotal + _gst;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Quote'),
        actions: [
          TextButton(
            onPressed: () => _saveAsDraft(context),
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job selection
            const _SectionHeader(title: 'Job Details'),
            DropdownButtonFormField<String>(
              value: 'J001 – Parnell Residential',
              decoration: const InputDecoration(labelText: 'Job', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'J001 – Parnell Residential', child: Text('J001 – Parnell Residential')),
                DropdownMenuItem(value: 'J003 – East Tāmaki Warehouse', child: Text('J003 – East Tāmaki Warehouse')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Quote title / description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Line items
            Row(
              children: [
                const _SectionHeader(title: 'Line Items'),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Line'),
                  onPressed: () => setState(() => _lineItems.add(_LineItem())),
                ),
              ],
            ),

            // Column headers
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Description', style: TextStyle(fontSize: 11, color: Colors.black45))),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: Text('Unit', style: TextStyle(fontSize: 11, color: Colors.black45))),
                  SizedBox(width: 8),
                  SizedBox(width: 70, child: Text('Qty', style: TextStyle(fontSize: 11, color: Colors.black45))),
                  SizedBox(width: 8),
                  SizedBox(width: 70, child: Text('Rate \$', style: TextStyle(fontSize: 11, color: Colors.black45))),
                  SizedBox(width: 8),
                  SizedBox(width: 75, child: Text('Total \$', style: TextStyle(fontSize: 11, color: Colors.black45))),
                  SizedBox(width: 32),
                ],
              ),
            ),

            ...List.generate(_lineItems.length, (i) => _LineItemRow(
              item: _lineItems[i],
              onDelete: () => setState(() => _lineItems.removeAt(i)),
              onChanged: () => setState(() {}),
            )),

            const Divider(height: 24),

            // Totals
            _TotalRow(label: 'Subtotal', value: _subtotal),
            _TotalRow(label: 'GST (10%)', value: _gst),
            _TotalRow(label: 'Total (inc. GST)', value: _total, bold: true),

            const SizedBox(height: 24),

            // Exclusions & assumptions
            const _SectionHeader(title: 'Exclusions & Assumptions'),
            TextFormField(
              controller: _exclusionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. Scaffolding by others, provisional sums exclude...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            const _SectionHeader(title: 'Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional notes for the client...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _saveAsDraft(context),
                    child: const Text('Save as Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _submitQuote(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit Quote'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _saveAsDraft(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote saved as draft')),
    );
    Navigator.pop(context);
  }

  void _submitQuote(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Quote?'),
        content: Text('Submit this quote for \$${_total.toStringAsFixed(2)} to the main contractor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quote submitted successfully')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final _LineItem item;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _LineItemRow({required this.item, required this.onDelete, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: item.description,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Item description'),
              onChanged: (v) {
                item.description = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: DropdownButtonFormField<String>(
              value: item.unit,
              isDense: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'm²', child: Text('m²')),
                DropdownMenuItem(value: 'lm', child: Text('lm')),
                DropdownMenuItem(value: 'no.', child: Text('no.')),
                DropdownMenuItem(value: 'hrs', child: Text('hrs')),
                DropdownMenuItem(value: 'sum', child: Text('sum')),
              ],
              onChanged: (v) {
                item.unit = v ?? 'm²';
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: item.quantity == 0 ? '' : item.quantity.toString(),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              onChanged: (v) {
                item.quantity = double.tryParse(v) ?? 0;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: item.rate == 0 ? '' : item.rate.toString(),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              onChanged: (v) {
                item.rate = double.tryParse(v) ?? 0;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: Text(
              '\$${item.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _TotalRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: bold ? 16 : 14),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
    );
  }
}
