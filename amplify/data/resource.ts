import { type ClientSchema, a, defineData } from "@aws-amplify/backend";
import { jobManager } from '../functions/jobManager/resource';
import { quoteManager } from '../functions/quoteManager/resource';
import { quoteLineItemManager } from '../functions/quoteLineItemManager/resource';
import { variationManager } from '../functions/variationManager/resource';
import { claimManager } from '../functions/claimManager/resource';
import {
  jobManagerArgsSchemaFields,
  quoteManagerArgsSchemaFields,
  quoteLineItemManagerArgsSchemaFields,
  variationManagerArgsSchemaFields,
  claimManagerArgsSchemaFields,
} from './manager_args_schema';

// ── Shared authorization shorthand ────────────────────────────────────────────
// All manager Lambdas get full read/write access to all models so they can
// enforce business rules in code.  Role-level access is also declared for
// direct Amplify client usage from the Flutter app (read-only for site-manager).

const schema = a.schema({

  // ── Enums ───────────────────────────────────────────────────────────────────

  JobStatus: a.enum([
    'Enquiry', 'Quoted', 'Contracted', 'Mobilised',
    'InProgress', 'VariationPending', 'Completed', 'Closed',
  ]),
  ContractType: a.enum(['LumpSum', 'ScheduleOfRates', 'CostPlus']),
  StageTriggerType: a.enum(['Milestone', 'Date', 'PercentComplete', 'Manual']),
  StageStatus: a.enum(['Pending', 'Active', 'ClaimDraft', 'DocumentSent', 'Paid']),
  WorkPackageStatus: a.enum(['Pending', 'Active', 'VariationPending', 'Completed']),
  QuoteStatus: a.enum(['Draft', 'Submitted', 'DocumentSent', 'Accepted', 'Rejected']),
  VariationStatus: a.enum(['Logged', 'PricedUp', 'DocumentSent', 'Approved', 'Declined']),
  ClaimStatus: a.enum(['Draft', 'DocumentSent', 'Paid']),
  TaskType: a.enum([
    'UpdateWorkPlan', 'CompleteMobilisationChecklist', 'ResolveDefect', 'ReviewVariation',
  ]),
  TaskStatus: a.enum(['Pending', 'InProgress', 'Completed']),

  // ── Manager query endpoints ──────────────────────────────────────────────────
  // All manager operations are surfaced as a single query per domain entity.
  // The apiFunction field dispatches to the correct handler operation.
  // Returns a JSON string — clients parse it as { success, data } | { success, error, message }.

  callJobManagerAPI: a
    .query()
    .arguments(jobManagerArgsSchemaFields)
    .returns(a.string())
    .authorization(allow => [allow.authenticated('userPools')])
    .handler(a.handler.function(jobManager)),

  callQuoteManagerAPI: a
    .query()
    .arguments(quoteManagerArgsSchemaFields)
    .returns(a.string())
    .authorization(allow => [allow.authenticated('userPools')])
    .handler(a.handler.function(quoteManager)),

  callQuoteLineItemManagerAPI: a
    .query()
    .arguments(quoteLineItemManagerArgsSchemaFields)
    .returns(a.string())
    .authorization(allow => [allow.authenticated('userPools')])
    .handler(a.handler.function(quoteLineItemManager)),

  callVariationManagerAPI: a
    .query()
    .arguments(variationManagerArgsSchemaFields)
    .returns(a.string())
    .authorization(allow => [allow.authenticated('userPools')])
    .handler(a.handler.function(variationManager)),

  callClaimManagerAPI: a
    .query()
    .arguments(claimManagerArgsSchemaFields)
    .returns(a.string())
    .authorization(allow => [allow.authenticated('userPools')])
    .handler(a.handler.function(claimManager)),

  // ── Models ───────────────────────────────────────────────────────────────────

  Job: a
    .model({
      clientName: a.string().required(),
      clientContactName: a.string(),
      clientEmail: a.string(),
      clientPhone: a.string(),
      siteAddress: a.string().required(),
      description: a.string(),
      contractType: a.ref('ContractType'),
      paymentTerms: a.string(),
      totalContractValue: a.float().default(0),
      status: a.ref('JobStatus').required(),
      retentionModel: a.string(),
      documents: a.string().array(),
    })
    .secondaryIndexes(index => [index('status')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
      allow.groups(['site-manager']).to(['read']),
    ]),

  Stage: a
    .model({
      jobId: a.id().required(),
      sequence: a.integer().required(),
      description: a.string().required(),
      scheduledValue: a.float().required(),
      triggerType: a.ref('StageTriggerType').required(),
      triggerValue: a.string(),
      retentionRate: a.float().default(0.10),
      retentionHeld: a.float().default(0),
      retentionReleased: a.float().default(0),
      status: a.ref('StageStatus').required(),
      percentComplete: a.float().default(0),
      claimId: a.id(),
    })
    .secondaryIndexes(index => [index('jobId')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
      allow.groups(['site-manager']).to(['read']),
    ]),

  WorkPackage: a
    .model({
      jobId: a.id().required(),
      siteManagerId: a.string(),
      description: a.string().required(),
      plannedStart: a.date(),
      plannedEnd: a.date(),
      // JSON-serialised Resource[] — avoids nested array model overhead
      resources: a.string(),
      relatedStageIds: a.string().array(),
      status: a.ref('WorkPackageStatus').required(),
      notes: a.string(),
    })
    .secondaryIndexes(index => [index('jobId'), index('siteManagerId')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
      allow.groups(['site-manager']).to(['read']),
    ]),

  Quote: a
    .model({
      jobId: a.id().required(),
      // JSON-serialised string[] exclusions / assumptions
      exclusions: a.string().array(),
      assumptions: a.string().array(),
      total: a.float().default(0),
      validUntil: a.string(),
      status: a.ref('QuoteStatus').required(),
      documentS3Key: a.string(),
      documentSentAt: a.string(),
      acceptedAt: a.string(),
      rejectedAt: a.string(),
      notes: a.string(),
    })
    .secondaryIndexes(index => [index('jobId')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
    ]),

  QuoteLineItem: a
    .model({
      quoteId: a.id().required(),
      description: a.string().required(),
      quantity: a.float().required(),
      unit: a.string().default('m2'),
      rate: a.float().required(),
      total: a.float().required(),
    })
    .secondaryIndexes(index => [index('quoteId')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
    ]),

  Variation: a
    .model({
      jobId: a.id().required(),
      workPackageId: a.id(),
      description: a.string().required(),
      reason: a.string(),
      clientInitiated: a.boolean().default(false),
      clientContactName: a.string(),
      price: a.float().required(),
      timeImpactDays: a.integer().default(0),
      status: a.ref('VariationStatus').required(),
      documentS3Key: a.string(),
      documentSentAt: a.string(),
      approvedAt: a.string(),
      declinedAt: a.string(),
      evidence: a.string().array(),
      notes: a.string(),
    })
    .secondaryIndexes(index => [index('jobId'), index('workPackageId')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
      allow.groups(['site-manager']).to(['read']),
    ]),

  StageClaim: a
    .model({
      stageId: a.id().required(),
      jobId: a.id().required(),
      periodDescription: a.string().required(),
      variationsIncluded: a.string().array(),
      grossClaimValue: a.float().required(),
      retentionHeld: a.float().required(),
      claimTotal: a.float().required(),
      status: a.ref('ClaimStatus').required(),
      documentS3Key: a.string(),
      documentSentAt: a.string(),
      paidAt: a.string(),
      paidAmount: a.float(),
      evidence: a.string().array(),
      notes: a.string(),
    })
    .secondaryIndexes(index => [index('stageId'), index('jobId')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
    ]),

  DailyLog: a
    .model({
      workPackageId: a.id().required(),
      jobId: a.id().required(),
      siteManagerId: a.string().required(),
      date: a.date().required(),
      // JSON-serialised complex arrays (avoids nested model overhead)
      labourEntries: a.string(),
      materialsUsed: a.string(),
      progressNotes: a.string().required(),
      scopeProgress: a.string(),
      photos: a.string().array(),
      weatherConditions: a.string(),
      totalLabourHours: a.float().default(0),
    })
    .secondaryIndexes(index => [index('workPackageId'), index('siteManagerId')])
    .authorization(allow => [
      allow.groups(['admin-manager']).to(['read']),
      // Site managers create and read their own logs via group auth
      allow.groups(['site-manager']).to(['create', 'read', 'update']),
    ]),

  Task: a
    .model({
      assigneeId: a.string().required(),
      type: a.ref('TaskType').required(),
      referenceId: a.string(),
      description: a.string().required(),
      status: a.ref('TaskStatus').required(),
      dueDate: a.string(),
      completedAt: a.string(),
      notes: a.string(),
    })
    .secondaryIndexes(index => [index('assigneeId'), index('status')])
    .authorization(allow => [
      allow.groups(['admin-manager']),
      // Site managers can read and complete their own tasks
      allow.groups(['site-manager']).to(['read', 'update']),
    ]),

// Schema-level resource authorization — grants all manager Lambdas full access
// to all models so they can enforce business rules in code.
}).authorization(allow => [
  allow.resource(jobManager),
  allow.resource(quoteManager),
  allow.resource(quoteLineItemManager),
  allow.resource(variationManager),
  allow.resource(claimManager),
]);

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});
