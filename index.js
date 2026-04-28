const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

if (!admin.apps.length) {
  admin.initializeApp();
}

const ADMIN_EMAIL = "abhimaniu041@gmail.com";

// ───────────────────────────────────────────────────────────────
// Helper: read global config (signupCredits, maxLimit, planPricing)
// Admin UI can edit `config/global` doc to change these live.
// ───────────────────────────────────────────────────────────────
async function readConfig() {
  const doc = await admin.firestore().collection("config").doc("global").get();
  const data = doc.exists ? doc.data() : {};
  return {
    signupCredits: data.signupCredits ?? 7,
    dailyReward: data.dailyReward ?? 2,
    maxLimit: data.maxLimit ?? 1000,
    appCost: data.appCost ?? 100,
    gameCost: data.gameCost ?? 70,
  };
}

function razorpayKeys() {
  const cfg = functions.config().razorpay || {};
  return {
    keyId: cfg.key_id || process.env.RAZORPAY_KEY_ID || null,
    keySecret: cfg.key_secret || process.env.RAZORPAY_KEY_SECRET || null,
  };
}

// ───────────────────────────────────────────────────────────────
// 1. createUserDoc — Auto-create user doc + assign admin role
// ───────────────────────────────────────────────────────────────
exports.createUserDoc = functions.auth.user().onCreate(async (user) => {
  const cfg = await readConfig();
  const isSetupAdmin = user.email === ADMIN_EMAIL;
  return admin.firestore().collection("users").doc(user.uid).set({
    uid: user.uid,
    email: user.email,
    credits: cfg.signupCredits,
    role: isSetupAdmin ? "admin" : "user",
    totalUsageCost: 0,
    totalRevenue: 0,
    isUsageBlocked: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
});

// ───────────────────────────────────────────────────────────────
// 2. processUsage — Deduct credits + enforce cap + write aiLogs
// ───────────────────────────────────────────────────────────────
exports.processUsage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
  }
  const cfg = await readConfig();
  const uid = context.auth.uid;
  const userRef = admin.firestore().collection("users").doc(uid);
  const doc = await userRef.get();
  const userData = doc.data() || {};

  if (userData.isUsageBlocked) {
    throw new functions.https.HttpsError("permission-denied", "Your account is blocked.");
  }
  if ((userData.totalUsageCost || 0) >= cfg.maxLimit) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "Limit reached. Need Admin Approval."
    );
  }

  const cost = Number(data.cost || 0);
  const credits = Number(data.credits || 0);
  const kind = data.kind || "app"; // 'app' | 'game'

  await userRef.update({
    totalUsageCost: admin.firestore.FieldValue.increment(cost),
    credits: admin.firestore.FieldValue.increment(-credits),
  });

  // Write AI log
  await admin.firestore().collection("aiLogs").add({
    userId: uid,
    email: userData.email || "",
    kind,
    creditsDeducted: credits,
    costRupees: cost,
    prompt: (data.prompt || "").toString().substring(0, 200),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ───────────────────────────────────────────────────────────────
// 3. adminManageUser — Admin: add credits / block users
// ───────────────────────────────────────────────────────────────
exports.adminManageUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }
  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Only Admins can perform this action.");
  }

  const { targetUid, addCredits, isBlocked } = data;
  if (!targetUid) {
    throw new functions.https.HttpsError("invalid-argument", "targetUid required.");
  }

  await admin.firestore().collection("users").doc(targetUid).update({
    credits: admin.firestore.FieldValue.increment(addCredits || 0),
    isUsageBlocked: !!isBlocked,
  });

  return { success: true, message: "User updated successfully." };
});

// ───────────────────────────────────────────────────────────────
// 4. adminUpdateConfig — Admin: edit global pricing/limits live
// ───────────────────────────────────────────────────────────────
exports.adminUpdateConfig = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "");
  const callerDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Admin only.");
  }

  const allowed = ["signupCredits", "dailyReward", "maxLimit", "appCost", "gameCost"];
  const payload = {};
  for (const k of allowed) {
    if (data[k] !== undefined && data[k] !== null) payload[k] = Number(data[k]);
  }
  if (Object.keys(payload).length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "Nothing to update.");
  }
  payload.updatedAt = admin.firestore.FieldValue.serverTimestamp();
  await admin.firestore().collection("config").doc("global").set(payload, { merge: true });
  return { success: true };
});

// ───────────────────────────────────────────────────────────────
// 5. claimDailyReward — configurable credits once per day
// ───────────────────────────────────────────────────────────────
exports.claimDailyReward = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
  const cfg = await readConfig();

  const uid = context.auth.uid;
  const userRef = admin.firestore().collection("users").doc(uid);

  return admin.firestore().runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    const userData = userDoc.data();
    const today = new Date().toISOString().split("T")[0];
    if (userData.lastClaimDate === today) {
      throw new functions.https.HttpsError("already-exists", "Reward already claimed today.");
    }
    transaction.update(userRef, {
      credits: admin.firestore.FieldValue.increment(cfg.dailyReward),
      lastClaimDate: today,
    });
    return { success: true, message: `${cfg.dailyReward} Credits added to your account!` };
  });
});

// ───────────────────────────────────────────────────────────────
// 6. notifyOnAdminReply — FCM push to USER when admin replies
// + unread counter increment
// ───────────────────────────────────────────────────────────────
exports.notifyOnAdminReply = functions.firestore
  .document("tickets/{ticketId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const msg = snap.data();
    if (!msg) return null;
    const ticketId = context.params.ticketId;
    const ticketRef = admin.firestore().collection("tickets").doc(ticketId);
    const ticketDoc = await ticketRef.get();
    if (!ticketDoc.exists) return null;
    const ticket = ticketDoc.data();

    // Increment unread counter for the opposite side
    if (msg.role === "admin") {
      await ticketRef.update({
        userUnread: admin.firestore.FieldValue.increment(1),
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else if (msg.role === "user" || msg.role === "assistant") {
      await ticketRef.update({
        adminUnread: admin.firestore.FieldValue.increment(1),
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Only admin messages trigger user push
    if (msg.role !== "admin") return null;

    const userDoc = await admin.firestore().collection("users").doc(ticket.userId).get();
    if (!userDoc.exists) return null;
    const tokens = userDoc.data().fcmTokens || [];
    if (!tokens.length) return null;

    const body = (msg.text || "").length > 140
      ? `${msg.text.substring(0, 140)}…`
      : (msg.text || "");

    try {
      const response = await admin.messaging().sendEachForMulticast({
        notification: { title: "Abhimaniu (Support) replied", body },
        data: { ticketId, type: "admin_reply", click_action: "FLUTTER_NOTIFICATION_CLICK" },
        android: { priority: "high", notification: { channelId: "triverse_support", color: "#B026FF" } },
        tokens,
      });
      const stale = [];
      response.responses.forEach((r, idx) => {
        if (!r.success) {
          const code = r.error && r.error.code;
          if (code === "messaging/invalid-registration-token" ||
              code === "messaging/registration-token-not-registered") {
            stale.push(tokens[idx]);
          }
        }
      });
      if (stale.length) {
        await admin.firestore().collection("users").doc(ticket.userId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...stale),
        });
      }
    } catch (e) {
      console.error("FCM admin->user error:", e);
    }
    return null;
  });

// ───────────────────────────────────────────────────────────────
// 7. notifyAdminOnNewTicket — Push to every admin on new ticket
// ───────────────────────────────────────────────────────────────
exports.notifyAdminOnNewTicket = functions.firestore
  .document("tickets/{ticketId}")
  .onCreate(async (snap, context) => {
    const ticket = snap.data();
    if (!ticket) return null;

    const adminsSnap = await admin.firestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const tokens = [];
    adminsSnap.forEach((d) => {
      const arr = d.data().fcmTokens || [];
      tokens.push(...arr);
    });
    if (!tokens.length) return null;

    const body = `From ${ticket.email || "user"}: ${(ticket.issue || "").substring(0, 120)}`;
    try {
      await admin.messaging().sendEachForMulticast({
        notification: { title: "🆕 New Support Ticket", body },
        data: { ticketId: context.params.ticketId, type: "new_ticket", click_action: "FLUTTER_NOTIFICATION_CLICK" },
        android: { priority: "high", notification: { channelId: "triverse_support", color: "#00C853" } },
        tokens,
      });
    } catch (e) {
      console.error("FCM admin->new ticket error:", e);
    }
    return null;
  });

// ───────────────────────────────────────────────────────────────
// 8. createRazorpayOrder — Start payment (MOCK mode if no keys)
// ───────────────────────────────────────────────────────────────
exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required.");
  const uid = context.auth.uid;
  const amountRupees = Number(data.amount || 0);           // rupees e.g. 500
  const creditsToAdd = Number(data.creditsToAdd || 0);     // credits e.g. 1000
  if (amountRupees <= 0 || creditsToAdd <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid amount/credits.");
  }

  const keys = razorpayKeys();
  const orderRef = admin.firestore().collection("orders").doc();

  // MOCK mode (no Razorpay keys configured) — grant credits immediately for dev/test
  if (!keys.keyId || !keys.keySecret) {
    await admin.firestore().collection("users").doc(uid).update({
      credits: admin.firestore.FieldValue.increment(creditsToAdd),
      totalRevenue: admin.firestore.FieldValue.increment(amountRupees),
    });
    await orderRef.set({
      userId: uid,
      amountRupees,
      creditsToAdd,
      status: "mock_success",
      mode: "mock",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { mock: true, orderId: orderRef.id, message: "Mock mode: credits granted directly." };
  }

  // REAL mode
  const Razorpay = require("razorpay");
  const rzp = new Razorpay({ key_id: keys.keyId, key_secret: keys.keySecret });
  const receiptShort = `rcpt_${orderRef.id.substring(0, 30)}`;
  const rzpOrder = await rzp.orders.create({
    amount: Math.round(amountRupees * 100), // paise
    currency: "INR",
    receipt: receiptShort,
    notes: { userId: uid, creditsToAdd: String(creditsToAdd) },
  });

  await orderRef.set({
    userId: uid,
    amountRupees,
    creditsToAdd,
    status: "created",
    mode: "live",
    razorpayOrderId: rzpOrder.id,
    receipt: receiptShort,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    mock: false,
    orderId: orderRef.id,
    razorpayOrderId: rzpOrder.id,
    keyId: keys.keyId,
    amountPaise: rzpOrder.amount,
    currency: "INR",
  };
});

// ───────────────────────────────────────────────────────────────
// 9. verifyRazorpayPayment — Verify signature + grant credits
// ───────────────────────────────────────────────────────────────
exports.verifyRazorpayPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required.");
  const keys = razorpayKeys();
  if (!keys.keySecret) {
    throw new functions.https.HttpsError("failed-precondition", "Razorpay not configured.");
  }
  const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = data;
  if (!orderId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
    throw new functions.https.HttpsError("invalid-argument", "Missing payment params.");
  }

  const expected = crypto
    .createHmac("sha256", keys.keySecret)
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest("hex");
  if (expected !== razorpaySignature) {
    throw new functions.https.HttpsError("permission-denied", "Invalid payment signature.");
  }

  const orderRef = admin.firestore().collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) throw new functions.https.HttpsError("not-found", "Order not found.");
  const order = orderSnap.data();
  if (order.userId !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "Order mismatch.");
  }
  if (order.status === "paid") {
    return { success: true, alreadyPaid: true };
  }

  await admin.firestore().collection("users").doc(order.userId).update({
    credits: admin.firestore.FieldValue.increment(order.creditsToAdd),
    totalRevenue: admin.firestore.FieldValue.increment(order.amountRupees),
  });
  await orderRef.update({
    status: "paid",
    razorpayPaymentId,
    paidAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, creditsAdded: order.creditsToAdd };
});
