/**
 * ESP32 Arduino Sketch — Ambulance GPS Tracker
 * 
 * Hardware: ESP32 + Neo-6M/7M GPS Module
 * 
 * Wiring:
 *   GPS TX → ESP32 GPIO16 (RX2)
 *   GPS RX → ESP32 GPIO17 (TX2)
 *   VCC → 3.3V, GND → GND
 * 
 * Dependencies (install via Arduino Library Manager):
 *   - WiFi.h (built-in)
 *   - HTTPClient.h (built-in)
 *   - TinyGPS++ (by Mikal Hart)
 *   - ArduinoJson (by Benoit Blanchon) >= v6
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <TinyGPS++.h>
#include <ArduinoJson.h>

const char* ssid       = "YOUR_WIFI_SSID";
const char* password   = "YOUR_WIFI_PASSWORD";
const char* cloudFnUrl = "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/updateAmbulanceLocation";
const char* iotApiKey  = "SUPER_SECRET_IOT_KEY";
const char* ambulanceId = "AMB_001";
const char* hospitalId  = "hosp_123";

TinyGPSPlus gps;
HardwareSerial gpsSerial(2); // UART2 on ESP32

const unsigned long GPS_SEND_INTERVAL_MS = 5000; // Send every 5 seconds
unsigned long lastSendMs = 0;

void setup() {
  Serial.begin(115200);
  gpsSerial.begin(9600, SERIAL_8N1, 16, 17); // RX=16, TX=17

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected! IP: " + WiFi.localIP().toString());
}

void loop() {
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  unsigned long nowMs = millis();
  if ((nowMs - lastSendMs) >= GPS_SEND_INTERVAL_MS) {
    if (gps.location.isValid() && gps.location.isUpdated()) {
      double lat = gps.location.lat();
      double lng = gps.location.lng();
      double speed = gps.speed.kmph();

      Serial.printf("GPS: %.6f, %.6f  Speed: %.1f km/h\n", lat, lng, speed);
      
      bool ok = sendLocation(lat, lng, speed);
      if (ok) lastSendMs = nowMs;
    } else {
      Serial.println("Waiting for GPS fix...");
    }
  }
}

bool sendLocation(double lat, double lng, double speed) {
  HTTPClient http;
  http.begin(cloudFnUrl);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<256> doc;
  doc["apiKey"]      = iotApiKey;
  doc["ambulanceId"] = ambulanceId;
  doc["hospitalId"]  = hospitalId;
  doc["lat"]         = lat;
  doc["lng"]         = lng;
  doc["speed"]       = speed;
  doc["status"]      = "dispatched";

  String payload;
  serializeJson(doc, payload);

  int httpCode = http.POST(payload);
  http.end();

  if (httpCode == 200) {
    Serial.println("✓ Location sent");
    return true;
  } else {
    Serial.printf("✗ HTTP Error: %d\n", httpCode);
    return false;
  }
}
