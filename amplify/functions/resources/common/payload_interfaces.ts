/**
 * Unwraps the arguments payload from an AppSync Lambda resolver event.
 *
 * Handles two calling conventions:
 *  1. Inline arguments  → event.arguments  (standard .arguments({...}) schema)
 *  2. Ref-wrapped input → event.arguments.input  (when using a.ref("InputType"))
 *
 * Falls back to the raw event for direct Lambda invocations (e.g. unit tests).
 */
export function unwrapPayload<T>(event: unknown): T {
  const e = event as Record<string, unknown>;
  const args = e?.arguments as Record<string, unknown> | undefined;

  // Ref-wrapped: .arguments({ input: a.ref('SomeInputType') })
  if (args?.input !== undefined && args?.input !== null) {
    return args.input as T;
  }

  // Inline: .arguments({ apiFunction: a.string(), ... })
  if (args !== undefined) {
    return args as unknown as T;
  }

  // Direct Lambda invocation (testing / manual invoke)
  return event as T;
}

// Re-export the alias used in the template (unwrapPayloadUsingInputRef)
export const unwrapPayloadUsingInputRef = unwrapPayload;
