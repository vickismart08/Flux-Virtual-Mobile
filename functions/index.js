const functions = require("firebase-functions");
const admin = require("firebase-admin");
const twilio = require("twilio");
const Paystack = require("paystack-node");

admin.initializeApp();

// ── Keys ─────────────────────────────────────────────────────
const TWILIO_ACCOUNT_SID = "AC566dd7b7e6f28dac3f95ee2603ecbf87";
const TWILIO_AUTH_TOKEN = "adde5c104ada988b1cbef3ee650285d4";
const PAYSTACK_SECRET_KEY = "sk_test_c9f718664c42136947d1ea926731edc403972c16"; // your test secret key

const twilioClient = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
const paystack = new Paystack(PAYSTACK_SECRET_KEY);

// ── 1. Initialize Paystack payment ───────────────────────────
exports.initializePayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const { amount, email } = data; // amount in kobo (₦100 = 10000 kobo)

  try {
    const response = await paystack.transaction.initialize({
      email: email,
      amount: amount,
      metadata: {
        userId: context.auth.uid,
      },
    });

    return {
      authorizationUrl: response.body.data.authorization_url,
      reference: response.body.data.reference,
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ── 2. Verify Paystack payment & add credit ──────────────────
exports.verifyPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const { reference } = data;

  try {
    const response = await paystack.transaction.verify({ reference });
    const transaction = response.body.data;

    if (transaction.status === "success") {
      const amountInNaira = transaction.amount / 100;

      // add credit to user balance in Firestore
      const userRef = admin
        .firestore()
        .collection("users")
        .doc(context.auth.uid);

      await userRef.update({
        creditBalance: admin.firestore.FieldValue.increment(amountInNaira),
      });

      // save transaction record
      await userRef.collection("transactions").add({
        reference: reference,
        amount: amountInNaira,
        status: "success",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, amount: amountInNaira };
    } else {
      throw new functions.https.HttpsError("aborted", "Payment not successful");
    }
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ── 3. Search available Twilio numbers ───────────────────────
exports.searchNumbers = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const { countryCode } = data; // e.g "US", "GB", "NG"

  try {
    const numbers = await twilioClient
      .availablePhoneNumbers(countryCode)
      .local.list({ limit: 10 });

    return numbers.map((n) => ({
      phoneNumber: n.phoneNumber,
      friendlyName: n.friendlyName,
      region: n.region,
      isoCountry: n.isoCountry,
    }));
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ── 4. Purchase a Twilio number ──────────────────────────────
exports.purchaseNumber = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const { phoneNumber } = data;
  const MONTHLY_RATE = 2.99; // what you charge user per month

  try {
    // check user credit balance
    const userRef = admin
      .firestore()
      .collection("users")
      .doc(context.auth.uid);
    const userDoc = await userRef.get();
    const balance = userDoc.data().creditBalance;

    if (balance < MONTHLY_RATE) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Insufficient credit balance"
      );
    }

    // purchase number from Twilio
    const number = await twilioClient.incomingPhoneNumbers.create({
      phoneNumber: phoneNumber,
    });

    // deduct credit from user
    await userRef.update({
      creditBalance: admin.firestore.FieldValue.increment(-MONTHLY_RATE),
    });

    // save number to user's account
    await userRef.collection("numbers").add({
      sid: number.sid,
      phoneNumber: number.phoneNumber,
      friendlyName: number.friendlyName,
      monthlyRate: MONTHLY_RATE,
      purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      active: true,
    });

    return { success: true, phoneNumber: number.phoneNumber };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ── 5. Make a call ───────────────────────────────────────────
exports.makeCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const { to, from } = data;
  const COST_PER_MINUTE = 0.05; // what you charge user per minute

  try {
    // check user credit
    const userRef = admin
      .firestore()
      .collection("users")
      .doc(context.auth.uid);
    const userDoc = await userRef.get();
    const balance = userDoc.data().creditBalance;

    if (balance < COST_PER_MINUTE) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Insufficient credit balance"
      );
    }

    // initiate call via Twilio
    const call = await twilioClient.calls.create({
      to: to,
      from: from,
      url: "http://demo.twilio.com/docs/voice.xml", // replace with your TwiML
    });

    // save call to history
    await userRef.collection("callHistory").add({
      callSid: call.sid,
      to: to,
      from: from,
      status: call.status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, callSid: call.sid };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ── 6. Send FCM push when a notification doc is created ──────
exports.onNotificationCreated = functions.firestore
  .document("users/{userId}/notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const data = snap.data();

    const title = data.title || "Flux Virtual";
    const body = data.body || data.message || "";

    try {
      await admin.messaging().send({
        topic: `user_${userId}`,
        notification: { title, body },
        apns: {
          payload: { aps: { sound: "default", badge: 1 } },
        },
        android: {
          priority: "high",
          notification: { sound: "default" },
        },
      });
    } catch (e) {
      console.error("FCM send failed:", e);
    }
  });