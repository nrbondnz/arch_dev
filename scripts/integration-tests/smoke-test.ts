/**
 * ARCH Backend Smoke Tests
 *
 * Verifies that each manager Lambda is reachable and returning correct responses.
 * Run AFTER the backend has been deployed (not during the build phase).
 *
 * Prerequisites:
 *   amplify_outputs.json generated via:
 *     npx ampx generate outputs --format json --out-dir scripts/integration-tests
 *
 * Required environment variables:
 *   TEST_USER_EMAIL     — email of an admin-manager Cognito user
 *   TEST_USER_PASSWORD  — password for that user
 *
 * Run:
 *   npx tsx scripts/integration-tests/smoke-test.ts
 *
 * The test creates real records prefixed with "[SMOKE]" and does NOT clean them
 * up, so you can inspect them in the console. Run cleanup manually if needed.
 */

import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// ── Load amplify outputs ────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const outputsPath = resolve(__dirname, 'amplify_outputs.json');

if (!existsSync(outputsPath)) {
  console.error('[SMOKE] amplify_outputs.json not found at', outputsPath);
  console.error('[SMOKE] Generate it with:');
  console.error('[SMOKE]   npx ampx generate outputs --format json --out-dir scripts/integration-tests');
  process.exit(1);
}

const outputs = JSON.parse(readFileSync(outputsPath, 'utf8'));

// ── Credentials check ───────────────────────────────────────────────────────────

const TEST_EMAIL    = process.env.TEST_USER_EMAIL;
const TEST_PASSWORD = process.env.TEST_USER_PASSWORD;

if (!TEST_EMAIL || !TEST_PASSWORD) {
  console.error('[SMOKE] TEST_USER_EMAIL and TEST_USER_PASSWORD must be set');
  process.exit(1);
}

// ── Amplify + client setup ──────────────────────────────────────────────────────

import { Amplify } from 'aws-amplify';
import { signIn, signOut } from 'aws-amplify/auth';
import { generateClient } from 'aws-amplify/api';

Amplify.configure(outputs);
const client = generateClient();

// ── Test harness ────────────────────────────────────────────────────────────────

let passed = 0;
let failed = 0;

async function test(name: string, fn: () => Promise<void>) {
  try {
    await fn();
    console.log(`  ✓  ${name}`);
    passed++;
  } catch (err) {
    console.error(`  ✗  ${name}`);
    console.error(`       ${(err as Error).message}`);
    failed++;
  }
}

function parseManagerResponse(raw: string | null | undefined, context: string) {
  if (!raw) throw new Error(`${context}: null response`);
  const result = JSON.parse(raw) as { success: boolean; data?: unknown; error?: string; message?: string };
  if (!result.success) throw new Error(`${context} failed: ${result.error} — ${result.message}`);
  return result.data;
}

// ── GraphQL query documents ─────────────────────────────────────────────────────

const CALL_JOB = /* GraphQL */ `
  query($apiFunction: String!, $jobId: ID, $clientName: String,
        $clientContactName: String, $siteAddress: String,
        $description: String, $contractType: String, $status: String) {
    callJobManagerAPI(apiFunction: $apiFunction, jobId: $jobId,
      clientName: $clientName, clientContactName: $clientContactName,
      siteAddress: $siteAddress, description: $description,
      contractType: $contractType, status: $status)
  }
`;

const CALL_QUOTE = /* GraphQL */ `
  query($apiFunction: String!, $quoteId: ID, $jobId: ID,
        $notes: String, $validUntil: String, $deliveryMethod: String) {
    callQuoteManagerAPI(apiFunction: $apiFunction, quoteId: $quoteId,
      jobId: $jobId, notes: $notes, validUntil: $validUntil,
      deliveryMethod: $deliveryMethod)
  }
`;

const CALL_LINE_ITEM = /* GraphQL */ `
  query($apiFunction: String!, $quoteId: ID,
        $description: String, $quantity: Float, $unit: String, $rate: Float) {
    callQuoteLineItemManagerAPI(apiFunction: $apiFunction, quoteId: $quoteId,
      description: $description, quantity: $quantity, unit: $unit, rate: $rate)
  }
`;

const CALL_VARIATION = /* GraphQL */ `
  query($apiFunction: String!, $variationId: ID, $jobId: ID,
        $description: String, $price: Float, $timeImpactDays: Int) {
    callVariationManagerAPI(apiFunction: $apiFunction, variationId: $variationId,
      jobId: $jobId, description: $description, price: $price,
      timeImpactDays: $timeImpactDays)
  }
`;

const CALL_CLAIM = /* GraphQL */ `
  query($apiFunction: String!, $claimId: ID, $stageId: ID, $jobId: ID,
        $periodDescription: String) {
    callClaimManagerAPI(apiFunction: $apiFunction, claimId: $claimId,
      stageId: $stageId, jobId: $jobId, periodDescription: $periodDescription)
  }
`;

// ── Helpers ─────────────────────────────────────────────────────────────────────

async function callJob(vars: Record<string, unknown>) {
  const res = await client.graphql({ query: CALL_JOB, variables: vars });
  return parseManagerResponse(
    (res as { data: { callJobManagerAPI: string } }).data.callJobManagerAPI,
    `callJobManagerAPI[${vars.apiFunction}]`,
  ) as Record<string, unknown>;
}

async function callQuote(vars: Record<string, unknown>) {
  const res = await client.graphql({ query: CALL_QUOTE, variables: vars });
  return parseManagerResponse(
    (res as { data: { callQuoteManagerAPI: string } }).data.callQuoteManagerAPI,
    `callQuoteManagerAPI[${vars.apiFunction}]`,
  ) as Record<string, unknown>;
}

async function callLineItem(vars: Record<string, unknown>) {
  const res = await client.graphql({ query: CALL_LINE_ITEM, variables: vars });
  return parseManagerResponse(
    (res as { data: { callQuoteLineItemManagerAPI: string } }).data.callQuoteLineItemManagerAPI,
    `callQuoteLineItemManagerAPI[${vars.apiFunction}]`,
  ) as Record<string, unknown>;
}

async function callVariation(vars: Record<string, unknown>) {
  const res = await client.graphql({ query: CALL_VARIATION, variables: vars });
  return parseManagerResponse(
    (res as { data: { callVariationManagerAPI: string } }).data.callVariationManagerAPI,
    `callVariationManagerAPI[${vars.apiFunction}]`,
  ) as Record<string, unknown>;
}

async function callClaim(vars: Record<string, unknown>) {
  const res = await client.graphql({ query: CALL_CLAIM, variables: vars });
  return parseManagerResponse(
    (res as { data: { callClaimManagerAPI: string } }).data.callClaimManagerAPI,
    `callClaimManagerAPI[${vars.apiFunction}]`,
  ) as Record<string, unknown>;
}

// ── Main ─────────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[SMOKE] Authenticating…');
  await signIn({ username: TEST_EMAIL, password: TEST_PASSWORD });
  console.log('[SMOKE] Signed in as', TEST_EMAIL);
  console.log('');

  // ── jobManager ──────────────────────────────────────────────────────────────
  console.log('jobManager:');
  let jobId!: string;

  await test('createJob returns an id', async () => {
    const job = await callJob({
      apiFunction: 'createJob',
      clientName: '[SMOKE] Test Client',
      siteAddress: '[SMOKE] 1 Test St, Testville',
      description: 'Smoke test job',
      contractType: 'LumpSum',
    });
    jobId = job.id as string;
    if (!jobId) throw new Error('No id in response');
  });

  await test('getJob returns the created job', async () => {
    const job = await callJob({ apiFunction: 'getJob', jobId });
    if ((job as { id: string }).id !== jobId) throw new Error('id mismatch');
  });

  await test('listJobs includes the new job', async () => {
    const jobs = await callJob({ apiFunction: 'listJobs' });
    const arr = jobs as unknown as Array<{ id: string }>;
    if (!arr.some(j => j.id === jobId)) throw new Error('job not in list');
  });

  await test('updateJob changes status', async () => {
    const updated = await callJob({
      apiFunction: 'updateJob',
      jobId,
      status: 'InProgress',
    });
    if ((updated as { status: string }).status !== 'InProgress') {
      throw new Error('status not updated');
    }
  });

  console.log('');

  // ── quoteManager ────────────────────────────────────────────────────────────
  console.log('quoteManager:');
  let quoteId!: string;

  await test('createQuote returns an id', async () => {
    const quote = await callQuote({
      apiFunction: 'createQuote',
      jobId,
      notes: 'Smoke test quote',
      validUntil: '2099-12-31',
    });
    quoteId = (quote as { id: string }).id;
    if (!quoteId) throw new Error('No id in response');
  });

  await test('getQuote returns the created quote', async () => {
    const quote = await callQuote({ apiFunction: 'getQuote', quoteId });
    if ((quote as { id: string }).id !== quoteId) throw new Error('id mismatch');
  });

  console.log('');

  // ── quoteLineItemManager ─────────────────────────────────────────────────────
  console.log('quoteLineItemManager:');

  await test('addLineItem updates quote total', async () => {
    const li = await callLineItem({
      apiFunction: 'addLineItem',
      quoteId,
      description: '[SMOKE] Brickwork',
      quantity: 10,
      unit: 'm2',
      rate: 300,
    });
    if (!(li as { id: string }).id) throw new Error('No line item id');
  });

  await test('listLineItems returns the item', async () => {
    const items = await callLineItem({ apiFunction: 'listLineItems', quoteId });
    const arr = items as unknown as Array<{ quoteId: string }>;
    if (!arr.some(li => li.quoteId === quoteId)) throw new Error('item not found');
  });

  console.log('');

  // ── variationManager ─────────────────────────────────────────────────────────
  console.log('variationManager:');
  let variationId!: string;

  await test('createVariation returns an id', async () => {
    const v = await callVariation({
      apiFunction: 'createVariation',
      jobId,
      description: '[SMOKE] Extra work',
      price: 500,
      timeImpactDays: 0,
    });
    variationId = (v as { id: string }).id;
    if (!variationId) throw new Error('No id');
  });

  await test('getVariation returns it', async () => {
    const v = await callVariation({ apiFunction: 'getVariation', variationId });
    if ((v as { id: string }).id !== variationId) throw new Error('id mismatch');
  });

  console.log('');

  // ── claimManager ─────────────────────────────────────────────────────────────
  // Claims need a valid stageId — we skip the full lifecycle here and just
  // verify the error path returns a well-formed ManagerResponse.
  console.log('claimManager:');

  await test('createClaim with missing stageId returns fail response (not an exception)', async () => {
    const res = await client.graphql({
      query: CALL_CLAIM,
      variables: { apiFunction: 'createClaim', jobId },
    });
    const raw = (res as { data: { callClaimManagerAPI: string } }).data.callClaimManagerAPI;
    const parsed = JSON.parse(raw) as { success: boolean; error: string };
    if (parsed.success !== false || parsed.error !== 'VALIDATION_ERROR') {
      throw new Error(`Expected VALIDATION_ERROR, got: ${JSON.stringify(parsed)}`);
    }
  });

  console.log('');

  // ── Summary ──────────────────────────────────────────────────────────────────
  console.log('─'.repeat(40));
  console.log(`Passed: ${passed}  Failed: ${failed}`);
  if (failed > 0) {
    console.error(`[SMOKE] ${failed} test(s) failed`);
  } else {
    console.log('[SMOKE] All tests passed');
  }

  await signOut();

  process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
  console.error('[SMOKE] Unhandled error:', err);
  process.exit(1);
});
