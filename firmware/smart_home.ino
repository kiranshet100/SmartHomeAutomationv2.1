#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

// Pin definitions
#define DHTPIN 4
#define PIRPIN 5
#define LDRPIN 6
#define MQ2PIN 7
#define WATERPIN 8
#define RELAY1 9
#define RELAY2 10
#define RELAY3 11
#define RELAY4 12
#define STATUS_LED 13
#define WIFI_LED 14
#define ALERT_LED 15

// Sensor type
#define DHTTYPE DHT22

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT broker details
const char* mqtt_server = "YOUR_MQTT_BROKER_IP";
const int mqtt_port = 1883;
const char* mqtt_user = "YOUR_MQTT_USER";
const char* mqtt_pass = "YOUR_MQTT_PASSWORD";

// MQTT topics
const char* topic_sensor = "home/sensors";
const char* topic_control = "home/control";
const char* topic_alert = "home/alert";

// Device ID
const char* device_id = "esp32_001";

// Objects
WiFiClient espClient;
PubSubClient client(espClient);
DHT dht(DHTPIN, DHTTYPE);

// Variables
float temperature = 0;
float humidity = 0;
int motion = 0;
int light_level = 0;
int gas_level = 0;
int water_level = 0;
bool relay1_state = false;
bool relay2_state = false;
bool relay3_state = false;
bool relay4_state = false;

unsigned long lastSensorRead = 0;
const long sensorInterval = 5000; // 5 seconds

void setup() {
  Serial.begin(115200);

  // Initialize pins
  pinMode(PIRPIN, INPUT);
  pinMode(LDRPIN, INPUT);
  pinMode(MQ2PIN, INPUT);
  pinMode(WATERPIN, INPUT);
  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  pinMode(STATUS_LED, OUTPUT);
  pinMode(WIFI_LED, OUTPUT);
  pinMode(ALERT_LED, OUTPUT);

  // Initialize relays (off)
  digitalWrite(RELAY1, HIGH);
  digitalWrite(RELAY2, HIGH);
  digitalWrite(RELAY3, HIGH);
  digitalWrite(RELAY4, HIGH);

  // Initialize DHT sensor
  dht.begin();

  // Connect to WiFi
  setup_wifi();

  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  // Status LED
  digitalWrite(STATUS_LED, HIGH);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long currentMillis = millis();

  // Read sensors every 5 seconds
  if (currentMillis - lastSensorRead >= sensorInterval) {
    readSensors();
    publishSensorData();
    lastSensorRead = currentMillis;
  }

  // Check for alerts
  checkAlerts();

  delay(100);
}

void setup_wifi() {
  delay(10);
  Serial.println("Connecting to WiFi...");
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  digitalWrite(WIFI_LED, HIGH);
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");

  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);

  // Parse control commands
  if (String(topic) == topic_control) {
    parseControlCommand(message);
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect(device_id, mqtt_user, mqtt_pass)) {
      Serial.println("connected");
      client.subscribe(topic_control);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void readSensors() {
  // Read DHT22
  temperature = dht.readTemperature();
  humidity = dht.readHumidity();

  // Read PIR
  motion = digitalRead(PIRPIN);

  // Read LDR
  light_level = analogRead(LDRPIN);

  // Read MQ2
  gas_level = analogRead(MQ2PIN);

  // Read Water Level
  water_level = analogRead(WATERPIN);

  // Print readings
  Serial.println("Sensor Readings:");
  Serial.print("Temperature: "); Serial.println(temperature);
  Serial.print("Humidity: "); Serial.println(humidity);
  Serial.print("Motion: "); Serial.println(motion);
  Serial.print("Light: "); Serial.println(light_level);
  Serial.print("Gas: "); Serial.println(gas_level);
  Serial.print("Water: "); Serial.println(water_level);
}

void publishSensorData() {
  String payload = "{";
  payload += "\"device_id\":\"" + String(device_id) + "\",";
  payload += "\"temperature\":