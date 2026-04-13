import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';
import 'daily_log_screen.dart';
import 'task_detail_screen.dart';

class WorkPackageDetailScreen extends StatelessWidget {
  final WorkPackage pkg;
  final Job job;

  const WorkPackageDetailScreen({
    super.key,
    required this.pkg,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    final logs = MockData.dailyLogs[pkg.id] ?? [];
    final tasks = MockData.tasks
        .where((t) =>
            t.referenceId != null &&
            MockData.variations[job.id]
                    ?.any((v) => v.id == t.referenceId && v.workPackageId == pkg.id) ==
                true)
        .toList();
    final relatedStages = MockData.stages[job.id]
            ?.where((s) => pkg.relatedStageIds.contains(s.id))
            .toList() ??
        [];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pkg.description, maxLines: 1, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Daily Logs'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(pkg: pkg, job: job, stages: relatedStages),
            _DailyLogsTab(logs: logs, pkg: pkg),
            _TasksTab(tasks: tasks, pkg: pkg, job: job),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DailyLogScreen(workPackage: pkg),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text("Today's Log"),
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final WorkPackage pkg;
  final Job job;
  final List<Stage> stages;

  const _OverviewTab({
    required this.pkg,
    required this.job,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: workPackageStatusColor(pkg.status).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: workPackageStatusColor(pkg.status).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                StatusBadge.workPackage(pkg.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    workPackageStatusLabel(pkg.status),
                    style: TextStyle(
                        fontSize: 13,
                        color: workPackageStatusColor(pkg.status),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionLabel('Site Details'),
          _InfoRow(Icons.location_on_outlined, 'Site', job.siteAddress),
          _InfoRow(Icons.person_outline, 'Client', job.clientName),
          _InfoRow(Icons.groups_outlined, 'Resources', pkg.resources),

          const SizedBox(height: 16),
          _SectionLabel('Schedule'),
          _InfoRow(Icons.play_arrow_outlined, 'Planned Start', _fmt(pkg.plannedStart)),
          _InfoRow(Icons.stop_outlined, 'Planned End', _fmt(pkg.plannedEnd)),
          _InfoRow(Icons.timer_outlined, 'Duration',
              '${pkg.plannedEnd.difference(pkg.plannedStart).inDays} days'),

          if (stages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Stage Progress'),
            ...stages.map((s) => _StageProgressCard(stage: s)),
          ],

          if (pkg.status == WorkPackageStatus.variationPending) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3A008).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFE3A008).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Color(0xFFE3A008), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have a pending task: update the work plan to reflect an approved variation.',
                      style: TextStyle(fontSize: 13, color: Color(0xFFE3A008)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _StageProgressCard extends StatelessWidget {
  final Stage stage;
  const _StageProgressCard({required this.stage});

  @override
  Widget build(BuildContext context) {
    final pct = stage.percentComplete / 100;
    final color = stageStatusColor(stage.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stage.description,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              StatusBadge.stage(stage.status),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage.triggerType == StageTriggerType.percentComplete
                    ? 'Trigger at ${stage.triggerValue}%'
                    : stageTriggerLabel(stage.triggerType),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                '${stage.percentComplete}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Daily Logs Tab ────────────────────────────────────────────────────────────

class _DailyLogsTab extends StatelessWidget {
  final List<DailyLog> logs;
  final WorkPackage pkg;

  const _DailyLogsTab({required this.logs, required this.pkg});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No daily logs yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tap the button below to add today\'s log',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }

    // Sort descending by date
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _LogCard(log: sorted[i]),
    );
  }
}

class _LogCard extends StatelessWidget {
  final DailyLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${log.date.day} ${months[log.date.month - 1]} ${log.date.year}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A56DB)),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${log.labourHours}h',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (log.photoCount > 0) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.photo_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${log.photoCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(log.progressNotes,
              style: const TextStyle(fontSize: 13, height: 1.4)),
          if (log.materialsUsed != null && log.materialsUsed!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(log.materialsUsed!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tasks Tab ─────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  final List<Task> tasks;
  final WorkPackage pkg;
  final Job job;

  const _TasksTab({required this.tasks, required this.pkg, required this.job});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No outstanding tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('All clear!',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...tasks.map((t) => _TaskCard(task: t, pkg: pkg, job: job)),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final WorkPackage pkg;
  final Job job;

  const _TaskCard({required this.task, required this.pkg, required this.job});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    return GestureDetector(
      onTap: isCompleted
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TaskDetailScreen(task: task, pkg: pkg, job: job),
                ),
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCompleted
                  ? Colors.grey.withValues(alpha: 0.1)
                  : const Color(0xFFE3A008).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.grey.withValues(alpha: 0.1)
                    : const Color(0xFFE3A008).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.pending_actions,
                color:
                    isCompleted ? Colors.grey : const Color(0xFFE3A008),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(taskTypeLabel(task.type),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isCompleted ? Colors.grey : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(
                    task.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text('Due ${task.dueDate}',
                        style: TextStyle(
                            fontSize: 11,
                            color: isCompleted
                                ? Colors.grey
                                : const Color(0xFFE3A008))),
                  ],
                ],
              ),
            ),
            if (!isCompleted)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
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
