/**
 * Firebase Cloud Function: Update Ambulance GPS Location via IoT
 * 
 * Deploy alongside iot_cloud_function.js using: firebase deploy --only functions
 * 
 * ESP32 GPS tracker will POST every 5 seconds:
 * POST https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/updateAmbulanceLocation
 * 
 * Payload:
 * {
 *   "apiKey": "SUPER_SECRET_IOT_KEY",
 *   "ambulanceId": "AMB_001",
 *   "hospitalId": "hosp_123",
 *   "lat": 28.5672,
 *   "lng": 77.2100,
 *   "speed": 45.2,
 *   "status": "dispatched"
 * }
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
    admin.initializeApp();
}

const IOT_API_KEY = "SUPER_SECRET_IOT_KEY";

exports.updateAmbulanceLocation = functions.https.onRequest(async (req, res) => {
  // 1. Security
  if (!req.body.apiKey || req.body.apiKey !== IOT_API_KEY) {
    res.status(401).send("Unauthorized");
    return;
  }

  const { ambulanceId, hospitalId, lat, lng, speed, status } = req.body;
  if (!ambulanceId || lat == null || lng == null) {
    res.status(400).send("Missing required fields: ambulanceId, lat, lng");
    return;
  }

  try {
    await admin.firestore().collection("ambulances").doc(ambulanceId).set(
      {
        hospital_id: hospitalId || null,
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        speed_kmh: parseFloat(speed) || 0,
        status: status || "unknown",
        last_updated: admin.firestore.FieldValue.serverTimestamp(),
        source: "iot",
        device_id: req.body.deviceId || "esp32_gps_generic",
      },
      { merge: true }
    );

    res.status(200).send("Ambulance location updated");
  } catch (error) {
    console.error("Ambulance update error:", error);
    res.status(500).send("Internal Server Error");
  }
});
