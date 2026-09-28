# Smart Bike BLE Binary Framing Protocol Specification

Version: `1.0.0`  
Transport: Bluetooth Low Energy (BLE) GATT (Characteristic MTU negotiated, default min 23 bytes, recommended >= 64-128 bytes).

---

## 1. GATT Profile & Architecture

### Service & Characteristic UUIDs
- **Primary Service UUID**: `0000A000-0000-1000-8000-00805F9B34FB` (Smart Bike Service)
- **RX Characteristic (Write / Write Without Response)**: `0000A001-0000-1000-8000-00805F9B34FB` (App -> ESP32)
- **TX Characteristic (Notify / Indicate)**: `0000A002-0000-1000-8000-00805F9B34FB` (ESP32 -> App)

---

## 2. Frame Structure (Packet Layout)

All multi-byte integer values are transmitted in **Big-Endian (Network Byte Order)** unless specified otherwise.

| Field | Size (Bytes) | Description |
|---|---|---|
| **SOF** (Start of Frame) | 2 | Magic bytes: `0xAA`, `0x55` |
| **Sequence ID** | 1 | Monotonically incrementing packet counter `0x00` - `0xFF` for ACK matching |
| **Command ID** | 1 | Opcode identifying request / telemetry stream / response |
| **Payload Length** | 2 | `uint16_t` length of Payload ($N \le 512$) |
| **Payload** | $N$ | Command-specific parameters or telemetry data |
| **CRC16** | 2 | CRC-16-CCITT (Polynomial `0x1021`, Init `0xFFFF`) calculated over [Seq, Cmd, Len_H, Len_L, Payload...] |

**Packet Overhead**: 8 bytes (`SOF[2] + Seq[1] + Cmd[1] + Len[2] + CRC[2]`).

---

## 3. Command ID Enumeration (`CmdID`)

### Mobile App -> Bike (Requests / Control: `0x01` - `0x3F`)
- `0x01` : **CMD_PING** (Keepalive / Connection test)
- `0x02` : **CMD_GET_STATUS** (Request full snapshot of all sensors & state)
- `0x10` : **CMD_LOCK_CONTROL** (Payload: `0x00` = Unlock, `0x01` = Lock)
- `0x11` : **CMD_ALARM_CONTROL** (Payload: `0x00` = Off, `0x01` = Sound Siren, `0x02` = Silent Alarm)
- `0x20` : **CMD_FINGERPRINT_ENROLL_START** (Payload: User ID [uint8_t])
- `0x21` : **CMD_FINGERPRINT_DELETE** (Payload: User ID [uint8_t], `0xFF` for all)
- `0x30` : **CMD_GPS_CONFIG** (Payload: Update interval in seconds [uint16_t])

### Bike -> Mobile App (Responses / Telemetry: `0x80` - `0xBF`)
- `0x80` : **RSP_ACK** (Command executed successfully, returns Acked Seq ID)
- `0x81` : **RSP_NACK** (Command rejected or CRC failure, returns Error Code)
- `0x90` : **NOTIF_TELEMETRY_STREAM** (Periodic telemetry broadcast: battery, speed, lock, cadence)
- `0x91` : **NOTIF_GPS_UPDATE** (Latitude, Longitude, Altitude, Speed, Sats, Fix)
- `0x92` : **NOTIF_FINGERPRINT_EVENT** (Enrollment step, match result, unauthorized attempt)
- `0x93` : **NOTIF_ALARM_TRIGGERED** (Theft/tamper alert, shock sensor triggered)

---

## 4. Payload Specifications

### 4.1. `CMD_LOCK_CONTROL` (`0x10`) -> `RSP_ACK` (`0x80`)
- **Request Payload (1 byte)**:
  - Byte 0: `0x00` (Unlock), `0x01` (Lock)
- **Response Payload (2 bytes)**:
  - Byte 0: Resulting Lock State (`0x00` = Unlocked, `0x01` = Locked, `0x02` = Jammed)
  - Byte 1: Motor current / status code

### 4.2. `NOTIF_TELEMETRY_STREAM` (`0x90`) (16 bytes payload)
```
Offset  Size  Type       Description
0       1     uint8_t    Lock State (0=Unlocked, 1=Locked, 2=Jammed)
1       2     uint16_t   Battery Voltage (mV, e.g., 4150 = 4.15V)
3       1     uint8_t    Battery State of Charge (0 - 100%)
4       2     uint16_t   Current Speed (0.1 km/h resolution, e.g., 254 = 25.4 km/h)
6       2     uint16_t   Cadence (RPM)
8       2     int16_t    Temperature (0.1 °C resolution, e.g., 285 = 28.5 °C)
10      1     uint8_t    Light/Headlamp State (0=Off, 1=Low, 2=High)
11      1     uint8_t    Alarm State (0=Disarmed, 1=Armed, 2=Triggered)
12      4     uint32_t   Trip Distance (meters)
```

### 4.3. `NOTIF_GPS_UPDATE` (`0x91`) (15 bytes payload)
```
Offset  Size  Type       Description
0       4     int32_t    Latitude (Scaled by 1e7, e.g., 377749290 = 37.774929)
4       4     int32_t    Longitude (Scaled by 1e7, e.g., -1224194160 = -122.419416)
8       2     int16_t    Altitude (Meters above sea level)
10      2     uint16_t   Ground Speed (0.1 km/h)
12      1     uint8_t    Satellites in view
13      1     uint8_t    Fix Quality (0=No fix, 1=2D GPS, 2=3D DGPS/RTK)
14      1     uint8_t    HDOP (0.1 precision)
```

### 4.4. `NOTIF_FINGERPRINT_EVENT` (`0x92`) (3 bytes payload)
```
Offset  Size  Type       Description
0       1     uint8_t    Event Type:
                         0x01 = Scan OK (Matched)
                         0x02 = Scan Failed (Not recognized)
                         0x03 = Enrollment Progress (Needs touch again)
                         0x04 = Enrollment Complete
                         0x05 = Sensor Error
1       1     uint8_t    User / Slot ID (0 - 255)
2       1     uint8_t    Confidence Score (0 - 100)
```

---

## 5. CRC-16-CCITT Verification Algorithm
- Polynomial: `0x1021` ($x^{16} + x^{12} + x^5 + 1$)
- Initial Value: `0xFFFF`
- Final XOR: `0x0000`
- RefIn: `false`, RefOut: `false`
