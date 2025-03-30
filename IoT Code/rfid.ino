
#include <SPI.h>
#include <MFRC522.h>
constexpr uint8_t RST_PIN = D3;     // Configurable, see typical pin layout above
constexpr uint8_t SS_PIN = D8;     // Configurable, see typical pin layout above
MFRC522 rfid(SS_PIN, RST_PIN); // Instance of the class
MFRC522::MIFARE_Key key;
String tag;
#define led D0
#define na D2
void setup() {
  Serial.begin(115200);
  SPI.begin(); // Init SPI bus
  rfid.PCD_Init(); // Init MFRC522
  pinMode(led,OUTPUT);
  pinMode(na,OUTPUT);
}
void loop() {
  if ( ! rfid.PICC_IsNewCardPresent())
    return;
  if (rfid.PICC_ReadCardSerial()) {
    for (byte i = 0; i < 4; i++) {
      tag += rfid.uid.uidByte[i];
    }
    Serial.print(tag);
    if(tag=="8624725537")   //rfid tag value
    {
    Serial.println(" Verified");
    digitalWrite(led,HIGH);
    delay(5000);
    digitalWrite(led,LOW);
    }
    else{
    Serial.println(" Not Verified");
    digitalWrite(na,HIGH);
    delay(100);
    digitalWrite(na,LOW);
    delay(100);
    digitalWrite(na,HIGH);
    delay(100);
    digitalWrite(na,LOW);
    delay(100);
    digitalWrite(na,HIGH);
    delay(100);
    digitalWrite(na,LOW);
     delay(100);
    digitalWrite(na,HIGH);
    delay(100);
    digitalWrite(na,LOW);
    }
    tag = "";
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
  }
}