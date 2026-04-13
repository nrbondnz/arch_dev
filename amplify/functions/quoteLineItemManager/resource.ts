import { defineFunction } from '@aws-amplify/backend';

export const quoteLineItemManager = defineFunction({
  name: 'quoteLineItemManager',
  entry: './handler.ts',
  resourceGroupName: 'data',
  timeoutSeconds: 30,
  memoryMB: 512,
  runtime: 20,
});
