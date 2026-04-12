import { type ClientSchema, a, defineData } from "@aws-amplify/backend";

const schema = a.schema({
  // ── Enums ─────────────────────────────────────────────────────────────────
  JobStatus: a.enum(["Enquiry", "Quoted", "Contracted"]),
  QuoteStatus: a.enum(["Draft", "Submitted", "Accepted", "Rejected"]),

  // ── Job ───────────────────────────────────────────────────────────────────
  Job: a
    .model({
      jobName: a.string().required(),
      client: a.string().required(),
      location: a.string(),
      description: a.string(),
      status: a.ref("JobStatus").required(),
      contractValue: a.float().default(0),
      quotes: a.hasMany("Quote", "jobId"),
    })
    .secondaryIndexes((index) => [index("status")])
    .authorization((allow) => [
      allow.owner(),
      allow.groups(["main-contractor", "qs"]).to(["read"]),
    ]),

  // ── Quote ─────────────────────────────────────────────────────────────────
  Quote: a
    .model({
      jobId: a.id().required(),
      job: a.belongsTo("Job", "jobId"),
      title: a.string().required(),
      status: a.ref("QuoteStatus").required(),
      subtotal: a.float().default(0),
      gstRate: a.float().default(0.15),
      totalIncGst: a.float().default(0),
      exclusions: a.string(),
      notes: a.string(),
      validityDays: a.integer().default(30),
      submittedAt: a.datetime(),
      acceptedAt: a.datetime(),
      lineItems: a.hasMany("QuoteLineItem", "quoteId"),
    })
    .secondaryIndexes((index) => [index("status")])
    .authorization((allow) => [
      allow.owner(),
      allow.groups(["main-contractor"]).to(["read", "update"]),
      allow.groups(["qs"]).to(["read"]),
    ]),

  // ── QuoteLineItem ─────────────────────────────────────────────────────────
  QuoteLineItem: a
    .model({
      quoteId: a.id().required(),
      quote: a.belongsTo("Quote", "quoteId"),
      description: a.string().required(),
      unit: a.string().default("m2"),
      quantity: a.float().required(),
      rate: a.float().required(),
      total: a.float().required(),
    })
    .authorization((allow) => [
      allow.owner(),
      allow.groups(["main-contractor", "qs"]).to(["read"]),
    ]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: "userPool",
  },
});
