import 'package:flutter/material.dart';
import '../models/domain.dart';

// ── Job ───────────────────────────────────────────────────────────────────────

String jobStatusLabel(JobStatus s) => switch (s) {
      JobStatus.enquiry => 'Enquiry',
      JobStatus.quoted => 'Quoted',
      JobStatus.contracted => 'Contracted',
      JobStatus.mobilised => 'Mobilising',
      JobStatus.inProgress => 'In Progress',
      JobStatus.variationPending => 'Variation Pending',
      JobStatus.completed => 'Completed',
      JobStatus.closed => 'Closed',
    };

Color jobStatusColor(JobStatus s) => switch (s) {
      JobStatus.enquiry => Colors.grey,
      JobStatus.quoted => const Color(0xFF1A56DB),
      JobStatus.contracted => Colors.teal,
      JobStatus.mobilised => Colors.cyan.shade700,
      JobStatus.inProgress => const Color(0xFF0E9F6E),
      JobStatus.variationPending => const Color(0xFFE3A008),
      JobStatus.completed => Colors.green.shade800,
      JobStatus.closed => Colors.grey.shade500,
    };

// ── Stage ─────────────────────────────────────────────────────────────────────

String stageStatusLabel(StageStatus s) => switch (s) {
      StageStatus.pending => 'Pending',
      StageStatus.active => 'Active',
      StageStatus.claimDraft => 'Claim Draft',
      StageStatus.documentSent => 'Claim Sent',
      StageStatus.paid => 'Paid',
    };

Color stageStatusColor(StageStatus s) => switch (s) {
      StageStatus.pending => Colors.grey,
      StageStatus.active => const Color(0xFF0E9F6E),
      StageStatus.claimDraft => Colors.orange,
      StageStatus.documentSent => const Color(0xFF1A56DB),
      StageStatus.paid => Colors.green.shade800,
    };

String stageTriggerLabel(StageTriggerType t) => switch (t) {
      StageTriggerType.milestone => 'Milestone',
      StageTriggerType.date => 'Date',
      StageTriggerType.percentComplete => '% Complete',
      StageTriggerType.manual => 'Manual',
    };

// ── Work Package ──────────────────────────────────────────────────────────────

String workPackageStatusLabel(WorkPackageStatus s) => switch (s) {
      WorkPackageStatus.pending => 'Pending',
      WorkPackageStatus.active => 'Active',
      WorkPackageStatus.variationPending => 'Variation Pending',
      WorkPackageStatus.completed => 'Completed',
    };

Color workPackageStatusColor(WorkPackageStatus s) => switch (s) {
      WorkPackageStatus.pending => Colors.grey,
      WorkPackageStatus.active => const Color(0xFF0E9F6E),
      WorkPackageStatus.variationPending => const Color(0xFFE3A008),
      WorkPackageStatus.completed => Colors.green.shade800,
    };

// ── Quote ─────────────────────────────────────────────────────────────────────

String domainQuoteStatusLabel(QuoteStatus s) => switch (s) {
      QuoteStatus.draft => 'Draft',
      QuoteStatus.submitted => 'Submitted',
      QuoteStatus.documentSent => 'Sent to Client',
      QuoteStatus.accepted => 'Accepted',
      QuoteStatus.rejected => 'Rejected',
    };

Color domainQuoteStatusColor(QuoteStatus s) => switch (s) {
      QuoteStatus.draft => Colors.grey,
      QuoteStatus.submitted => Colors.orange,
      QuoteStatus.documentSent => const Color(0xFF1A56DB),
      QuoteStatus.accepted => const Color(0xFF0E9F6E),
      QuoteStatus.rejected => Colors.red,
    };

// ── Variation ─────────────────────────────────────────────────────────────────

String variationStatusLabel(VariationStatus s) => switch (s) {
      VariationStatus.logged => 'Logged',
      VariationStatus.pricedUp => 'Priced Up',
      VariationStatus.documentSent => 'Sent to Client',
      VariationStatus.approved => 'Approved',
      VariationStatus.declined => 'Declined',
    };

Color variationStatusColor(VariationStatus s) => switch (s) {
      VariationStatus.logged => Colors.grey,
      VariationStatus.pricedUp => Colors.orange,
      VariationStatus.documentSent => const Color(0xFF1A56DB),
      VariationStatus.approved => const Color(0xFF0E9F6E),
      VariationStatus.declined => Colors.red,
    };

// ── Claim ─────────────────────────────────────────────────────────────────────

String claimStatusLabel(ClaimStatus s) => switch (s) {
      ClaimStatus.draft => 'Draft',
      ClaimStatus.documentSent => 'Sent to Client',
      ClaimStatus.paid => 'Paid',
    };

Color claimStatusColor(ClaimStatus s) => switch (s) {
      ClaimStatus.draft => Colors.grey,
      ClaimStatus.documentSent => const Color(0xFF1A56DB),
      ClaimStatus.paid => Colors.green.shade800,
    };

// ── Task ──────────────────────────────────────────────────────────────────────

String taskStatusLabel(TaskStatus s) => switch (s) {
      TaskStatus.pending => 'Pending',
      TaskStatus.inProgress => 'In Progress',
      TaskStatus.completed => 'Completed',
    };

Color taskStatusColor(TaskStatus s) => switch (s) {
      TaskStatus.pending => const Color(0xFFE3A008),
      TaskStatus.inProgress => const Color(0xFF1A56DB),
      TaskStatus.completed => const Color(0xFF0E9F6E),
    };

String taskTypeLabel(TaskType t) => switch (t) {
      TaskType.updateWorkPlan => 'Update Work Plan',
      TaskType.completeMobilisation => 'Complete Mobilisation',
      TaskType.resolveDefect => 'Resolve Defect',
    };

// ── Currency ──────────────────────────────────────────────────────────────────

String formatNzd(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '\$$intPart.${parts[1]} ex. GST';
}

String formatNzdShort(double amount) {
  if (amount >= 1000) {
    return '\$${(amount / 1000).toStringAsFixed(1)}k';
  }
  return '\$${amount.toStringAsFixed(0)}';
}
