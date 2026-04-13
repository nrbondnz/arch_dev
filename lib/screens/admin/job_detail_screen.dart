import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';
import 'contract_setup_screen.dart';
import 'work_package_screen.dart';
import 'variation_form_screen.dart';
import 'stage_claim_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(job.siteAddress,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Stages'),
              Tab(text: 'Work Packages'),
              Tab(text: 'Quote'),
              Tab(text: 'Variations'),
              Tab(text: 'Claims'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(job: job),
            _StagesTab(job: job),
            _WorkPackagesTab(job: job),
            _QuoteTab(job: job),
            _VariationsTab(job: job),
            _ClaimsTab(job: job),
          ],
        ),
        floatingActionButton: _buildFab(context),
      ),
    );
  }

  Widget? _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showActions(context),
      backgroundColor: const Color(0xFF1A56DB),
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ActionSheet(job: job),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  final Job job;
  const _ActionSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _ActionTile(Icons.layers_outlined, 'Set Up Contract Stages',
                const Color(0xFF1A56DB), () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ContractSetupScreen(job: job)));
            }),
            _ActionTile(Icons.work_outline, 'Manage Work Packages',
                Colors.teal, () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => WorkPackageScreen(job: job)));
            }),
            _ActionTile(Icons.edit_note, 'Log Variation', const Color(0xFFE3A008),
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => VariationFormScreen(job: job)));
            }),
            _ActionTile(Icons.payments_outlined, 'Create Stage Claim',
                const Color(0xFF0E9F6E), () {
              final stages = MockData.stages[job.id] ?? [];
              final activeStage = stages.where((s) => s.status == StageStatus.active).firstOrNull;
              if (activeStage != null) {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => StageClaimScreen(job: job, stage: activeStage)));
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No active stage to claim')));
              }
            }),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration:
            BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

// ── Tab: Overview ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Job job;
  const _OverviewTab({required this.job});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge.domainJob(job.status),
                    const Spacer(),
                    if (job.totalContractValue > 0)
                      Text(formatNzd(job.totalContractValue),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(job.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionHeader('Client Details'),
          _InfoRow('Company', job.clientName),
          _InfoRow('Contact', job.clientContactName),
          _InfoRow('Email', job.clientEmail),
          const SizedBox(height: 16),

          _SectionHeader('Contract'),
          _InfoRow('Type', job.contractType),
          _InfoRow('Payment Terms', job.paymentTerms),
          const SizedBox(height: 16),

          _SectionHeader('Documents'),
          _DocRow('Signed Subcontract Agreement', Icons.description_outlined),
          _DocRow('RAMS — Brickwork & Blockwork', Icons.safety_check_outlined),
          _DocRow('Insurance Certificate', Icons.verified_outlined),
          _DocRow('IFC Drawings Rev C', Icons.architecture_outlined),
        ],
      ),
    );
  }
}

// ── Tab: Stages ────────────────────────────────────────────────────────────────

class _StagesTab extends StatelessWidget {
  final Job job;
  const _StagesTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final stages = MockData.stages[job.id] ?? [];
    if (stages.isEmpty) {
      return _EmptyState(
        icon: Icons.layers_outlined,
        message: 'No stages defined yet',
        actionLabel: 'Set Up Stages',
        onAction: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ContractSetupScreen(job: job))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _StageCard(stage: stages[i]),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Stage stage;
  const _StageCard({required this.stage});

  @override
  Widget build(BuildContext context) {
    final color = stageStatusColor(stage.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: Center(
                  child: Text('${stage.sequence}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(stage.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14))),
              StatusBadge.stage(stage.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StageChip(
                  Icons.attach_money, formatNzdShort(stage.scheduledValue)),
              const SizedBox(width: 8),
              _StageChip(Icons.flag_outlined,
                  '${stageTriggerLabel(stage.triggerType)}${stage.triggerValue.isNotEmpty ? ': ${stage.triggerValue}' : ''}'),
              const SizedBox(width: 8),
              _StageChip(Icons.percent,
                  '${(stage.retentionRate * 100).toStringAsFixed(0)}% retention'),
            ],
          ),
          if (stage.status == StageStatus.active && stage.percentComplete > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stage.percentComplete / 100,
                      backgroundColor: Colors.grey[200],
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${stage.percentComplete.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
            const SizedBox(height: 4),
            if (stage.triggerType == StageTriggerType.percentComplete) ...[
              Text(
                  'Trigger at ${stage.triggerValue}% — ${stage.percentComplete < double.parse(stage.triggerValue) ? '${(double.parse(stage.triggerValue) - stage.percentComplete).toStringAsFixed(0)}% to go' : 'READY TO CLAIM'}',
                  style: TextStyle(
                      fontSize: 11,
                      color: stage.percentComplete >=
                              double.parse(stage.triggerValue)
                          ? const Color(0xFF0E9F6E)
                          : Colors.grey[600])),
            ],
          ],
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StageChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Tab: Work Packages ────────────────────────────────────────────────────────

class _WorkPackagesTab extends StatelessWidget {
  final Job job;
  const _WorkPackagesTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final packages = MockData.workPackages[job.id] ?? [];
    if (packages.isEmpty) {
      return _EmptyState(
        icon: Icons.work_outline,
        message: 'No work packages yet',
        actionLabel: 'Create Work Package',
        onAction: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => WorkPackageScreen(job: job))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PackageCard(pkg: packages[i]),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final WorkPackage pkg;
  const _PackageCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(pkg.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14))),
              StatusBadge.workPackage(pkg.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(pkg.siteManagerName,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(width: 12),
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${_fmtDate(pkg.plannedStart)} → ${_fmtDate(pkg.plannedEnd)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(pkg.resources,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ),
          if (pkg.status == WorkPackageStatus.variationPending) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFFE3A008).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 13, color: Color(0xFFE3A008)),
                  SizedBox(width: 5),
                  Text('Work plan update task outstanding',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFFE3A008))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${_month(d.month)} ${d.year}';
  String _month(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

// ── Tab: Quote ────────────────────────────────────────────────────────────────

class _QuoteTab extends StatelessWidget {
  final Job job;
  const _QuoteTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final quote = MockData.quotes[job.id];
    if (quote == null) {
      return _EmptyState(
        icon: Icons.description_outlined,
        message: 'No quote yet',
        actionLabel: 'Build Quote',
        onAction: () {},
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.domainQuote(quote.status),
              const Spacer(),
              if (quote.documentSentAt != null)
                Text('Sent ${quote.documentSentAt}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          _SectionHeader('Line Items'),
          ...quote.lineItems.map((li) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(li.description,
                            style: const TextStyle(fontSize: 13))),
                    Text(
                        '${li.quantity.toStringAsFixed(0)} ${li.unit} @ \$${li.rate.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 8),
                    Text(formatNzdShort(li.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total: ',
                  style: TextStyle(color: Colors.grey[600])),
              Text(formatNzd(quote.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          if (quote.exclusions.isNotEmpty) ...[
            _SectionHeader('Exclusions'),
            ...quote.exclusions.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_circle_outline,
                          size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(e, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          ],
          if (quote.acceptedAt != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF0E9F6E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF0E9F6E), size: 16),
                  const SizedBox(width: 8),
                  Text('Client accepted ${quote.acceptedAt}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF0E9F6E))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab: Variations ───────────────────────────────────────────────────────────

class _VariationsTab extends StatelessWidget {
  final Job job;
  const _VariationsTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final vars = MockData.variations[job.id] ?? [];
    if (vars.isEmpty) {
      return _EmptyState(
        icon: Icons.edit_note,
        message: 'No variations',
        actionLabel: 'Log Variation',
        onAction: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => VariationFormScreen(job: job))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vars.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _VariationCard(v: vars[i]),
    );
  }
}

class _VariationCard extends StatelessWidget {
  final Variation v;
  const _VariationCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(v.id,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13,
                      color: Color(0xFF1A56DB))),
              const SizedBox(width: 8),
              if (v.clientInitiated)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Client request',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              const Spacer(),
              StatusBadge.variation(v.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(v.description,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('\$${v.price.toStringAsFixed(2)} ex. GST',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (v.timeImpactDays != 0) ...[
                const SizedBox(width: 10),
                Icon(Icons.schedule, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 3),
                Text(
                    '${v.timeImpactDays > 0 ? '+' : ''}${v.timeImpactDays} day${v.timeImpactDays.abs() != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ],
          ),
          if (v.documentSentAt != null) ...[
            const SizedBox(height: 4),
            Text('Sent ${v.documentSentAt}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
          if (v.approvedAt != null) ...[
            const SizedBox(height: 4),
            Text('Approved ${v.approvedAt}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF0E9F6E))),
          ],
        ],
      ),
    );
  }
}

// ── Tab: Claims ───────────────────────────────────────────────────────────────

class _ClaimsTab extends StatelessWidget {
  final Job job;
  const _ClaimsTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final claims = MockData.claims[job.id] ?? [];
    if (claims.isEmpty) {
      return const _EmptyState(
          icon: Icons.payments_outlined, message: 'No claims submitted yet');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: claims.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ClaimCard(claim: claims[i]),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final StageClaim claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(claim.periodDescription,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14))),
              StatusBadge.claim(claim.status),
            ],
          ),
          const SizedBox(height: 12),
          _FinRow('Gross Claim', claim.grossClaimValue),
          _FinRow('Retention Held', -claim.retentionHeld,
              color: Colors.red.shade700),
          const Divider(height: 12),
          _FinRow('Claim Total', claim.claimTotal, bold: true),
          if (claim.paidAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 14, color: Color(0xFF0E9F6E)),
                const SizedBox(width: 4),
                Text('Paid ${claim.paidAt}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF0E9F6E))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  final Color? color;

  const _FinRow(this.label, this.amount,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? (bold ? null : Colors.grey[700]))),
          Text(
            formatNzd(amount.abs()),
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? (bold ? null : Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.6)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String name;
  final IconData icon;
  const _DocRow(this.name, this.icon);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: const Color(0xFF1A56DB)),
      title: Text(name, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.download_outlined, size: 18, color: Colors.grey),
      dense: true,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
