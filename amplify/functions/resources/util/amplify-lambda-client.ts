/**
 * Shared Amplify + API client for Lambda handlers.
 *
 * Problem: `Amplify.configure({ API: { GraphQL: { defaultAuthMode: 'iam' } } })`
 * alone does not provide credentials in a Lambda context — Amplify tries to
 * fetch them from a Cognito Identity Pool which doesn't exist here.
 *
 * Fix: supply a `credentialsProvider` in the LibraryOptions second argument
 * that reads directly from the Lambda execution-role environment variables.
 * Those are always present (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
 * `AWS_SESSION_TOKEN`) when the Lambda runs with an IAM execution role.
 */

import { Amplify } from 'aws-amplify';
import { generateClient } from 'aws-amplify/api';
import type { LibraryOptions } from '@aws-amplify/core';

const lambdaCredentialsProvider: LibraryOptions = {
  Auth: {
    credentialsProvider: {
      getCredentialsAndIdentityId: async () => ({
        credentials: {
          accessKeyId: process.env.AWS_ACCESS_KEY_ID ?? '',
          secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY ?? '',
          sessionToken: process.env.AWS_SESSION_TOKEN,
        },
      }),
      clearCredentialsAndIdentityId: () => { /* no-op in Lambda */ },
    },
  },
};

Amplify.configure(
  {
    API: {
      GraphQL: {
        endpoint: process.env.AMPLIFY_DATA_GRAPHQL_ENDPOINT ?? '',
        region: process.env.AWS_REGION ?? 'ap-southeast-2',
        defaultAuthMode: 'iam',
      },
    },
  },
  lambdaCredentialsProvider,
);

export const client = generateClient();

/**
 * Strips Amplify's auto-managed system fields before using a fetched record as
 * an update mutation input.
 *
 * WHY THIS EXISTS:
 * Amplify Gen 2's generated update resolvers use DynamoDB PutItem (replace
 * semantics), NOT UpdateItem (partial-update semantics).  If you pass only the
 * fields you want to change (e.g. `{id, status}`), DynamoDB replaces the whole
 * item with just those fields, silently clearing every other attribute.
 *
 * USAGE: spread this into every update mutation input alongside your overrides:
 *   input: { ...forUpdate(existing), id: entityId, status: 'NewStatus' }
 */
export function forUpdate<T extends Record<string, unknown>>(
  obj: T,
): Omit<T, 'createdAt' | 'updatedAt' | '__typename'> {
  const { createdAt: _c, updatedAt: _u, __typename: _t, ...rest } = obj;
  return rest as Omit<T, 'createdAt' | 'updatedAt' | '__typename'>;
}
