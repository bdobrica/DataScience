#include "DHT.h"
#include "Seeed_BMP280.h"
#include <Wire.h>
#include "LIS3DHTR.h"
#include <U8x8lib.h>

#define DHTTYPE DHT20

int lightPin = A6;
int soundPin = A2;
int ledPin = 4;
DHT dht(DHTTYPE);
BMP280 bmp280;
LIS3DHTR<TwoWire> LIS;
U8X8_SSD1306_128X64_NONAME_HW_I2C u8x8(U8X8_PIN_NONE);
 
void setup()
{
    pinMode(ledPin, OUTPUT);
    Wire.begin();
    dht.begin();
    bmp280.init();
    LIS.begin(Wire, 0x19); 
    delay(100);
    LIS.setOutputDataRate(LIS3DHTR_DATARATE_50HZ);
    u8x8.begin();
    u8x8.setPowerSave(0);
    u8x8.setFlipMode(1);
    u8x8.setFont(u8x8_font_chroma48medium8_r);
    Serial.begin(9600);
}
 
void loop()
{
    if (Serial.available() > 0 && Serial.read() == 'r') {
        float lightValue = ((float) analogRead(lightPin)) / 1023.0; // Citește valoarea senzorului
        float soundValue = ((float) analogRead(soundPin)) / 1023.0;
        float dhtTempValue = dht.readTemperature();
        float dhtHumiValue = dht.readHumidity();
        float bmpTempValue = bmp280.getTemperature();
        float bmpPresValue = bmp280.getPressure();
        float bmpAltitudeValue = bmp280.calcAltitude(bmpPresValue);
        float accX = LIS.getAccelerationX();
        float accY = LIS.getAccelerationY();
        float accZ = LIS.getAccelerationZ();
    
        digitalWrite(ledPin, HIGH);
        Serial.print(lightValue, 4); Serial.print(",");
        Serial.print(soundValue, 4); Serial.print(",");
        Serial.print(dhtTempValue, 4); Serial.print(",");
        Serial.print(dhtHumiValue, 4); Serial.print(",");
        Serial.print(bmpTempValue, 4); Serial.print(",");
        Serial.print(bmpPresValue, 4); Serial.print(",");
        Serial.print(bmpAltitudeValue, 4); Serial.print(",");
        Serial.print(accX, 4); Serial.print(",");
        Serial.print(accY, 4); Serial.print(",");
        Serial.println(accZ, 4);
        digitalWrite(ledPin, LOW);

        u8x8.setCursor(0, 1);
        u8x8.print("TMP_1:"); u8x8.print(dhtTempValue); u8x8.print("C");
        u8x8.setCursor(0, 10);
        u8x8.print("HUMID:"); u8x8.print(dhtHumiValue); u8x8.print("%");
        u8x8.setCursor(0, 19);
        u8x8.print("TMP_2:"); u8x8.print(bmpTempValue); u8x8.print("C");
        u8x8.setCursor(0, 28);
        u8x8.print("PRESS:"); u8x8.print(bmpPresValue / 1000.0); u8x8.print("kPa");
        u8x8.setCursor(0, 37);
        u8x8.print("LIGHT:"); u8x8.print(lightValue);
        u8x8.setCursor(0, 46);
        u8x8.print("SOUND:"); u8x8.print(lightValue);
        u8x8.setCursor(0, 55);
        u8x8.print(accX, 1); u8x8.print(" "); u8x8.print(accY, 1); u8x8.print(" "); u8x8.print(accZ, 1); u8x8.print(" ");
        u8x8.refreshDisplay();
    }
}
