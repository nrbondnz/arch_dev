/**
 * TypeScript types for all ARCH manager Lambda function arguments and responses.
 *
 * `ValidateSchemaContract` enforces compile-time parity between each TypeScript
 * interface and its corresponding schema field object in manager_args_schema.ts.
 * If a field is added to one side but not the other, tsc will error on the
 * `_validate_*` constant at the bottom of this file.
 */
import type {
  jobManagerArgsSchemaFields,
  quoteManagerArgsSchemaFields,
  quoteLineItemManagerArgsSchemaFields,
  variationManagerArgsSchemaFields,
  claimManagerArgsSchemaFields,
} from './manager_args_schema.js';

// ── Schema/type sync utility ───────────────────────────────────────────────────

type SchemaLike = Record<string, unknown>;

type KeysOfSchema<S extends SchemaLike> = keyof S;

/**
 * Compile-time check that a TypeScript interface `TS` and an Amplify schema
 * field object `S` have exactly the same keys.
 *
 * Assign the result to `[true, true]` — tsc will error if either tuple element
 * is not `true`, surfacing which side has extra or missing fields.
 */
export type ValidateSchemaContract<
  TS extends object,
  S extends SchemaLike,
> = [
  Exclude<keyof TS, KeysOfSchema<S>> extends never
    ? true
    : ['❌ Type has fields missing in schema', Exclude<keyof TS, KeysOfSchema<S>>],
  Exclude<KeysOfSchema<S>, keyof TS> extends never
    ? true
    : ['❌ Schema has fields missing in type', Exclude<KeysOfSchema<S>, keyof TS>],
];

// ── Enums (string unions matching Amplify enum values) ────────────────────────

export type JobStatus =
  | 'Enquiry' | 'Quoted' | 'Contracted' | 'Mobilised'
  | 'InProgress' | 'VariationPending' | 'Completed' | 'Closed';

export type ContractType = 'LumpSum' | 'ScheduleOfRates' | 'CostPlus';

export type StageStatus = 'Pending' | 'Active' | 'ClaimDraft' | 'DocumentSent' | 'Paid';

export type StageTriggerType = 'Milestone' | 'Date' | 'PercentComplete' | 'Manual';

export type WorkPackageStatus = 'Pending' | 'Active' | 'VariationPending' | 'Completed';

export type QuoteStatus = 'Draft' | 'Submitted' | 'DocumentSent' | 'Accepted' | 'Rejected';

export type VariationStatus = 'Logged' | 'PricedUp' | 'DocumentSent' | 'Approved' | 'Declined';

export type ClaimStatus = 'Draft' | 'DocumentSent' | 'Paid';

export type TaskType =
  | 'UpdateWorkPlan' | 'CompleteMobilisationChecklist' | 'ResolveDefect' | 'ReviewVariation';

export type TaskStatus = 'Pending' | 'InProgress' | 'Completed';

// ── Manager arg types ─────────────────────────────────────────────────────────

export type JobApiFunction = 'createJob' | 'updateJob' | 'getJob' | 'listJobs';

export interface JobManagerArgs {
  apiFunction: JobApiFunction;
  jobId?: string;
  clientName?: string;
  clientContactName?: string;
  clientEmail?: string;
  clientPhone?: string;
  siteAddress?: string;
  description?: string;
  contractType?: string;
  paymentTerms?: string;
  status?: string;
}

// ─────────────────────────────────────────────────────────────────────────────

export type QuoteApiFunction =
  | 'createQuote' | 'updateQuote' | 'getQuote' | 'listQuotesForJob'
  | 'sendDocument' | 'recordAccepted' | 'recordRejected';

export interface QuoteManagerArgs {
  apiFunction: QuoteApiFunction;
  quoteId?: string;
  jobId?: string;
  exclusions?: string[];
  assumptions?: string[];
  validUntil?: string;
  notes?: string;
  deliveryMethod?: string;
  acceptedAt?: string;
  rejectedAt?: string;
}

// ─────────────────────────────────────────────────────────────────────────────

export type QuoteLineItemApiFunction =
  | 'addLineItem' | 'updateLineItem' | 'removeLineItem' | 'listLineItems';

export interface QuoteLineItemManagerArgs {
  apiFunction: QuoteLineItemApiFunction;
  lineItemId?: string;
  quoteId?: string;
  description?: string;
  quantity?: number;
  unit?: string;
  rate?: number;
}

// ─────────────────────────────────────────────────────────────────────────────

export type VariationApiFunction =
  | 'createVariation' | 'updateVariation' | 'getVariation' | 'listVariations'
  | 'sendDocument' | 'recordApproved' | 'recordDeclined';

export interface VariationManagerArgs {
  apiFunction: VariationApiFunction;
  variationId?: string;
  jobId?: string;
  workPackageId?: string;
  description?: string;
  reason?: string;
  clientInitiated?: boolean;
  clientContactName?: string;
  price?: number;
  timeImpactDays?: number;
  deliveryMethod?: string;
  approvedAt?: string;
  declinedAt?: string;
  notes?: string;
}

// ─────────────────────────────────────────────────────────────────────────────

export type ClaimApiFunction =
  | 'createClaim' | 'updateClaim' | 'getClaim' | 'listClaims'
  | 'sendDocument' | 'recordPaid';

export interface ClaimManagerArgs {
  apiFunction: ClaimApiFunction;
  claimId?: string;
  stageId?: string;
  jobId?: string;
  periodDescription?: string;
  variationsIncluded?: string[];
  deliveryMethod?: string;
  paidAt?: string;
  paidAmount?: number;
  notes?: string;
}

// ── Standard response wrapper ─────────────────────────────────────────────────

export interface ManagerResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export function ok<T>(data: T): string {
  return JSON.stringify({ success: true, data } satisfies ManagerResponse<T>);
}

export function fail(error: string, message: string): string {
  return JSON.stringify({ success: false, error, message } satisfies ManagerResponse);
}

// ── Compile-time schema/type parity checks ────────────────────────────────────
// These constants will produce a tsc error if any interface above diverges from
// the corresponding schema field object in manager_args_schema.ts.

export const _validate_JobManagerArgs: ValidateSchemaContract<
  JobManagerArgs,
  typeof jobManagerArgsSchemaFields
> = [true, true];

export const _validate_QuoteManagerArgs: ValidateSchemaContract<
  QuoteManagerArgs,
  typeof quoteManagerArgsSchemaFields
> = [true, true];

export const _validate_QuoteLineItemManagerArgs: ValidateSchemaContract<
  QuoteLineItemManagerArgs,
  typeof quoteLineItemManagerArgsSchemaFields
> = [true, true];

export const _validate_VariationManagerArgs: ValidateSchemaContract<
  VariationManagerArgs,
  typeof variationManagerArgsSchemaFields
> = [true, true];

export const _validate_ClaimManagerArgs: ValidateSchemaContract<
  ClaimManagerArgs,
  typeof claimManagerArgsSchemaFields
> = [true, true];
