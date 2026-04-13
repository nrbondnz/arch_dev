/**
 * Schema field definitions for all manager Lambda argument types.
 *
 * These constants serve dual purpose:
 *   1. Used directly in resource.ts `.arguments({...})` calls — single source of truth
 *      for what AppSync accepts.
 *   2. Imported by clean_models.ts for compile-time `ValidateSchemaContract` checks
 *      that keep TypeScript interfaces in sync with the schema.
 */
import { a } from '@aws-amplify/backend';

export const jobManagerArgsSchemaFields = {
  apiFunction:        a.string().required(),
  jobId:              a.id(),
  clientName:         a.string(),
  clientContactName:  a.string(),
  clientEmail:        a.string(),
  clientPhone:        a.string(),
  siteAddress:        a.string(),
  description:        a.string(),
  contractType:       a.string(),
  paymentTerms:       a.string(),
  status:             a.string(),
  // Stage fields
  stageId:            a.id(),
  sequence:           a.integer(),
  scheduledValue:     a.float(),
  triggerType:        a.string(),
  triggerValue:       a.string(),
  retentionRate:      a.float(),
  percentComplete:    a.float(),
  // WorkPackage fields
  siteManagerId:      a.string(),
  plannedStart:       a.string(),
  plannedEnd:         a.string(),
  relatedStageIds:    a.string().array(),
};

export const quoteManagerArgsSchemaFields = {
  apiFunction:     a.string().required(),
  quoteId:         a.id(),
  jobId:           a.id(),
  exclusions:      a.string().array(),
  assumptions:     a.string().array(),
  validUntil:      a.string(),
  notes:           a.string(),
  deliveryMethod:  a.string(),
  acceptedAt:      a.string(),
  rejectedAt:      a.string(),
};

export const quoteLineItemManagerArgsSchemaFields = {
  apiFunction:  a.string().required(),
  lineItemId:   a.id(),
  quoteId:      a.id(),
  description:  a.string(),
  quantity:     a.float(),
  unit:         a.string(),
  rate:         a.float(),
};

export const variationManagerArgsSchemaFields = {
  apiFunction:       a.string().required(),
  variationId:       a.id(),
  jobId:             a.id(),
  workPackageId:     a.id(),
  description:       a.string(),
  reason:            a.string(),
  clientInitiated:   a.boolean(),
  clientContactName: a.string(),
  price:             a.float(),
  timeImpactDays:    a.integer(),
  deliveryMethod:    a.string(),
  approvedAt:        a.string(),
  declinedAt:        a.string(),
  notes:             a.string(),
};

export const claimManagerArgsSchemaFields = {
  apiFunction:         a.string().required(),
  claimId:             a.id(),
  stageId:             a.id(),
  jobId:               a.id(),
  periodDescription:   a.string(),
  variationsIncluded:  a.string().array(),
  deliveryMethod:      a.string(),
  paidAt:              a.string(),
  paidAmount:          a.float(),
  notes:               a.string(),
};
