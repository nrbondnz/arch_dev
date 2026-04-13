/**
* Backend infrastructure with a stable, custom domain per environment using subdomains.
*
* DNS model:
* - Zone: appssfromnz.com
* - Endpoints in use:
*   - sandbox.webhook.wherewillwevisit.com   (covered by wildcard cert: *.webhook.wherewillwevisit.com)
*   - webhook.wherewillwevisit.com           (covered by apex cert for webhook.wherewillwevisit.com)
*
* Highlights:
* - Environment is derived from AMPLIFY_BRANCH/AMPLIFY_ENV/USER; no forced "sandbox" by default.
* - All named resources get an environment-specific suffix for isolation (e.g., -nigel, -sandbox).
* - API Gateway custom domain:
*     - non-sandbox -> webhook.wherewillwevisit.com (apex certificate)
* - Injects EVENT_BUS_NAME into myWebhook so it can publish to the correct EventBridge bus.
* - Outputs exact CNAME pair for Route 53 (Name -> Value) to wire up subdomain DNS.
* - Use the custom domain for a sticky URL. The execute-api URL can change across deployments.
    */

// --- Amplify Core Resources ---
import {defineBackend, secret} from '@aws-amplify/backend';
import { auth } from './auth/resource.js';
import { data } from './data/resource.js';
import { storage } from './storage/resource.js';

// --- User & Profile Management Functions ---
import { historyManager } from "./functions/historyManager/resource.js";
import { supportManager } from "./functions/supportManager/resource.js";

// --- Payment & Subscription Functions (Stripe) ---
import { myWebhook } from './functions/myWebhook/resource.js';
// import { stripeSubscriptionCall } from './functions/stripeSubscriptionCall/resource.js';
//import { stripeSubscriptionCancelCall } from './functions/cancel_stripe_subscription/resource.js';
//import { transactionProcessor } from './javasrc/resources/transactionProcessor/resource.js';
import { createProductPaymentIntent } from './functions/createProductPaymentIntent/resource.js';

// --- AI & Content Functions ---
import { geminiCalls } from './functions/geminiCalls/resource.js';
//import { updateUserTable } from './functions/updateUserTable/resource.js';
import { qaPromptDelivery } from './functions/qaPromptDelivery/resource.js';
import { productDetails } from './functions/productDetails/resource.js';
import { locationSearch } from './functions/locationSearch/resource.js';
import { userManager } from './functions/userManager/resource.js';
import { cancelStripeSubscription } from './functions/cancelStripeSubscription/resource.js';
//import { placesToStay } from './functions/places_to_stay/resource.js';

// --- Utility & External Service Functions ---
//import { locationSearch } from './functions/locationSearch/resource.js';

// --- AWS CDK & Third Party Imports ---
import {Aws, Duration} from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3_assets from 'aws-cdk-lib/aws-s3-assets';
import * as path from 'path';
import { fileURLToPath } from 'url';


import { PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { FunctionUrlAuthType, HttpMethod as LambdaUrlHttpMethod } from 'aws-cdk-lib/aws-lambda';
import { EventBus, Rule } from 'aws-cdk-lib/aws-events';
import { LambdaFunction } from 'aws-cdk-lib/aws-events-targets';
import {  EventDetailsEnum } from './data/models.js';

import {
RestApi,
LambdaIntegration,
Cors,
DomainName as RestDomainName,
BasePathMapping,
CfnBasePathMapping,
EndpointType,
SecurityPolicy,
} from 'aws-cdk-lib/aws-apigateway';
import { Certificate } from 'aws-cdk-lib/aws-certificatemanager';
import { defineFunction } from "@aws-amplify/backend";
export const stripeSecretKey = secret("STRIPE_SECRET_KEY");
export const stripePublishableKey = secret("STRIPE_PUBLISHABLE_KEY");
export const stripeWebhookSecret = secret("STRIPE_WEBHOOK_SECRET");
export const stripeTestSecretKey = secret("STRIPE_TEST_SECRET_KEY");
export const stripeDevWebhookSecret = secret("STRIPE_DEV_WEBHOOK_SECRET");




/* ---------- Configuration & Environment ---------- */

// Stable custom domain configuration - prevents recreation on deployments
// Set the current working domain alias to make it "sticky"
const STABLE_WEBHOOK_DOMAIN_ALIAS = 'd-qdto9rw5u5.execute-api.ap-southeast-2.amazonaws.com';

// Environment-specific picker configuration
const PICKER_CONFIGS = {
'NewZealand': 'gReffffeefe3rkopf8jgle3',
'UnitedKingdom': '34ff4hhtht66f1bbfe4',
};

// App Hosting Subpath Configuration
// Serve Flutter app from wherewillwevisit.com/whereinnz/ instead of subdomain to avoid wildcard cert costs
const APP_BASE_PATH = '/';
const APP_DOMAIN_NAME = 'wherewillwevisit.com';

/* ---------- Environment Derivation ---------- */
const rawId =
process.env.AWS_BRANCH ||
process.env.AMPLIFY_BRANCH ||
process.env.USER ||
process.env.USERNAME ||
'test';

const aws_branch = process.env.AWS_BRANCH;

let baseEnv =
(rawId!)
.trim()
.toLowerCase()
.replace(/[^a-z0-9-]/g, '')
.replace(/^-+|-+$/g, '');

if (!baseEnv || baseEnv.length === 0) {
baseEnv = 'default';
}

const environment = baseEnv;

// Unique resource suffix per environment (e.g., -sandbox, -prod)
const suffix = `-${environment}`;

/* ---------- Path Resolution for External Assets (Java JAR) ---------- */
import * as fs from 'node:fs';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const JAR_PATH = path.resolve(__dirname, './resources/java_jar/wherewwv-functions-lambda-1.0.0.jar');

if (!fs.existsSync(JAR_PATH)) {
console.warn(`[BACKEND] JAR file not found at: ${JAR_PATH}`);
}

/* ---------- Define backend logical resources ---------- */
export const backend = defineBackend({
// --- Core Services ---
auth,
data,
storage,

    // --- User Management ---
    userManager,
    historyManager,
    supportManager,
    //updateUserTable,

    // --- Payments (Stripe) ---
    myWebhook,
    //transactionProcessor,
    // stripeSubscriptionCall,
    cancelStripeSubscription,
    createProductPaymentIntent,

    // --- AI & Content ---
    geminiCalls,
    qaPromptDelivery,
    productDetails,

    // --- External Services ---
    locationSearch,
});

/* ---------- Messaging & Notifications (EventBridge & SNS) ---------- */

// Neutral infra stack (shared infra, env-scoped)
const infra = backend.createStack(`infra${suffix}`);

// SNS Topic for support emails
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sns_sub from 'aws-cdk-lib/aws-sns-subscriptions';

const supportTopic = new sns.Topic(infra, 'SupportTopic', {
topicName: `support-topic${suffix}`,
});

// Subscribe support email to the topic
supportTopic.addSubscription(new sns_sub.EmailSubscription('bondsfamily0007@gmail.com'));

// EventBridge buses to fan-out normalized payment and history events.
const backendEventBus = new EventBus(infra, 'TransactionEventBus', {
eventBusName: `transaction-events${suffix}`,
});
/*const tableUpdateEventBus = new EventBus(infra, 'TableUpdateEventBus', {
eventBusName: `tableUpd-events${suffix}`,
});
const historyEventBus = new EventBus(infra, 'HistoryEventBus', {
eventBusName: `history-events${suffix}`,
});*/
const bucket = backend.storage.resources.bucket;
const bucketName = bucket.bucketName;
const appsyncArnWildcard = `arn:aws:appsync:${Aws.REGION}:${Aws.ACCOUNT_ID}:apis/*`;
const userTableArnPattern = `arn:aws:dynamodb:${Aws.REGION}:${Aws.ACCOUNT_ID}:table/User-*`;
// Allow webhook lambda to PutEvents on this environment's EventBridge buses
backend.myWebhook.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['events:PutEvents'],
resources: [backendEventBus.eventBusArn],
})
);

// backend.userManager.addEnvironment(
//     'GRAPHQL_ENDPOINT',
//     backend.data.graphqlUrl
// );

/*new Rule(backend.userManager.stack, 'TableUpdateRule', {
eventBus: backendEventBus,
eventPattern: {
source: ['userManager'],
detailType: [EventDetailsEnum.UPDATE_USER_TABLE],
},
targets: [new LambdaFunction(backend.updateUserTable.resources.lambda)],
});*/

backend.userManager.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['appsync:GraphQL'],
resources: [appsyncArnWildcard],
})
);

backend.data.resources.tables['User'].grantReadWriteData(
backend.userManager.resources.lambda
);

backend.userManager.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: [
'dynamodb:GetItem',
'dynamodb:PutItem',
'dynamodb:UpdateItem',
'dynamodb:DeleteItem',
'dynamodb:Query',
'dynamodb:Scan',
'dynamodb:DescribeTable'
],
resources: [
backend.data.resources.tables['User'].tableArn,
userTableArnPattern
],
})
);



// Allow userManager to PutEvents to the table update bus
backend.userManager.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['events:PutEvents'],
resources: [backendEventBus.eventBusArn],
})
);
backend.geminiCalls.addEnvironment('EVENT_BUS_NAME', backendEventBus.eventBusName);
backend.geminiCalls.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['events:PutEvents'],
resources: [backendEventBus.eventBusArn],
})
);
backend.geminiCalls.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['s3:GetObject', 's3:GetObject', 's3:PutObject','s3:ListBucket', 's3:HeadObject', 's3:GetBucketLocation'],
resources: [
`arn:aws:s3:::${bucketName}`,
`arn:aws:s3:::${bucketName}/*`,
`arn:aws:s3:::wherein0007bucket`,
`arn:aws:s3:::wherein0007bucket/*`
],
})
);
backend.geminiCalls.addEnvironment('WHEREIN_BUCKET_NAME', bucketName);
backend.geminiCalls.addEnvironment('STORAGE_BUCKET_NAME', 'wherein0007bucket');
backend.geminiCalls.addEnvironment('BUCKET_REGION', 'us-east-1');
backend.qaPromptDelivery.addEnvironment('WHEREIN_BUCKET_NAME', bucketName);





backend.myWebhook.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['appsync:GraphQL'],
resources: [appsyncArnWildcard],
})
);
const transactionHistoryTableName = backend.data.resources.tables['TransactionHistory'].tableName;
backend.historyManager.addEnvironment('TRANSACTION_HISTORY_TABLE_NAME', transactionHistoryTableName);
backend.historyManager.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);
backend.historyManager.addEnvironment('EVENT_BUS_NAME', backendEventBus.eventBusName);
// EventBridge Rule -> historyManager
new Rule(backend.myWebhook.stack, 'processingHistoricEventRule', {
eventBus: backendEventBus,
eventPattern: {
source: ['myWebhook'],
detailType: [
EventDetailsEnum.ADD_HISTORIC_EVENT
],
},
targets: [
new LambdaFunction(backend.historyManager.resources.lambda)],
});
new Rule(backend.geminiCalls.stack, 'processingRecommendationEventRule', {
eventBus: backendEventBus,
eventPattern: {
source: ['geminiCalls'],
detailType: [
EventDetailsEnum.RECOMMENDATION_USED,
],
},
targets: [
new LambdaFunction(backend.userManager.resources.lambda)],
});
new Rule(backend.myWebhook.stack, 'processingStripeEventRule', {
eventBus: backendEventBus,
eventPattern: {
source: ['myWebhook'],
detailType: [
EventDetailsEnum.PAYMENT_SUCCEEDED,
EventDetailsEnum.PAYMENT_FAILED,
EventDetailsEnum.SUBSCRIPTION_CREATED,
EventDetailsEnum.PAYMENT_INTENT_SUCCEEDED,
EventDetailsEnum.SUBSCRIPTION_PAYMENT_SUCCEEDED,
EventDetailsEnum.SUBSCRIPTION_CANCELLED,
EventDetailsEnum.RECOMMENDATION_USED,
],
},
targets: [
new LambdaFunction(backend.userManager.resources.lambda)],
});
backend.historyManager.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['appsync:GraphQL'],
resources: [appsyncArnWildcard],
})
);
// backend.historyManager.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);

// Explicitly grant DynamoDB permissions to historyManager via table ARN pattern
backend.historyManager.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: [
'dynamodb:GetItem',
'dynamodb:PutItem',
'dynamodb:UpdateItem',
'dynamodb:DeleteItem',
'dynamodb:Query',
'dynamodb:Scan',
'dynamodb:DescribeTable'
],
resources: [backend.data.resources.tables['TransactionHistory'].tableArn],
})
);

const userTableName = backend.data.resources.tables['User'].tableName;
backend.userManager.addEnvironment('USER_TABLE_NAME', userTableName);
backend.userManager.addEnvironment('USER_TABLE', userTableName);
// backend.userManager.addEnvironment('APPSYNC_URL', backend.data.graphqlUrl);
// backend.userManager.addEnvironment('EVENT_BUS_NAME', backendEventBus.eventBusName);
// backend.userManager.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);

// only needed i
backend.myWebhook.addEnvironment('USER_TABLE_NAME', userTableName);
backend.myWebhook.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);
backend.myWebhook.addEnvironment('APPSYNC_URL', backend.data.graphqlUrl);

// backend.data.resources.tables['User'].grantReadWriteData(backend.userManager.resources.lambda);
backend.myWebhook.addEnvironment('EVENT_BUS_NAME', backendEventBus.eventBusName);
backend.myWebhook.addEnvironment('PRODUCT_DETAILS_FUNCTION_NAME', backend.productDetails.resources.lambda.functionName);
backend.myWebhook.addEnvironment('APP_ENV', environment);
backend.myWebhook.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);
backend.productDetails.resources.lambda.grantInvoke(backend.myWebhook.resources.lambda);



// EventBridge rule
/*new Rule(backend.myWebhook.stack, 'UserManagerRule', {
eventBus: backendEventBus,
eventPattern: {
source: ['myWebhook'],
detailType: [
EventDetailsEnum.PAYMENT_FAILED,
EventDetailsEnum.PAYMENT_SUCCEEDED,
EventDetailsEnum.PAYMENT_INTENT_SUCCEEDED,
EventDetailsEnum.SUBSCRIPTION_CREATED,
EventDetailsEnum.CUSTOMER_SUBSCRIPTION_CREATED,
EventDetailsEnum.SUBSCRIPTION_PAYMENT_SUCCEEDED,
EventDetailsEnum.SUBSCRIPTION_CANCELLED
],
},
targets: [new LambdaFunction(backend.userManager.resources.lambda)],
});*/
// Support Notifications (SNS)
// Ensure this topic exists and has a confirmed email subscription to support@wherewillwevisit.com
const SUPPORT_SNS_TOPIC_ARN = `arn:aws:sns:${Aws.REGION}:${Aws.ACCOUNT_ID}:support-notifications`;
//backend.transactionProcessor.addEnvironment('SUPPORT_SNS_TOPIC_ARN', SUPPORT_SNS_TOPIC_ARN);
//backend.transactionProcessor.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);
//backend.transactionProcessor.resources.lambda.addToRolePolicy(
//    new PolicyStatement({
//        actions: ['sns:Publish'],
//        resources: [SUPPORT_SNS_TOPIC_ARN],
//    })
//);

//backend.transactionProcessor.resources.lambda.addToRolePolicy(
//    new PolicyStatement({
//        actions: ['appsync:GraphQL'],
//        resources: [appsyncArnWildcard],
//    })
//);






backend.cancelStripeSubscription.addEnvironment("APPSYNC_URL", backend.data.graphqlUrl);
backend.cancelStripeSubscription.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['appsync:GraphQL'],
resources: [appsyncArnWildcard],
})
);

backend.productDetails.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['appsync:GraphQL'],
resources: [appsyncArnWildcard],
})
);

backend.productDetails.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['ssm:GetParameter', 'ssm:GetParameters', 'kms:Decrypt'],
resources: ['*'],
})
);

backend.locationSearch.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['appsync:GraphQL'],
resources: [appsyncArnWildcard],
})
);

// Location Service permissions
backend.locationSearch.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['geo:SearchPlaceIndexForSuggestions', 'geo:SearchPlaceIndexForText'],
resources: [
'arn:aws:geo:ap-southeast-2:445567075330:place-index/MyNZPlaceIndex',
'arn:aws:geo:ap-southeast-2:445567075330:place-index/MyUnitedKingdomPlaceIndex'
],
})
);

// S3 Storage Access (Workaround for root-level files)
// Using ImportValue or referential logic causes circular deps: [storage, auth, data, webhook]
// Grant storage access to users and Lambdas for root-level files (bypasses standard Amplify restrictions)


backend.qaPromptDelivery.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['s3:GetObject', 's3:ListBucket', 's3:HeadObject', 's3:GetBucketLocation'],
resources: [
`arn:aws:s3:::${bucketName}`,
`arn:aws:s3:::${bucketName}/*`,
`arn:aws:s3:::wherein0007bucket`,
`arn:aws:s3:::wherein0007bucket/*`
],
})
);
backend.qaPromptDelivery.addEnvironment('WHEREIN_BUCKET_NAME', bucketName);

// Grant permissions to roles via bucket policy to avoid auth -> storage cycle.
// This keeps the dependency direction as storage -> auth.
bucket.addToResourcePolicy(
new PolicyStatement({
actions: ['s3:GetObject', 's3:ListBucket', 's3:GetBucketLocation'],
resources: [
bucket.bucketArn,
bucket.arnForObjects('*'),
bucket.arnForObjects('public/*')
],
principals: [
backend.auth.resources.unauthenticatedUserIamRole,
backend.auth.resources.authenticatedUserIamRole,
],
})
);
bucket.addToResourcePolicy(
new PolicyStatement({
actions: ['s3:PutObject', 's3:DeleteObject'],
resources: [
bucket.arnForObjects('*'),
bucket.arnForObjects('public/*')
],
principals: [backend.auth.resources.authenticatedUserIamRole],
})
);

/* ---------- Function Configuration & Environment Variables ---------- */

// Add picker configuration to backend
backend.qaPromptDelivery.addEnvironment('PICKER_CONFIGS', JSON.stringify(PICKER_CONFIGS));




backend.createProductPaymentIntent.addEnvironment('USER_TABLE_NAME', userTableName);
backend.createProductPaymentIntent.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);
backend.createProductPaymentIntent.addEnvironment('APPSYNC_URL', backend.data.graphqlUrl);
backend.data.resources.tables['User'].grantReadWriteData(backend.createProductPaymentIntent.resources.lambda);

// Broadening permissions for the User table using its ARN pattern to ensure correctness
// even if naming resolution in Gen2 is inconsistent.







backend.cancelStripeSubscription.addEnvironment('GRAPHQL_ENDPOINT', backend.data.graphqlUrl);
backend.data.resources.tables['User'].grantReadWriteData(backend.cancelStripeSubscription.resources.lambda);

// Explicitly grant DynamoDB permissions to cancelStripeSubscription via table ARN pattern
backend.cancelStripeSubscription.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: [
'dynamodb:GetItem',
'dynamodb:PutItem',
'dynamodb:UpdateItem',
'dynamodb:DeleteItem',
'dynamodb:Query',
'dynamodb:Scan',
'dynamodb:DescribeTable'
],
resources: [backend.data.resources.tables['User'].tableArn, userTableArnPattern],
})
);

// Keep Lambda Function URL for debug (use custom domain for stable public URL)
const myWebhookUrl = backend.myWebhook.resources.lambda.addFunctionUrl({
authType: FunctionUrlAuthType.NONE,
cors: {
allowedOrigins: ['*'],
allowedMethods: [LambdaUrlHttpMethod.ALL],
allowedHeaders: ['content-type', 'stripe-signature'],
},
});




/* ---------- API Gateway in front of myWebhook ---------- */
/**
* Expose POST "/" on the API and wire a custom domain:
*   sandbox -> https://sandbox.webhook.wherewillwevisit.com/
*   others  -> https://webhook.wherewillwevisit.com/
* Use this custom domain for a sticky URL; the execute-api URL may change.
  */
  const webhookStack = backend.createStack(`webhook${suffix}`);

const webhookIntegration = new LambdaIntegration(backend.myWebhook.resources.lambda);

const webhookApi = new RestApi(webhookStack, 'WebhookRestApi', {
defaultCorsPreflightOptions: {
allowOrigins: Cors.ALL_ORIGINS,
allowMethods: Cors.ALL_METHODS,
allowHeaders: ['content-type', 'stripe-signature'],
},
});

// Root resource for Stripe webhooks
webhookApi.root.addMethod('POST', webhookIntegration);

// Proxy all other paths to the same Lambda
webhookApi.root.addProxy({
defaultIntegration: webhookIntegration,
anyMethod: true,
});


// Certificates:
// - Wildcard for subdomains: *.webhook.wherewillwevisit.com
// - Apex for exact host:     webhook.wherewillwevisit.com
// - App hosting cert NZ:     whereinnz.wherewillwevisit.com, www.whereinnz.wherewillwevisit.com
// - App hosting cert UK:     whereinuk.wherewillwevisit.com, www.whereinuk.wherewillwevisit.com
const webhookCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/2456607a-39e6-40f3-83fc-3786ecd35b6a';
const apexCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/9f3b9869-6deb-449d-b24d-0421abb07a4d';
const appHostingNZCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/e4bbf207-67ab-4160-b2c7-3dd5730f4331';
const appHostingUKCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/274cb808-c82a-41f9-b941-75e8bb4a0db6';
const nzdevwebhookCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/86fe4dab-366f-4dd1-b7da-c40dc6475839';
const ukdevwebhookCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/86fe4dab-366f-4dd1-b7da-c40dc6475839';
const nzsandboxwebhookCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/3c924dc2-1637-4339-a767-22e7a6565524';
const uksandboxwebhookCertArn = 'arn:aws:acm:ap-southeast-2:445567075330:certificate/3c924dc2-1637-4339-a767-22e7a6565524';

/* ---------- Function Naming & Mapping (Diagnostics) ---------- */
// Function name mappings for easier identification
const functionMappings = {
locationSearch: backend.locationSearch.resources.lambda.functionName,
userManager: backend.userManager.resources.lambda.functionName,
//updateUserTable: backend.updateUserTable.resources.lambda.functionName,
geminiCalls: backend.geminiCalls.resources.lambda.functionName,
myWebhook: backend.myWebhook.resources.lambda.functionName,
// stripeSubscriptionCall: backend.stripeSubscriptionCall.resources.lambda.functionName,
cancelStripeSubscriptionCall: backend.cancelStripeSubscription.resources.lambda.functionName,
//transactionProcessor: backend.transactionProcessor.resources.lambda.functionName,
createProductPaymentIntent: backend.createProductPaymentIntent.resources.lambda.functionName,
qaPromptDelivery: backend.qaPromptDelivery.resources.lambda.functionName,
historyManager: backend.historyManager.resources.lambda.functionName,
supportManager: backend.supportManager.resources.lambda.functionName,
productDetails: backend.productDetails.resources.lambda.functionName

};

// Environment and resource mapping info
const resourceInfo = {
aws_branch: aws_branch,
aws_account_id: Aws.ACCOUNT_ID,
aws_region: Aws.REGION,
appsyncUrl: backend.data.graphqlUrl,
aws_appsync_api_id: backend.data.resources.graphqlApi.apiId,
bucketName: bucketName,
userTableName,
transactionHistoryTableName: backend.data.resources.tables['TransactionHistory'].tableName,
environment,
suffix,
functionNamingPattern: `amplify-{stackId}-{envAbbrev}-{resourceName}lambda{hash}-{randomId}`,
envAbbreviation: environment.substring(0, 2), // 'ma' for master, 'sa' for sandbox, etc.
};
const isProdEnvironment = false;
const isNZSandboxEnvironment = process.env.SANDBOX_ENV === 'NZ';
const isUKSandboxEnvironment = process.env.SANDBOX_ENV === 'UK';

// Always use subdomain pattern to leverage single wildcard cert
const webhookDomainName = isProdEnvironment? `prod.webhook.wherewillwevisit.com` :
( isNZSandboxEnvironment )? `nz.sandbox.webhook.wherewillwevisit.com` :
( isUKSandboxEnvironment )? `uk.sandbox.webhook.wherewillwevisit.com` :
(environment === 'whereinuk' || environment === 'uk') ? `uk.dev.webhook.wherewillwevisit.com` :
(environment === 'whereinnz' || environment === 'nz') ? `nz.dev.webhook.wherewillwevisit.com` :
`dev.webhook.wherewillwevisit.com`;
const webhookCert = Certificate.fromCertificateArn(
webhookStack,
'WebhookAcmCert',
(environment === 'whereinuk' || environment === 'whereinnz' ? nzdevwebhookCertArn :
isNZSandboxEnvironment ? nzsandboxwebhookCertArn :
isUKSandboxEnvironment ? uksandboxwebhookCertArn :
webhookCertArn)
);

/* ---------- Stripe Webhook URLs & Environment Variables ---------- */
// Stable URL to use publicly
const webhookUrl = `https://${webhookDomainName}/`;
const webhookSuccessUrl = `${webhookUrl}success`;
const webhookCancelUrl = `${webhookUrl}cancel`;
// Create custom domain - CloudFormation will handle idempotency
// If domain already exists in stack, it will be updated/retained
// If it doesn't exist, it will be created
const webhookCustomDomain = new RestDomainName(webhookStack, 'WebhookCustomDomain', {
domainName: webhookDomainName,
certificate: webhookCert,
endpointType: EndpointType.REGIONAL,
securityPolicy: SecurityPolicy.TLS_1_2,
});
// Map API root ("/") to the custom domain
// CloudFormation handles idempotency - won't recreate if mapping exists
new BasePathMapping(webhookStack, 'WebhookBasePathMapping', {
domainName: webhookCustomDomain,
restApi: webhookApi,
});


const route53CnameName = webhookDomainName;
const route53CnameValue = webhookCustomDomain.domainNameAliasDomainName;


backend.supportManager.addEnvironment(
'SUPPORT_EMAIL_ADDRESS',
'bondsfamil@bondsfamily.com'
);

backend.supportManager.addEnvironment(
'USER_TABLE_NAME',
backend.data.resources.tables['User'].tableName
);

backend.supportManager.addEnvironment(
'SUPPORT_SNS_TOPIC_ARN',
supportTopic.topicArn
);

backend.supportManager.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['sns:Publish'],
resources: [supportTopic.topicArn],
})
);

backend.supportManager.resources.lambda.addToRolePolicy(
new PolicyStatement({
actions: ['dynamodb:GetItem', 'dynamodb:Query', 'dynamodb:DescribeTable'],
resources: [backend.data.resources.tables['User'].tableArn],
})
);

try {
backend.addOutput({
custom: {
myWebhookUrl: myWebhookUrl.url ?? '',
webhookApiBaseUrl: webhookApi.url ?? '',
webhookCustomDomainRoot: webhookUrl ?? '',
route53CnameName: route53CnameName ?? '',
route53CnameValue: route53CnameValue ?? '',
appDomainName: (typeof APP_DOMAIN_NAME !== 'undefined') ? APP_DOMAIN_NAME : '',
appBasePath: (typeof APP_BASE_PATH !== 'undefined') ? APP_BASE_PATH : '/',
appFullUrl: `https://${(typeof APP_DOMAIN_NAME !== 'undefined') ? APP_DOMAIN_NAME : 'unknown'}${(typeof APP_BASE_PATH !== 'undefined') ? APP_BASE_PATH : '/'}/`,
environment: environment ?? 'unknown',
isProdEnvironment: process.env.isProdEnvironment === 'true',
envDerivation: {
namingSuffix: suffix ?? '',
selectedDomain: webhookDomainName ?? '',
selectedCertArn: (environment !== 'master') ? (typeof appHostingNZCertArn !== 'undefined' ? appHostingNZCertArn : '') : (typeof appHostingUKCertArn !== 'undefined' ? appHostingUKCertArn : ''),
},
eventBusName: backendEventBus.eventBusName ?? '',
functionMappings: (typeof functionMappings !== 'undefined') ? functionMappings : {},
resourceInfo: (typeof resourceInfo !== 'undefined') ? resourceInfo : {},
},
});
console.log('[BACKEND_SYNTHESIS] backend.addOutput completed successfully.');
} catch (outputError) {
console.error('[BACKEND_SYNTHESIS] ERROR during backend.addOutput:', outputError);
// Even if addOutput fails, we want to see the error in the logs
throw outputError;
}
