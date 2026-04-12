import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/ModelProvider.dart';
import '../../services/quote_service.dart';
import '../../utils/status_helpers.dart';
import '../../widgets/status_badge.dart';
import 'quote_builder_screen.dart';
import 'daily_log_screen.dart';
import 'variation_form_screen.dart';
import 'progress_claim_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      appBar: AppBar(
        title: Text(job.jobName, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Quotes'),
            Tab(text: 'Variations'),
            Tab(text: 'Claims'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(job: job),
          _QuotesTab(job: job),
          _VariationsTab(),
          _ClaimsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Color(0xFF1A56DB)),
              title: const Text('New Quote'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => QuoteBuilderScreen(jobId: widget.job.id),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.today, color: Colors.green),
              title: const Text('Log Daily Progress'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyLogScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.purple),
              title: const Text('Raise Variation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VariationFormScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: Colors.teal),
              title: const Text('Submit Progress Claim'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressClaimScreen()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Job job;
  const _OverviewTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final value = (job.contractValue ?? 0) > 0
        ? '\$${job.contractValue!.toStringAsFixed(0)}'
        : 'TBC';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(job.jobName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      StatusBadge.job(job.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Client', value: job.client),
                  if (job.location != null)
                    _DetailRow(label: 'Location', value: job.location!),
                  _DetailRow(label: 'Contract Value', value: value),
                  if (job.description != null && job.description!.isNotEmpty)
                    _DetailRow(label: 'Description', value: job.description!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Documents section (hardcoded for Phase 1)
          const Text('Documents', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _DocumentTile(icon: Icons.picture_as_pdf, title: 'IFC Drawings – Rev 3', date: '14 Mar 2026'),
          _DocumentTile(icon: Icons.picture_as_pdf, title: 'Scope of Works', date: '01 Feb 2026'),
          _DocumentTile(icon: Icons.picture_as_pdf, title: 'Signed Subcontract', date: '15 Feb 2026'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  const _DocumentTile({required this.icon, required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.red[700]),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: Text(date, style: const TextStyle(fontSize: 12, color: Colors.black45)),
      onTap: () {},
    );
  }
}

// ── Quotes tab (LIVE DATA) ──────────────────────────────────────────────────

class _QuotesTab extends StatefulWidget {
  final Job job;
  const _QuotesTab({required this.job});

  @override
  State<_QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<_QuotesTab> {
  List<Quote> _quotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _loading = true);
    try {
      final quotes = await QuoteService.listQuotesForJob(widget.job.id);
      if (mounted) setState(() { _quotes = quotes; _loading = false; });
    } on Exception catch (e) {
      safePrint('Error loading quotes: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_quotes.isEmpty) {
      return const Center(child: Text('No quotes yet', style: TextStyle(color: Colors.black54)));
    }

    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quotes.length,
        itemBuilder: (context, i) {
          final q = _quotes[i];
          return _QuoteListItem(quote: q);
        },
      ),
    );
  }
}

class _QuoteListItem extends StatelessWidget {
  final Quote quote;
  const _QuoteListItem({required this.quote});

  String _dateLabel(String? isoDate) =>
      isoDate?.toString().split('T').first ?? '';

  @override
  Widget build(BuildContext context) {
    final subtotal = (quote.subtotal ?? 0) > 0
        ? '\$${quote.subtotal!.toStringAsFixed(0)} ex. GST'
        : '–';

    // FR-15: timeline dates
    final created = _dateLabel(quote.createdAt?.toString());
    final submitted = _dateLabel(quote.submittedAt?.toString());
    final accepted = _dateLabel(quote.acceptedAt?.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(quote.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                StatusBadge.quote(quote.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtotal, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0E9F6E))),
            const SizedBox(height: 6),
            // FR-15: quote timeline
            Wrap(
              spacing: 16,
              children: [
                if (created.isNotEmpty)
                  Text('Created $created', style: const TextStyle(color: Colors.black45, fontSize: 11)),
                if (submitted.isNotEmpty)
                  Text('Submitted $submitted', style: const TextStyle(color: Colors.blue, fontSize: 11)),
                if (accepted.isNotEmpty)
                  Text('Accepted $accepted', style: const TextStyle(color: Colors.green, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Variations tab (hardcoded for Phase 1) ──────────────────────────────────

class _VariationsTab extends StatelessWidget {
  const _VariationsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HardcodedCard(ref: 'V-001', description: 'Additional lintels – window revisions', value: '\$4,200', status: 'Approved', statusColor: Colors.green),
        _HardcodedCard(ref: 'V-002', description: 'Extra coursing – colonnade area', value: '\$7,800', status: 'Approved', statusColor: Colors.green),
        _HardcodedCard(ref: 'V-003', description: 'Brick type change – east facade', value: '\$3,400', status: 'Pending', statusColor: Colors.orange),
      ],
    );
  }
}

// ── Claims tab (hardcoded for Phase 1) ──────────────────────────────────────

class _ClaimsTab extends StatelessWidget {
  const _ClaimsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HardcodedCard(ref: 'PC-001 – February 2026', description: 'Gross \$52,000 | Retention \$2,600 | Net \$49,400', value: '\$49,400', status: 'Paid', statusColor: Colors.teal),
        _HardcodedCard(ref: 'PC-002 – March 2026', description: 'Gross \$40,000 | Retention \$2,000 | Net \$38,000', value: '\$38,000', status: 'Submitted', statusColor: Colors.blue),
      ],
    );
  }
}

/// Generic card for hardcoded variation/claim items (until those modules are built).
class _HardcodedCard extends StatelessWidget {
  final String ref;
  final String description;
  final String value;
  final String status;
  final Color statusColor;

  const _HardcodedCard({
    required this.ref,
    required this.description,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(ref, style: const TextStyle(fontWeight: FontWeight.bold))),
                StatusBadge(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0E9F6E))),
          ],
        ),
      ),
    );
  }
}
