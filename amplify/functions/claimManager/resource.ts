import { defineFunction } from '@aws-amplify/backend';

export const claimManager = defineFunction({
  name: 'claimManager',
  entry: './handler.ts',
  resourceGroupName: 'data',
  timeoutSeconds: 30,
  memoryMB: 512,
  runtime: 20,
});
