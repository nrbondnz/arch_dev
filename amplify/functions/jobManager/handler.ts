import { createBaseHandler } from '../resources/util/BaseHandler.js';
import { unwrapPayload } from '../resources/common/payload_interfaces.js';
import { ok, fail, type JobManagerArgs } from '../../data/clean_models.js';
import { client, forUpdate } from '../resources/util/amplify-lambda-client.js';

// ── GraphQL operations ────────────────────────────────────────────────────────

const JOB_FIELDS = `
  id clientName clientContactName clientEmail clientPhone
  siteAddress description contractType paymentTerms
  totalContractValue status retentionModel documents createdAt updatedAt
`;

const CREATE_JOB = `
  mutation CreateJob($input: CreateJobInput!) {
    createJob(input: $input) { ${JOB_FIELDS} }
  }
`;

const UPDATE_JOB = `
  mutation UpdateJob($input: UpdateJobInput!) {
    updateJob(input: $input) { ${JOB_FIELDS} }
  }
`;

const GET_JOB = `
  query GetJob($id: ID!) {
    getJob(id: $id) { ${JOB_FIELDS} }
  }
`;

const LIST_JOBS = `
  query ListJobs {
    listJobs { items { ${JOB_FIELDS} } nextToken }
  }
`;

const LIST_JOBS_BY_STATUS = `
  query ListJobByStatus($status: JobStatus!) {
    listJobByStatus(status: $status) { items { ${JOB_FIELDS} } nextToken }
  }
`;

// ── Handler ───────────────────────────────────────────────────────────────────

export const handler = createBaseHandler(async (event: unknown) => {
  const args = unwrapPayload<JobManagerArgs>(event);
  console.log('[jobManager] apiFunction:', args.apiFunction, '| jobId:', args.jobId);

  switch (args.apiFunction) {
    case 'createJob':  return await createJob(args);
    case 'updateJob':  return await updateJob(args);
    case 'getJob':     return await getJob(args);
    case 'listJobs':   return await listJobs(args);
    case 'deleteJob':  return await deleteJobCascade(args);
    default:
      return fail('UNKNOWN_FUNCTION', `Unknown apiFunction: ${args.apiFunction}`);
  }
});

// ── Operations ────────────────────────────────────────────────────────────────

async function createJob(args: JobManagerArgs): Promise<string> {
  if (!args.clientName || !args.siteAddress) {
    return fail('VALIDATION_ERROR', 'clientName and siteAddress are required');
  }

  const { data, errors } = await client.graphql({
    query: CREATE_JOB,
    variables: {
      input: {
        clientName: args.clientName,
        clientContactName: args.clientContactName,
        clientEmail: args.clientEmail,
        clientPhone: args.clientPhone,
        siteAddress: args.siteAddress,
        description: args.description,
        contractType: args.contractType,
        paymentTerms: args.paymentTerms,
        status: 'Enquiry',
        totalContractValue: 0,
      },
    },
  }) as { data: { createJob: Record<string, unknown> }; errors?: unknown[] };

  if (errors?.length) {
    console.error('[jobManager] createJob errors:', errors);
    return fail('CREATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  }

  const job = data?.createJob;
  console.log('[jobManager] created job:', job?.id);
  return ok(job);
}

async function updateJob(args: JobManagerArgs): Promise<string> {
  if (!args.jobId) return fail('VALIDATION_ERROR', 'jobId is required');

  const changedFields = Object.keys(args)
    .filter(k => k !== 'apiFunction' && k !== 'jobId' && (args as unknown as Record<string,unknown>)[k] !== undefined)
    .join(', ');
  console.log('[jobManager] updateJob | jobId:', args.jobId, '| changing:', changedFields || '(none)');

  // Fetch existing job first — Amplify Gen 2 update resolvers use DynamoDB PutItem
  // (replace semantics), so we must supply ALL fields or unspecified ones are cleared.
  console.log('[jobManager] updateJob | step: GET existing job');
  const { data: gd, errors: ge } = await client.graphql({
    query: GET_JOB,
    variables: { id: args.jobId },
  }) as { data: { getJob: Record<string, unknown> | null }; errors?: unknown[] };

  if (ge?.length) {
    console.error('[jobManager] updateJob GET failed:', JSON.stringify(ge));
    return fail('FETCH_FAILED', (ge[0] as { message?: string }).message ?? JSON.stringify(ge[0]));
  }
  const existing = gd?.getJob;
  if (!existing) return fail('JOB_NOT_FOUND', `Job ${args.jobId} not found`);
  console.log('[jobManager] updateJob | existing fields:', Object.keys(existing).join(', '));

  const input: Record<string, unknown> = { ...forUpdate(existing), id: args.jobId };
  // AppSync passes null (not undefined) for omitted optional arguments, so guard
  // against both null and undefined to avoid overwriting existing field values.
  if (args.clientName != null)        input.clientName = args.clientName;
  if (args.clientContactName != null) input.clientContactName = args.clientContactName;
  if (args.clientEmail != null)       input.clientEmail = args.clientEmail;
  if (args.clientPhone != null)       input.clientPhone = args.clientPhone;
  if (args.siteAddress != null)       input.siteAddress = args.siteAddress;
  if (args.description != null)       input.description = args.description;
  if (args.contractType != null)      input.contractType = args.contractType;
  if (args.paymentTerms != null)      input.paymentTerms = args.paymentTerms;
  if (args.status != null)            input.status = args.status;

  console.log('[jobManager] updateJob | step: UPDATE with fields:', Object.keys(input).join(', '));
  const { data, errors } = await client.graphql({
    query: UPDATE_JOB,
    variables: { input },
  }) as { data: { updateJob: Record<string, unknown> }; errors?: unknown[] };

  if (errors?.length) {
    console.error('[jobManager] updateJob UPDATE failed:', JSON.stringify(errors));
    return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  }
  console.log('[jobManager] updateJob SUCCESS | id:', data?.updateJob?.id);
  return ok(data?.updateJob);
}

async function getJob(args: JobManagerArgs): Promise<string> {
  if (!args.jobId) return fail('VALIDATION_ERROR', 'jobId is required');

  const { data, errors } = await client.graphql({
    query: GET_JOB,
    variables: { id: args.jobId },
  }) as { data: { getJob: Record<string, unknown> | null }; errors?: unknown[] };

  if (errors?.length) return fail('FETCH_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  if (!data?.getJob) return fail('JOB_NOT_FOUND', `Job ${args.jobId} not found`);
  return ok(data.getJob);
}

async function deleteJobCascade(args: JobManagerArgs): Promise<string> {
  if (!args.jobId) return fail('VALIDATION_ERROR', 'jobId is required');
  const jobId = args.jobId;
  console.log('[deleteJob] cascade delete | jobId:', jobId);

  // Fetch all child IDs in parallel
  const [stageIds, wpIds, varIds, claimIds, quoteIds] = await Promise.all([
    listIdsByField('listStageByJobId',        'jobId',   jobId),
    listIdsByField('listWorkPackageByJobId',   'jobId',   jobId),
    listIdsByField('listVariationByJobId',     'jobId',   jobId),
    listIdsByField('listStageClaimByJobId',    'jobId',   jobId),
    listIdsByField('listQuoteByJobId',         'jobId',   jobId),
  ]);

  // Quote line items must go before quotes
  const lineItemArrays = await Promise.all(
    quoteIds.map(qId => listIdsByField('listQuoteLineItemByQuoteId', 'quoteId', qId)),
  );
  const lineItemIds = lineItemArrays.flat();

  await Promise.all([
    ...lineItemIds.map(id => deleteById('deleteQuoteLineItem', id)),
    ...stageIds.map(id => deleteById('deleteStage', id)),
    ...wpIds.map(id => deleteById('deleteWorkPackage', id)),
    ...varIds.map(id => deleteById('deleteVariation', id)),
    ...claimIds.map(id => deleteById('deleteStageClaim', id)),
    ...quoteIds.map(id => deleteById('deleteQuote', id)),
  ]);

  console.log('[deleteJob] children removed | stages:', stageIds.length,
    '| wps:', wpIds.length, '| vars:', varIds.length, '| claims:', claimIds.length,
    '| quotes:', quoteIds.length, '| lineItems:', lineItemIds.length);

  const { errors } = await client.graphql({
    query: `mutation($id: ID!) { deleteJob(input: {id: $id}) { id } }`,
    variables: { id: jobId },
  }) as { data: unknown; errors?: unknown[] };

  if (errors?.length) return fail('DELETE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  console.log('[deleteJob] SUCCESS | id:', jobId);
  return ok({ deleted: jobId });
}

async function listIdsByField(queryName: string, fieldName: string, fieldValue: string): Promise<string[]> {
  const query = `query($${fieldName}: ID!) { ${queryName}(${fieldName}: $${fieldName}) { items { id } } }`;
  const { data, errors } = await client.graphql({
    query,
    variables: { [fieldName]: fieldValue },
  }) as { data: Record<string, { items: { id: string }[] } | null>; errors?: unknown[] };
  if (errors?.length) console.warn(`[listIdsByField] ${queryName}:`, JSON.stringify(errors));
  return data?.[queryName]?.items?.map(i => i.id) ?? [];
}

async function deleteById(mutationName: string, id: string): Promise<void> {
  const mutation = `mutation($id: ID!) { ${mutationName}(input: {id: $id}) { id } }`;
  const { errors } = await client.graphql({
    query: mutation,
    variables: { id },
  }) as { data: unknown; errors?: unknown[] };
  if (errors?.length) console.warn(`[deleteById] ${mutationName} ${id}:`, JSON.stringify(errors));
}

async function listJobs(args: JobManagerArgs): Promise<string> {
  if (args.status) {
    const { data, errors } = await client.graphql({
      query: LIST_JOBS_BY_STATUS,
      variables: { status: args.status },
    }) as { data: { listJobByStatus: { items: unknown[] } }; errors?: unknown[] };

    if (errors?.length) return fail('FETCH_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
    return ok(data?.listJobByStatus?.items ?? []);
  }

  const { data, errors } = await client.graphql({
    query: LIST_JOBS,
  }) as { data: { listJobs: { items: unknown[] } }; errors?: unknown[] };

  if (errors?.length) return fail('FETCH_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.listJobs?.items ?? []);
}
