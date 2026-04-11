import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';

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

// ── Shared approval card ──────────────────────────────────────────────────────

class _ApprovalCard extends StatelessWidget {
  final String ref;
  final String subcontractor;
  final String jobName;
  final String description;
  final String value;
  final JobStatus status;
  final String date;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onView;

  const _ApprovalCard({
    required this.ref,
    required this.subcontractor,
    required this.jobName,
    required this.description,
    required this.value,
    required this.status,
    required this.date,
    required this.onApprove,
    required this.onDecline,
    required this.onView,
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
                StatusBadge(status),
                const Spacer(),
                Text(date, style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(jobName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 2),
            Text(subcontractor, style: const TextStyle(fontSize: 12, color: Colors.black38)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0E9F6E))),
                const Spacer(),
                TextButton(onPressed: onView, child: const Text('View')),
                const SizedBox(width: 8),
                if (status == JobStatus.submitted || status == JobStatus.pending) ...[
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

// ── Approval dialog ───────────────────────────────────────────────────────────

void _showApprovalDialog(BuildContext context, {required bool isApprove, required String ref}) {
  final commentController = TextEditingController();
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(isApprove ? 'Approve $ref?' : 'Decline $ref?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isApprove
                ? 'This will notify the subcontractor and update the contract.'
                : 'Please provide a reason for declining.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isApprove ? 'Optional comments...' : 'Reason for declining...',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isApprove ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$ref ${isApprove ? 'approved' : 'declined'}')),
            );
          },
          child: Text(isApprove ? 'Approve' : 'Decline'),
        ),
      ],
    ),
  );
}

// ── Quotes tab ────────────────────────────────────────────────────────────────

class _QuotesApprovalTab extends StatelessWidget {
  final Color roleColor;
  const _QuotesApprovalTab({required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryBanner(counts: {'Submitted': 2, 'Accepted': 5, 'Rejected': 1}, color: roleColor),
        const SizedBox(height: 12),
        _ApprovalCard(
          ref: 'Q-002',
          subcontractor: 'Apex Brickwork Pty Ltd',
          jobName: 'J001 – Fitzroy Residential',
          description: 'Stage 2 – Blockwork (internal walls)',
          value: '\$62,000 ex. GST',
          status: JobStatus.submitted,
          date: '01 Apr 2026',
          onApprove: () => _showApprovalDialog(context, isApprove: true, ref: 'Q-002'),
          onDecline: () => _showApprovalDialog(context, isApprove: false, ref: 'Q-002'),
          onView: () {},
        ),
        _ApprovalCard(
          ref: 'Q-004',
          subcontractor: 'Melbourne Masonry Co.',
          jobName: 'J003 – Collingwood Warehouse',
          description: 'Full brickwork package – warehouse shell',
          value: '\$210,000 ex. GST',
          status: JobStatus.submitted,
          date: '08 Apr 2026',
          onApprove: () => _showApprovalDialog(context, isApprove: true, ref: 'Q-004'),
          onDecline: () => _showApprovalDialog(context, isApprove: false, ref: 'Q-004'),
          onView: () {},
        ),
      ],
    );
  }
}

// ── Variations tab ────────────────────────────────────────────────────────────

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
        _ApprovalCard(
          ref: 'V-003',
          subcontractor: 'Apex Brickwork Pty Ltd',
          jobName: 'J001 – Fitzroy Residential',
          description: 'Brick type change – east facade (heritage brick specified)',
          value: '\$3,400 ex. GST',
          status: JobStatus.pending,
          date: '10 Apr 2026',
          onApprove: () => _showApprovalDialog(context, isApprove: true, ref: 'V-003'),
          onDecline: () => _showApprovalDialog(context, isApprove: false, ref: 'V-003'),
          onView: () {},
        ),
        // Approved variation (read-only)
        _ApprovalCard(
          ref: 'V-001',
          subcontractor: 'Apex Brickwork Pty Ltd',
          jobName: 'J001 – Fitzroy Residential',
          description: 'Additional lintels – window revisions (SI-007)',
          value: '\$4,200 ex. GST',
          status: JobStatus.approved,
          date: '22 Mar 2026',
          onApprove: () {},
          onDecline: () {},
          onView: () {},
        ),
      ],
    );
  }
}

// ── Claims tab ────────────────────────────────────────────────────────────────

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
        _ClaimDetailCard(isQS: isQS),
      ],
    );
  }
}

class _ClaimDetailCard extends StatelessWidget {
  final bool isQS;
  const _ClaimDetailCard({required this.isQS});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('PC-002 – March 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                StatusBadge(JobStatus.submitted),
              ],
            ),
            const SizedBox(height: 4),
            const Text('J001 – Fitzroy Residential', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const Text('Apex Brickwork Pty Ltd', style: TextStyle(color: Colors.black38, fontSize: 12)),
            const Divider(height: 20),

            // Financials
            _ClaimRow(label: 'Gross Claim', value: '\$40,000.00'),
            _ClaimRow(label: 'Retention (5%)', value: '-\$2,000.00', negative: true),
            _ClaimRow(label: 'Net Certified', value: '\$38,000.00', bold: true),
            const Divider(height: 20),

            // QS adjustment field (only shown to QS)
            if (isQS) ...[
              const Text('QS Assessment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: '40000',
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'Certified Amount (ex. GST)',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 2,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'QS Comments (optional)',
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                TextButton(onPressed: () {}, child: const Text('View Documents')),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => _showApprovalDialog(context, isApprove: false, ref: 'PC-002'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showApprovalDialog(context, isApprove: true, ref: 'PC-002'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: Text(isQS ? 'Certify' : 'Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool negative;

  const _ClaimRow({required this.label, required this.value, this.bold = false, this.negative = false});

  @override
  Widget build(BuildContext context) {
    final color = negative ? Colors.red : (bold ? const Color(0xFF0E9F6E) : Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final Map<String, int> counts;
  final Color color;
  const _SummaryBanner({required this.counts, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
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
