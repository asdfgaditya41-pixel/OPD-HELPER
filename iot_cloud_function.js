/**
 * Firebase Cloud Function: Update Bed Status via IoT
 * 
 * Deploy using: firebase deploy --only functions
 * 
 * ESP32 will make a simple POST request to this endpoint:
 * POST https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/updateIotBedStatus
 * Content-Type: application/json
 * 
 * Payload:
 * {
 *   "apiKey": "SUPER_SECRET_IOT_KEY",
 *   "hospitalId": "hosp_123",
 *   "roomId": "101",
 *   "bedId": "bed_1",
 *   "status": "occupied"
 * }
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
    admin.initializeApp();
}

const IOT_API_KEY = "SUPER_SECRET_IOT_KEY";

exports.updateIotBedStatus = functions.https.onRequest(async (req, res) => {
  // 1. Security check
  const providedKey = req.body.apiKey;
  if (!providedKey || providedKey !== IOT_API_KEY) {
    res.status(401).send("Unauthorized: Invalid IoT API Key");
    return;
  }

  // 2. Extract Data
  const { hospitalId, roomId, bedId, status } = req.body;
  if (!hospitalId || !roomId || !bedId || !status) {
    res.status(400).send("Bad Request: Missing required fields");
    return;
  }
  
  const roomRef = admin.firestore()
    .collection("hospitals")
    .doc(hospitalId)
    .collection("rooms")
    .doc(roomId);
    
  const hospitalRef = admin.firestore().collection("hospitals").doc(hospitalId);

  try {
    await admin.firestore().runTransaction(async (transaction) => {
      const roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) {
        throw new Error("Room not found");
      }
      
      const data = roomDoc.data();
      const beds = data.beds || {};
      const bed = beds[bedId];
      if (!bed) {
        throw new Error("Bed not found");
      }
      
      // Hardware Debouncing / Anomaly constraint: Ignore spam within 5 seconds
      if (bed.last_updated) {
        const lastMs = bed.last_updated.toMillis();
        const nowMs = Date.now();
        if ((nowMs - lastMs) < 5000) {
            console.log(`Bouncing payload ignored for ${bedId}`);
            return;
        }
      }

      // If status hasn't actually changed, just refresh the timestamp to mark it online
      if (bed.status === status) {
        transaction.update(roomRef, {
          [`beds.${bedId}.last_updated`]: admin.firestore.FieldValue.serverTimestamp(),
          [`beds.${bedId}.source`]: "iot"
        });
        return;
      }
      
      // 3. Atomically Update
      transaction.update(roomRef, {
        [`beds.${bedId}.status`]: status,
        [`beds.${bedId}.last_updated`]: admin.firestore.FieldValue.serverTimestamp(),
        [`beds.${bedId}.source`]: "iot",
        [`beds.${bedId}.device_id`]: req.body.deviceId || "esp32_generic"
      });
      
      // Update hospital counters
      const diff = status === 'available' ? 1 : -1;
      transaction.update(hospitalRef, {
        "beds_available": admin.firestore.FieldValue.increment(diff),
        "beds.available": admin.firestore.FieldValue.increment(diff),
        "last_updated": admin.firestore.FieldValue.serverTimestamp()
      });
    });

    res.status(200).send("IoT update successful");
  } catch (error) {
    console.error("IoT Transaction Error:", error);
    res.status(500).send("Internal Server Error");
  }
});
