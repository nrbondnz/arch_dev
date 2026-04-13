import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final WorkPackage pkg;
  final Job job;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.pkg,
    required this.job,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late DateTime _revisedEnd;
  final _resourceNotesCtrl = TextEditingController();
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _revisedEnd = widget.pkg.plannedEnd;
  }

  @override
  void dispose() {
    _resourceNotesCtrl.dispose();
    super.dispose();
  }

  Variation? get _variation {
    if (widget.task.referenceId == null) return null;
    return MockData.variations[widget.job.id]
        ?.firstWhere((v) => v.id == widget.task.referenceId,
            orElse: () => MockData.variations[widget.job.id]!.first);
  }

  @override
  Widget build(BuildContext context) {
    final v = _variation;
    final isCompleted = _completed || widget.task.status == TaskStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: Text(taskTypeLabel(widget.task.type)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF0E9F6E).withValues(alpha: 0.08)
                    : const Color(0xFFE3A008).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF0E9F6E).withValues(alpha: 0.3)
                        : const Color(0xFFE3A008).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_outline : Icons.pending_actions,
                    color: isCompleted
                        ? const Color(0xFF0E9F6E)
                        : const Color(0xFFE3A008),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompleted ? 'Task Completed' : 'Action Required',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isCompleted
                                  ? const Color(0xFF0E9F6E)
                                  : const Color(0xFFE3A008)),
                        ),
                        if (widget.task.dueDate != null)
                          Text(
                            isCompleted
                                ? 'Completed'
                                : 'Due ${widget.task.dueDate}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge.task(isCompleted ? TaskStatus.completed : widget.task.status),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task description
            _SectionLabel('Task'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Text(
                widget.task.description,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // Variation details (if this task is linked to a variation)
            if (v != null) ...[
              _SectionLabel('Variation Details'),
              Container(
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
                        const Text('Variation ',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        Text(v.id,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A56DB))),
                        const Spacer(),
                        StatusBadge.variation(v.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(v.description,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${v.reason}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    // Financial + time impact chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ImpactChip(
                          icon: Icons.attach_money,
                          label: formatNzd(v.price),
                          color: const Color(0xFF0E9F6E),
                        ),
                        _ImpactChip(
                          icon: Icons.schedule,
                          label: v.timeImpactDays == 0
                              ? 'No time change'
                              : '${v.timeImpactDays > 0 ? '+' : ''}${v.timeImpactDays} day${v.timeImpactDays.abs() != 1 ? 's' : ''}',
                          color: v.timeImpactDays != 0
                              ? const Color(0xFFE3A008)
                              : Colors.grey,
                        ),
                        if (v.approvedAt != null)
                          _ImpactChip(
                            icon: Icons.check_circle_outline,
                            label: 'Approved ${v.approvedAt}',
                            color: const Color(0xFF0E9F6E),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Current plan
            _SectionLabel('Current Work Package'),
            _PlanRow(Icons.calendar_today_outlined, 'Planned End',
                _fmtDate(widget.pkg.plannedEnd)),
            _PlanRow(Icons.groups_outlined, 'Resources', widget.pkg.resources),
            const SizedBox(height: 20),

            // Revised plan inputs (only if not completed)
            if (!isCompleted) ...[
              _SectionLabel('Updated Work Plan'),
              _Label('Revised End Date'),
              GestureDetector(
                onTap: _pickRevisedDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _revisedEnd != widget.pkg.plannedEnd
                            ? const Color(0xFFE3A008)
                            : Colors.grey.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(8),
                    color: _revisedEnd != widget.pkg.plannedEnd
                        ? const Color(0xFFE3A008).withValues(alpha: 0.04)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: _revisedEnd != widget.pkg.plannedEnd
                            ? const Color(0xFFE3A008)
                            : const Color(0xFF1A56DB),
                      ),
                      const SizedBox(width: 10),
                      Text(_fmtDate(_revisedEnd),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _revisedEnd != widget.pkg.plannedEnd
                                  ? const Color(0xFFE3A008)
                                  : Colors.black87)),
                      const Spacer(),
                      if (_revisedEnd != widget.pkg.plannedEnd)
                        Text(
                          '+${_revisedEnd.difference(widget.pkg.plannedEnd).inDays} day${_revisedEnd.difference(widget.pkg.plannedEnd).inDays != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE3A008),
                              fontWeight: FontWeight.w600),
                        )
                      else
                        Text('Tap to change',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Label('Resource Adjustment Notes (optional)'),
              TextField(
                controller: _resourceNotesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'e.g. Adding 1 extra bricklayer on Thu-Fri to cover time impact',
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Complete task button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _completeTask,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Complete Task — Work Plan Updated'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E9F6E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],

            // Completed state
            if (isCompleted) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E9F6E).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF0E9F6E), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Work plan updated',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0E9F6E))),
                          Text(
                            'Revised end: ${_fmtDate(_revisedEnd)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRevisedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _revisedEnd,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _revisedEnd = picked);
  }

  void _completeTask() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Task Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This will mark the UpdateWorkPlan task as complete and clear the work package\'s Variation Pending status.'),
            const SizedBox(height: 12),
            if (_revisedEnd != widget.pkg.plannedEnd)
              Text(
                'Revised end date: ${_fmtDate(_revisedEnd)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _completed = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task completed — work plan updated (demo)'),
                  backgroundColor: Color(0xFF0E9F6E),
                ),
              );
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E9F6E)),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ImpactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ImpactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PlanRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
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
