import * as admin from "firebase-admin";
import { error as logError, info as logInfo } from "firebase-functions/logger";
import { defineSecret, defineString } from "firebase-functions/params";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import {
  Configuration,
  CountryCode,
  PlaidApi,
  PlaidEnvironments,
  Products,
} from "plaid";

const db = admin.firestore();

/** Set via `functions/.env` (see `.env.example`) or deploy-time params. */
const plaidClientId = defineString("PLAID_CLIENT_ID", { default: "" });

/** Create with: `firebase functions:secrets:set PLAID_SECRET_SANDBOX` */
const plaidSecretSandbox = defineSecret("PLAID_SECRET_SANDBOX");

/** Create with: `firebase functions:secrets:set PLAID_SECRET_PRODUCTION` */
const plaidSecretProduction = defineSecret("PLAID_SECRET_PRODUCTION");

const plaidSecrets = [plaidSecretSandbox, plaidSecretProduction];

type PlaidEnv = "sandbox" | "production";

function getPlaidClient(env: PlaidEnv): PlaidApi {
  const clientId = plaidClientId.value().trim();
  const secret =
    (env === "production" ? plaidSecretProduction.value() : plaidSecretSandbox.value()).trim();

  if (!clientId || !secret) {
    throw new HttpsError(
      "failed-precondition",
      "Plaid is not configured. Set PLAID_CLIENT_ID (e.g. in functions/.env) and create secrets " +
        "PLAID_SECRET_SANDBOX / PLAID_SECRET_PRODUCTION with `firebase functions:secrets:set`."
    );
  }

  const basePath =
    env === "production" ? PlaidEnvironments.production : PlaidEnvironments.sandbox;

  const configuration = new Configuration({
    basePath,
    baseOptions: {
      headers: {
        "PLAID-CLIENT-ID": clientId,
        "PLAID-SECRET": secret,
      },
    },
  });

  return new PlaidApi(configuration);
}

function parseEnv(data: unknown): PlaidEnv {
  return data === "production" ? "production" : "sandbox";
}

/** Firestore doc id for an expense imported from Plaid (stable across syncs). */
function expenseDocIdForPlaidTransaction(transactionId: string): string {
  const safe = transactionId.replace(/[/]/g, "_");
  return `plaid_txn_${safe}`;
}

/** Best-effort map into Allocent TransactionCategory raw values. */
function mapCategoryLabel(detailed?: string | null, primary?: string | null): string {
  const blob = `${detailed ?? ""} ${primary ?? ""}`.toLowerCase();
  if (blob.includes("food") || blob.includes("restaurant") || blob.includes("coffee")) {
    return "Food & Drink";
  }
  if (blob.includes("grocer")) {
    return "Groceries";
  }
  if (blob.includes("transport") || blob.includes("gas") || blob.includes("uber") || blob.includes("lyft")) {
    return "Transport";
  }
  if (blob.includes("shop") || blob.includes("retail") || blob.includes("merchandise")) {
    return "Shopping";
  }
  if (blob.includes("entertain") || blob.includes("movie") || blob.includes("music")) {
    return "Entertainment";
  }
  if (blob.includes("health") || blob.includes("medical") || blob.includes("pharmacy")) {
    return "Health";
  }
  if (blob.includes("utilit") || blob.includes("internet") || blob.includes("electric")) {
    return "Utilities";
  }
  return "Other";
}

function monthKeyFromDate(d: Date): string {
  const y = d.getFullYear();
  const m = `${d.getMonth() + 1}`.padStart(2, "0");
  return `${y}-${m}`;
}

interface PlaidConnectionDoc {
  userId: string;
  accessToken: string;
  transactionsCursor: string | null;
  environment: PlaidEnv;
  institutionName?: string;
  itemId: string;
}

export const plaidCreateLinkToken = onCall(
  { region: "us-central1", cors: true, invoker: "public", secrets: plaidSecrets },
  async (request) => {
    if (!request.auth?.uid) {
      const authHeader = request.rawRequest.headers.authorization;
      const appCheckHeader = request.rawRequest.headers["x-firebase-appcheck"];
      logInfo("plaidCreateLinkToken unauthenticated", {
        hasAuth: Boolean(request.auth?.uid),
        hasAuthorizationHeader: Boolean(authHeader),
        authHeaderPrefix: typeof authHeader === "string" ? authHeader.split(" ")[0] : null,
        hasAppCheckHeader: Boolean(appCheckHeader),
        contentType: request.rawRequest.headers["content-type"] ?? null,
        userAgent: request.rawRequest.headers["user-agent"] ?? null,
      });
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const env = parseEnv(request.data?.environment);
    const client = getPlaidClient(env);
    const resp = await client.linkTokenCreate({
      user: { client_user_id: request.auth.uid },
      client_name: "Allocent",
      products: [Products.Transactions],
      country_codes: [CountryCode.Us],
      language: "en",
    });

    const linkToken = resp.data.link_token;
    if (!linkToken) {
      throw new HttpsError("internal", "Plaid did not return a link token.");
    }
    return { linkToken, environment: env };
  }
);

export const plaidExchangePublicToken = onCall(
  { region: "us-central1", cors: true, invoker: "public", secrets: plaidSecrets },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const publicToken = request.data?.publicToken as string | undefined;
    if (!publicToken?.trim()) {
      throw new HttpsError("invalid-argument", "publicToken is required.");
    }
    const env = parseEnv(request.data?.environment);
    const client = getPlaidClient(env);

    const exchange = await client.itemPublicTokenExchange({
      public_token: publicToken.trim(),
    });

    const accessToken = exchange.data.access_token;
    const itemId = exchange.data.item_id;
    if (!accessToken || !itemId) {
      throw new HttpsError("internal", "Plaid exchange failed.");
    }

    let institutionName: string | undefined;
    try {
      const itemResp = await client.itemGet({ access_token: accessToken });
      const instId = itemResp.data.item.institution_id;
      if (instId) {
        const inst = await client.institutionsGetById({
          institution_id: instId,
          country_codes: [CountryCode.Us],
        });
        institutionName = inst.data.institution.name;
      }
    } catch {
      // optional metadata
    }

    const conn: PlaidConnectionDoc = {
      userId: request.auth.uid,
      accessToken,
      transactionsCursor: null,
      environment: env,
      institutionName,
      itemId,
    };

    await db.collection("plaidConnections").doc(itemId).set(
      {
        ...conn,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { itemId, institutionName };
  }
);

async function syncSingleItem(itemId: string, uid: string): Promise<{ added: number; modified: number; removed: number }> {
  const ref = db.collection("plaidConnections").doc(itemId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Linked item not found.");
  }
  const data = snap.data() as PlaidConnectionDoc;
  if (data.userId !== uid) {
    throw new HttpsError("permission-denied", "This link belongs to another user.");
  }

  const client = getPlaidClient(data.environment);
  let cursor = data.transactionsCursor ?? undefined;
  let added = 0;
  let modified = 0;
  let removed = 0;

  for (;;) {
    const resp = await client.transactionsSync({
      access_token: data.accessToken,
      cursor: cursor ?? undefined,
      count: 500,
    });

    const next = resp.data;
    cursor = next.next_cursor;

    let batch = db.batch();
    const expenses = db.collection("users").doc(uid).collection("expenses");
    let batchOps = 0;

    const flushBatch = async () => {
      if (batchOps === 0) return;
      await batch.commit();
      batch = db.batch();
      batchOps = 0;
    };

    for (const t of next.added) {
      const tid = t.transaction_id;
      if (!tid) continue;
      const docId = expenseDocIdForPlaidTransaction(tid);
      const d = t.date ? new Date(t.date) : new Date();
      const categoryLabel = mapCategoryLabel(
        t.personal_finance_category?.detailed,
        t.personal_finance_category?.primary
      );
      batch.set(
        expenses.doc(docId),
        {
          amount: typeof t.amount === "number" ? t.amount : Number(t.amount),
          categoryId: "",
          date: admin.firestore.Timestamp.fromDate(d),
          month: monthKeyFromDate(d),
          merchant: (t.merchant_name || t.name || "Unknown").trim(),
          category: categoryLabel,
          source: "plaid",
          plaidTransactionId: tid,
          plaidItemId: itemId,
          pending: t.pending ?? false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      batchOps += 1;
      added += 1;
      if (batchOps >= 450) {
        await flushBatch();
      }
    }

    for (const t of next.modified) {
      const tid = t.transaction_id;
      if (!tid) continue;
      const docId = expenseDocIdForPlaidTransaction(tid);
      const d = t.date ? new Date(t.date) : new Date();
      const categoryLabel = mapCategoryLabel(
        t.personal_finance_category?.detailed,
        t.personal_finance_category?.primary
      );
      batch.set(
        expenses.doc(docId),
        {
          amount: typeof t.amount === "number" ? t.amount : Number(t.amount),
          categoryId: "",
          date: admin.firestore.Timestamp.fromDate(d),
          month: monthKeyFromDate(d),
          merchant: (t.merchant_name || t.name || "Unknown").trim(),
          category: categoryLabel,
          source: "plaid",
          plaidTransactionId: tid,
          plaidItemId: itemId,
          pending: t.pending ?? false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      batchOps += 1;
      modified += 1;
      if (batchOps >= 450) {
        await flushBatch();
      }
    }

    for (const t of next.removed) {
      const tid = t.transaction_id;
      if (!tid) continue;
      const docId = expenseDocIdForPlaidTransaction(tid);
      batch.delete(expenses.doc(docId));
      batchOps += 1;
      removed += 1;
      if (batchOps >= 450) {
        await flushBatch();
      }
    }

    await flushBatch();

    await ref.set(
      { transactionsCursor: cursor ?? null, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );

    if (!next.has_more) break;
  }

  return { added, modified, removed };
}

export const plaidSyncTransactions = onCall(
  { region: "us-central1", cors: true, invoker: "public", secrets: plaidSecrets },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    const itemIdArg = request.data?.itemId as string | undefined;

    if (itemIdArg?.trim()) {
      const r = await syncSingleItem(itemIdArg.trim(), uid);
      return { items: 1, ...r };
    }

    const qs = await db.collection("plaidConnections").where("userId", "==", uid).get();
    if (qs.empty) {
      return { items: 0, added: 0, modified: 0, removed: 0 };
    }

    let added = 0;
    let modified = 0;
    let removed = 0;
    for (const doc of qs.docs) {
      const r = await syncSingleItem(doc.id, uid);
      added += r.added;
      modified += r.modified;
      removed += r.removed;
    }
    return { items: qs.size, added, modified, removed };
  }
);

/**
 * Plaid webhooks (e.g. SYNC_UPDATES_AVAILABLE). Configure the URL in the Plaid Dashboard.
 * For production, add webhook signature verification (Plaid docs: Webhook verification).
 */
export const plaidWebhook = onRequest(
  { region: "us-central1", cors: false, invoker: "public", secrets: plaidSecrets },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    let body: {
      webhook_type?: string;
      webhook_code?: string;
      item_id?: string;
    };
    try {
      body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    } catch {
      res.status(400).send("Invalid JSON");
      return;
    }

    const itemId = body.item_id;
    if (!itemId) {
      res.status(200).send("ok");
      return;
    }

    const snap = await db.collection("plaidConnections").doc(itemId).get();
    if (!snap.exists) {
      res.status(200).send("ok");
      return;
    }
    const uid = (snap.data() as PlaidConnectionDoc).userId;

    if (
      body.webhook_type === "TRANSACTIONS" &&
      (body.webhook_code === "SYNC_UPDATES_AVAILABLE" || body.webhook_code === "DEFAULT_UPDATE")
    ) {
      try {
        await syncSingleItem(itemId, uid);
      } catch (e) {
        logError("plaidWebhook sync failed", { itemId, err: String(e) });
      }
    }

    res.status(200).send("ok");
  }
);
