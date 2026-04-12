import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ModelProvider.dart';
import '../../services/job_service.dart';
import '../../services/quote_service.dart';

class QuoteBuilderScreen extends StatefulWidget {
  /// If provided, pre-selects this job in the dropdown.
  final String? jobId;

  const QuoteBuilderScreen({super.key, this.jobId});

  @override
  State<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends State<QuoteBuilderScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _exclusionsController = TextEditingController();

  List<Job> _jobs = [];
  String? _selectedJobId;
  bool _loadingJobs = true;
  bool _saving = false;

  final List<_LineItem> _lineItems = [_LineItem()];

  double get _subtotal => _lineItems.fold(0, (sum, item) => sum + item.total);
  double get _gst => _subtotal * 0.15;
  double get _total => _subtotal + _gst;

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.jobId;
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await JobService.listJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _loadingJobs = false;
          // Validate pre-selected jobId still exists
          if (_selectedJobId != null && !jobs.any((j) => j.id == _selectedJobId)) {
            _selectedJobId = null;
          }
        });
      }
    } on Exception catch (e) {
      safePrint('Error loading jobs: $e');
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Quote'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(context, submit: false),
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
            _loadingJobs
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedJobId,
                    decoration: const InputDecoration(labelText: 'Job', border: OutlineInputBorder()),
                    hint: const Text('Select a job'),
                    items: [
                      ..._jobs.map((j) => DropdownMenuItem(
                            value: j.id,
                            child: Text(j.jobName, overflow: TextOverflow.ellipsis),
                          )),
                      const DropdownMenuItem(
                        value: '__new__',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Create New Job'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == '__new__') {
                        _showCreateJobDialog(context);
                      } else {
                        setState(() => _selectedJobId = value);
                      }
                    },
                  ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
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
              onDelete: _lineItems.length > 1
                  ? () => setState(() => _lineItems.removeAt(i))
                  : null,
              onChanged: () => setState(() {}),
            )),

            const Divider(height: 24),

            // Totals
            _TotalRow(label: 'Subtotal (ex. GST)', value: _subtotal),
            _TotalRow(label: 'GST (15%)', value: _gst),
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
            if (_saving)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _save(context, submit: false),
                      child: const Text('Save as Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _save(context, submit: true),
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

  Future<void> _save(BuildContext context, {required bool submit}) async {
    if (_selectedJobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job')),
      );
      return;
    }
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quote title')),
      );
      return;
    }
    // Must have at least one line item with description
    final validItems = _lineItems.where((li) => li.description.isNotEmpty && li.quantity > 0 && li.rate > 0).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one complete line item')),
      );
      return;
    }

    if (submit) {
      // FR-14: Show summary/review before submitting (totals, exclusions, notes)
      final exclusionsText = _exclusionsController.text.trim();
      final notesText = _notesController.text.trim();
      final summary = StringBuffer()
        ..writeln('${validItems.length} line item(s)')
        ..writeln('Subtotal: \$${_subtotal.toStringAsFixed(2)} ex. GST')
        ..writeln('GST (15%): \$${_gst.toStringAsFixed(2)}')
        ..writeln('Total: \$${_total.toStringAsFixed(2)} inc. GST');
      if (exclusionsText.isNotEmpty) {
        summary.writeln('\nExclusions: $exclusionsText');
      }
      if (notesText.isNotEmpty) {
        summary.writeln('\nNotes: $notesText');
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submit Quote?'),
          content: SingleChildScrollView(
            child: Text(summary.toString()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    try {
      final lineItemData = validItems
          .map((li) => LineItemData(
                description: li.description,
                unit: li.unit,
                quantity: li.quantity,
                rate: li.rate,
              ))
          .toList();

      final quote = await QuoteService.saveQuoteWithLineItems(
        jobId: _selectedJobId!,
        title: _titleController.text,
        exclusions: _exclusionsController.text.isEmpty ? null : _exclusionsController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        lineItems: lineItemData,
      );

      if (submit) {
        await QuoteService.submitQuote(quote.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(submit ? 'Quote submitted successfully' : 'Quote saved as draft')),
        );
      }
    } on Exception catch (e) {
      safePrint('Error saving quote: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateJobDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Job Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || clientCtrl.text.isEmpty) return;
              Navigator.pop(context);
              try {
                final job = await JobService.createJob(
                  jobName: nameCtrl.text,
                  client: clientCtrl.text,
                  location: locationCtrl.text.isEmpty ? null : locationCtrl.text,
                );
                setState(() {
                  _jobs.add(job);
                  _selectedJobId = job.id;
                });
              } on Exception catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ── Local line item for in-memory editing ────────────────────────────────────

class _LineItem {
  String description;
  String unit;
  double quantity;
  double rate;

  _LineItem({this.description = '', this.unit = 'm²', this.quantity = 0, this.rate = 0});

  double get total => quantity * rate;
}

// ── Reusable widgets ────────────────────────────────────────────────────────

class _LineItemRow extends StatelessWidget {
  final _LineItem item;
  final VoidCallback? onDelete;
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
              onChanged: (v) { item.description = v; onChanged(); },
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
              onChanged: (v) { item.unit = v ?? 'm²'; onChanged(); },
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
              onChanged: (v) { item.quantity = double.tryParse(v) ?? 0; onChanged(); },
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
              onChanged: (v) { item.rate = double.tryParse(v) ?? 0; onChanged(); },
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
            icon: Icon(Icons.close, size: 18, color: onDelete != null ? Colors.red : Colors.grey),
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
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
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
