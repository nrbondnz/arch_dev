import { defineFunction } from '@aws-amplify/backend';

export const quoteManager = defineFunction({
  name: 'quoteManager',
  entry: './handler.ts',
  resourceGroupName: 'data',
  timeoutSeconds: 30,
  memoryMB: 512,
  runtime: 20,
});
