import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';

class StageClaimScreen extends StatefulWidget {
  final Job job;
  final Stage stage;

  const StageClaimScreen({super.key, required this.job, required this.stage});

  @override
  State<StageClaimScreen> createState() => _StageClaimScreenState();
}

class _StageClaimScreenState extends State<StageClaimScreen> {
  ClaimStatus _claimStatus = ClaimStatus.draft;
  String? _sentAt;
  String? _paidAt;

  // Mock measured work for S002 (external brickwork)
  final List<_WorkRow> _measuredWork = [
    _WorkRow('External brickwork', 198.4, 320, 'm²', 88.0),
    _WorkRow('Window reveals (variation V001)', 1, 1, 'lump', 450),
  ];

  final List<_VariationRow> _variations = [
    _VariationRow('V001', 'Extra brick pier', 450, true),
    _VariationRow('V002', 'Window reveal depth change', 1200, false),
  ];

  double get _workTotal =>
      _measuredWork.fold(0, (sum, w) => sum + w.quantity * w.rate);

  double get _variationsTotal =>
      _variations.where((v) => v.included).fold(0, (sum, v) => sum + v.price);

  double get _grossClaim => _workTotal + _variationsTotal;
  double get _retentionHeld => _grossClaim * widget.stage.retentionRate;
  double get _claimTotal => _grossClaim - _retentionHeld;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage Claim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0E9F6E).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF0E9F6E).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.stage.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      StatusBadge.stage(widget.stage.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Scheduled value: ',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                      Text(formatNzd(widget.stage.scheduledValue),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                          'Retention: ${(widget.stage.retentionRate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.stage.percentComplete / 100,
                            backgroundColor: Colors.grey[200],
                            color: const Color(0xFF0E9F6E),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                          '${widget.stage.percentComplete.toStringAsFixed(0)}% complete',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0E9F6E),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Measured work
            _SectionLabel('Measured Work Completed (auto-populated from daily logs)'),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15))),
              child: Column(
                children: _measuredWork.asMap().entries.map((e) {
                  final i = e.key;
                  final w = e.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.scopeItem,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                    'Contract: ${w.contractQty.toStringAsFixed(0)} ${w.unit}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600])),
                                const Spacer(),
                                Text(
                                    '@ \$${w.rate.toStringAsFixed(2)}/${w.unit}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue:
                                        w.quantity.toStringAsFixed(1),
                                    keyboardType:
                                        TextInputType.number,
                                    onChanged: (v) {
                                      setState(() {
                                        _measuredWork[i].quantity =
                                            double.tryParse(v) ??
                                                w.quantity;
                                      });
                                    },
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      border:
                                          const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8),
                                      suffixText: w.unit,
                                      suffixStyle: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('=',
                                    style: TextStyle(
                                        color: Colors.grey)),
                                const SizedBox(width: 10),
                                Text(
                                    formatNzdShort(
                                        w.quantity * w.rate),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i < _measuredWork.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Approved variations
            _SectionLabel('Approved Variations to Include'),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15))),
              child: Column(
                children: _variations.asMap().entries.map((e) {
                  final v = e.value;
                  return CheckboxListTile(
                    title: Text('${v.id} — ${v.description}',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                        '\$${v.price.toStringAsFixed(2)} ex. GST',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    value: v.included,
                    onChanged: (val) =>
                        setState(() => v.included = val ?? false),
                    activeColor: const Color(0xFF0E9F6E),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Financial summary
            _SectionLabel('Financial Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ]),
              child: Column(
                children: [
                  _FinRow('Work Completed', _workTotal),
                  _FinRow('Approved Variations', _variationsTotal),
                  const Divider(height: 16),
                  _FinRow('Gross Claim Value', _grossClaim),
                  _FinRow(
                    'Retention Held (${(widget.stage.retentionRate * 100).toStringAsFixed(0)}%)',
                    _retentionHeld,
                    color: Colors.red.shade700,
                    prefix: '-',
                  ),
                  const Divider(height: 16),
                  _FinRow('Claim Total', _claimTotal,
                      bold: true, large: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            _buildActions(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_claimStatus == ClaimStatus.draft) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _sendDocument(context),
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('Send Claim Document to Client'),
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0E9F6E),
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      );
    }

    if (_claimStatus == ClaimStatus.documentSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF1A56DB).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF1A56DB), size: 16),
                const SizedBox(width: 8),
                Text('Document sent to client${_sentAt != null ? ' on $_sentAt' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF1A56DB))),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _recordPayment(context),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Record Payment Received'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E9F6E),
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      );
    }

    // Paid
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200)),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payment received${_paidAt != null ? ' on $_paidAt' : ''}',
              style: TextStyle(
                  color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _sendDocument(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Claim Document'),
        content: Text(
            'Send claim of ${formatNzd(_claimTotal)} to ${widget.job.clientEmail}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _claimStatus = ClaimStatus.documentSent;
                _sentAt = 'today';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Claim document sent (demo)')),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E9F6E)),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _recordPayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _RecordPaymentDialog(
        expectedAmount: _claimTotal,
        onConfirm: (date, amount) {
          setState(() {
            _claimStatus = ClaimStatus.paid;
            _paidAt = date;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Payment recorded (demo)')),
          );
        },
      ),
    );
  }
}

class _RecordPaymentDialog extends StatefulWidget {
  final double expectedAmount;
  final Function(String date, double amount) onConfirm;

  const _RecordPaymentDialog(
      {required this.expectedAmount, required this.onConfirm});

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _dateCtrl;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.expectedAmount.toStringAsFixed(2));
    final now = DateTime.now();
    _dateCtrl = TextEditingController(
        text: '${now.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month-1]} ${now.year}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment Received'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _dateCtrl,
            decoration: const InputDecoration(
                labelText: 'Payment date',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Amount received (NZD)',
                prefixText: '\$',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(
                _dateCtrl.text,
                double.tryParse(_amountCtrl.text) ?? widget.expectedAmount);
          },
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0E9F6E)),
          child: const Text('Mark as Paid'),
        ),
      ],
    );
  }
}

class _WorkRow {
  final String scopeItem;
  double quantity;
  final double contractQty;
  final String unit;
  final double rate;

  _WorkRow(this.scopeItem, this.quantity, this.contractQty, this.unit, this.rate);
}

class _VariationRow {
  final String id;
  final String description;
  final double price;
  bool included;

  _VariationRow(this.id, this.description, this.price, this.included);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.5)),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  final bool large;
  final Color? color;
  final String prefix;

  const _FinRow(this.label, this.amount,
      {this.bold = false,
      this.large = false,
      this.color,
      this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (bold ? Colors.black : Colors.grey[700]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: large ? 15 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: effectiveColor)),
          Text(
            '$prefix${formatNzd(amount)}',
            style: TextStyle(
                fontSize: large ? 15 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: effectiveColor),
          ),
        ],
      ),
    );
  }
}
