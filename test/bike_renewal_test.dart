import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bike_app/domain/models/bike_models.dart';
import 'package:smart_bike_app/data/repositories/bike_repository_impl.dart';
import 'package:smart_bike_app/data/services/ble_service.dart';
import 'package:smart_bike_app/ui/features/bike/view_models/bike_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bike Renewal Details & Overdue Notification Tests', () {
    late BikeRepository repository;
    late MockBleService mockBle;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockBle = MockBleService();
      repository = BikeRepositoryImpl(bleService: mockBle);
    });

    test('RenewalDetails overdue calculations work accurately', () {
      final details = RenewalDetails(
        insuranceExpiry: '2020-01-01', // Expired
        insuranceProvider: 'Test Ins',
        licensePlate: 'TN-01-AB-1234',
        licenseExpiry: '2030-01-01', // Valid
        serviceDueDate: '2020-05-01', // Expired
        serviceDueKm: 5000,
      );

      expect(details.isInsuranceOverdue(DateTime(2025, 1, 1)), isTrue);
      expect(details.isLicenseOverdue(DateTime(2025, 1, 1)), isFalse);
      expect(details.isServiceOverdue(6000, DateTime(2025, 1, 1)), isTrue);
      expect(details.isAnyOverdue(6000), isTrue);
    });

    test('BikeController updates and persists renewal details and flags overdue', () async {
      final controller = BikeController(repository: repository, disableAudio: true);

      expect(controller.state.renewal.licensePlate, isNotEmpty);

      final newDetails = RenewalDetails(
        insuranceExpiry: '2020-01-01', // Past date
        insuranceProvider: 'HDFC Ergo',
        licensePlate: 'KA-01-MJ-9999',
        licenseExpiry: '2035-12-31',
        serviceDueDate: '2020-01-01',
        serviceDueKm: 10000,
      );

      controller.updateRenewalDetails(newDetails);

      expect(controller.state.renewal.licensePlate, 'KA-01-MJ-9999');
      expect(controller.state.isRenewalOverdue, isTrue);

      controller.dispose();
    });
  });
}
