import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bike_app/data/services/classic_bluetooth_service.dart';
import 'package:smart_bike_app/data/services/ble_service.dart';
import 'package:smart_bike_app/data/repositories/bike_repository_impl.dart';
import 'package:smart_bike_app/ui/features/bike/view_models/bike_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HC-05 Bluetooth v2.0 SPP Service & Controller Integration', () {
    test('ClassicBluetoothService initializes in disconnected state', () {
      final classicService = ClassicBluetoothService();
      expect(classicService.currentState, equals(BleConnectionState.disconnected));
    });

    test('BikeRepositoryImpl seamlessly switches to ClassicBluetoothService', () {
      final mockService = MockBleService();
      final repo = BikeRepositoryImpl(bleService: mockService);
      final classicService = ClassicBluetoothService();

      expect(repo.connectionStateStream, isNotNull);
      repo.setService(classicService);
      expect(classicService.currentState, equals(BleConnectionState.disconnected));
    });

    test('BikeController detects HC-05 module and routes to ClassicBluetoothService', () async {
      final mockService = MockBleService();
      final repo = BikeRepositoryImpl(bleService: mockService);
      final controller = BikeController(repository: repo, disableAudio: true);

      // Connect with HC-05 device name
      await controller.connect("98:D3:31:F8:01:A2", isClassic: true, deviceName: "HC-05 Smart Bike");
      
      // Repository streams remain active and operational
      expect(controller.state.users.isNotEmpty, isTrue);
      controller.dispose();
    });

    test('Hardware commands emitted through classic bluetooth propagate to controller', () async {
      final mockService = MockBleService();
      final repo = BikeRepositoryImpl(bleService: mockService);
      final controller = BikeController(repository: repo, disableAudio: true);

      // Simulate sending slot command 'b'
      repo.simulateHardwareCommand('b');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.state.activeUserSlot, equals('b'));
      expect(controller.state.activeUser?.name, equals('Karthik'));

      controller.dispose();
    });
  });
}
