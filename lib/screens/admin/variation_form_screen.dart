import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';

class VariationFormScreen extends StatefulWidget {
  final Job job;
  final Variation? existing; // null = new variation

  const VariationFormScreen({super.key, required this.job, this.existing});

  @override
  State<VariationFormScreen> createState() => _VariationFormScreenState();
}

class _VariationFormScreenState extends State<VariationFormScreen> {
  bool _clientInitiated = true;
  final _clientContactCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _timeDaysCtrl = TextEditingController(text: '0');
  String _reason = 'Client site instruction';
  String? _selectedPackageId;

  VariationStatus _status = VariationStatus.logged;

  final List<String> _reasons = [
    'Client site instruction',
    'Design change',
    'Unexpected conditions',
    'RFI response',
    'Client request',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    if (v != null) {
      _clientInitiated = v.clientInitiated;
      _clientContactCtrl.text = v.clientContactName ?? '';
      _descCtrl.text = v.description;
      _priceCtrl.text = v.price.toStringAsFixed(2);
      _timeDaysCtrl.text = v.timeImpactDays.toString();
      _reason = v.reason;
      _selectedPackageId = v.workPackageId;
      _status = v.status;
    }
  }

  double get _price => double.tryParse(_priceCtrl.text) ?? 0;
  int get _days => int.tryParse(_timeDaysCtrl.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final packages = MockData.workPackages[widget.job.id] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? 'Log Variation'
            : 'Variation ${widget.existing!.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status (if editing existing)
            if (widget.existing != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: variationStatusColor(widget.existing!.status)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    StatusBadge.variation(widget.existing!.status),
                    const SizedBox(width: 10),
                    if (widget.existing!.documentSentAt != null)
                      Text('Sent ${widget.existing!.documentSentAt}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],

            // Client-initiated toggle
            _SectionLabel('Source'),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Client requested this change',
                        style: TextStyle(fontSize: 13)),
                    value: true,
                    groupValue: _clientInitiated,
                    onChanged: (v) =>
                        setState(() => _clientInitiated = v ?? true),
                    activeColor: const Color(0xFF1A56DB),
                    dense: true,
                  ),
                  RadioListTile<bool>(
                    title: const Text('Scope change identified on site',
                        style: TextStyle(fontSize: 13)),
                    value: false,
                    groupValue: _clientInitiated,
                    onChanged: (v) =>
                        setState(() => _clientInitiated = v ?? false),
                    activeColor: const Color(0xFF1A56DB),
                    dense: true,
                  ),
                ],
              ),
            ),

            if (_clientInitiated) ...[
              const SizedBox(height: 12),
              _Label('Client Contact Name'),
              TextField(
                controller: _clientContactCtrl,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Dave Wilson',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12)),
                style: const TextStyle(fontSize: 13),
              ),
            ],

            const SizedBox(height: 16),
            _SectionLabel('Variation Details'),
            _Label('Affected Work Package (optional)'),
            DropdownButtonFormField<String?>(
              value: _selectedPackageId,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              hint: const Text('Select work package',
                  style: TextStyle(fontSize: 13)),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('None', style: TextStyle(fontSize: 13))),
                ...packages.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.description,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() => _selectedPackageId = v),
            ),
            const SizedBox(height: 12),
            _Label('Description'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe what changed',
                  contentPadding: EdgeInsets.all(12)),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            _Label('Reason'),
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: _reasons
                  .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _reason = v ?? _reason),
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),

            const SizedBox(height: 16),
            _SectionLabel('Impact'),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Cost Impact (NZD ex. GST)'),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12)),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Time Impact (days)'),
                      TextField(
                        controller: _timeDaysCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '0, +1, -2',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12)),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_price > 0 || _days != 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_price > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cost ex. GST',
                              style: TextStyle(color: Colors.grey[600])),
                          Text('\$${_price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    if (_days != 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time impact',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                              '${_days > 0 ? '+' : ''}$_days day${_days.abs() != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            _SectionLabel('Supporting Evidence'),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Photo upload — backend integration coming')),
              ),
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Attach Photo or Site Instruction',
                  style: TextStyle(fontSize: 13)),
            ),

            const SizedBox(height: 28),

            // Action buttons based on status
            _buildActionButtons(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (widget.existing == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _descCtrl.text.isNotEmpty ? () => _saveLogged(context) : null,
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Save Variation'),
        ),
      );
    }

    // Existing variation — show status-appropriate actions
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_status == VariationStatus.logged ||
            _status == VariationStatus.pricedUp) ...[
          FilledButton.icon(
            onPressed: () => _sendDocument(context),
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Send Document to Client'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
        if (_status == VariationStatus.documentSent) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _recordApproved(context),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0E9F6E),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Record Approved'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _recordDeclined(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Record Declined'),
                ),
              ),
            ],
          ),
        ],
        if (_status == VariationStatus.approved ||
            _status == VariationStatus.declined) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_status == VariationStatus.approved
                      ? const Color(0xFF0E9F6E)
                      : Colors.red)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                    _status == VariationStatus.approved
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: _status == VariationStatus.approved
                        ? const Color(0xFF0E9F6E)
                        : Colors.red,
                    size: 18),
                const SizedBox(width: 8),
                Text(
                    _status == VariationStatus.approved
                        ? 'Approved — contract value updated, site manager tasked'
                        : 'Declined — no changes to contract',
                    style: TextStyle(
                        fontSize: 13,
                        color: _status == VariationStatus.approved
                            ? const Color(0xFF0E9F6E)
                            : Colors.red)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _saveLogged(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Variation logged (demo — backend integration coming)')),
    );
    Navigator.pop(context);
  }

  void _sendDocument(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Variation Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send to: ${widget.job.clientEmail}'),
            const SizedBox(height: 12),
            const Text('Delivery method:'),
            const SizedBox(height: 8),
            ...['Email', 'Shareable Link', 'Both'].map((opt) => RadioListTile<String>(
                  title: Text(opt, style: const TextStyle(fontSize: 13)),
                  value: opt,
                  groupValue: 'Email',
                  onChanged: (_) {},
                  dense: true,
                  activeColor: const Color(0xFF1A56DB),
                )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _status = VariationStatus.documentSent);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Document sent to client (demo)')),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB)),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _recordApproved(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record Client Approval'),
        content: const Text(
            'This will update the contract value and create an "Update Work Plan" task for the site manager.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _status = VariationStatus.approved);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Variation approved — contract value updated, task created for site manager (demo)')),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E9F6E)),
            child: const Text('Record Approval'),
          ),
        ],
      ),
    );
  }

  void _recordDeclined(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record Client Decline'),
        content: const Text(
            'The variation will be marked Declined. No changes to contract value or work packages.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _status = VariationStatus.declined);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Variation declined (demo)')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Record Decline'),
          ),
        ],
      ),
    );
  }
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
              letterSpacing: 0.6)),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
