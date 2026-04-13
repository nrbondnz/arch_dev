import { createBaseHandler } from '../resources/util/BaseHandler.js';
import { unwrapPayload } from '../resources/common/payload_interfaces.js';
import { ok, fail, type VariationManagerArgs } from '../../data/clean_models.js';
import { client, forUpdate } from '../resources/util/amplify-lambda-client.js';

// ── GraphQL operations ────────────────────────────────────────────────────────

const VAR_FIELDS = `
  id jobId workPackageId description reason clientInitiated clientContactName
  price timeImpactDays status documentS3Key documentSentAt
  approvedAt declinedAt evidence notes createdAt updatedAt
`;

const CREATE_VAR = `
  mutation CreateVariation($input: CreateVariationInput!) {
    createVariation(input: $input) { ${VAR_FIELDS} }
  }
`;

const UPDATE_VAR = `
  mutation UpdateVariation($input: UpdateVariationInput!) {
    updateVariation(input: $input) { ${VAR_FIELDS} }
  }
`;

const GET_VAR = `
  query GetVariation($id: ID!) {
    getVariation(id: $id) { ${VAR_FIELDS} }
  }
`;

const LIST_VAR_BY_JOB = `
  query ListVariationByJobId($jobId: ID!) {
    listVariationByJobId(jobId: $jobId) { items { ${VAR_FIELDS} } nextToken }
  }
`;

// Full field sets needed because Amplify Gen 2 update resolvers use DynamoDB
// PutItem (replace semantics) — omitting a field in the update input wipes it.
const JOB_FIELDS = `
  id clientName clientContactName clientEmail clientPhone
  siteAddress description contractType paymentTerms
  totalContractValue status retentionModel documents createdAt updatedAt
`;

const WP_FIELDS = `
  id jobId siteManagerId description plannedStart plannedEnd
  resources relatedStageIds status notes createdAt updatedAt
`;

const GET_JOB = `
  query GetJob($id: ID!) {
    getJob(id: $id) { ${JOB_FIELDS} }
  }
`;

const UPDATE_JOB = `
  mutation UpdateJob($input: UpdateJobInput!) {
    updateJob(input: $input) { id totalContractValue updatedAt }
  }
`;

const GET_WP = `
  query GetWorkPackage($id: ID!) {
    getWorkPackage(id: $id) { ${WP_FIELDS} }
  }
`;

const UPDATE_WP = `
  mutation UpdateWorkPackage($input: UpdateWorkPackageInput!) {
    updateWorkPackage(input: $input) { id plannedEnd status updatedAt }
  }
`;

const CREATE_TASK = `
  mutation CreateTask($input: CreateTaskInput!) {
    createTask(input: $input) { id assigneeId type status dueDate }
  }
`;

// ── Handler ───────────────────────────────────────────────────────────────────

export const handler = createBaseHandler(async (event: unknown) => {
  const args = unwrapPayload<VariationManagerArgs>(event);
  console.log('[variationManager] apiFunction:', args.apiFunction, '| variationId:', args.variationId);

  switch (args.apiFunction) {
    case 'createVariation':   return await createVariation(args);
    case 'updateVariation':   return await updateVariation(args);
    case 'getVariation':      return await getVariation(args);
    case 'listVariations':    return await listVariations(args);
    case 'sendDocument':      return await sendDocument(args);
    case 'recordApproved':    return await recordApproved(args);
    case 'recordDeclined':    return await recordDeclined(args);
    default:
      return fail('UNKNOWN_FUNCTION', `Unknown apiFunction: ${args.apiFunction}`);
  }
});

// ── Operations ────────────────────────────────────────────────────────────────

type VarRow = {
  id: string; jobId?: string; workPackageId?: string; status?: string;
  price?: number; timeImpactDays?: number; description?: string;
  [k: string]: unknown;
};

async function createVariation(args: VariationManagerArgs): Promise<string> {
  if (!args.jobId)       return fail('VALIDATION_ERROR', 'jobId is required');
  if (!args.description) return fail('VALIDATION_ERROR', 'description is required');
  if (args.price == null) return fail('VALIDATION_ERROR', 'price is required');

  // Business rule: cannot log a variation against a Closed job
  const { data: jd } = await client.graphql({
    query: GET_JOB,
    variables: { id: args.jobId },
  }) as { data: { getJob: { id: string; status: string } | null } };

  const job = jd?.getJob;
  if (!job) return fail('JOB_NOT_FOUND', `Job ${args.jobId} not found`);
  if (job.status === 'Closed') {
    return fail('VARIATION_JOB_CLOSED', 'Cannot log a variation against a Closed job');
  }

  const { data, errors } = await client.graphql({
    query: CREATE_VAR,
    variables: {
      input: {
        jobId: args.jobId,
        workPackageId: args.workPackageId,
        description: args.description,
        reason: args.reason ?? '',
        clientInitiated: args.clientInitiated ?? false,
        clientContactName: args.clientContactName,
        price: args.price,
        timeImpactDays: args.timeImpactDays ?? 0,
        status: 'Logged',
      },
    },
  }) as { data: { createVariation: VarRow }; errors?: unknown[] };

  if (errors?.length) return fail('CREATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  console.log('[variationManager] created variation:', data?.createVariation?.id);
  return ok(data?.createVariation);
}

async function updateVariation(args: VariationManagerArgs): Promise<string> {
  if (!args.variationId) return fail('VALIDATION_ERROR', 'variationId is required');

  const existing = await getVariationById(args.variationId);
  if (!existing) return fail('VARIATION_NOT_FOUND', `Variation ${args.variationId} not found`);

  const editableStatuses = ['Logged', 'PricedUp'];
  if (!editableStatuses.includes(existing.status ?? '')) {
    return fail('INVALID_STATUS_TRANSITION', 'Variation can only be updated while Logged or PricedUp');
  }

  const input: Record<string, unknown> = { ...forUpdate(existing), id: args.variationId };
  if (args.description != null)       input.description = args.description;
  if (args.reason != null)            input.reason = args.reason;
  if (args.clientInitiated != null)   input.clientInitiated = args.clientInitiated;
  if (args.clientContactName != null) input.clientContactName = args.clientContactName;
  if (args.price != null)             input.price = args.price;
  if (args.timeImpactDays != null)    input.timeImpactDays = args.timeImpactDays;
  if (args.notes != null)             input.notes = args.notes;
  if (args.price != null && existing.status === 'Logged') {
    input.status = 'PricedUp';
  }

  const { data, errors } = await client.graphql({
    query: UPDATE_VAR,
    variables: { input },
  }) as { data: { updateVariation: VarRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.updateVariation);
}

async function getVariation(args: VariationManagerArgs): Promise<string> {
  if (!args.variationId) return fail('VALIDATION_ERROR', 'variationId is required');
  const v = await getVariationById(args.variationId);
  if (!v) return fail('VARIATION_NOT_FOUND', `Variation ${args.variationId} not found`);
  return ok(v);
}

async function listVariations(args: VariationManagerArgs): Promise<string> {
  if (!args.jobId) return fail('VALIDATION_ERROR', 'jobId is required');

  const { data, errors } = await client.graphql({
    query: LIST_VAR_BY_JOB,
    variables: { jobId: args.jobId },
  }) as { data: { listVariationByJobId: { items: VarRow[] } }; errors?: unknown[] };

  if (errors?.length) return fail('FETCH_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.listVariationByJobId?.items ?? []);
}

async function sendDocument(args: VariationManagerArgs): Promise<string> {
  if (!args.variationId) return fail('VALIDATION_ERROR', 'variationId is required');

  const existing = await getVariationById(args.variationId);
  if (!existing) return fail('VARIATION_NOT_FOUND', `Variation ${args.variationId} not found`);

  if (!['Logged', 'PricedUp'].includes(existing.status ?? '')) {
    return fail('INVALID_STATUS_TRANSITION', 'Variation must be Logged or PricedUp to send document');
  }

  // TODO: generate PDF and send via SES — backlog item
  console.log('[variationManager] sendDocument stub — delivery:', args.deliveryMethod ?? 'email');

  const { data, errors } = await client.graphql({
    query: UPDATE_VAR,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.variationId,
        status: 'DocumentSent',
        documentSentAt: new Date().toISOString(),
      },
    },
  }) as { data: { updateVariation: VarRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok({ ...data?.updateVariation, _stub: 'Document send pending SES integration' });
}

async function recordApproved(args: VariationManagerArgs): Promise<string> {
  if (!args.variationId) return fail('VALIDATION_ERROR', 'variationId is required');

  const existing = await getVariationById(args.variationId);
  if (!existing) return fail('VARIATION_NOT_FOUND', `Variation ${args.variationId} not found`);
  if (existing.status !== 'DocumentSent') {
    return fail('INVALID_STATUS_TRANSITION', 'Variation must be DocumentSent before recording approval');
  }

  const { data, errors } = await client.graphql({
    query: UPDATE_VAR,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.variationId,
        status: 'Approved',
        approvedAt: args.approvedAt ?? new Date().toISOString(),
        notes: args.notes,
      },
    },
  }) as { data: { updateVariation: VarRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  // Side-effect: add variation price to job total contract value
  if (existing.jobId && existing.price) {
    const { data: jd } = await client.graphql({
      query: GET_JOB,
      variables: { id: existing.jobId },
    }) as { data: { getJob: Record<string, unknown> | null } };

    if (jd?.getJob) {
      console.log('[variationManager] recordApproved: updating job totalContractValue');
      await client.graphql({
        query: UPDATE_JOB,
        variables: {
          input: {
            ...forUpdate(jd.getJob),
            id: existing.jobId,
            totalContractValue: ((jd.getJob.totalContractValue as number) ?? 0) + (existing.price ?? 0),
          },
        },
      });
    }
  }

  // Side-effect: extend work package planned end date if timeImpactDays set
  if (existing.workPackageId && existing.timeImpactDays && existing.timeImpactDays !== 0) {
    const { data: wpd } = await client.graphql({
      query: GET_WP,
      variables: { id: existing.workPackageId },
    }) as { data: { getWorkPackage: Record<string, unknown> | null } };

    const pkg = wpd?.getWorkPackage;
    if (pkg && pkg.plannedEnd) {
      const currentEnd = new Date(pkg.plannedEnd as string);
      currentEnd.setDate(currentEnd.getDate() + (existing.timeImpactDays ?? 0));
      console.log('[variationManager] recordApproved: extending WP plannedEnd');
      await client.graphql({
        query: UPDATE_WP,
        variables: {
          input: {
            ...forUpdate(pkg),
            id: existing.workPackageId,
            plannedEnd: currentEnd.toISOString().split('T')[0],
            status: 'VariationPending',
          },
        },
      });

      // Side-effect: create UpdateWorkPlan task for the site manager
      if (pkg.siteManagerId) {
        const dueDate = new Date();
        dueDate.setDate(dueDate.getDate() + 3);
        await client.graphql({
          query: CREATE_TASK,
          variables: {
            input: {
              assigneeId: pkg.siteManagerId,
              type: 'UpdateWorkPlan',
              referenceId: existing.id,
              description: `Update site work plan for variation ${existing.id} — ${existing.description}. Price: $${existing.price}. Time impact: ${existing.timeImpactDays ?? 0} day(s).`,
              status: 'Pending',
              dueDate: dueDate.toISOString().split('T')[0],
            },
          },
        });
      }
    }
  }

  return ok(data?.updateVariation);
}

async function recordDeclined(args: VariationManagerArgs): Promise<string> {
  if (!args.variationId) return fail('VALIDATION_ERROR', 'variationId is required');

  const existing = await getVariationById(args.variationId);
  if (!existing) return fail('VARIATION_NOT_FOUND', `Variation ${args.variationId} not found`);
  if (existing.status !== 'DocumentSent') {
    return fail('INVALID_STATUS_TRANSITION', 'Variation must be DocumentSent before recording decline');
  }

  const { data, errors } = await client.graphql({
    query: UPDATE_VAR,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.variationId,
        status: 'Declined',
        declinedAt: args.declinedAt ?? new Date().toISOString(),
        notes: args.notes,
      },
    },
  }) as { data: { updateVariation: VarRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.updateVariation);
}

// ── Internal helpers ──────────────────────────────────────────────────────────

async function getVariationById(id: string): Promise<VarRow | null> {
  const { data } = await client.graphql({
    query: GET_VAR,
    variables: { id },
  }) as { data: { getVariation: VarRow | null } };
  return data?.getVariation ?? null;
}
