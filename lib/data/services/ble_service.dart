import 'dart:async';
import 'dart:typed_data';
import 'ble_protocol.dart';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

abstract class BleService {
  Stream<BleConnectionState> get connectionStateStream;
  Stream<BlePacket> get packetStream;
  Stream<String> get hardwareCommandStream;
  BleConnectionState get currentState;

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<bool> sendPacket(BlePacket packet);
  void simulateHardwareCommand(String cmd);
}

/// Simulated BleService implementation for testing & UI presentation without physical ESP32
class MockBleService implements BleService {
  final _connectionController = StreamController<BleConnectionState>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _hardwareCommandController = StreamController<String>.broadcast();
  BleConnectionState _state = BleConnectionState.disconnected;
  Timer? _telemetryTimer;
  int _sequenceCounter = 0;
  bool _isLocked = true;
  double _mockSpeed = 0.0;
  final int _mockBattery = 92;

  @override
  Stream<BleConnectionState> get connectionStateStream => _connectionController.stream;

  @override
  Stream<BlePacket> get packetStream => _packetController.stream;

  @override
  Stream<String> get hardwareCommandStream => _hardwareCommandController.stream;

  @override
  BleConnectionState get currentState => _state;

  @override
  void simulateHardwareCommand(String cmd) {
    _hardwareCommandController.add(cmd);
  }

  @override
  Future<void> startScan() async {
    _state = BleConnectionState.scanning;
    _connectionController.add(_state);
  }

  @override
  Future<void> stopScan() async {
    if (_state == BleConnectionState.scanning) {
      _state = BleConnectionState.disconnected;
      _connectionController.add(_state);
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    _state = BleConnectionState.connecting;
    _connectionController.add(_state);

    await Future.delayed(const Duration(milliseconds: 100));
    _state = BleConnectionState.connected;
    _connectionController.add(_state);

    _startSimulatedTelemetry();
  }

  @override
  Future<void> disconnect() async {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _state = BleConnectionState.disconnected;
    _connectionController.add(_state);
  }

  @override
  Future<bool> sendPacket(BlePacket packet) async {
    if (_state != BleConnectionState.connected) return false;

    // Process incoming command and mock response
    if (packet.commandId == BleCommandId.cmdLockControl) {
      final shouldLock = packet.payload.isNotEmpty && packet.payload[0] == 0x01;
      _isLocked = shouldLock;

      Future.delayed(const Duration(milliseconds: 50), () {
        if (_state != BleConnectionState.connected) return;
        final ackPayload = Uint8List.fromList([_isLocked ? 0x01 : 0x00, 0x00]);
        _packetController.add(BlePacket(
          sequenceId: packet.sequenceId,
          commandId: BleCommandId.rspAck,
          payload: ackPayload,
        ));
      });
    }

    return true;
  }

  void _startSimulatedTelemetry() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state != BleConnectionState.connected) return;

      if (!_isLocked) {
        _mockSpeed = (_mockSpeed + 1.2) % 32.0;
      } else {
        _mockSpeed = 0.0;
      }

      final bdata = ByteData(16);
      bdata.setUint8(0, _isLocked ? 1 : 0);
      bdata.setUint16(1, 4120);
      bdata.setUint8(3, _mockBattery);
      bdata.setUint16(4, (_mockSpeed * 10).toInt());
      bdata.setUint16(6, _isLocked ? 0 : 75);
      bdata.setInt16(8, 265);
      bdata.setUint8(10, 1);
      bdata.setUint8(11, _isLocked ? 1 : 0);
      bdata.setUint32(12, 14250);

      _packetController.add(BlePacket(
        sequenceId: (_sequenceCounter++) & 0xFF,
        commandId: BleCommandId.notifTelemetry,
        payload: bdata.buffer.asUint8List(),
      ));
    });
  }
}
