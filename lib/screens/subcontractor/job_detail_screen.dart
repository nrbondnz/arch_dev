import 'package:flutter/material.dart';

import '../../widgets/status_badge.dart';
import 'job_list_screen.dart';
import 'quote_builder_screen.dart';
import 'daily_log_screen.dart';
import 'variation_form_screen.dart';
import 'progress_claim_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final JobSummary job;
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
        title: Text(job.id),
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
          _VariationsTab(job: job),
          _ClaimsTab(job: job),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteBuilderScreen()));
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
  final JobSummary job;
  const _OverviewTab({required this.job});

  @override
  Widget build(BuildContext context) {
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
                      Expanded(child: Text(job.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      StatusBadge(job.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Client', value: job.client),
                  _DetailRow(label: 'Location', value: job.location),
                  _DetailRow(label: 'Contract Value', value: job.contractValue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress
          const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.62,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 4),
          Text(job.progressPct, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 20),

          // Documents section
          const Text('Documents', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _DocumentTile(icon: Icons.picture_as_pdf, title: 'IFC Drawings – Rev 3', date: '14 Mar 2026'),
          _DocumentTile(icon: Icons.picture_as_pdf, title: 'Scope of Works', date: '01 Feb 2026'),
          _DocumentTile(icon: Icons.picture_as_pdf, title: 'Signed Subcontract', date: '15 Feb 2026'),

          const SizedBox(height: 20),

          // Issues / defects
          const Text('Open Issues', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _IssueTile(title: 'Brick coursing misalignment – Grid F3', severity: 'Minor', raised: '08 Apr 2026'),
          _IssueTile(title: 'Mortar colour variance – East elevation', severity: 'Observation', raised: '10 Apr 2026'),
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
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

class _IssueTile extends StatelessWidget {
  final String title;
  final String severity;
  final String raised;
  const _IssueTile({required this.title, required this.severity, required this.raised});

  @override
  Widget build(BuildContext context) {
    final color = severity == 'Minor' ? Colors.orange : Colors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.warning_amber_outlined, color: color),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        subtitle: Text('Raised $raised', style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(severity, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ── Quotes tab ────────────────────────────────────────────────────────────────

class _QuotesTab extends StatelessWidget {
  final JobSummary job;
  const _QuotesTab({required this.job});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _QuoteListItem(ref: 'Q-001', description: 'Stage 1 – Brickwork', value: '\$148,000', status: JobStatus.accepted, date: '20 Feb 2026'),
        _QuoteListItem(ref: 'Q-002', description: 'Stage 2 – Blockwork', value: '\$62,000', status: JobStatus.submitted, date: '01 Apr 2026'),
      ],
    );
  }
}

class _QuoteListItem extends StatelessWidget {
  final String ref;
  final String description;
  final String value;
  final JobStatus status;
  final String date;

  const _QuoteListItem({
    required this.ref,
    required this.description,
    required this.value,
    required this.status,
    required this.date,
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
                Text(ref, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                StatusBadge(status),
              ],
            ),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0E9F6E))),
                const Spacer(),
                Text(date, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Variations tab ────────────────────────────────────────────────────────────

class _VariationsTab extends StatelessWidget {
  final JobSummary job;
  const _VariationsTab({required this.job});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _VariationListItem(ref: 'V-001', description: 'Additional lintels – window revisions', value: '\$4,200', status: JobStatus.approved),
        _VariationListItem(ref: 'V-002', description: 'Extra coursing – colonnade area', value: '\$7,800', status: JobStatus.approved),
        _VariationListItem(ref: 'V-003', description: 'Brick type change – east facade', value: '\$3,400', status: JobStatus.pending),
      ],
    );
  }
}

class _VariationListItem extends StatelessWidget {
  final String ref;
  final String description;
  final String value;
  final JobStatus status;

  const _VariationListItem({
    required this.ref,
    required this.description,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(ref, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0E9F6E))),
          ],
        ),
        trailing: StatusBadge(status),
        isThreeLine: true,
      ),
    );
  }
}

// ── Claims tab ────────────────────────────────────────────────────────────────

class _ClaimsTab extends StatelessWidget {
  final JobSummary job;
  const _ClaimsTab({required this.job});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ClaimListItem(ref: 'PC-001', period: 'February 2026', gross: '\$52,000', retention: '\$2,600', net: '\$49,400', status: JobStatus.paid),
        _ClaimListItem(ref: 'PC-002', period: 'March 2026', gross: '\$40,000', retention: '\$2,000', net: '\$38,000', status: JobStatus.submitted),
      ],
    );
  }
}

class _ClaimListItem extends StatelessWidget {
  final String ref;
  final String period;
  final String gross;
  final String retention;
  final String net;
  final JobStatus status;

  const _ClaimListItem({
    required this.ref,
    required this.period,
    required this.gross,
    required this.retention,
    required this.net,
    required this.status,
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
                Text('$ref – $period', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                StatusBadge(status),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                _ClaimFigure(label: 'Gross', value: gross),
                _ClaimFigure(label: 'Retention', value: '($retention)', color: Colors.red),
                _ClaimFigure(label: 'Net Claim', value: net, color: const Color(0xFF0E9F6E)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimFigure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ClaimFigure({required this.label, required this.value, this.color = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
