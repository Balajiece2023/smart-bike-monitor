# Smart Bike BLE Architecture & System Overview

This project implements the complete bidirectional communication pipeline requested:
```
Flutter UI
    ↓
Riverpod State
    ↓
Bike Controller
    ↓
Bike Repository
    ↓
BLE Service
    ↓
BLE Protocol
    ↓
ESP32 / Bike Controller
    ↓
Sensors + Lock + GPS + Fingerprint
```

---

## 1. Architecture Components

### A. Flutter UI Layer
- **[BikeDashboardScreen](file:///e:/CProj_01/lib/ui/features/bike/views/bike_dashboard_screen.dart)**:
  - High-contrast cyber-styled dark mode dashboard.
  - Live speed gauge & trip metrics.
  - One-tap motorized lock/unlock toggle with active progress feedback.
  - Dynamic battery voltage & SoC percentage, motor temperature.
  - GPS satellite fix status (lat/long, precision HDOP).
  - Fingerprint enrollment trigger and alarm siren activation.

### B. Riverpod State & Controller Layer
- **[BikeController & BikeState](file:///e:/CProj_01/lib/ui/features/bike/view_models/bike_controller.dart)**:
  - Manages immutable state for telemetry, connection, lock, and security events.
  - Handles optimistic UI updates and dispatching asynchronous operations.

### C. Data & Repository Layer
- **[BikeRepository & BikeRepositoryImpl](file:///e:/CProj_01/lib/data/repositories/bike_repository_impl.dart)**:
  - Converts low-level byte buffers into clean domain entities: [BikeTelemetry, GpsData, FingerprintEvent](file:///e:/CProj_01/lib/domain/models/bike_models.dart).

### D. BLE Service & Protocol Framing Layer
- **[BleService](file:///e:/CProj_01/lib/data/services/ble_service.dart)**:
  - Interface supporting both [ReactiveBleService](file:///e:/CProj_01/lib/data/services/reactive_ble_service.dart) (physical Bluetooth) and [MockBleService](file:///e:/CProj_01/lib/data/services/ble_service.dart) (live simulation mode).
- **[BleProtocol](file:///e:/CProj_01/lib/data/services/ble_protocol.dart)** & **[BLE_PROTOCOL_SPEC.md](file:///e:/CProj_01/BLE_PROTOCOL_SPEC.md)**:
  - 8-byte framing: `[SOF1(0xAA), SOF2(0x55), Seq, CmdID, Len(2), Payload(N), CRC16(2)]`.
  - Stream state machine to assemble fragmented BLE MTU chunks.
  - CRC-16-CCITT packet verification.

### E. ESP32 Firmware
- **[esp32_smart_bike.ino](file:///e:/CProj_01/firmware/esp32_smart_bike.ino)**:
  - Dual GATT characteristic server (TX notify, RX write).
  - Actuator control for lock H-bridge and alarm buzzer.
  - Periodic telemetry broadcast loop.
