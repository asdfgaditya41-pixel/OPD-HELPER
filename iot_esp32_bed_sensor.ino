/**
 * ESP32 Arduino Sketch — Hospital IoT Smart Bed Sensor
 * 
 * Hardware: ESP32 + Pressure Sensor (e.g. FSR402) on GPIO pin 34.
 * 
 * Wiring:
 *   FSR402 → Voltage Divider → GPIO34 (ADC input, 0-3.3V)
 *   VCC → 3.3V, GND → GND
 * 
 * Logic:
 *   - Reads analog pressure from sensor
 *   - If ADC > threshold (patient detected) → "occupied"
 *   - If ADC <= threshold → "available"
 *   - Posts JSON payload to Firebase Cloud Function via HTTPS
 *   - Retries if WiFi or server is down
 *   - Debounced: Only sends when status changes or 5 minutes pass
 * 
 * Dependencies (install via Arduino Library Manager):
 *   - WiFi.h (built-in ESP32)
 *   - HTTPClient.h (built-in ESP32)
 *   - ArduinoJson (by Benoit Blanchon) >= v6
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ─── User Configuration ─────────────────────────────────────────
const char* ssid         = "YOUR_WIFI_SSID";
const char* password     = "YOUR_WIFI_PASSWORD";

// Firebase Cloud Function URL (replace with yours after deploy)
const char* cloudFnUrl = "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/updateIotBedStatus";

// Your Hospital and Room data
const char* iotApiKey    = "SUPER_SECRET_IOT_KEY";
const char* hospitalId   = "hosp_123";
const char* roomId       = "101";
const char* bedId        = "bed_1";
const char* deviceId     = "esp32_room101_bed1";

// Pressure detection threshold (tune to your FSR sensor)
const int PRESSURE_THRESHOLD = 500; // ADC value out of 4095
const int SENSOR_PIN = 34;

// Heartbeat interval when status hasn't changed (5 minutes)
const unsigned long HEARTBEAT_INTERVAL_MS = 5 * 60 * 1000;
// ────────────────────────────────────────────────────────────────

String lastSentStatus = "";
unsigned long lastSendTimeMs = 0;

void setup() {
  Serial.begin(115200);
  pinMode(SENSOR_PIN, INPUT);

  Serial.print("Connecting to WiFi...");
  WiFi.begin(ssid, password);

  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 20) {
    delay(500);
    Serial.print(".");
    retries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\nWiFi FAILED. Will retry in loop.");
  }
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected. Reconnecting...");
    WiFi.reconnect();
    delay(5000);
    return;
  }

  int adcValue = analogRead(SENSOR_PIN);
  String currentStatus = (adcValue > PRESSURE_THRESHOLD) ? "occupied" : "available";

  unsigned long nowMs = millis();
  bool statusChanged = (currentStatus != lastSentStatus);
  bool heartbeatDue  = (nowMs - lastSendTimeMs) >= HEARTBEAT_INTERVAL_MS;

  if (statusChanged || heartbeatDue) {
    Serial.print("ADC: ");
    Serial.print(adcValue);
    Serial.print(" → Sending status: ");
    Serial.println(currentStatus);

    bool ok = sendToFirebase(currentStatus);
    if (ok) {
      lastSentStatus = currentStatus;
      lastSendTimeMs = nowMs;
    } else {
      Serial.println("Send failed. Will retry next loop.");
    }
  }

  delay(2000); // Poll sensor every 2 seconds
}

bool sendToFirebase(String status) {
  HTTPClient http;
  http.begin(cloudFnUrl);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<256> doc;
  doc["apiKey"]     = iotApiKey;
  doc["hospitalId"] = hospitalId;
  doc["roomId"]     = roomId;
  doc["bedId"]      = bedId;
  doc["deviceId"]   = deviceId;
  doc["status"]     = status;

  String payload;
  serializeJson(doc, payload);

  int httpCode = http.POST(payload);
  http.end();

  if (httpCode == 200) {
    Serial.println("✓ Firebase update OK");
    return true;
  } else {
    Serial.print("✗ HTTP Error code: ");
    Serial.println(httpCode);
    return false;
  }
}
