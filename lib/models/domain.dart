// Pure Dart domain models for the ARCH sub-contractor management system.
// No Amplify dependency — used by all new screens with mock data.

enum UserRole { adminManager, siteManager }

enum JobStatus {
  enquiry,
  quoted,
  contracted,
  mobilised,
  inProgress,
  variationPending,
  completed,
  closed,
}

enum StageStatus { pending, active, claimDraft, documentSent, paid }

enum StageTriggerType { milestone, date, percentComplete, manual }

enum WorkPackageStatus { pending, active, variationPending, completed }

enum QuoteStatus { draft, submitted, documentSent, accepted, rejected }

enum VariationStatus { logged, pricedUp, documentSent, approved, declined }

enum ClaimStatus { draft, documentSent, paid }

enum TaskType { updateWorkPlan, completeMobilisation, resolveDefect }

enum TaskStatus { pending, inProgress, completed }

// ── Entities ──────────────────────────────────────────────────────────────────

class Job {
  final String id;
  final String clientName;
  final String clientContactName;
  final String clientEmail;
  final String siteAddress;
  final String description;
  final String contractType;
  final String paymentTerms;
  final double totalContractValue;
  final JobStatus status;

  const Job({
    required this.id,
    required this.clientName,
    required this.clientContactName,
    required this.clientEmail,
    required this.siteAddress,
    required this.description,
    required this.contractType,
    required this.paymentTerms,
    required this.totalContractValue,
    required this.status,
  });
}

class Stage {
  final String id;
  final String jobId;
  final int sequence;
  final String description;
  final double scheduledValue;
  final StageTriggerType triggerType;
  final String triggerValue;
  final double retentionRate;
  final StageStatus status;
  final double percentComplete;

  const Stage({
    required this.id,
    required this.jobId,
    required this.sequence,
    required this.description,
    required this.scheduledValue,
    required this.triggerType,
    required this.triggerValue,
    required this.retentionRate,
    required this.status,
    this.percentComplete = 0,
  });
}

class WorkPackage {
  final String id;
  final String jobId;
  final String siteManagerId;
  final String siteManagerName;
  final String description;
  final DateTime plannedStart;
  final DateTime plannedEnd;
  final WorkPackageStatus status;
  final String resources;
  final List<String> relatedStageIds;

  const WorkPackage({
    required this.id,
    required this.jobId,
    required this.siteManagerId,
    required this.siteManagerName,
    required this.description,
    required this.plannedStart,
    required this.plannedEnd,
    required this.status,
    required this.resources,
    this.relatedStageIds = const [],
  });
}

class QuoteLineItem {
  final String description;
  final double quantity;
  final String unit;
  final double rate;

  const QuoteLineItem({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
  });

  double get amount => quantity * rate;
}

class Quote {
  final String id;
  final String jobId;
  final List<QuoteLineItem> lineItems;
  final List<String> exclusions;
  final double total;
  final QuoteStatus status;
  final String? validUntil;
  final String? documentSentAt;
  final String? acceptedAt;

  const Quote({
    required this.id,
    required this.jobId,
    required this.lineItems,
    required this.exclusions,
    required this.total,
    required this.status,
    this.validUntil,
    this.documentSentAt,
    this.acceptedAt,
  });
}

class Variation {
  final String id;
  final String jobId;
  final String workPackageId;
  final String description;
  final String reason;
  final bool clientInitiated;
  final String? clientContactName;
  final double price;
  final int timeImpactDays;
  final VariationStatus status;
  final String? documentSentAt;
  final String? approvedAt;

  const Variation({
    required this.id,
    required this.jobId,
    required this.workPackageId,
    required this.description,
    required this.reason,
    required this.clientInitiated,
    this.clientContactName,
    required this.price,
    required this.timeImpactDays,
    required this.status,
    this.documentSentAt,
    this.approvedAt,
  });
}

class StageClaim {
  final String id;
  final String stageId;
  final String jobId;
  final String periodDescription;
  final double grossClaimValue;
  final double retentionHeld;
  final double claimTotal;
  final ClaimStatus status;
  final String? documentSentAt;
  final String? paidAt;
  final double? paidAmount;

  const StageClaim({
    required this.id,
    required this.stageId,
    required this.jobId,
    required this.periodDescription,
    required this.grossClaimValue,
    required this.retentionHeld,
    required this.claimTotal,
    required this.status,
    this.documentSentAt,
    this.paidAt,
    this.paidAmount,
  });
}

class DailyLog {
  final String id;
  final String workPackageId;
  final DateTime date;
  final double labourHours;
  final String progressNotes;
  final String? materialsUsed;
  final int photoCount;

  const DailyLog({
    required this.id,
    required this.workPackageId,
    required this.date,
    required this.labourHours,
    required this.progressNotes,
    this.materialsUsed,
    this.photoCount = 0,
  });
}

class Task {
  final String id;
  final String assigneeId;
  final String assigneeName;
  final TaskType type;
  final String? referenceId;
  final String description;
  TaskStatus status;
  final String? dueDate;

  Task({
    required this.id,
    required this.assigneeId,
    required this.assigneeName,
    required this.type,
    this.referenceId,
    required this.description,
    required this.status,
    this.dueDate,
  });
}
