import 'package:flutter/material.dart';

class ProgressClaimScreen extends StatefulWidget {
  const ProgressClaimScreen({super.key});

  @override
  State<ProgressClaimScreen> createState() => _ProgressClaimScreenState();
}

class _ClaimLineItem {
  final String description;
  final String contractQty;
  final String unit;
  double rate;
  double claimedQty;
  final double previousQty;

  _ClaimLineItem({
    required this.description,
    required this.contractQty,
    required this.unit,
    required this.rate,
    required this.claimedQty,
    required this.previousQty,
  });

  double get thisClaimAmount => claimedQty * rate;
}

class _ProgressClaimScreenState extends State<ProgressClaimScreen> {
  String _selectedPeriod = 'March 2026';
  final double _retentionRate = 0.05;

  final List<_ClaimLineItem> _items = [
    _ClaimLineItem(description: 'Face brickwork – external walls', contractQty: '850', unit: 'm²', rate: 120, claimedQty: 210, previousQty: 320),
    _ClaimLineItem(description: 'Blockwork – internal walls', contractQty: '400', unit: 'm²', rate: 85, claimedQty: 80, previousQty: 120),
    _ClaimLineItem(description: 'Brick paving – ground floor', contractQty: '200', unit: 'm²', rate: 95, claimedQty: 50, previousQty: 0),
  ];

  // Approved variations not yet claimed
  final List<_ApprovedVariation> _variations = [
    _ApprovedVariation(ref: 'V-001', description: 'Additional lintels – window revisions', amount: 4200),
    _ApprovedVariation(ref: 'V-002', description: 'Extra coursing – colonnade area', amount: 7800),
  ];

  bool _includeV001 = true;
  bool _includeV002 = true;

  double get _claimSubtotal => _items.fold(0.0, (sum, i) => sum + i.thisClaimAmount);
  double get _variationsTotal => (_includeV001 ? _variations[0].amount : 0) + (_includeV002 ? _variations[1].amount : 0);
  double get _grossClaim => _claimSubtotal + _variationsTotal;
  double get _retention => _grossClaim * _retentionRate;
  double get _netClaim => _grossClaim - _retention;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Claim'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: () {}, tooltip: 'Preview PDF'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selection
            const _SectionHeader('Claim Period'),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'March 2026', child: Text('March 2026')),
                DropdownMenuItem(value: 'April 2026', child: Text('April 2026')),
              ],
              onChanged: (v) => setState(() => _selectedPeriod = v ?? _selectedPeriod),
            ),
            const SizedBox(height: 8),
            const Text(
              'Line quantities auto-populated from recorded progress logs.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 20),

            // Progress items
            const _SectionHeader('Measured Progress'),
            ..._items.asMap().entries.map((e) => _ClaimItemCard(
              item: e.value,
              onQtyChanged: (v) => setState(() => e.value.claimedQty = v),
            )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Progress Subtotal: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${_claimSubtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A56DB))),
              ],
            ),
            const SizedBox(height: 20),

            // Approved variations to include
            const _SectionHeader('Include Approved Variations'),
            _VariationClaimTile(
              variation: _variations[0],
              included: _includeV001,
              onToggle: (v) => setState(() => _includeV001 = v),
            ),
            _VariationClaimTile(
              variation: _variations[1],
              included: _includeV002,
              onToggle: (v) => setState(() => _includeV002 = v),
            ),
            const SizedBox(height: 20),

            // Summary
            const _SectionHeader('Claim Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Measured Progress', value: _claimSubtotal),
                  _SummaryRow(label: 'Approved Variations', value: _variationsTotal),
                  const Divider(),
                  _SummaryRow(label: 'Gross Claim (ex. GST)', value: _grossClaim, bold: true),
                  _SummaryRow(label: 'Retention (5%)', value: -_retention, negative: true),
                  const Divider(),
                  _SummaryRow(label: 'Net Claim', value: _netClaim, bold: true, highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Retention will be held until practical completion.',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Preview PDF'),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit Claim', style: TextStyle(fontSize: 16)),
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

  void _submit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Progress Claim?'),
        content: Text(
          'Submit claim for $_selectedPeriod?\n\nNet claim: \$${_netClaim.toStringAsFixed(2)} (after retention).\n\nThis will notify the QS for review.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Claim submitted – awaiting QS review')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _ClaimItemCard extends StatelessWidget {
  final _ClaimLineItem item;
  final ValueChanged<double> onQtyChanged;

  const _ClaimItemCard({required this.item, required this.onQtyChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ClaimStat(label: 'Contract', value: '${item.contractQty} ${item.unit}'),
                _ClaimStat(label: 'Previous', value: '${item.previousQty} ${item.unit}'),
                _ClaimStat(label: 'Rate', value: '\$${item.rate.toStringAsFixed(0)}/${item.unit}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('This claim: ', style: TextStyle(fontSize: 13, color: Colors.black54)),
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    initialValue: item.claimedQty.toStringAsFixed(0),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixText: item.unit,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onQtyChanged(double.tryParse(v) ?? item.claimedQty),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${item.thisClaimAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0E9F6E)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimStat extends StatelessWidget {
  final String label;
  final String value;
  const _ClaimStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ApprovedVariation {
  final String ref;
  final String description;
  final double amount;
  const _ApprovedVariation({required this.ref, required this.description, required this.amount});
}

class _VariationClaimTile extends StatelessWidget {
  final _ApprovedVariation variation;
  final bool included;
  final ValueChanged<bool> onToggle;

  const _VariationClaimTile({required this.variation, required this.included, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: included ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: included ? Colors.green.shade200 : Colors.grey.shade200),
      ),
      child: CheckboxListTile(
        value: included,
        onChanged: (v) => onToggle(v ?? false),
        title: Text('${variation.ref} – ${variation.description}', style: const TextStyle(fontSize: 13)),
        subtitle: Text('\$${variation.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0E9F6E))),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.green,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool negative;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.negative = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? const Color(0xFF0E9F6E)
        : negative
            ? Colors.red
            : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(
            '${negative ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color, fontSize: bold ? 15 : 13),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}
