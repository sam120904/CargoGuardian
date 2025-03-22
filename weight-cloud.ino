
#define BLYNK_PRINT Serial
#include <ESP8266WiFi.h>
#include <BlynkSimpleEsp8266.h>
#define BLYNK_AUTH_TOKEN "5VyqNitgoIiqWJynb38LQMgqtotgnj_M" //Enter  blynk auth token
char auth[] = BLYNK_AUTH_TOKEN;
char ssid[] = "Meenuvikas_2.4ghz";//Enter  WIFI name
char pass[] = "Parth2005";//Enter  WIFI password
BLYNK_WRITE(V1) {
  digitalWrite(D1, param.asInt());
}

#include <ESP8266WiFi.h>
#include <HX711.h>
#define DOUT  D7
#define CLK   D6  
#define o D2
#define g D3
#define r D5
HX711 scale;

void setup() {
  Serial.begin(115200);
  scale.begin(DOUT, CLK);
  scale.set_scale(135000);  
  scale.tare();     

  pinMode(D1, OUTPUT);
  pinMode(o, OUTPUT);
  pinMode(g, OUTPUT);
  pinMode(r, OUTPUT);
  Blynk.begin(auth, ssid, pass, "blynk.cloud", 80);
}

void loop() {
  Blynk.run();
  float weight = scale.get_units(5);  
  int w=(weight *178) - 0.10;//DONT CHANGE
  if(w<1)
  {
    w=0;
  }
  if(w>5 && w<30){
    digitalWrite(o, HIGH);
    digitalWrite(g, LOW);
    digitalWrite(r, LOW);
 }
 else if(w>=30 && w<=80){
    digitalWrite(o, LOW);
    digitalWrite(g, HIGH);
    digitalWrite(r, LOW);
 }
 else if(w>80){
    digitalWrite(o, LOW);
    digitalWrite(g, LOW);
    digitalWrite(r, HIGH);
 }
 else if(w==0){
    digitalWrite(o, LOW);
    digitalWrite(g, LOW);
    digitalWrite(r, LOW);
 }
  Serial.print(w);
  Serial.println(" g");
  Blynk.virtualWrite(V0, w);
}




