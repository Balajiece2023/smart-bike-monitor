/*
 * ESP32 Smart Bike Controller Firmware Skeleton
 * Implements BLE GATT Server matching the Smart Bike Binary Framing Protocol
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "0000A000-0000-1000-8000-00805F9B34FB"
#define RX_CHAR_UUID        "0000A001-0000-1000-8000-00805F9B34FB"
#define TX_CHAR_UUID        "0000A002-0000-1000-8000-00805F9B34FB"

#define PIN_LOCK_MOTOR_A    18
#define PIN_LOCK_MOTOR_B    19
#define PIN_ALARM_BUZZER    23

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
bool deviceConnected = false;
uint8_t txSequence = 0;
bool isLocked = true;

// CRC-16-CCITT implementation
uint16_t calculateCrc16(const uint8_t* data, size_t length) {
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < length; i++) {
        crc ^= (uint16_t)data[i] << 8;
        for (uint8_t bit = 0; bit < 8; bit++) {
            if (crc & 0x8000) {
                crc = (crc << 1) ^ 0x1021;
            } else {
                crc = crc << 1;
            }
        }
    }
    return crc;
}

void sendPacket(uint8_t commandId, const uint8_t* payload, uint16_t payloadLen) {
    if (!deviceConnected || pTxCharacteristic == NULL) return;

    size_t totalLen = 2 + 4 + payloadLen + 2;
    uint8_t* packet = (uint8_t*)malloc(totalLen);

    packet[0] = 0xAA;
    packet[1] = 0x55;
    packet[2] = txSequence++;
    packet[3] = commandId;
    packet[4] = (payloadLen >> 8) & 0xFF;
    packet[5] = payloadLen & 0xFF;

    if (payloadLen > 0 && payload != NULL) {
        memcpy(&packet[6], payload, payloadLen);
    }

    uint16_t crc = calculateCrc16(&packet[2], 4 + payloadLen);
    packet[totalLen - 2] = (crc >> 8) & 0xFF;
    packet[totalLen - 1] = crc & 0xFF;

    pTxCharacteristic->setValue(packet, totalLen);
    pTxCharacteristic->notify();

    free(packet);
}

class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
    }
    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        pServer->startAdvertising();
    }
};

class RxCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) {
        std::string rxVal = pCharacteristic->getValue();
        if (rxVal.length() < 8) return;

        const uint8_t* bytes = (const uint8_t*)rxVal.data();
        if (bytes[0] != 0xAA || bytes[1] != 0x55) return;

        uint8_t seq = bytes[2];
        uint8_t cmd = bytes[3];
        uint16_t len = ((uint16_t)bytes[4] << 8) | bytes[5];

        if (rxVal.length() < (size_t)(8 + len)) return;

        uint16_t recCrc = ((uint16_t)bytes[6 + len] << 8) | bytes[7 + len];
        uint16_t calcCrc = calculateCrc16(&bytes[2], 4 + len);

        if (recCrc != calcCrc) return; // CRC mismatch

        // Handle Command
        if (cmd == 0x10) { // CMD_LOCK_CONTROL
            bool lockRequest = bytes[6] == 0x01;
            isLocked = lockRequest;

            // Drive H-bridge motor
            digitalWrite(PIN_LOCK_MOTOR_A, isLocked ? HIGH : LOW);
            digitalWrite(PIN_LOCK_MOTOR_B, isLocked ? LOW : HIGH);
            delay(150);
            digitalWrite(PIN_LOCK_MOTOR_A, LOW);
            digitalWrite(PIN_LOCK_MOTOR_B, LOW);

            // Send ACK back
            uint8_t ackPayload[2] = { (uint8_t)(isLocked ? 1 : 0), 0x00 };
            sendPacket(0x80, ackPayload, 2);
        }
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(PIN_LOCK_MOTOR_A, OUTPUT);
    pinMode(PIN_LOCK_MOTOR_B, OUTPUT);
    pinMode(PIN_ALARM_BUZZER, OUTPUT);

    BLEDevice::init("ESP32_SMART_BIKE");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);
    pTxCharacteristic = pService->createCharacteristic(
        TX_CHAR_UUID,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pTxCharacteristic->addDescriptor(new BLE2902());

    BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
        RX_CHAR_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pRxCharacteristic->setCallbacks(new RxCallbacks());

    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();
}

unsigned long lastTelemetryTime = 0;

void loop() {
    if (deviceConnected && (millis() - lastTelemetryTime > 1000)) {
        lastTelemetryTime = millis();

        // 16-byte telemetry frame
        uint8_t telem[16] = {0};
        telem[0] = isLocked ? 1 : 0;
        telem[1] = 0x10; telem[2] = 0x68; // 4200 mV
        telem[3] = 98;                    // 98% SoC
        telem[4] = 0x00; telem[5] = 0xF0; // 24.0 km/h
        telem[6] = 0x00; telem[7] = 72;   // 72 RPM
        telem[8] = 0x01; telem[9] = 0x0E; // 27.0 °C
        telem[10] = 1;                    // Headlight
        telem[11] = isLocked ? 1 : 0;     // Alarm armed
        telem[12] = 0x00; telem[13] = 0x00; telem[14] = 0x30; telem[15] = 0x39; // Trip distance

        sendPacket(0x90, telem, 16);
    }
    delay(20);
}
