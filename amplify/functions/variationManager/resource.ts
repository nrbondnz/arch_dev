import { defineFunction } from '@aws-amplify/backend';

export const variationManager = defineFunction({
  name: 'variationManager',
  entry: './handler.ts',
  resourceGroupName: 'data',
  timeoutSeconds: 30,
  memoryMB: 512,
  runtime: 20,
});
