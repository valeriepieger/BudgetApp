import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

const db = admin.firestore();

interface ExpenseData {
  amount: number;
  categoryId: string;
  month: string;
}

/** 2nd gen Firestore trigger (avoids 1st gen Cloud Build permission issues on new projects). */
export const onExpenseWrite = onDocumentWritten(
  {
    document: "users/{userId}/expenses/{expenseId}",
    region: "us-central1",
  },
  async (event) => {
    const change = event.data;
    if (!change) {
      return;
    }

    const userId = event.params.userId as string;

    const after = change.after.exists ? (change.after.data() as ExpenseData) : null;
    const before = change.before.exists ? (change.before.data() as ExpenseData) : null;

    const affected = after ?? before;
    if (!affected) {
      return;
    }

    const { categoryId, month } = affected;

    const expensesRef = db
      .collection("users")
      .doc(userId)
      .collection("expenses")
      .where("categoryId", "==", categoryId)
      .where("month", "==", month);

    const snapshot = await expensesRef.get();

    let totalSpent = 0;
    snapshot.forEach((doc) => {
      const data = doc.data() as ExpenseData;
      totalSpent += data.amount || 0;
    });

    const summaryRef = db
      .collection("users")
      .doc(userId)
      .collection("categorySummaries")
      .doc(`${month}_${categoryId}`);

    await summaryRef.set(
      {
        categoryId,
        month,
        spent: totalSpent,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
);
