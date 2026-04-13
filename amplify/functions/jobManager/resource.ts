import { defineFunction } from '@aws-amplify/backend';

export const jobManager = defineFunction({
  name: 'jobManager',
  entry: './handler.ts',
  resourceGroupName: 'data',
  timeoutSeconds: 30,
  memoryMB: 512,
  runtime: 20,
});
