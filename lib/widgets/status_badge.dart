import 'package:flutter/material.dart';

import '../models/ModelProvider.dart';
import '../utils/status_helpers.dart';

/// A coloured badge that displays an entity's status.
///
/// Use the named constructors for type-safe usage:
///   StatusBadge.job(JobStatus.Enquiry)
///   StatusBadge.quote(QuoteStatus.Draft)
///
/// Or use the default constructor with raw label/colour for
/// entities not yet backed by Amplify models (variations, claims).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  /// Badge for a [JobStatus] value.
  StatusBadge.job(JobStatus status, {super.key})
      : label = jobStatusLabel(status),
        color = jobStatusColor(status);

  /// Badge for a [QuoteStatus] value.
  StatusBadge.quote(QuoteStatus status, {super.key})
      : label = quoteStatusLabel(status),
        color = quoteStatusColor(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

