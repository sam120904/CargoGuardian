#define BLYNK_PRINT Serial
#include <ESP8266WiFi.h>
#include <BlynkSimpleEsp8266.h>

#define BLYNK_AUTH_TOKEN "5VyqNitgoIiqWJynb38LQMgqtotgnj_M"

const char* ssid = "Meenuvikas_2.4ghz";  
const char* pass = "Parth2005";  
BLYNK_WRITE(V1) {
  digitalWrite(D0, param.asInt());
}
BLYNK_WRITE(V2) {
  digitalWrite(D7, param.asInt());
}

#define o D1
#define g D2
#define r D3

// HX711 Pins
#define DT_PIN 14  // ESP8266 D5 (GPIO14)
#define SCK_PIN 12 // ESP8266 D6 (GPIO12)

// Calibration Values (Adjust based on real calibration)
long raw_offset = -3850;  
float scale_factor = 1000;  

// Noise Reduction Settings
const int numReadings = 5; // Number of samples for averaging

bool underloadAlertSent = false;
bool overloadAlertSent = false;

void setup() {
    Serial.begin(9600);
    pinMode(DT_PIN, INPUT);
    pinMode(SCK_PIN, OUTPUT);

    pinMode(D0, OUTPUT);
    pinMode(D7, OUTPUT);
    pinMode(o, OUTPUT);
    pinMode(g, OUTPUT);
    pinMode(r, OUTPUT);

    // Connect to WiFi
    WiFi.begin(ssid, pass);
    Serial.println("\n🔄 Connecting to WiFi...");
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.print(".");
    }
    Serial.println("\n✅ WiFi Connected!");
    
    // Connect to Blynk
    Serial.println("🔄 Connecting to Blynk...");
    Blynk.config(BLYNK_AUTH_TOKEN, "blynk.cloud", 80);
    Blynk.connect();  // Connect manually
}

// Function to read raw HX711 data
long readHX711() {
    while (digitalRead(DT_PIN)); // Wait for HX711 to be ready (DT goes LOW)

    long value = 0;

    for (int i = 0; i < 24; i++) {
        digitalWrite(SCK_PIN, HIGH);
        delayMicroseconds(1);
        value = (value << 1) | digitalRead(DT_PIN);
        digitalWrite(SCK_PIN, LOW);
        delayMicroseconds(1);
    }

    digitalWrite(SCK_PIN, HIGH);
    delayMicroseconds(1);
    digitalWrite(SCK_PIN, LOW);
    delayMicroseconds(1);

    if (value & 0x800000) {
        value |= 0xFF000000;
    }

    return value;
}

// Function to get a stable reading using averaging
long getStableReading() {
    long sum = 0;
    for (int i = 0; i < numReadings; i++) {
        sum += readHX711();
        delay(1); // Small delay between readings
    }
    return sum / numReadings;
}

void loop() {
    if (Blynk.connected()) {
        Blynk.run();
    } else {
        Serial.println("❌ Blynk Disconnected! Retrying...");
        Blynk.connect();
    }

    long raw_value = getStableReading();  
    int weight = ((raw_value - raw_offset) / scale_factor); 
    
    Serial.print("Stable Raw ADC: ");
    Serial.print(raw_value);
    Serial.print(" | Weight: ");
    Serial.print(weight);
    Serial.println(" grams");

    Blynk.virtualWrite(V0, weight);

    if(weight>5 && weight<20){
    digitalWrite(o, HIGH);
    digitalWrite(g, LOW);
    digitalWrite(r, LOW);
 }
 else if(weight>20 && weight<60){
    digitalWrite(o, LOW);
    digitalWrite(g, HIGH);
    digitalWrite(r, LOW);
 }
 else if(weight>60){
    digitalWrite(o, LOW);
    digitalWrite(g, LOW);
    digitalWrite(r, HIGH);
 }
 else if(weight==0){
    digitalWrite(o, LOW);
    digitalWrite(g, LOW);
    digitalWrite(r, LOW);
 }

    // 🔴 Underload Alert (Weight < 5g)
    if (weight > 5 && weight <20 && !underloadAlertSent) {
        Serial.println("⚠️ Underload Detected! Sending Alert...");
        Blynk.logEvent("underload_alert", "⚠️ Weight is too low!");
        underloadAlertSent = true;
        overloadAlertSent = false;  // Reset overload flag
    }

    // 🔴 Overload Alert (Weight > 60g)
    if (weight > 60 && !overloadAlertSent) {
        Serial.println("⚠️ Overload Detected! Sending Alert...");
        Blynk.logEvent("overload_alert", "⚠️ Weight is too high!");
        overloadAlertSent = true;
        underloadAlertSent = false;  // Reset underload flag
    }

    // Reset alerts if weight is normal
    if (weight >= 5 && weight <= 60) {
        underloadAlertSent = false;
        overloadAlertSent = false;
    }

    delay(200);
}
