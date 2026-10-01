import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_protocol.dart';
import 'ble_service.dart';

/// Real implementation of BleService connecting to physical ESP32 GATT server
class ReactiveBleService implements BleService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  static final Uuid serviceUuid = Uuid.parse("0000A000-0000-1000-8000-00805F9B34FB");
  static final Uuid rxCharUuid = Uuid.parse("0000A001-0000-1000-8000-00805F9B34FB"); // Mobile -> Bike
  static final Uuid txCharUuid = Uuid.parse("0000A002-0000-1000-8000-00805F9B34FB"); // Bike -> Mobile

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _hardwareCommandController = StreamController<String>.broadcast();
  final BlePacketParser _parser = BlePacketParser();

  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<DiscoveredDevice>? _scanSub;

  BleConnectionState _state = BleConnectionState.disconnected;
  String? _connectedDeviceId;

  @override
  Stream<BleConnectionState> get connectionStateStream => _connectionStateController.stream;

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
    _connectionStateController.add(_state);

    _scanSub?.cancel();
    _scanSub = _ble.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      // Typically auto-connect or emit to discovered devices stream
    }, onError: (err) {
      _state = BleConnectionState.disconnected;
      _connectionStateController.add(_state);
    });
  }

  @override
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (_state == BleConnectionState.scanning) {
      _state = BleConnectionState.disconnected;
      _connectionStateController.add(_state);
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    await stopScan();
    _connectedDeviceId = deviceId;
    _state = BleConnectionState.connecting;
    _connectionStateController.add(_state);

    _connSub?.cancel();
    _connSub = _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    ).listen((update) async {
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          _state = BleConnectionState.connected;
          _connectionStateController.add(_state);
          await _subscribeToNotifications(deviceId);
          break;
        case DeviceConnectionState.disconnected:
          _state = BleConnectionState.disconnected;
          _connectionStateController.add(_state);
          _cleanupSubscription();
          break;
        case DeviceConnectionState.connecting:
          _state = BleConnectionState.connecting;
          _connectionStateController.add(_state);
          break;
        case DeviceConnectionState.disconnecting:
          _state = BleConnectionState.disconnecting;
          _connectionStateController.add(_state);
          break;
      }
    }, onError: (err) {
      _state = BleConnectionState.disconnected;
      _connectionStateController.add(_state);
    });
  }

  Future<void> _subscribeToNotifications(String deviceId) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: txCharUuid,
      deviceId: deviceId,
    );

    _notifySub?.cancel();
    _parser.reset();
    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((chunk) {
      // Also inspect raw chunks for hardware ASCII character commands ('X', 'a', 'b', 'c', 'd')
      for (final byte in chunk) {
        final char = String.fromCharCode(byte);
        if (char == 'X' || char == 'a' || char == 'b' || char == 'c' || char == 'd') {
          _hardwareCommandController.add(char);
        }
      }

      final packets = _parser.processBytes(chunk);
      for (final pkt in packets) {
        _packetController.add(pkt);
      }
    });
  }

  void _cleanupSubscription() {
    _notifySub?.cancel();
    _notifySub = null;
    _parser.reset();
  }

  @override
  Future<void> disconnect() async {
    _state = BleConnectionState.disconnecting;
    _connectionStateController.add(_state);
    await _connSub?.cancel();
    _connSub = null;
    _cleanupSubscription();
    _state = BleConnectionState.disconnected;
    _connectionStateController.add(_state);
  }

  @override
  Future<bool> sendPacket(BlePacket packet) async {
    if (_state != BleConnectionState.connected || _connectedDeviceId == null) {
      return false;
    }

    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: rxCharUuid,
      deviceId: _connectedDeviceId!,
    );

    try {
      final data = packet.toBytes();
      await _ble.writeCharacteristicWithResponse(characteristic, value: data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
