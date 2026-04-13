import 'package:flutter/material.dart';

import '../../models/app_state.dart';
import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/app_drawer.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';
import 'job_list_screen.dart';
import 'job_detail_screen.dart';
import 'variation_form_screen.dart';
import 'stage_claim_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

  // Derived counts from mock data
  int get _activeJobCount =>
      MockData.jobs.where((j) => j.status == JobStatus.inProgress).length;

  int get _pendingVariationCount => MockData.variations.values
      .expand((l) => l)
      .where((v) =>
          v.status == VariationStatus.logged ||
          v.status == VariationStatus.pricedUp ||
          v.status == VariationStatus.documentSent)
      .length;

  int get _outstandingClaimCount => MockData.claims.values
      .expand((l) => l)
      .where((c) => c.status == ClaimStatus.documentSent)
      .length;

  int get _outstandingTaskCount =>
      MockData.tasks.where((t) => t.status == TaskStatus.pending).length;

  /// Stages whose trigger condition is met and no claim exists yet.
  List<_StageTriggerItem> get _readyStages {
    final result = <_StageTriggerItem>[];
    for (final job in MockData.jobs) {
      final jobStages = MockData.stages[job.id] ?? [];
      for (final stage in jobStages) {
        if (stage.status == StageStatus.active &&
            stage.triggerType == StageTriggerType.percentComplete) {
          final threshold = double.tryParse(stage.triggerValue) ?? 100;
          if (stage.percentComplete >= threshold) {
            result.add(_StageTriggerItem(job: job, stage: stage));
          }
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARCH Developments'),
        centerTitle: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      drawer: buildArchDrawer(context),
      body: _navIndex == 0
          ? _buildHome()
          : _navIndex == 1
              ? const JobListScreen()
              : _buildPlaceholder('Variations', Icons.edit_note),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Jobs'),
          NavigationDestination(
              icon: Icon(Icons.edit_note),
              selectedIcon: Icon(Icons.edit),
              label: 'Variations'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Claims'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final name = AppState().currentUserName.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final readyStages = _readyStages;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text('$greeting, $name',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text("Here's your business at a glance",
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 20),

            // Summary tiles
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              childAspectRatio: 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryTile(
                  label: 'Active Jobs',
                  count: '$_activeJobCount',
                  icon: Icons.work_outline,
                  color: const Color(0xFF1A56DB),
                  onTap: () => setState(() => _navIndex = 1),
                ),
                _SummaryTile(
                  label: 'Claims Awaiting',
                  count: '$_outstandingClaimCount',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF0E9F6E),
                  onTap: () {},
                ),
                _SummaryTile(
                  label: 'Variations Pending',
                  count: '$_pendingVariationCount',
                  icon: Icons.edit_note,
                  color: const Color(0xFFE3A008),
                  onTap: () => setState(() => _navIndex = 2),
                ),
                _SummaryTile(
                  label: 'Tasks Outstanding',
                  count: '$_outstandingTaskCount',
                  icon: Icons.task_alt,
                  color: Colors.purple,
                  onTap: () {},
                ),
              ],
            ),

            // Stage triggers alert
            if (readyStages.isNotEmpty) ...[
              const SizedBox(height: 20),
              _AlertCard(
                icon: Icons.payments_outlined,
                color: const Color(0xFF0E9F6E),
                title: '${readyStages.length} stage${readyStages.length > 1 ? 's' : ''} ready to claim',
                items: readyStages
                    .map((s) =>
                        '${s.stage.description} — ${formatNzdShort(s.stage.scheduledValue)}')
                    .toList(),
                actionLabel: 'Create Claim',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StageClaimScreen(
                      job: readyStages.first.job,
                      stage: readyStages.first.stage,
                    ),
                  ),
                ),
              ),
            ],

            // Variations pending send
            if (_pendingVariationCount > 0) ...[
              const SizedBox(height: 12),
              _AlertCard(
                icon: Icons.send_outlined,
                color: const Color(0xFFE3A008),
                title: '$_pendingVariationCount variation${_pendingVariationCount > 1 ? 's' : ''} need document sent',
                items: MockData.variations.values
                    .expand((l) => l)
                    .where((v) => v.status == VariationStatus.pricedUp)
                    .map((v) => '${v.id} — ${v.description.length > 40 ? '${v.description.substring(0, 40)}…' : v.description}')
                    .toList(),
                actionLabel: 'View',
                onAction: () => setState(() => _navIndex = 2),
              ),
            ],

            const SizedBox(height: 24),

            // Active jobs list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Jobs',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => setState(() => _navIndex = 1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...MockData.jobs
                .where((j) =>
                    j.status == JobStatus.inProgress ||
                    j.status == JobStatus.quoted ||
                    j.status == JobStatus.contracted)
                .map((job) => _JobCard(job: job)),

            const SizedBox(height: 24),

            // Quick actions
            const Text('Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'New Job',
                  color: const Color(0xFF1A56DB),
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.description_outlined,
                  label: 'New Quote',
                  color: Colors.indigo,
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.edit_note,
                  label: 'Log Variation',
                  color: const Color(0xFFE3A008),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VariationFormScreen(
                        job: MockData.jobs.first,
                      ),
                    ),
                  ),
                ),
                _QuickAction(
                  icon: Icons.payments_outlined,
                  label: 'New Claim',
                  color: const Color(0xFF0E9F6E),
                  onTap: () {
                    final job = MockData.jobs.first;
                    final stage =
                        MockData.stages[job.id]!.firstWhere((s) => s.status == StageStatus.active);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StageClaimScreen(job: job, stage: stage),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Backend integration coming in Phase 2',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;
  final String actionLabel;
  final VoidCallback onAction;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: color)),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...items.map((i) => Text('• $i',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[700]))),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF1A56DB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.siteAddress,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(job.clientName,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge.domainJob(job.status),
                const SizedBox(height: 4),
                if (job.totalContractValue > 0)
                  Text(
                    formatNzdShort(job.totalContractValue),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 5),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageTriggerItem {
  final Job job;
  final Stage stage;
  const _StageTriggerItem({required this.job, required this.stage});
}
