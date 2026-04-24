import * as admin from "firebase-admin";

admin.initializeApp();

export { onExpenseWrite } from "./expenseTriggers";
export {
  plaidCreateLinkToken,
  plaidExchangePublicToken,
  plaidSyncTransactions,
  plaidWebhook,
} from "./plaidEndpoints";
