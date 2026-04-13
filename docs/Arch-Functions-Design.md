Each function should be designed to be used in a specific way.
In data/resource.ts calls will look similar to this example,
In the ModelSchema calls will look similar to this example.
export const schema = a.schema({

callUserManagerAPI: a
.query()
.arguments({
input: a.ref("UserManagerArgs")
})
.returns(a.string())
.authorization(allow => [allow.authenticated("identityPool"), allow.authenticated("userPools"), allow.guest()])
.handler(a.handler.function(userManager)),

and tables would look like this,

User: a
.model({
id: a.id(),
subscriptionId: a.string(),
createdAt: a.datetime().required(),
updatedAt: a.datetime(),
accountState: a.enum(accountStateEnum),
email: a.email().required(),
freeRecs: a.integer().required(),
lastBuy: a.float(),
totalBuy: a.float().required(),
subRecs: a.integer().required(),
subscriptionStartDate: a.date(),
subscriptionNextDate: a.date(),
subscriptionEndingDate: a.date(),
subscriptionExpiryDate: a.date(),
topupRecs: a.integer().required(),
topupActive: a.boolean(),
topupStartDate: a.date(),
topupExpiryDate: a.date(),
destinationCountry: a.string(),
variation: a.string(),
destinationCountryVariationIndex: a.integer(),
geoLocation: a.string(),
billingCurrency: a.string(),
dummyFix: a.string(),
})
.authorization((allow) => [allow.authenticated("identityPool"),
allow.authenticated("userPools"), allow.guest()]),

Then exported like this

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
schema,
authorizationModes: {
defaultAuthorizationMode: "identityPool",
apiKeyAuthorizationMode: {
expiresInDays: 30
},
},
});

Each function will have a resource.ts and a handler.ts file in its definition, e.g.
resource.ts
import { defineFunction, secret } from '@aws-amplify/backend';

export const geminiCalls = defineFunction({
name: 'geminiCalls',
entry: './handler.ts',
resourceGroupName: 'data',
timeoutSeconds: 40,
memoryMB: 1024,
runtime: 20,
environment: {
GEMINI_API_KEY: secret('GEMINI_API_KEY'),
// These will be overridden by backend.ts but good to keep as reference or for local sandbox
//WHEREIN_BUCKET_NAME: 'amplify-d13bqu5p13015a-ma-wherein0007bucketbucketb-shtbwrliipml',
STORAGE_BUCKET_NAME: 'wherein0007bucket',
PICKER_MAPPING_KEY: 'picker_mapping.json',
BUCKET_REGION: 'us-east-1',
ACCOUNT_ID: '445567075330',
USE_CACHE: 'false',
},
});

and handler.ts, just an example, but the signature is what matters

import https from 'https';
import { createBaseHandler } from "../../resources/util/BaseHandler.js";
import { unwrapPayloadUsingInputRef } from "../../resources/common/payload_interfaces.js";
import { GeminiCallArgs } from "../../data/clean_models.js";
import { getRequiredEnvVar } from "../../resources/util/env_utils.js";
import TransactionHistoryTable from "../../data/table_utils/transactionHistoryTable.js";
import {EventBridgeClient} from "@aws-sdk/client-eventbridge";
import {EventBridgeEventUtils} from "../../data/table_utils/event_bridge_event_utils.js";
import {TransactionHistoryArgs, EventAction} from "../../data/clean_models.js";
import { S3Client, PutObjectCommand, ListObjectsV2Command, GetObjectCommand } from "@aws-sdk/client-s3";

export const handler = createBaseHandler(async (event: any) => {

console.log("GEMINI_HANDLER: Received event: ", JSON.stringify(event, null, 2));

const args: GeminiCallArgs = unwrapPayloadUsingInputRef<GeminiCallArgs>(event);
const userId = args.userId;
const apiFunction = args.apiFunction || 'promptGeneration'; // promptGeneration(default), getAdviceList, getAdviceById
const adviceId = args.adviceId;
const apiKey = getRequiredEnvVar("GEMINI_API_KEY");

const bucketName = process.env.STORAGE_BUCKET_NAME || process.env.WHEREIN_BUCKET_NAME;
const bucketRegion = process.env.BUCKET_REGION || 'ap-southeast-2';
try {
const s3Client = new S3Client({ region: bucketRegion });

    if (apiFunction === 'getAdviceList') {
      if (!bucketName) {
        throw new Error("STORAGE_BUCKET_NAME not defined");
      }
      console.log(`GEMINI_HANDLER: Listing advice for user: ${userId}`);
      const prefix = `results_store/${userId}/`;
      const listCommand = new ListObjectsV2Command({
        Bucket: bucketName,
        Prefix: prefix,
      });
      const listResponse = await s3Client.send(listCommand);
      const files = listResponse.Contents?.map(obj => obj.Key?.replace(prefix, ''))
          .filter((key): key is string => !!key) || [];

      const responseBody = JSON.stringify(files);
      if (event.body) {
        return {
          statusCode: 200,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "POST"
          },
          body: responseBody,
        };
      }
      return responseBody;
    }

    if (apiFunction === 'getAdviceById') {
      if (!bucketName) {
        throw new Error("STORAGE_BUCKET_NAME not defined");
      }
      if (!adviceId) {
        throw new Error("adviceId is required for getAdviceById");
      }
      console.log(`GEMINI_HANDLER: Getting advice ${adviceId} for user: ${userId}`);
      const key = `results_store/${userId}/${adviceId}`;
      const getCommand = new GetObjectCommand({
        Bucket: bucketName,
        Key: key,
      });
      const getResponse = await s3Client.send(getCommand);
      const bodyContents = await getResponse.Body?.transformToString();
      // bodyContents is already JSON-encoded string if it was stored as JSON.stringify(advice)
      // which it is in promptGeneration.

      if (event.body) {
        return {
          statusCode: 200,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "POST"
          },
          body: bodyContents || "",
        };
      }
      return bodyContents || "";
    }

    // Default: promptGeneration
    // Call Gemini API using Node.js https module
    const requestBody = JSON.stringify({
      contents: [{
        parts: [{
          text: args.prompt
        }]
      }],
      generationConfig: {
        temperature: 0.4
      }
    });

    type GeminiSuccess = {
      candidates: Array<{
        content: {
          parts: Array<{ text?: string }>;
        };
        finishReason?: string;
      }>;
      usageMetadata?: Record<string, unknown>;
    };

    type GeminiError = {
      error: {
        code: number;
        status: string;
        message: string;
        details?: unknown[];
      };
    };

    type GeminiResponse = GeminiSuccess | GeminiError;

    function parseGeminiStrict(data: GeminiResponse) {
      // Error envelope
      if ("error" in data) {
        return {
          ok: false as const,
          error: {
            code: data.error.code,
            status: data.error.status,
            message: data.error.message,
            details: data.error.details ?? null
          }
        };
      }

      // Success envelope
      const candidate = data.candidates?.[0];
      const part = candidate?.content?.parts?.[0];
      const text = part?.text ?? null;

      return {
        ok: true as const,
        text,
        raw: data
      };
    }


    const response = await makeHttpsRequest(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(requestBody)
        }
      },
      requestBody
    );
    const eventBusName = process.env.EVENT_BUS_NAME || "default";
    const ebClient = new EventBridgeClient({});
    const eventBridgeEventUtils = new EventBridgeEventUtils(ebClient, eventBusName);
    const data = JSON.parse(response);
    const result = parseGeminiStrict(data);
    const transactionHistoryArgs: TransactionHistoryArgs = {
      userId,
      actionEvent: 'used_recommendation' as EventAction,
      amount: 0,
      description: 'Generated advice for a Visit location',
      apiFunction: 'createTransactionHistory', // required!
      createdAt: new Date().toISOString(),
    };

    if (!result.ok) {
      console.error("Gemini error:", result.error);
      transactionHistoryArgs.description = "AI error happened, we are looking into it";
      await eventBridgeEventUtils.addHistoryEventBusEvent(
          transactionHistoryArgs);
    } else {
      console.log("Gemini output:", result.text);
      await eventBridgeEventUtils.addHistoryEventBusEvent(
          transactionHistoryArgs);
      // TODO need to send an event to the userManager via event bridge RECOMMENDATION_USED
      await eventBridgeEventUtils.addUserManagerEventBusEvent({
        userId,
        actionEvent: 'used_recommendation' as EventAction, //these fields do not matter
        amount: 0, //these fields do not matter
        description: 'AI advice generated', //these fields do not matter
        apiFunction: 'consumeARequest'
      });
    }

    const advice = data.candidates?.[0]?.content?.parts?.[0]?.text || 'ERROR';


    console.log(`GEMINI_HANDLER: Generated advice for prompt`);
    const stringifyAdvice = JSON.stringify(advice);
    
    // Store advice in S3 bucket
    if (bucketName) {
      try {
        console.log(`GEMINI_HANDLER: Storing advice in S3 bucket: ${bucketName} (region: ${bucketRegion})`);
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const key = `results_store/${userId}/advice_${timestamp}.json`;
        
        await s3Client.send(new PutObjectCommand({
          Bucket: bucketName,
          Key: key,
          Body: stringifyAdvice,
          ContentType: 'application/json'
        }));
        console.log(`GEMINI_HANDLER: Stored advice in S3: ${key}`);
      } catch (s3Error) {
        console.error("GEMINI_HANDLER: Failed to store advice in S3:", s3Error);
      }
    } else {
      console.warn("GEMINI_HANDLER: No bucket name defined (STORAGE_BUCKET_NAME or WHEREIN_BUCKET_NAME), skipping S3 storage");
    }

    // Return format depends on how the function was invoked
    if (event.body) {
      // REST API response
      return {
        statusCode: 200,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "Content-Type",
          "Access-Control-Allow-Methods": "POST"
        },
        body: stringifyAdvice,
      };
    } else {
      // Direct/GraphQL invocation response
      return advice;
    }

} catch (unknownError) {
const error = unknownError instanceof Error ? unknownError : new Error(String(unknownError));
console.error("GEMINI_HANDLER: Error occurred in Lambda Handler:", error);

    try {
      const eventBusName = process.env.EVENT_BUS_NAME || "default";
      const ebClient = new EventBridgeClient({});
      const eventBridgeEventUtils = new EventBridgeEventUtils(ebClient, eventBusName);
      const transactionHistoryArgs: TransactionHistoryArgs = {
        userId,
        actionEvent: 'recommandation_usage_failed_gemini' as EventAction,
        amount: 0,
        description: 'Generated advice failed to generate',
        apiFunction: 'createTransactionHistory', // required!
        createdAt: new Date().toISOString(),
      };
      await eventBridgeEventUtils.addHistoryEventBusEvent(
          transactionHistoryArgs);
    } catch (ebError) {
      console.error("GEMINI_HANDLER: Failed to send error event to EventBridge:", ebError);
    }

    if (event.body) {
      // REST API error response
      return {
        statusCode: 500,
        body: JSON.stringify({
          error: "GEMINI_HANDLER: Failed to generate advice. Please check your input or configuration.",
          message: error.message,
        }),
      };
    } else {
      // Direct/GraphQL error response
      throw error;
    }
}
});

// Helper function to make HTTPS requests
function makeHttpsRequest(url: string, options: any, body?: string): Promise<string> {
return new Promise((resolve, reject) => {
const req = https.request(url, options, (res) => {
let data = '';
res.on('data', (chunk) => {
data += chunk;
});
res.on('end', () => {
if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
resolve(data);
} else {
reject(new Error(`HTTP ${res.statusCode}: ${data}`));
}
});
});

    req.on('error', (error) => {
      reject(error);
    });

    if (body) {
      req.write(body);
    }
    req.end();
});
}

BaseHandler is a wrapper around the handler function that handles common error handling and logging.
// Cold start log: runs once per execution environment before any handlerOld invocation.
// This code executes when the module is imported/loaded.
const _moduleLoadedAt = new Date().toISOString();
console.log(`[${process.env.AWS_LAMBDA_FUNCTION_NAME || 'UNKNOWN'}] Lambda module loaded (cold start).`, {
time: _moduleLoadedAt,
functionName: process.env.AWS_LAMBDA_FUNCTION_NAME || null,
awsRegion: process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || null,
});

export function createBaseHandler<T>(handlerFunc: T): T {
new BaseHandler();
const _moduleLoadedAt = new Date().toISOString();
console.log(`[${process.env.AWS_LAMBDA_FUNCTION_NAME || 'UNKNOWN'}] Lambda module loaded (cold start).`, {
time: _moduleLoadedAt,
functionName: process.env.AWS_LAMBDA_FUNCTION_NAME || null,
awsRegion: process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || null,
});
return handlerFunc;
}

/**
* Base class for Lambda handlers.
* Extending this class ensures the cold start logging above runs when the module is loaded.
  */
  export class BaseHandler {
  constructor() {
  // Cold start log: runs once per execution environment when the class is instantiated for the first time
  // and because we instantiate it at the top level of each handlerOld file.
  }
  }
