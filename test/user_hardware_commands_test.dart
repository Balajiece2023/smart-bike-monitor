import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bike_app/domain/models/bike_models.dart';
import 'package:smart_bike_app/data/services/ble_service.dart';
import 'package:smart_bike_app/data/repositories/bike_repository_impl.dart';
import 'package:smart_bike_app/ui/features/bike/view_models/bike_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hardware Commands & User Management Tests', () {
    late MockBleService mockBle;
    late BikeRepositoryImpl repository;
    late BikeController controller;

    setUp(() {
      mockBle = MockBleService();
      repository = BikeRepositoryImpl(bleService: mockBle);
      controller = BikeController(repository: repository, disableAudio: true);
    });

    tearDown(() {
      controller.dispose();
      repository.disconnect();
    });

    test('Initial users are populated with default slots a, b, c, d', () {
      final state = controller.state;
      expect(state.users.length, greaterThanOrEqualTo(4));
      expect(state.activeUserSlot, 'a');
      expect(state.activeUser?.name, contains('Bala'));
      expect(state.activeUser?.isActive, isTrue);
    });

    test('Hardware commands a, b, c, d switch active user and mark others inactive', () {
      // Send hardware command 'b'
      controller.handleHardwareCommand('b');
      expect(controller.state.activeUserSlot, 'b');
      expect(controller.state.activeUser?.slotKey, 'b');
      expect(controller.state.activeUser?.name, contains('Karthik'));
      expect(controller.state.activeUser?.isActive, isTrue);

      // Verify slot 'a' is now inactive
      final userA = controller.state.users.firstWhere((u) => u.slotKey == 'a');
      expect(userA.isActive, isFalse);

      // Send hardware command 'c'
      controller.handleHardwareCommand('c');
      expect(controller.state.activeUserSlot, 'c');
      expect(controller.state.activeUser?.slotKey, 'c');
      expect(controller.state.activeUser?.isActive, isTrue);

      // Send hardware command 'd'
      controller.handleHardwareCommand('d');
      expect(controller.state.activeUserSlot, 'd');
      expect(controller.state.activeUser?.isActive, isTrue);
    });

    test('Hardware command X triggers unauthorized underage access alert & auto-lock', () {
      expect(controller.state.underageAlertActive, isFalse);

      // Send hardware command 'X'
      controller.handleHardwareCommand('X');

      expect(controller.state.underageAlertActive, isTrue);
      expect(controller.state.underageAlertMessage, contains('below 18 years'));

      // Dismiss alert
      controller.dismissUnderageAlert();
      expect(controller.state.underageAlertActive, isFalse);
    });

    test('Hardware command 1 triggers accident detection & fetches realtime location from admin geofencing', () {
      expect(controller.state.accidentAlertActive, isFalse);

      // Customize admin geofence coordinates
      controller.updateGeoFenceConfig(controller.state.geoFence.copyWith(
        centerLatitude: 13.0827,
        centerLongitude: 80.2707,
      ));

      // Send hardware command '1' (Accident detected)
      controller.handleHardwareCommand('1');

      expect(controller.state.accidentAlertActive, isTrue);
      // Verify realtime coordinates were synchronized with admin geofencing center
      expect(controller.state.gps.latitude, 13.0827);
      expect(controller.state.gps.longitude, 80.2707);

      // Dismiss accident alert
      controller.dismissAccidentAlert();
      expect(controller.state.accidentAlertActive, isFalse);
    });

    test('User details can be edited, saved, enabled, disabled, and added', () {
      // Edit User 'b'
      final userB = controller.state.users.firstWhere((u) => u.slotKey == 'b');
      final updatedB = userB.copyWith(
        name: 'Karthik Raja',
        age: 26,
        bloodGroup: 'O-',
        isBiometricEnabled: false,
      );
      controller.updateUser(updatedB);

      final fetchedB = controller.state.users.firstWhere((u) => u.slotKey == 'b');
      expect(fetchedB.name, 'Karthik Raja');
      expect(fetchedB.age, 26);
      expect(fetchedB.bloodGroup, 'O-');
      expect(fetchedB.isBiometricEnabled, isFalse);

      // Disable user 'b'
      controller.toggleUserEnabled('b', false);
      final disabledB = controller.state.users.firstWhere((u) => u.slotKey == 'b');
      expect(disabledB.isUserEnabled, isFalse);

      // Add a new user 'e'
      const newUser = RegisteredUser(
        slotKey: 'e',
        name: 'Guest Rider',
        dob: '2002-05-10',
        age: 24,
        bloodGroup: 'B+',
        aadharNumber: '1122 3344 5566',
        mobileNumber: '+91 99999 88888',
        emergencyNumber: '+91 94444 11223',
        isBiometricEnabled: true,
        isUserEnabled: true,
        isActive: false,
      );
      controller.addUser(newUser);

      expect(controller.state.users.any((u) => u.slotKey == 'e'), isTrue);
      final fetchedE = controller.state.users.firstWhere((u) => u.slotKey == 'e');
      expect(fetchedE.name, 'Guest Rider');
      expect(fetchedE.aadharNumber, '1122 3344 5566');
    });

    test('Each user has respective travel radius and switching users enforces radius', () {
      // Check default radii
      final userA = controller.state.users.firstWhere((u) => u.slotKey == 'a');
      final userD = controller.state.users.firstWhere((u) => u.slotKey == 'd');
      expect(userA.geoFenceRadiusKm, 15.0);
      expect(userD.geoFenceRadiusKm, 3.0);

      // Active is Bala (slot 'a') -> radius 15.0 km
      expect(controller.state.effectiveGeoFenceRadiusKm, 15.0);

      // Move bike to ~6 km away from center
      // Fence center: 12.9716, 77.5946. Moving lat by +0.054 is roughly 6 km
      controller.simulateBikeLocation(12.9716 + 0.054, 77.5946);

      // Bala has 15km limit -> not breached
      expect(controller.state.distanceToFenceCenterKm, greaterThan(5.0));
      expect(controller.state.distanceToFenceCenterKm, lessThan(8.0));
      expect(controller.state.isGeoFenceBreached, isFalse);

      // Switch to Dinesh (slot 'd') with 3.0 km limit
      controller.handleHardwareCommand('d');
      expect(controller.state.effectiveGeoFenceRadiusKm, 3.0);

      // Now at ~6 km, Dinesh's 3.0 km radius is breached!
      expect(controller.state.isGeoFenceBreached, isTrue);

      // Admin customizes Dinesh's radius to 10.0 km
      controller.updateUserRadius('d', 10.0);
      expect(controller.state.effectiveGeoFenceRadiusKm, 10.0);
      expect(controller.state.isGeoFenceBreached, isFalse);
    });
  });
}
