import 'dart:typed_data';

/// CRC-16-CCITT implementation for Smart Bike BLE Framing Protocol.
/// Polynomial: 0x1021, Init: 0xFFFF, RefIn: false, RefOut: false, XorOut: 0x0000.
class Crc16Ccitt {
  static const int polynomial = 0x1021;
  static const int initialValue = 0xFFFF;

  static int compute(List<int> bytes) {
    int crc = initialValue;
    for (final byte in bytes) {
      crc ^= (byte & 0xFF) << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ polynomial) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }
}

/// Commands and Response identifiers for the protocol
class BleCommandId {
  static const int cmdPing = 0x01;
  static const int cmdGetStatus = 0x02;
  static const int cmdLockControl = 0x10;
  static const int cmdAlarmControl = 0x11;
  static const int cmdFingerprintEnroll = 0x20;
  static const int cmdFingerprintDelete = 0x21;
  static const int cmdGpsConfig = 0x30;

  static const int rspAck = 0x80;
  static const int rspNack = 0x81;
  static const int notifTelemetry = 0x90;
  static const int notifGpsUpdate = 0x91;
  static const int notifFingerprintEvent = 0x92;
  static const int notifAlarmTriggered = 0x93;
}

/// Packet Frame representation
class BlePacket {
  final int sequenceId;
  final int commandId;
  final Uint8List payload;

  BlePacket({
    required this.sequenceId,
    required this.commandId,
    required this.payload,
  });

  static const int sof1 = 0xAA;
  static const int sof2 = 0x55;

  /// Serializes packet to raw byte frame: [SOF1, SOF2, Seq, Cmd, Len_H, Len_L, Payload..., CRC_H, CRC_L]
  Uint8List toBytes() {
    final len = payload.length;
    final buffer = BytesBuilder();

    // Body over which CRC is calculated
    final crcBody = BytesBuilder();
    crcBody.addByte(sequenceId & 0xFF);
    crcBody.addByte(commandId & 0xFF);
    crcBody.addByte((len >> 8) & 0xFF);
    crcBody.addByte(len & 0xFF);
    crcBody.add(payload);

    final crc = Crc16Ccitt.compute(crcBody.toBytes());

    // Complete packet
    buffer.addByte(sof1);
    buffer.addByte(sof2);
    buffer.add(crcBody.toBytes());
    buffer.addByte((crc >> 8) & 0xFF);
    buffer.addByte(crc & 0xFF);

    return buffer.toBytes();
  }
}

/// State-machine stream parser to handle chunked/fragmented BLE packets
class BlePacketParser {
  final List<int> _rxBuffer = [];

  List<BlePacket> processBytes(List<int> chunk) {
    _rxBuffer.addAll(chunk);
    final List<BlePacket> decodedPackets = [];

    while (_rxBuffer.length >= 8) {
      // Find start of frame
      if (_rxBuffer[0] != BlePacket.sof1 || _rxBuffer[1] != BlePacket.sof2) {
        _rxBuffer.removeAt(0);
        continue;
      }

      // Check if header is available
      final payloadLen = (_rxBuffer[4] << 8) | _rxBuffer[5];
      final totalPacketLen = 2 + 4 + payloadLen + 2; // SOF(2) + [Seq,Cmd,Len(2)] + Payload + CRC(2)

      if (_rxBuffer.length < totalPacketLen) {
        // Need more data from BLE MTU chunks
        break;
      }

      // Extract packet slice
      final packetData = _rxBuffer.sublist(0, totalPacketLen);
      final sequenceId = packetData[2];
      final commandId = packetData[3];
      final payload = Uint8List.fromList(packetData.sublist(6, 6 + payloadLen));
      final receivedCrc = (packetData[totalPacketLen - 2] << 8) | packetData[totalPacketLen - 1];

      // Validate CRC
      final crcBody = packetData.sublist(2, totalPacketLen - 2);
      final calculatedCrc = Crc16Ccitt.compute(crcBody);

      if (receivedCrc == calculatedCrc) {
        decodedPackets.add(BlePacket(
          sequenceId: sequenceId,
          commandId: commandId,
          payload: payload,
        ));
      }

      // Remove processed packet from buffer
      _rxBuffer.removeRange(0, totalPacketLen);
    }

    return decodedPackets;
  }

  void reset() {
    _rxBuffer.clear();
  }
}
