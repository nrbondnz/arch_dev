import 'package:flutter/material.dart';

import '../models/ModelProvider.dart';
import '../models/domain.dart' as d;
import '../utils/status_helpers.dart';
import '../utils/domain_helpers.dart' as dh;

/// A coloured badge that displays an entity's status.
///
/// Legacy constructors use Amplify-generated enums (job, quote).
/// Domain constructors use the new pure-Dart domain enums.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  // ── Legacy Amplify constructors ───────────────────────────────────────────

  /// Badge for an Amplify [JobStatus] value (legacy screens).
  StatusBadge.job(JobStatus status, {super.key})
      : label = jobStatusLabel(status),
        color = jobStatusColor(status);

  /// Badge for an Amplify [QuoteStatus] value (legacy screens).
  StatusBadge.quote(QuoteStatus status, {super.key})
      : label = quoteStatusLabel(status),
        color = quoteStatusColor(status);

  // ── Domain constructors ───────────────────────────────────────────────────

  StatusBadge.domainJob(d.JobStatus status, {super.key})
      : label = dh.jobStatusLabel(status),
        color = dh.jobStatusColor(status);

  StatusBadge.stage(d.StageStatus status, {super.key})
      : label = dh.stageStatusLabel(status),
        color = dh.stageStatusColor(status);

  StatusBadge.workPackage(d.WorkPackageStatus status, {super.key})
      : label = dh.workPackageStatusLabel(status),
        color = dh.workPackageStatusColor(status);

  StatusBadge.domainQuote(d.QuoteStatus status, {super.key})
      : label = dh.domainQuoteStatusLabel(status),
        color = dh.domainQuoteStatusColor(status);

  StatusBadge.variation(d.VariationStatus status, {super.key})
      : label = dh.variationStatusLabel(status),
        color = dh.variationStatusColor(status);

  StatusBadge.claim(d.ClaimStatus status, {super.key})
      : label = dh.claimStatusLabel(status),
        color = dh.claimStatusColor(status);

  StatusBadge.task(d.TaskStatus status, {super.key})
      : label = dh.taskStatusLabel(status),
        color = dh.taskStatusColor(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

