import 'package:flutter/material.dart';

import '../../models/app_state.dart';
import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/app_drawer.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';
import 'daily_log_screen.dart';
import 'work_package_detail_screen.dart';

class SiteManagerDashboardScreen extends StatelessWidget {
  const SiteManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final myPackages = MockData.packagesForUser(state.currentUserId);
    final myTasks = MockData.tasksForUser(state.currentUserId)
        .where((t) => t.status != TaskStatus.completed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARCH — Site Manager'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      drawer: buildArchDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting
          _buildGreeting(state.currentUserName),
          const SizedBox(height: 16),

          // Pending tasks alert
          if (myTasks.isNotEmpty) ...[
            _TaskAlertCard(tasks: myTasks),
            const SizedBox(height: 16),
          ],

          // Quick actions
          _QuickActionsRow(packages: myPackages),
          const SizedBox(height: 20),

          // My Work Packages
          _SectionHeader(
            label: 'MY WORK PACKAGES',
            count: myPackages.length,
          ),
          const SizedBox(height: 8),
          if (myPackages.isEmpty)
            _EmptyPackages()
          else
            ...myPackages.map((p) => _WorkPackageCard(pkg: p)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting,', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(
          _todayLabel(),
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _TaskAlertCard extends StatelessWidget {
  final List<Task> tasks;
  const _TaskAlertCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3A008).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3A008).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: Color(0xFFE3A008), size: 18),
              const SizedBox(width: 8),
              Text(
                '${tasks.length} task${tasks.length != 1 ? 's' : ''} require your attention',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFFE3A008)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 26),
                    const Icon(Icons.chevron_right,
                        size: 14, color: Color(0xFFE3A008)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        taskTypeLabel(t.type),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFE3A008)),
                      ),
                    ),
                    Text(
                      'Due ${t.dueDate ?? 'N/A'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final List<WorkPackage> packages;
  const _QuickActionsRow({required this.packages});

  @override
  Widget build(BuildContext context) {
    final activePackage = packages.firstWhere(
      (p) =>
          p.status == WorkPackageStatus.active ||
          p.status == WorkPackageStatus.variationPending,
      orElse: () => packages.isNotEmpty ? packages.first : _dummyPackage(),
    );

    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.edit_note_outlined,
            label: "Today's Log",
            color: const Color(0xFF1A56DB),
            onTap: packages.isNotEmpty
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyLogScreen(workPackage: activePackage),
                      ),
                    )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.photo_camera_outlined,
            label: 'Add Photo',
            color: const Color(0xFF0E9F6E),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo upload — coming soon')),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.notifications_active_outlined,
            label: 'Report Issue',
            color: Colors.orange,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Issue report — coming soon')),
            ),
          ),
        ),
      ],
    );
  }

  WorkPackage _dummyPackage() => WorkPackage(
        id: '',
        jobId: '',
        siteManagerId: '',
        siteManagerName: '',
        description: '',
        plannedStart: DateTime.now(),
        plannedEnd: DateTime.now(),
        status: WorkPackageStatus.pending,
        resources: '',
        relatedStageIds: [],
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.6)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A56DB))),
        ),
      ],
    );
  }
}

class _WorkPackageCard extends StatelessWidget {
  final WorkPackage pkg;
  const _WorkPackageCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final job = MockData.jobs.firstWhere(
      (j) => j.id == pkg.jobId,
      orElse: () => MockData.jobs.first,
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkPackageDetailScreen(pkg: pkg, job: job),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.description,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(job.siteAddress,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                StatusBadge.workPackage(pkg.status),
              ],
            ),
            const SizedBox(height: 10),

            // Dates
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  '${_fmt(pkg.plannedStart)} → ${_fmt(pkg.plannedEnd)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Resources
            Row(
              children: [
                Icon(Icons.groups_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(pkg.resources,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
              ],
            ),

            // Variation pending warning
            if (pkg.status == WorkPackageStatus.variationPending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3A008).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFE3A008).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: Color(0xFFE3A008), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Work plan update required',
                      style: TextStyle(fontSize: 11, color: Color(0xFFE3A008)),
                    ),
                  ],
                ),
              ),
            ],

            // Navigate hint
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('View details',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400])),
                Icon(Icons.chevron_right, size: 14, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _EmptyPackages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.construction_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No work packages assigned',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask your admin/manager to assign work packages to you.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
