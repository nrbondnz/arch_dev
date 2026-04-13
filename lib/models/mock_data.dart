import 'domain.dart';

/// Static mock data for UI demonstration.
/// All entities are linked by ID — the same job J001 appears across admin
/// and site-manager screens, telling one coherent story.
class MockData {
  // ── Jobs ────────────────────────────────────────────────────────────────────

  static final List<Job> jobs = [
    const Job(
      id: 'J001',
      clientName: 'Apex Construction Ltd',
      clientContactName: 'Dave Wilson',
      clientEmail: 'dave@apexconstruction.co.nz',
      siteAddress: '14 Hillcrest Rd, Auckland',
      description: 'Blockwork and brickwork — residential development, 3-stage contract',
      contractType: 'Lump Sum',
      paymentTerms: '20th of following month, 20 working days',
      totalContractValue: 72500,
      status: JobStatus.inProgress,
    ),
    const Job(
      id: 'J002',
      clientName: 'Pacific Build',
      clientContactName: 'Sarah Lee',
      clientEmail: 'sarah@pacificbuild.co.nz',
      siteAddress: 'Level 8, 22 Queen St, Auckland CBD',
      description: 'Internal blockwork and feature stone wall — commercial fitout',
      contractType: 'Schedule of Rates',
      paymentTerms: '15th of month, 20 working days',
      totalContractValue: 43000,
      status: JobStatus.quoted,
    ),
    const Job(
      id: 'J003',
      clientName: 'Greenfield Developments',
      clientContactName: 'Mark Stevenson',
      clientEmail: 'mark@greenfield.co.nz',
      siteAddress: 'Lot 17 Meadowbrook Estate, Pukekohe',
      description: 'Full masonry package — new residential build',
      contractType: 'Lump Sum',
      paymentTerms: 'TBD',
      totalContractValue: 0,
      status: JobStatus.enquiry,
    ),
  ];

  // ── Stages ───────────────────────────────────────────────────────────────────

  static final Map<String, List<Stage>> stages = {
    'J001': [
      const Stage(
        id: 'S001',
        jobId: 'J001',
        sequence: 1,
        description: 'Stage 1 — Foundation blockwork',
        scheduledValue: 18500,
        triggerType: StageTriggerType.milestone,
        triggerValue: 'Foundation inspection passed',
        retentionRate: 0.10,
        status: StageStatus.paid,
        percentComplete: 100,
      ),
      const Stage(
        id: 'S002',
        jobId: 'J001',
        sequence: 2,
        description: 'Stage 2 — External brickwork',
        scheduledValue: 42000,
        triggerType: StageTriggerType.percentComplete,
        triggerValue: '80',
        retentionRate: 0.10,
        status: StageStatus.active,
        percentComplete: 62,
      ),
      const Stage(
        id: 'S003',
        jobId: 'J001',
        sequence: 3,
        description: 'Stage 3 — Retaining walls & paving',
        scheduledValue: 12000,
        triggerType: StageTriggerType.manual,
        triggerValue: '',
        retentionRate: 0.05,
        status: StageStatus.pending,
        percentComplete: 0,
      ),
    ],
    'J002': [
      const Stage(
        id: 'S004',
        jobId: 'J002',
        sequence: 1,
        description: 'Stage 1 — Internal blockwork',
        scheduledValue: 28000,
        triggerType: StageTriggerType.date,
        triggerValue: '15 Jul 2026',
        retentionRate: 0.10,
        status: StageStatus.pending,
      ),
      const Stage(
        id: 'S005',
        jobId: 'J002',
        sequence: 2,
        description: 'Stage 2 — Feature stone wall',
        scheduledValue: 15000,
        triggerType: StageTriggerType.milestone,
        triggerValue: 'Stone wall inspection sign-off',
        retentionRate: 0.10,
        status: StageStatus.pending,
      ),
    ],
  };

  // ── Work Packages ────────────────────────────────────────────────────────────

  static final Map<String, List<WorkPackage>> workPackages = {
    'J001': [
      WorkPackage(
        id: 'WP001',
        jobId: 'J001',
        siteManagerId: 'SM001',
        siteManagerName: 'Tom Chen',
        description: 'Foundation blockwork — north & south wings',
        plannedStart: DateTime(2026, 3, 1),
        plannedEnd: DateTime(2026, 3, 25),
        status: WorkPackageStatus.completed,
        resources: '3 blocklayers, 1 labourer',
        relatedStageIds: ['S001'],
      ),
      WorkPackage(
        id: 'WP002',
        jobId: 'J001',
        siteManagerId: 'SM001',
        siteManagerName: 'Tom Chen',
        description: 'External brickwork — all elevations',
        plannedStart: DateTime(2026, 4, 1),
        plannedEnd: DateTime(2026, 5, 22),
        status: WorkPackageStatus.variationPending,
        resources: '4 bricklayers, 1 labourer, scaffold access',
        relatedStageIds: ['S002'],
      ),
    ],
  };

  // ── Quotes ───────────────────────────────────────────────────────────────────

  static final Map<String, Quote> quotes = {
    'J001': const Quote(
      id: 'Q001',
      jobId: 'J001',
      lineItems: [
        QuoteLineItem(description: 'Blockwork — foundations', quantity: 180, unit: 'm²', rate: 102.78),
        QuoteLineItem(description: 'Brickwork — external walls', quantity: 320, unit: 'm²', rate: 88.0),
        QuoteLineItem(description: 'Retaining walls + paving', quantity: 1, unit: 'lump', rate: 12000),
      ],
      exclusions: ['Scaffolding', 'Site toilet', 'Skip bin'],
      total: 72500,
      status: QuoteStatus.accepted,
      validUntil: '1 Apr 2026',
      documentSentAt: '3 Mar 2026',
      acceptedAt: '7 Mar 2026',
    ),
    'J002': const Quote(
      id: 'Q002',
      jobId: 'J002',
      lineItems: [
        QuoteLineItem(description: 'Internal blockwork', quantity: 210, unit: 'm²', rate: 133.33),
        QuoteLineItem(description: 'Feature stone wall', quantity: 1, unit: 'lump', rate: 15000),
      ],
      exclusions: ['Scaffolding', 'Masonry cleaning'],
      total: 43000,
      status: QuoteStatus.documentSent,
      validUntil: '30 Apr 2026',
      documentSentAt: '5 Apr 2026',
    ),
  };

  // ── Variations ───────────────────────────────────────────────────────────────

  static final Map<String, List<Variation>> variations = {
    'J001': [
      const Variation(
        id: 'V001',
        jobId: 'J001',
        workPackageId: 'WP001',
        description: 'Extra brick pier to support relocated lintel',
        reason: 'Client site instruction',
        clientInitiated: true,
        clientContactName: 'Dave Wilson',
        price: 450,
        timeImpactDays: 0,
        status: VariationStatus.approved,
        documentSentAt: '10 Mar 2026',
        approvedAt: '12 Mar 2026',
      ),
      const Variation(
        id: 'V002',
        jobId: 'J001',
        workPackageId: 'WP002',
        description: 'Design change — window reveal depth increased 50mm across east elevation',
        reason: 'Design change',
        clientInitiated: false,
        price: 1200,
        timeImpactDays: 1,
        status: VariationStatus.documentSent,
        documentSentAt: '8 Apr 2026',
      ),
    ],
  };

  // ── Stage Claims ─────────────────────────────────────────────────────────────

  static final Map<String, List<StageClaim>> claims = {
    'J001': [
      const StageClaim(
        id: 'C001',
        stageId: 'S001',
        jobId: 'J001',
        periodDescription: 'Stage 1 — March 2026',
        grossClaimValue: 18950,
        retentionHeld: 1895,
        claimTotal: 17055,
        status: ClaimStatus.paid,
        documentSentAt: '20 Mar 2026',
        paidAt: '9 Apr 2026',
        paidAmount: 17055,
      ),
    ],
  };

  // ── Daily Logs ───────────────────────────────────────────────────────────────

  static final Map<String, List<DailyLog>> dailyLogs = {
    'WP001': [
      DailyLog(
        id: 'DL001',
        workPackageId: 'WP001',
        date: DateTime(2026, 3, 22),
        labourHours: 32,
        progressNotes: 'Completed south wing foundation blocks to plate height. Minor alignment issue on SE corner resolved on-site.',
        materialsUsed: '480 blocks, 12 bags mortar',
        photoCount: 3,
      ),
      DailyLog(
        id: 'DL002',
        workPackageId: 'WP001',
        date: DateTime(2026, 3, 23),
        labourHours: 32,
        progressNotes: 'North wing complete. Foundation inspection requested. Inspection passed PM.',
        materialsUsed: '320 blocks, 8 bags mortar',
        photoCount: 2,
      ),
    ],
    'WP002': [
      DailyLog(
        id: 'DL003',
        workPackageId: 'WP002',
        date: DateTime(2026, 4, 10),
        labourHours: 40,
        progressNotes: 'East elevation now 60% complete. Good progress, on track for milestone. Scaffold tight but workable.',
        materialsUsed: '800 bricks, mortar, wall ties',
        photoCount: 4,
      ),
      DailyLog(
        id: 'DL004',
        workPackageId: 'WP002',
        date: DateTime(2026, 4, 11),
        labourHours: 38,
        progressNotes: 'East elevation 75%. Waiting on window frame delivery for NE corner — blocked 2 hrs in afternoon.',
        materialsUsed: '650 bricks, mortar',
        photoCount: 2,
      ),
    ],
  };

  // ── Tasks ────────────────────────────────────────────────────────────────────

  static final List<Task> tasks = [
    Task(
      id: 'T001',
      assigneeId: 'SM001',
      assigneeName: 'Tom Chen',
      type: TaskType.updateWorkPlan,
      referenceId: 'V002',
      description: 'Update site work plan for variation V002 — window reveal change. Time impact: +1 day. Revise planned end date and crew allocation as needed.',
      status: TaskStatus.pending,
      dueDate: '15 Apr 2026',
    ),
  ];

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static List<Task> tasksForUser(String userId) =>
      tasks.where((t) => t.assigneeId == userId).toList();

  static List<WorkPackage> packagesForUser(String userId) => workPackages.values
      .expand((list) => list)
      .where((p) => p.siteManagerId == userId)
      .toList();
}
