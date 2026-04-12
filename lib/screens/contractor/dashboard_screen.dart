import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/ModelProvider.dart';
import '../../services/quote_service.dart';
import '../../widgets/status_badge.dart';

class ContractorDashboardScreen extends StatefulWidget {
  final bool isQS;
  const ContractorDashboardScreen({super.key, this.isQS = false});

  @override
  State<ContractorDashboardScreen> createState() => _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState extends State<ContractorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _roleLabel => widget.isQS ? 'Quantity Surveyor' : 'Main Contractor';
  Color get _roleColor => widget.isQS ? const Color(0xFFE3A008) : const Color(0xFF0E9F6E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Approvals', style: TextStyle(fontSize: 18)),
            Text(_roleLabel, style: TextStyle(fontSize: 11, color: _roleColor, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SignOutButton(),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Quotes'),
            Tab(text: 'Variations'),
            Tab(text: 'Claims'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _QuotesApprovalTab(roleColor: _roleColor),
          _VariationsApprovalTab(roleColor: _roleColor),
          _ClaimsApprovalTab(isQS: widget.isQS, roleColor: _roleColor),
        ],
      ),
    );
  }
}

// ── Quotes tab (LIVE DATA) ──────────────────────────────────────────────────

class _QuotesApprovalTab extends StatefulWidget {
  final Color roleColor;
  const _QuotesApprovalTab({required this.roleColor});

  @override
  State<_QuotesApprovalTab> createState() => _QuotesApprovalTabState();
}

class _QuotesApprovalTabState extends State<_QuotesApprovalTab> {
  List<Quote> _submitted = [];
  List<Quote> _accepted = [];
  List<Quote> _rejected = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        QuoteService.listQuotesByStatus(QuoteStatus.Submitted),
        QuoteService.listQuotesByStatus(QuoteStatus.Accepted),
        QuoteService.listQuotesByStatus(QuoteStatus.Rejected),
      ]);
      if (mounted) {
        setState(() {
          _submitted = results[0];
          _accepted = results[1];
          _rejected = results[2];
          _loading = false;
        });
      }
    } on Exception catch (e) {
      safePrint('Error loading quotes: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryBanner(
            counts: {
              'Submitted': _submitted.length,
              'Accepted': _accepted.length,
              'Rejected': _rejected.length,
            },
            color: widget.roleColor,
          ),
          const SizedBox(height: 12),
          if (_submitted.isEmpty && _accepted.isEmpty && _rejected.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No quotes to review', style: TextStyle(color: Colors.black54)),
            )),
          ..._submitted.map((q) => _QuoteApprovalCard(
            quote: q,
            showActions: true,
            onApprove: () => _approve(q),
            onDecline: () => _decline(q),
          )),
          ..._accepted.map((q) => _QuoteApprovalCard(quote: q, showActions: false, onApprove: () {}, onDecline: () {})),
          ..._rejected.map((q) => _QuoteApprovalCard(quote: q, showActions: false, onApprove: () {}, onDecline: () {})),
        ],
      ),
    );
  }

  Future<void> _approve(Quote quote) async {
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Approve ${quote.title}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will notify the subcontractor and update the contract.'),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Optional comments...', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await QuoteService.acceptQuote(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${quote.title} approved')),
        );
      }
      _loadQuotes();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _decline(Quote quote) async {
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Decline ${quote.title}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for declining.'),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Reason for declining...', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await QuoteService.rejectQuote(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${quote.title} declined')),
        );
      }
      _loadQuotes();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _QuoteApprovalCard extends StatelessWidget {
  final Quote quote;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const _QuoteApprovalCard({
    required this.quote,
    required this.showActions,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final total = (quote.subtotal ?? 0) > 0
        ? '\$${quote.subtotal!.toStringAsFixed(2)} ex. GST'
        : '–';
    final dateStr = quote.submittedAt?.toString().split('T').first ?? '';

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
                Expanded(child: Text(quote.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                StatusBadge.quote(quote.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('Job: ${quote.jobId}', style: const TextStyle(fontSize: 12, color: Colors.black38)),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Submitted: $dateStr', style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0E9F6E))),
                const Spacer(),
                if (showActions) ...[
                  OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Approve'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Variations tab (hardcoded for Phase 1) ──────────────────────────────────

class _VariationsApprovalTab extends StatelessWidget {
  final Color roleColor;
  const _VariationsApprovalTab({required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryBanner(counts: {'Pending': 1, 'Approved': 2, 'Declined': 0}, color: roleColor),
        const SizedBox(height: 12),
        _HardcodedApprovalCard(
          ref: 'V-003',
          jobName: 'J001 – Parnell Residential',
          description: 'Brick type change – east facade (heritage brick specified)',
          value: '\$3,400 ex. GST',
          status: 'Pending',
          statusColor: Colors.orange,
        ),
        _HardcodedApprovalCard(
          ref: 'V-001',
          jobName: 'J001 – Parnell Residential',
          description: 'Additional lintels – window revisions (SI-007)',
          value: '\$4,200 ex. GST',
          status: 'Approved',
          statusColor: Colors.green,
        ),
      ],
    );
  }
}

// ── Claims tab (hardcoded for Phase 1) ──────────────────────────────────────

class _ClaimsApprovalTab extends StatelessWidget {
  final bool isQS;
  final Color roleColor;
  const _ClaimsApprovalTab({required this.isQS, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isQS)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.calculate_outlined, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As QS, you assess and certify claims before payment is authorised.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        _SummaryBanner(counts: {'Submitted': 1, 'Paid': 3, 'Overdue': 0}, color: roleColor),
        const SizedBox(height: 12),
        _HardcodedApprovalCard(
          ref: 'PC-002 – March 2026',
          jobName: 'J001 – Parnell Residential',
          description: 'Gross \$40,000 | Retention \$2,000 | Net \$38,000',
          value: '\$38,000',
          status: 'Submitted',
          statusColor: Colors.blue,
        ),
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final Map<String, int> counts;
  final Color color;
  const _SummaryBanner({required this.counts, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: counts.entries.map((e) => Column(
          children: [
            Text(e.value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(e.key, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        )).toList(),
      ),
    );
  }
}

class _HardcodedApprovalCard extends StatelessWidget {
  final String ref;
  final String jobName;
  final String description;
  final String value;
  final String status;
  final Color statusColor;

  const _HardcodedApprovalCard({
    required this.ref,
    required this.jobName,
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
                Text(ref, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                StatusBadge(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(jobName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0E9F6E))),
          ],
        ),
      ),
    );
  }
}
