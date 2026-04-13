import { createBaseHandler } from '../resources/util/BaseHandler.js';
import { unwrapPayload } from '../resources/common/payload_interfaces.js';
import { ok, fail, type QuoteLineItemManagerArgs } from '../../data/clean_models.js';
import { client, forUpdate } from '../resources/util/amplify-lambda-client.js';

// ── GraphQL operations ────────────────────────────────────────────────────────

const LI_FIELDS = `
  id quoteId description quantity unit rate total createdAt updatedAt
`;

const CREATE_LI = `
  mutation CreateQuoteLineItem($input: CreateQuoteLineItemInput!) {
    createQuoteLineItem(input: $input) { ${LI_FIELDS} }
  }
`;

const UPDATE_LI = `
  mutation UpdateQuoteLineItem($input: UpdateQuoteLineItemInput!) {
    updateQuoteLineItem(input: $input) { ${LI_FIELDS} }
  }
`;

const DELETE_LI = `
  mutation DeleteQuoteLineItem($input: DeleteQuoteLineItemInput!) {
    deleteQuoteLineItem(input: $input) { id quoteId }
  }
`;

const GET_LI = `
  query GetQuoteLineItem($id: ID!) {
    getQuoteLineItem(id: $id) { ${LI_FIELDS} }
  }
`;

const LIST_LI_BY_QUOTE = `
  query ListQuoteLineItemByQuoteId($quoteId: ID!) {
    listQuoteLineItemByQuoteId(quoteId: $quoteId) { items { ${LI_FIELDS} } nextToken }
  }
`;

const GET_QUOTE = `
  query GetQuote($id: ID!) {
    getQuote(id: $id) { id status }
  }
`;

const UPDATE_QUOTE = `
  mutation UpdateQuote($input: UpdateQuoteInput!) {
    updateQuote(input: $input) { id total }
  }
`;

// ── Handler ───────────────────────────────────────────────────────────────────

export const handler = createBaseHandler(async (event: unknown) => {
  const args = unwrapPayload<QuoteLineItemManagerArgs>(event);
  console.log('[quoteLineItemManager] apiFunction:', args.apiFunction);

  switch (args.apiFunction) {
    case 'addLineItem':    return await addLineItem(args);
    case 'updateLineItem': return await updateLineItem(args);
    case 'removeLineItem': return await removeLineItem(args);
    case 'listLineItems':  return await listLineItems(args);
    default:
      return fail('UNKNOWN_FUNCTION', `Unknown apiFunction: ${args.apiFunction}`);
  }
});

// ── Operations ────────────────────────────────────────────────────────────────

type LiRow = { id: string; quoteId?: string; quantity?: number; rate?: number; total?: number; [k: string]: unknown };

async function addLineItem(args: QuoteLineItemManagerArgs): Promise<string> {
  if (!args.quoteId)      return fail('VALIDATION_ERROR', 'quoteId is required');
  if (!args.description)  return fail('VALIDATION_ERROR', 'description is required');
  if (args.quantity == null) return fail('VALIDATION_ERROR', 'quantity is required');
  if (args.rate == null)     return fail('VALIDATION_ERROR', 'rate is required');

  // Business rule: quote must still be Draft
  const { data: qd } = await client.graphql({
    query: GET_QUOTE,
    variables: { id: args.quoteId },
  }) as { data: { getQuote: { id: string; status: string } | null } };

  const quote = qd?.getQuote;
  if (!quote) return fail('QUOTE_NOT_FOUND', `Quote ${args.quoteId} not found`);
  if (quote.status !== 'Draft') {
    return fail('INVALID_STATUS_TRANSITION', 'Line items can only be added to Draft quotes');
  }

  const total = args.quantity * args.rate;

  const { data, errors } = await client.graphql({
    query: CREATE_LI,
    variables: {
      input: {
        quoteId: args.quoteId,
        description: args.description,
        quantity: args.quantity,
        unit: args.unit ?? 'm2',
        rate: args.rate,
        total,
      },
    },
  }) as { data: { createQuoteLineItem: LiRow }; errors?: unknown[] };

  if (errors?.length) return fail('CREATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  await recalculateQuoteTotal(args.quoteId);
  return ok(data?.createQuoteLineItem);
}

async function updateLineItem(args: QuoteLineItemManagerArgs): Promise<string> {
  if (!args.lineItemId) return fail('VALIDATION_ERROR', 'lineItemId is required');

  const { data: ld } = await client.graphql({
    query: GET_LI,
    variables: { id: args.lineItemId },
  }) as { data: { getQuoteLineItem: LiRow | null } };

  const existing = ld?.getQuoteLineItem;
  if (!existing) return fail('LINE_ITEM_NOT_FOUND', `LineItem ${args.lineItemId} not found`);

  const qty   = args.quantity ?? existing.quantity ?? 0;
  const rate  = args.rate     ?? existing.rate ?? 0;
  const total = qty * rate;

  const { data, errors } = await client.graphql({
    query: UPDATE_LI,
    variables: {
      input: {
        ...forUpdate(existing),
        id: args.lineItemId,
        description: args.description ?? existing.description,
        quantity: qty,
        unit: args.unit ?? existing.unit,
        rate,
        total,
      },
    },
  }) as { data: { updateQuoteLineItem: LiRow }; errors?: unknown[] };

  if (errors?.length) return fail('UPDATE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  if (existing.quoteId) await recalculateQuoteTotal(existing.quoteId as string);
  return ok(data?.updateQuoteLineItem);
}

async function removeLineItem(args: QuoteLineItemManagerArgs): Promise<string> {
  if (!args.lineItemId) return fail('VALIDATION_ERROR', 'lineItemId is required');

  const { data: ld } = await client.graphql({
    query: GET_LI,
    variables: { id: args.lineItemId },
  }) as { data: { getQuoteLineItem: LiRow | null } };

  const existing = ld?.getQuoteLineItem;
  if (!existing) return fail('LINE_ITEM_NOT_FOUND', `LineItem ${args.lineItemId} not found`);

  const { errors } = await client.graphql({
    query: DELETE_LI,
    variables: { input: { id: args.lineItemId } },
  }) as { errors?: unknown[] };

  if (errors?.length) return fail('DELETE_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));

  if (existing.quoteId) await recalculateQuoteTotal(existing.quoteId as string);
  return ok({ deleted: args.lineItemId });
}

async function listLineItems(args: QuoteLineItemManagerArgs): Promise<string> {
  if (!args.quoteId) return fail('VALIDATION_ERROR', 'quoteId is required');

  const { data, errors } = await client.graphql({
    query: LIST_LI_BY_QUOTE,
    variables: { quoteId: args.quoteId },
  }) as { data: { listQuoteLineItemByQuoteId: { items: LiRow[] } }; errors?: unknown[] };

  if (errors?.length) return fail('FETCH_FAILED', (errors[0] as { message?: string }).message ?? JSON.stringify(errors[0]));
  return ok(data?.listQuoteLineItemByQuoteId?.items ?? []);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

async function recalculateQuoteTotal(quoteId: string): Promise<void> {
  const { data } = await client.graphql({
    query: LIST_LI_BY_QUOTE,
    variables: { quoteId },
  }) as { data: { listQuoteLineItemByQuoteId: { items: LiRow[] } } };

  const items = data?.listQuoteLineItemByQuoteId?.items ?? [];
  const total = items.reduce((sum: number, li: LiRow) => sum + (li.total ?? 0), 0);

  await client.graphql({
    query: UPDATE_QUOTE,
    variables: { input: { id: quoteId, total } },
  });
}
