import 'package:flutter/material.dart';

enum JobStatus { draft, submitted, accepted, rejected, pending, approved, declined, paid }

class StatusBadge extends StatelessWidget {
  final JobStatus status;

  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }

  String get _label => switch (status) {
        JobStatus.draft => 'Draft',
        JobStatus.submitted => 'Submitted',
        JobStatus.accepted => 'Accepted',
        JobStatus.rejected => 'Rejected',
        JobStatus.pending => 'Pending',
        JobStatus.approved => 'Approved',
        JobStatus.declined => 'Declined',
        JobStatus.paid => 'Paid',
      };

  Color get _color => switch (status) {
        JobStatus.draft => Colors.grey,
        JobStatus.submitted => Colors.blue,
        JobStatus.accepted => Colors.green,
        JobStatus.rejected => Colors.red,
        JobStatus.pending => Colors.orange,
        JobStatus.approved => Colors.green,
        JobStatus.declined => Colors.red,
        JobStatus.paid => Colors.teal,
      };
}
