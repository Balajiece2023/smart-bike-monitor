import 'dart:async';
import 'package:flutter/services.dart';
import 'ble_protocol.dart';
import 'ble_service.dart';

/// Bluetooth Classic SPP Service specifically tailored for HC-05 / HC-06 Bluetooth v2.0 modules.
/// Uses RFCOMM Serial Port Profile via Android Platform Channel.
class ClassicBluetoothService implements BleService {
  static const _channel = MethodChannel('com.example.smart_bike_app/bluetooth');

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _hardwareCommandController = StreamController<String>.broadcast();
  final BlePacketParser _parser = BlePacketParser();

  BleConnectionState _state = BleConnectionState.disconnected;
  String? _connectedAddress;

  String? get connectedAddress => _connectedAddress;

  ClassicBluetoothService() {
    _channel.setMethodCallHandler(_handlePlatformCalls);
  }

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

  Future<dynamic> _handlePlatformCalls(MethodCall call) async {
    switch (call.method) {
      case 'onClassicDataReceived':
        final rawData = call.arguments['data'];
        if (rawData != null) {
          final List<int> bytes = rawData is List<int> ? rawData : List<int>.from(rawData);
          _processIncomingBytes(bytes);
        }
        break;

      case 'onClassicStatusChanged':
        final status = call.arguments['status']?.toString();
        if (status == 'connected') {
          _state = BleConnectionState.connected;
          _connectionStateController.add(_state);
        } else if (status == 'disconnected') {
          _state = BleConnectionState.disconnected;
          _connectionStateController.add(_state);
          _connectedAddress = null;
        }
        break;
    }
  }

  void _processIncomingBytes(List<int> bytes) {
    // 1. Check for single-character hardware triggers commonly sent by HC-05 Arduino sketches
    // e.g. '1' (Accident), 'X' (Underage), 'a','b','c','d' (User slots)
    for (final b in bytes) {
      final char = String.fromCharCode(b);
      if (char == '1' || char == 'X' || char == 'a' || char == 'b' || char == 'c' || char == 'd') {
        _hardwareCommandController.add(char);
      }
    }

    // 2. Process framed BLE/SPP protocol packets
    final packets = _parser.processBytes(bytes);
    for (final pkt in packets) {
      _packetController.add(pkt);
    }
  }

  @override
  Future<void> startScan() async {
    _state = BleConnectionState.scanning;
    _connectionStateController.add(_state);
  }

  @override
  Future<void> stopScan() async {
    if (_state == BleConnectionState.scanning) {
      _state = BleConnectionState.disconnected;
      _connectionStateController.add(_state);
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    _state = BleConnectionState.connecting;
    _connectionStateController.add(_state);
    _connectedAddress = deviceId;

    try {
      final success = await _channel.invokeMethod<bool>('classicConnect', {
        'address': deviceId,
      });

      if (success == true) {
        _state = BleConnectionState.connected;
        _connectionStateController.add(_state);
      } else {
        _state = BleConnectionState.disconnected;
        _connectionStateController.add(_state);
        _connectedAddress = null;
      }
    } catch (e) {
      _state = BleConnectionState.disconnected;
      _connectionStateController.add(_state);
      _connectedAddress = null;
    }
  }

  @override
  Future<void> disconnect() async {
    _state = BleConnectionState.disconnecting;
    _connectionStateController.add(_state);

    try {
      await _channel.invokeMethod('classicDisconnect');
    } catch (_) {}

    _parser.reset();
    _state = BleConnectionState.disconnected;
    _connectionStateController.add(_state);
    _connectedAddress = null;
  }

  @override
  Future<bool> sendPacket(BlePacket packet) async {
    if (_state != BleConnectionState.connected) return false;

    try {
      final bytes = packet.toBytes();
      final success = await _channel.invokeMethod<bool>('classicSend', {
        'data': bytes,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Send raw ASCII commands to HC-05 (e.g. "LOCK\n", "1", "a", etc.)
  Future<bool> sendRawText(String text) async {
    if (_state != BleConnectionState.connected) return false;
    try {
      final success = await _channel.invokeMethod<bool>('classicSend', {
        'text': text,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
