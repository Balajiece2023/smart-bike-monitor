import 'dart:async';
import 'dart:typed_data';
import '../services/ble_protocol.dart';
import '../services/ble_service.dart';
import '../../domain/models/bike_models.dart';

abstract class BikeRepository {
  Stream<BikeTelemetry> get telemetryStream;
  Stream<GpsData> get gpsStream;
  Stream<FingerprintEvent> get fingerprintStream;
  Stream<BleConnectionState> get connectionStateStream;
  Stream<String> get hardwareCommandStream;

  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<bool> setLock(bool locked);
  Future<bool> setAlarm(AlarmState state);
  Future<bool> enrollFingerprint(int slotId);
  void simulateHardwareCommand(String cmd);
}

class BikeRepositoryImpl implements BikeRepository {
  final BleService _bleService;
  int _sequenceCounter = 0;

  final _telemetryController = StreamController<BikeTelemetry>.broadcast();
  final _gpsController = StreamController<GpsData>.broadcast();
  final _fingerprintController = StreamController<FingerprintEvent>.broadcast();

  BikeRepositoryImpl({required BleService bleService}) : _bleService = bleService {
    _bleService.packetStream.listen(_handleIncomingPacket);
  }

  @override
  Stream<BikeTelemetry> get telemetryStream => _telemetryController.stream;

  @override
  Stream<GpsData> get gpsStream => _gpsController.stream;

  @override
  Stream<FingerprintEvent> get fingerprintStream => _fingerprintController.stream;

  @override
  Stream<BleConnectionState> get connectionStateStream => _bleService.connectionStateStream;

  @override
  Stream<String> get hardwareCommandStream => _bleService.hardwareCommandStream;

  @override
  void simulateHardwareCommand(String cmd) => _bleService.simulateHardwareCommand(cmd);

  int _nextSeq() => (_sequenceCounter++) & 0xFF;

  @override
  Future<void> connect(String deviceId) => _bleService.connect(deviceId);

  @override
  Future<void> disconnect() => _bleService.disconnect();

  @override
  Future<bool> setLock(bool locked) async {
    final packet = BlePacket(
      sequenceId: _nextSeq(),
      commandId: BleCommandId.cmdLockControl,
      payload: Uint8List.fromList([locked ? 0x01 : 0x00]),
    );
    return _bleService.sendPacket(packet);
  }

  @override
  Future<bool> setAlarm(AlarmState state) async {
    final val = state == AlarmState.disarmed ? 0x00 : (state == AlarmState.armed ? 0x01 : 0x02);
    final packet = BlePacket(
      sequenceId: _nextSeq(),
      commandId: BleCommandId.cmdAlarmControl,
      payload: Uint8List.fromList([val]),
    );
    return _bleService.sendPacket(packet);
  }

  @override
  Future<bool> enrollFingerprint(int slotId) async {
    final packet = BlePacket(
      sequenceId: _nextSeq(),
      commandId: BleCommandId.cmdFingerprintEnroll,
      payload: Uint8List.fromList([slotId & 0xFF]),
    );
    return _bleService.sendPacket(packet);
  }

  void _handleIncomingPacket(BlePacket packet) {
    switch (packet.commandId) {
      case BleCommandId.notifTelemetry:
        _parseTelemetry(packet.payload);
        break;
      case BleCommandId.notifGpsUpdate:
        _parseGps(packet.payload);
        break;
      case BleCommandId.notifFingerprintEvent:
        _parseFingerprint(packet.payload);
        break;
    }
  }

  void _parseTelemetry(Uint8List payload) {
    if (payload.length < 16) return;
    final bdata = ByteData.sublistView(payload);

    final lockRaw = bdata.getUint8(0);
    final lockState = lockRaw == 0
        ? LockState.unlocked
        : (lockRaw == 1 ? LockState.locked : LockState.jammed);

    final telemetry = BikeTelemetry(
      lockState: lockState,
      batteryMillivolts: bdata.getUint16(1),
      batterySocPercentage: bdata.getUint8(3),
      speedKmh: bdata.getUint16(4) / 10.0,
      cadenceRpm: bdata.getUint16(6),
      temperatureCelsius: bdata.getInt16(8) / 10.0,
      lightState: bdata.getUint8(10),
      alarmState: bdata.getUint8(11) == 0
          ? AlarmState.disarmed
          : (bdata.getUint8(11) == 1 ? AlarmState.armed : AlarmState.triggered),
      tripDistanceMeters: bdata.getUint32(12),
    );

    _telemetryController.add(telemetry);
  }

  void _parseGps(Uint8List payload) {
    if (payload.length < 15) return;
    final bdata = ByteData.sublistView(payload);

    final gps = GpsData(
      latitude: bdata.getInt32(0) / 1e7,
      longitude: bdata.getInt32(4) / 1e7,
      altitudeMeters: bdata.getInt16(8),
      speedKmh: bdata.getUint16(10) / 10.0,
      satellites: bdata.getUint8(12),
      fixQuality: bdata.getUint8(13),
      hdop: bdata.getUint8(14) / 10.0,
    );

    _gpsController.add(gps);
  }

  void _parseFingerprint(Uint8List payload) {
    if (payload.length < 3) return;
    final rawType = payload[0];
    FingerprintEventType type = FingerprintEventType.scanFailed;
    if (rawType == 0x01) type = FingerprintEventType.scanOk;
    if (rawType == 0x03) type = FingerprintEventType.enrollmentStep;
    if (rawType == 0x04) type = FingerprintEventType.enrollmentComplete;
    if (rawType == 0x05) type = FingerprintEventType.sensorError;

    _fingerprintController.add(FingerprintEvent(
      type: type,
      slotId: payload[1],
      confidenceScore: payload[2],
    ));
  }
}
