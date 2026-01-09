#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// ================= WIFI & FIREBASE =================
const char* WIFI_SSID  = "YOUR_WIFI_SSID";
const char* WIFI_PASS  = "YOUR_WIFI_PASSWORD";

const char* FIREBASE_HOST = "https://YOUR_PROJECT_ID.firebaseio.com";
const char* FIREBASE_AUTH = "YOUR_FIREBASE_SECRET";
const char* DEVICE_ID     = "esp32_device_01";

// ================= PINS =================
#define RELAY_1 25   // Light (ACTIVE LOW)
#define RELAY_2 26   // Fan   (ACTIVE LOW)

#define GAS_SENSOR 34
#define PIR_SENSOR 32
#define DHT_PIN    33
#define DHT_TYPE   DHT11

DHT dht(DHT_PIN, DHT_TYPE);

// ================= STATES =================
bool relay1_state = false;
bool relay2_state = false;

int gasLevel = 0;
bool motionDetected = false;
bool lastMotionState = false;
uint32_t motionCount = 0;

float temperature = 0;
float humidity = 0;

// ================= ENERGY CONFIG =================
#define RELAY1_WATTS 60.0f     // Light power
#define RELAY2_WATTS 75.0f     // Fan power
#define COST_PER_KWH 6.5f      // ₹ per unit

float relay1_Wh = 0.0f;
float relay2_Wh = 0.0f;

unsigned long lastEnergyUpdate = 0;
unsigned long lastEnergyPush   = 0;
const unsigned long energyPushInterval = 5000;

// ================= TIMING =================
unsigned long lastSensorRead   = 0;
unsigned long lastFirebasePoll = 0;

const unsigned long sensorInterval       = 1500;
const unsigned long firebasePollInterval = 300;

// ================= FIREBASE URL =================
String firebaseUrl(String path) {
  String url = String(FIREBASE_HOST) + "/" + path + ".json";
  if (strlen(FIREBASE_AUTH) > 0) {
    url += "?auth=" + String(FIREBASE_AUTH);
  }
  return url;
}

// ================= WIFI =================
void connectWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");
}

// ================= RELAY CONTROL =================
void setRelayState(int relay, bool on) {
  if (relay == 1) {
    relay1_state = on;
    digitalWrite(RELAY_1, on ? LOW : HIGH);
  }
  if (relay == 2) {
    relay2_state = on;
    digitalWrite(RELAY_2, on ? LOW : HIGH);
  }
}

// ================= PUSH RELAYS =================
void pushRelaysToFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  StaticJsonDocument<128> doc;
  doc["relay1"] = relay1_state ? 1 : 0;
  doc["relay2"] = relay2_state ? 1 : 0;
  doc["timestamp"] = millis();

  String body;
  serializeJson(doc, body);

  HTTPClient http;
  http.begin(firebaseUrl("devices/" + String(DEVICE_ID) + "/relays"));
  http.addHeader("Content-Type", "application/json");
  http.PUT(body);
  http.end();
}

// ================= FETCH RELAYS =================
void fetchAndApplyRelayStates() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin(firebaseUrl("devices/" + String(DEVICE_ID) + "/relays"));
  int code = http.GET();

  if (code == 200) {
    StaticJsonDocument<256> doc;
    deserializeJson(doc, http.getString());

    bool r1 = (doc["relay1"] == 1);
    bool r2 = (doc["relay2"] == 1);

    if (r1 != relay1_state) setRelayState(1, r1);
    if (r2 != relay2_state) setRelayState(2, r2);
  }
  http.end();
}

// ================= SENSORS =================
void readSensors() {
  gasLevel = map(analogRead(GAS_SENSOR), 0, 4095, 0, 100);

  bool motion = digitalRead(PIR_SENSOR);
  motionDetected = motion;
  if (motion && !lastMotionState) motionCount++;
  lastMotionState = motion;

  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (!isnan(t)) temperature = t;
  if (!isnan(h)) humidity = h;
}

// ================= PUSH SENSORS =================
void pushSensors() {
  if (WiFi.status() != WL_CONNECTED) return;

  StaticJsonDocument<256> doc;
  doc["temperature"] = temperature;
  doc["humidity"]    = humidity;
  doc["gasLevel"]    = gasLevel;
  doc["motion"]      = motionDetected ? 1 : 0;
  doc["motionCount"] = motionCount;

  String body;
  serializeJson(doc, body);

  HTTPClient http;
  http.begin(firebaseUrl("devices/" + String(DEVICE_ID) + "/sensors"));
  http.addHeader("Content-Type", "application/json");
  http.PUT(body);
  http.end();
}

// ================= ENERGY CALCULATION =================
void updateEnergyUsage(unsigned long now) {
  if (lastEnergyUpdate == 0) {
    lastEnergyUpdate = now;
    return;
  }

  unsigned long dt = now - lastEnergyUpdate;
  if (dt == 0) return;

  float hours = dt / 3600000.0f;

  if (relay1_state) relay1_Wh += RELAY1_WATTS * hours;
  if (relay2_state) relay2_Wh += RELAY2_WATTS * hours;

  lastEnergyUpdate = now;
}

// ================= PUSH ENERGY =================
void pushEnergyToFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  float total_Wh  = relay1_Wh + relay2_Wh;
  float total_kWh = total_Wh / 1000.0f;
  float cost      = total_kWh * COST_PER_KWH;

  StaticJsonDocument<256> doc;
  doc["relay1_Wh"] = relay1_Wh;
  doc["relay2_Wh"] = relay2_Wh;
  doc["total_Wh"]  = total_Wh;
  doc["total_kWh"] = total_kWh;
  doc["cost_per_kWh"] = COST_PER_KWH;
  doc["estimatedCost"] = cost;
  doc["timestamp"] = millis();

  String body;
  serializeJson(doc, body);

  HTTPClient http;
  http.begin(firebaseUrl("devices/" + String(DEVICE_ID) + "/energy"));
  http.addHeader("Content-Type", "application/json");
  http.PUT(body);
  http.end();
}

// ================= SETUP =================
void setup() {
  Serial.begin(115200);

  pinMode(RELAY_1, OUTPUT);
  pinMode(RELAY_2, OUTPUT);
  digitalWrite(RELAY_1, HIGH);
  digitalWrite(RELAY_2, HIGH);

  pinMode(PIR_SENSOR, INPUT);
  pinMode(GAS_SENSOR, INPUT);

  dht.begin();
  connectWiFi();
}

// ================= LOOP =================
void loop() {
  unsigned long now = millis();

  updateEnergyUsage(now);

  if (now - lastSensorRead >= sensorInterval) {
    readSensors();
    pushSensors();
    lastSensorRead = now;
  }

  if (now - lastFirebasePoll >= firebasePollInterval) {
    fetchAndApplyRelayStates();
    lastFirebasePoll = now;
  }

  if (now - lastEnergyPush >= energyPushInterval) {
    pushEnergyToFirebase();
    lastEnergyPush = now;
  }

  if (Serial.available()) {
    char c = Serial.read();
    if (c == '1') { setRelayState(1, !relay1_state); pushRelaysToFirebase(); }
    if (c == '2') { setRelayState(2, !relay2_state); pushRelaysToFirebase(); }
  }
}