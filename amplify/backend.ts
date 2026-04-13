import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { data } from './data/resource';
import { jobManager } from './functions/jobManager/resource';
import { quoteManager } from './functions/quoteManager/resource';
import { quoteLineItemManager } from './functions/quoteLineItemManager/resource';
import { variationManager } from './functions/variationManager/resource';
import { claimManager } from './functions/claimManager/resource';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { Aws } from 'aws-cdk-lib';

export const backend = defineBackend({
  auth,
  data,
  jobManager,
  quoteManager,
  quoteLineItemManager,
  variationManager,
  claimManager,
});

// ── AppSync IAM wiring ────────────────────────────────────────────────────────
// Each manager Lambda calls back into AppSync via IAM auth to enforce business
// rules in code.  Two things are required:
//   1. The Lambda's execution role must have appsync:GraphQL permission.
//   2. The Lambda must know the GraphQL endpoint URL.
//
// The schema-level allow.resource(fn) handles AppSync's side (accepting the
// Lambda's IAM role) and auto-injects AMPLIFY_DATA_GRAPHQL_ENDPOINT, but we
// also add them explicitly here to match the established pattern and make the
// wiring visible in one place.

const appsyncArnWildcard = `arn:aws:appsync:${Aws.REGION}:${Aws.ACCOUNT_ID}:apis/*`;

const managers = [
  backend.jobManager,
  backend.quoteManager,
  backend.quoteLineItemManager,
  backend.variationManager,
  backend.claimManager,
] as const;

for (const manager of managers) {
  // Make the GraphQL endpoint available to the handler
  manager.addEnvironment('AMPLIFY_DATA_GRAPHQL_ENDPOINT', backend.data.graphqlUrl);

  // Grant IAM permission to invoke any operation on our AppSync API
  manager.resources.lambda.addToRolePolicy(
    new PolicyStatement({
      actions: ['appsync:GraphQL'],
      resources: [appsyncArnWildcard],
    })
  );
}
