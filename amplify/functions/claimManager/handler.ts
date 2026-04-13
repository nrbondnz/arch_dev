import { createBaseHandler } from '../resources/util/BaseHandler.js';
import { unwrapPayload } from '../resources/common/payload_interfaces.js';
import { ok, fail, type ClaimManagerArgs } from '../../data/clean_models.js';
import { client, forUpdate } from '../resources/util/amplify-lambda-client.js';

// ── GraphQL operations ────────────────────────────────────────────────────────

const CLAIM_FIELDS = `
  id stageId jobId periodDescription variationsIncluded
  grossClaimValue retentionHeld claimTotal status
  documentS3Key documentSentAt paidAt paidAmount evidence notes createdAt updatedAt
`;

const CREATE_CLAIM = `
  mutation CreateStageClaim($input: CreateStageClaimInput!) {
    createStageClaim(input: $input) { ${CLAIM_FIELDS} }
  }
`;

const UPDATE_CLAIM = `
  mutation UpdateStageClaim($input: UpdateStageClaimInput!) {
    updateStageClaim(input: $input) { ${CLAIM_FIELDS} }
  }
`;

const GET_CLAIM = `
  query GetStageClaim($id: ID!) {
    getStageClaim(id: $id) { ${CLAIM_FIELDS} }
  }
`;

const LIST_CLAIMS_BY_STAGE = `
  query ListStageClaimByStageId($stageId: ID!) {
    listStageClaimByStageId(stageId: $stageId) { items { ${CLAIM_FIELDS} } nextToken }
  }
`;

const LIST_CLAIMS_BY_JOB = `
  query ListStageClaimByJobId($jobId: ID!) {
    listStageClaimByJobId(jobId: $jobId) { items { ${CLAIM_FIELDS} } nextToken }
  }
`;

const GET_JOB = `
  query GetJob($id: ID!) {
    getJob(id: $id) { id status }
  }
`;

// Full field set — Amplify Gen 2 update resolver uses PutItem (replace semantics).
const STAGE_FIELDS = `
  id jobId sequence description scheduledValue triggerType triggerValue
  retentionRate retentionHeld retentionReleased status percentComplete claimId
  createdAt updatedAt
`;

const GET_STAGE = `
  query GetStage($id: ID!) {
    getStage(id: $id) { ${STAGE_FIELDS} }
  }
`;

const UPDATE_STAGE = `
  mutation UpdateStage($input: UpdateStageInput!) {
    updateStage(input: $input) { id claimId status updatedAt }
  }
`;

const GET_VAR = `
  query GetVariation($id: ID!) {
    getVariation(id: $id) { id status price }
  }
`;

// ── Handler ───────────────────────────────────────────────────────────────────

export const handler = createBaseHandler(async (event: unknown) => {
  const args = unwrapPayload<ClaimManagerArgs>(event);
  console.log('[claimManager] apiFunction:', args.apiFunction, '| claimId:', args.claimId);

  switch (args.apiFunction) {
    case 'createClaim':    return await createClaim(args);
    case 'updateClaim':    return await updateClaim(args);
    case 'getClaim':       return await getClaim(args);
    case 'listClaims':     return await listClaims(args);
    case 'sendDocument':   return await sendDocument(args);
    case 'recordPaid':     return await recordPaid(args);
    default:
      return fail('UNKNOWN_FUNCTION', `Unknown apiFunction: ${args.apiFunction}`);
  }
});

// ── Operations ────────────────────────────────────────────────────────────────

type ClaimRow = { id: string; stageId?: string; status?: string; claimTotal?: number; [k: string]: unknown };
type StageRow = { id: string; scheduledValue?: number; retentionRate?: number; [k: string]: unknown };

async function createClaim(args: ClaimManagerArgs): Promise<string> {
  if (!args.stageId) return fail('VALIDATION_ERROR', 'stageId is required');
  if (!args.jobId)   return fail('VALIDATION_ERROR', 'jobId is required');
  if (!args.periodDescription) return fail('VALIDATION_ERROR', 'periodDescription is required');

  // Business rule: only one claim per stage
  const existing = await listClaimsByStageId(args.stageId);
  if (existing.length > 0) {
    return fail('CLAIM_PERIOD_OVERLAP', `Stage ${args.stageId} already has a claim (${existing[0].id})`);
  }

  // Business rule: job must be InProgress or Completed
  const { data: jd } = await client.graphql({
    query: GET_JOB,
    variables: { id: args.jobId },
  }) as { data: { getJob: { id: string; status?: string } | null } };

  const job = jd?.getJob;
  if (!job) return fail('JOB_NOT_FOUND', `Job ${args.jobId} not found`);
  if (!['InProgress', 'Completed'].includes(job.status ?? '')) {
    return fail('INVALID_STATUS_TRANSITION', 'Claims can only be raised for InProgress or Completed jobs');
  }

  // Fetch stage for retention rate and scheduled value
  const { data: sd } = await client.graphql({
    query: GET_STAGE,
    variables: { id: args.stageId },
  }) as { data: { getStage: StageRow | null } };

  const stage = sd?.getStage;
  if (!stage) return fail('STAGE_NOT_FOUND', `Stage ${args.stageId} not found`);

  const retentionRate = stage.retentionRate ?? 0.10;
  let grossClaimValue = stage.scheduledValue ?? 0;

  const variationsIncluded = args.variationsIncluded ?? [];
  for (const varId of variationsIncluded) {
    const { data: vd } = await client.graphql({
      query: GET_VAR,
      variables: { id: varId },
    }) as { data: { getVariation: { id: string; status?: string; price?: number } | null } };

    if (vd?.getVariation?.status === 'Approved') {
      grossClaimValue += vd.getVariation.price ?? 0;
    }
  }

  const retentionHeld = grossClaimValue * retentionRate;
  const claimTotal = grossClaimValue - retentionHeld;

  const { data, errors } = await client.graphql({
    query: CREATE_CLAIM,
    variables: {
      input: {
        stageId: args.stageId,
        jobId: args.jobId,
        periodDescription: args.periodDescription,
        variationsIncluded,
        grossClaimValue,
        retentionHeld,
        claimTotal,
        status: 'Draft',
        notes: args.notes,
      },
    },
  }) as { data: { createStageClaim: ClaimRow }; errors?: unknown[] };

  if (errors?.length) return fail('CREATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  const claim = data?.createStageClaim;
  // Link stage to claim — use forUpdate(stage) because the resolver uses PutItem
  await client.graphql({
    query: UPDATE_STAGE,
    variables: { input: { ...forUpdate(stage as Record<string, unknown>), id: args.stageId, claimId: claim?.id, status: 'ClaimDraft' } },
  });

  console.log('[claimManager] created claim:', claim?.id);
  return ok(claim);
}

async function updateClaim(args: ClaimManagerArgs): Promise<string> {
  if (!args.claimId) return fail('VALIDATION_ERROR', 'claimId is required');

  const existing = await getClaimById(args.claimId);
  if (!existing) return fail('CLAIM_NOT_FOUND', `Claim ${args.claimId} not found`);
  if (existing.status !== 'Draft') {
    return fail('INVALID_STATUS_TRANSITION', 'Only Draft claims can be updated');
  }

  const input: Record<string, unknown> = { ...forUpdate(existing), id: args.claimId };
  if (args.periodDescription != null)   input.periodDescription = args.periodDescription;
  if (args.variationsIncluded != null)  input.variationsIncluded = args.variationsIncluded;
  if (args.notes != null)               input.notes = args.notes;

  const { data, errors } = await client.graphql({
    query: UPDATE_CLAIM,
    variables: { input },
  }) as { data: { updateStageClaim: ClaimRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.updateStageClaim);
}

async function getClaim(args: ClaimManagerArgs): Promise<string> {
  if (!args.claimId) return fail('VALIDATION_ERROR', 'claimId is required');
  const claim = await getClaimById(args.claimId);
  if (!claim) return fail('CLAIM_NOT_FOUND', `Claim ${args.claimId} not found`);
  return ok(claim);
}

async function listClaims(args: ClaimManagerArgs): Promise<string> {
  if (!args.jobId && !args.stageId) {
    return fail('VALIDATION_ERROR', 'jobId or stageId is required');
  }

  const items = args.stageId
    ? await listClaimsByStageId(args.stageId)
    : await listClaimsByJobId(args.jobId!);

  return ok(items);
}

async function sendDocument(args: ClaimManagerArgs): Promise<string> {
  if (!args.claimId) return fail('VALIDATION_ERROR', 'claimId is required');

  const existing = await getClaimById(args.claimId);
  if (!existing) return fail('CLAIM_NOT_FOUND', `Claim ${args.claimId} not found`);
  if (existing.status !== 'Draft') {
    return fail('INVALID_STATUS_TRANSITION', 'Claim must be Draft to send document');
  }

  // TODO: generate PDF and send via SES — backlog item
  console.log('[claimManager] sendDocument stub — delivery:', args.deliveryMethod ?? 'email');

  const { data, errors } = await client.graphql({
    query: UPDATE_CLAIM,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.claimId,
        status: 'DocumentSent',
        documentSentAt: new Date().toISOString(),
      },
    },
  }) as { data: { updateStageClaim: ClaimRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  // Advance the stage status — fetch first to avoid PutItem wiping required fields
  if (existing.stageId) {
    const { data: sd } = await client.graphql({
      query: GET_STAGE,
      variables: { id: existing.stageId },
    }) as { data: { getStage: Record<string, unknown> | null } };
    if (sd?.getStage) {
      await client.graphql({
        query: UPDATE_STAGE,
        variables: { input: { ...forUpdate(sd.getStage), id: existing.stageId, status: 'DocumentSent' } },
      });
    }
  }

  return ok({ ...data?.updateStageClaim, _stub: 'Document send pending SES integration' });
}

async function recordPaid(args: ClaimManagerArgs): Promise<string> {
  if (!args.claimId) return fail('VALIDATION_ERROR', 'claimId is required');
  if (args.paidAmount == null) return fail('VALIDATION_ERROR', 'paidAmount is required');

  const existing = await getClaimById(args.claimId);
  if (!existing) return fail('CLAIM_NOT_FOUND', `Claim ${args.claimId} not found`);
  if (existing.status !== 'DocumentSent') {
    return fail('INVALID_STATUS_TRANSITION', 'Claim must be DocumentSent before recording payment');
  }

  const { data, errors } = await client.graphql({
    query: UPDATE_CLAIM,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.claimId,
        status: 'Paid',
        paidAt: args.paidAt ?? new Date().toISOString(),
        paidAmount: args.paidAmount,
        notes: args.notes,
      },
    },
  }) as { data: { updateStageClaim: ClaimRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  // Advance the stage status to Paid — fetch first to avoid PutItem wiping required fields
  if (existing.stageId) {
    const { data: sd } = await client.graphql({
      query: GET_STAGE,
      variables: { id: existing.stageId },
    }) as { data: { getStage: Record<string, unknown> | null } };
    if (sd?.getStage) {
      await client.graphql({
        query: UPDATE_STAGE,
        variables: { input: { ...forUpdate(sd.getStage), id: existing.stageId, status: 'Paid' } },
      });
    }
  }

  return ok(data?.updateStageClaim);
}

// ── Internal helpers ──────────────────────────────────────────────────────────

async function getClaimById(id: string): Promise<ClaimRow | null> {
  const { data } = await client.graphql({
    query: GET_CLAIM,
    variables: { id },
  }) as { data: { getStageClaim: ClaimRow | null } };
  return data?.getStageClaim ?? null;
}

async function listClaimsByStageId(stageId: string): Promise<ClaimRow[]> {
  const { data } = await client.graphql({
    query: LIST_CLAIMS_BY_STAGE,
    variables: { stageId },
  }) as { data: { listStageClaimByStageId: { items: ClaimRow[] } } };
  return data?.listStageClaimByStageId?.items ?? [];
}

async function listClaimsByJobId(jobId: string): Promise<ClaimRow[]> {
  const { data } = await client.graphql({
    query: LIST_CLAIMS_BY_JOB,
    variables: { jobId },
  }) as { data: { listStageClaimByJobId: { items: ClaimRow[] } } };
  return data?.listStageClaimByJobId?.items ?? [];
}
