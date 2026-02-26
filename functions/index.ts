import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

interface ExpenseData {
  amount: number;
  categoryId: string;
  month: string;
}

export const onExpenseWrite = functions.firestore
  .document("users/{userId}/expenses/{expenseId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId as string;

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
  });

