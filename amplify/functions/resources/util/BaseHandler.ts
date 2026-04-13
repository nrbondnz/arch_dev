import { fail } from '../../../data/clean_models.js';

const _moduleLoadedAt = new Date().toISOString();
console.log(`[${process.env.AWS_LAMBDA_FUNCTION_NAME ?? 'UNKNOWN'}] Lambda module loaded (cold start).`, {
  time: _moduleLoadedAt,
  functionName: process.env.AWS_LAMBDA_FUNCTION_NAME ?? null,
  awsRegion: process.env.AWS_REGION ?? process.env.AWS_DEFAULT_REGION ?? null,
});

/**
 * Wraps a manager handler with:
 *  - Cold-start logging (already at module scope above)
 *  - Top-level try/catch so unhandled exceptions return a clean fail() JSON
 *    string rather than propagating as a raw Lambda error (which AppSync would
 *    surface as a GraphQL error with an opaque "[object Object]" message).
 */
export function createBaseHandler(
  handlerFunc: (event: unknown) => Promise<string>,
): (event: unknown) => Promise<string> {
  return async (event: unknown) => {
    try {
      return await handlerFunc(event);
    } catch (err: unknown) {
      const message =
        err instanceof Error
          ? err.message
          : typeof err === 'object'
            ? JSON.stringify(err)
            : String(err);
      console.error(`[${process.env.AWS_LAMBDA_FUNCTION_NAME ?? 'handler'}] Unhandled exception:`, message, err);
      return fail('INTERNAL_ERROR', message);
    }
  };
}
