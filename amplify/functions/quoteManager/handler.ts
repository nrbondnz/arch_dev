import { createBaseHandler } from '../resources/util/BaseHandler.js';
import { unwrapPayload } from '../resources/common/payload_interfaces.js';
import { ok, fail, type QuoteManagerArgs } from '../../data/clean_models.js';
import { client, forUpdate } from '../resources/util/amplify-lambda-client.js';

// ── GraphQL operations ────────────────────────────────────────────────────────

const QUOTE_FIELDS = `
  id jobId exclusions assumptions total validUntil status
  documentS3Key documentSentAt acceptedAt rejectedAt notes createdAt updatedAt
`;

const CREATE_QUOTE = `
  mutation CreateQuote($input: CreateQuoteInput!) {
    createQuote(input: $input) { ${QUOTE_FIELDS} }
  }
`;

const UPDATE_QUOTE = `
  mutation UpdateQuote($input: UpdateQuoteInput!) {
    updateQuote(input: $input) { ${QUOTE_FIELDS} }
  }
`;

const GET_QUOTE = `
  query GetQuote($id: ID!) {
    getQuote(id: $id) { ${QUOTE_FIELDS} }
  }
`;

const LIST_QUOTES_BY_JOB = `
  query ListQuoteByJobId($jobId: ID!) {
    listQuoteByJobId(jobId: $jobId) { items { ${QUOTE_FIELDS} } nextToken }
  }
`;

const UPDATE_JOB = `
  mutation UpdateJob($input: UpdateJobInput!) {
    updateJob(input: $input) { id status }
  }
`;

// ── Handler ───────────────────────────────────────────────────────────────────

export const handler = createBaseHandler(async (event: unknown) => {
  const args = unwrapPayload<QuoteManagerArgs>(event);
  console.log('[quoteManager] apiFunction:', args.apiFunction, '| quoteId:', args.quoteId);

  switch (args.apiFunction) {
    case 'createQuote':       return await createQuote(args);
    case 'updateQuote':       return await updateQuote(args);
    case 'getQuote':          return await getQuote(args);
    case 'listQuotesForJob':  return await listQuotesForJob(args);
    case 'sendDocument':      return await sendDocument(args);
    case 'recordAccepted':    return await recordAccepted(args);
    case 'recordRejected':    return await recordRejected(args);
    default:
      return fail('UNKNOWN_FUNCTION', `Unknown apiFunction: ${args.apiFunction}`);
  }
});

// ── Operations ────────────────────────────────────────────────────────────────

type QuoteRow = { id: string; jobId?: string; status?: string; [k: string]: unknown };

async function createQuote(args: QuoteManagerArgs): Promise<string> {
  if (!args.jobId) return fail('VALIDATION_ERROR', 'jobId is required');

  // Business rule: a job can only have one live (non-rejected) quote
  const existing = await listQuotesByJobId(args.jobId);
  const liveQuote = existing.find((q: QuoteRow) => q.status !== 'Rejected');
  if (liveQuote) {
    return fail('DUPLICATE_QUOTE', `Job ${args.jobId} already has an active quote (${liveQuote.id})`);
  }

  const { data, errors } = await client.graphql({
    query: CREATE_QUOTE,
    variables: {
      input: {
        jobId: args.jobId,
        exclusions: args.exclusions ?? [],
        assumptions: args.assumptions ?? [],
        total: 0,
        validUntil: args.validUntil,
        status: 'Draft',
        notes: args.notes,
      },
    },
  }) as { data: { createQuote: QuoteRow }; errors?: unknown[] };

  if (errors?.length) return fail('CREATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  const quote = data?.createQuote;
  console.log('[quoteManager] created quote:', quote?.id);
  return ok(quote);
}

async function updateQuote(args: QuoteManagerArgs): Promise<string> {
  if (!args.quoteId) return fail('VALIDATION_ERROR', 'quoteId is required');

  const existing = await getQuoteById(args.quoteId);
  if (!existing) return fail('QUOTE_NOT_FOUND', `Quote ${args.quoteId} not found`);
  if (existing.status !== 'Draft') {
    return fail('INVALID_STATUS_TRANSITION', 'Only Draft quotes can be updated');
  }

  const input: Record<string, unknown> = { ...forUpdate(existing), id: args.quoteId };
  if (args.exclusions != null)  input.exclusions = args.exclusions;
  if (args.assumptions != null) input.assumptions = args.assumptions;
  if (args.validUntil != null)  input.validUntil = args.validUntil;
  if (args.notes != null)       input.notes = args.notes;

  const { data, errors } = await client.graphql({
    query: UPDATE_QUOTE,
    variables: { input },
  }) as { data: { updateQuote: QuoteRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.updateQuote);
}

async function getQuote(args: QuoteManagerArgs): Promise<string> {
  if (!args.quoteId) return fail('VALIDATION_ERROR', 'quoteId is required');
  const quote = await getQuoteById(args.quoteId);
  if (!quote) return fail('QUOTE_NOT_FOUND', `Quote ${args.quoteId} not found`);
  return ok(quote);
}

async function listQuotesForJob(args: QuoteManagerArgs): Promise<string> {
  if (!args.jobId) return fail('VALIDATION_ERROR', 'jobId is required');
  const quotes = await listQuotesByJobId(args.jobId);
  return ok(quotes);
}

async function sendDocument(args: QuoteManagerArgs): Promise<string> {
  if (!args.quoteId) return fail('VALIDATION_ERROR', 'quoteId is required');

  const existing = await getQuoteById(args.quoteId);
  if (!existing) return fail('QUOTE_NOT_FOUND', `Quote ${args.quoteId} not found`);
  if (!['Draft', 'Submitted'].includes(existing.status ?? '')) {
    return fail('INVALID_STATUS_TRANSITION', 'Quote must be Draft or Submitted to send');
  }

  // TODO: generate PDF and send via SES — backlog item
  console.log('[quoteManager] sendDocument stub — delivery:', args.deliveryMethod ?? 'email');

  const { data, errors } = await client.graphql({
    query: UPDATE_QUOTE,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.quoteId,
        status: 'DocumentSent',
        documentSentAt: new Date().toISOString(),
      },
    },
  }) as { data: { updateQuote: QuoteRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok({ ...data?.updateQuote, _stub: 'Document send pending SES integration' });
}

async function recordAccepted(args: QuoteManagerArgs): Promise<string> {
  if (!args.quoteId) return fail('VALIDATION_ERROR', 'quoteId is required');

  const existing = await getQuoteById(args.quoteId);
  if (!existing) return fail('QUOTE_NOT_FOUND', `Quote ${args.quoteId} not found`);
  if (existing.status !== 'DocumentSent') {
    return fail('INVALID_STATUS_TRANSITION', 'Quote must be DocumentSent before recording acceptance');
  }

  const { data, errors } = await client.graphql({
    query: UPDATE_QUOTE,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.quoteId,
        status: 'Accepted',
        acceptedAt: args.acceptedAt ?? new Date().toISOString(),
      },
    },
  }) as { data: { updateQuote: QuoteRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  // Side-effect: advance the parent job to Contracted
  if (existing.jobId) {
    await client.graphql({
      query: UPDATE_JOB,
      variables: { input: { id: existing.jobId, status: 'Contracted' } },
    });
  }

  return ok(data?.updateQuote);
}

async function recordRejected(args: QuoteManagerArgs): Promise<string> {
  if (!args.quoteId) return fail('VALIDATION_ERROR', 'quoteId is required');

  const existing = await getQuoteById(args.quoteId);
  if (!existing) return fail('QUOTE_NOT_FOUND', `Quote ${args.quoteId} not found`);
  if (existing.status !== 'DocumentSent') {
    return fail('INVALID_STATUS_TRANSITION', 'Quote must be DocumentSent before recording rejection');
  }

  const { data, errors } = await client.graphql({
    query: UPDATE_QUOTE,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.quoteId,
        status: 'Rejected',
        rejectedAt: args.rejectedAt ?? new Date().toISOString(),
        notes: args.notes,
      },
    },
  }) as { data: { updateQuote: QuoteRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.updateQuote);
}

// ── Internal helpers ──────────────────────────────────────────────────────────

async function getQuoteById(id: string): Promise<QuoteRow | null> {
  const { data } = await client.graphql({
    query: GET_QUOTE,
    variables: { id },
  }) as { data: { getQuote: QuoteRow | null } };
  return data?.getQuote ?? null;
}

async function listQuotesByJobId(jobId: string): Promise<QuoteRow[]> {
  const { data } = await client.graphql({
    query: LIST_QUOTES_BY_JOB,
    variables: { jobId },
  }) as { data: { listQuoteByJobId: { items: QuoteRow[] } } };
  return data?.listQuoteByJobId?.items ?? [];
}
