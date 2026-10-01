enum LockState { unlocked, locked, jammed, unknown }

enum AlarmState { disarmed, armed, triggered }

class BikeTelemetry {
  final LockState lockState;
  final int batteryMillivolts;
  final int batterySocPercentage;
  final double speedKmh;
  final int cadenceRpm;
  final double temperatureCelsius;
  final int lightState;
  final AlarmState alarmState;
  final int tripDistanceMeters;
  final double tiltAngleDegrees;
  final bool accidentDetected;

  const BikeTelemetry({
    required this.lockState,
    required this.batteryMillivolts,
    required this.batterySocPercentage,
    required this.speedKmh,
    required this.cadenceRpm,
    required this.temperatureCelsius,
    required this.lightState,
    required this.alarmState,
    required this.tripDistanceMeters,
    this.tiltAngleDegrees = 0.0,
    this.accidentDetected = false,
  });

  factory BikeTelemetry.initial() => const BikeTelemetry(
        lockState: LockState.locked,
        batteryMillivolts: 4200,
        batterySocPercentage: 92,
        speedKmh: 0.0,
        cadenceRpm: 0,
        temperatureCelsius: 24.5,
        lightState: 0,
        alarmState: AlarmState.armed,
        tripDistanceMeters: 22000,
        tiltAngleDegrees: 3.5,
        accidentDetected: false,
      );

  BikeTelemetry copyWith({
    LockState? lockState,
    int? batteryMillivolts,
    int? batterySocPercentage,
    double? speedKmh,
    int? cadenceRpm,
    double? temperatureCelsius,
    int? lightState,
    AlarmState? alarmState,
    int? tripDistanceMeters,
    double? tiltAngleDegrees,
    bool? accidentDetected,
  }) {
    return BikeTelemetry(
      lockState: lockState ?? this.lockState,
      batteryMillivolts: batteryMillivolts ?? this.batteryMillivolts,
      batterySocPercentage: batterySocPercentage ?? this.batterySocPercentage,
      speedKmh: speedKmh ?? this.speedKmh,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      lightState: lightState ?? this.lightState,
      alarmState: alarmState ?? this.alarmState,
      tripDistanceMeters: tripDistanceMeters ?? this.tripDistanceMeters,
      tiltAngleDegrees: tiltAngleDegrees ?? this.tiltAngleDegrees,
      accidentDetected: accidentDetected ?? this.accidentDetected,
    );
  }
}

class GpsData {
  final double latitude;
  final double longitude;
  final int altitudeMeters;
  final double speedKmh;
  final int satellites;
  final int fixQuality;
  final double hdop;

  const GpsData({
    required this.latitude,
    required this.longitude,
    required this.altitudeMeters,
    required this.speedKmh,
    required this.satellites,
    required this.fixQuality,
    required this.hdop,
  });

  factory GpsData.initial() => const GpsData(
        latitude: 37.774929,
        longitude: -122.419416,
        altitudeMeters: 15,
        speedKmh: 0.0,
        satellites: 8,
        fixQuality: 1,
        hdop: 1.2,
      );
}

enum FingerprintEventType {
  scanOk,
  scanFailed,
  enrollmentStep,
  enrollmentComplete,
  sensorError,
}

class FingerprintEvent {
  final FingerprintEventType type;
  final int slotId;
  final int confidenceScore;

  const FingerprintEvent({
    required this.type,
    required this.slotId,
    required this.confidenceScore,
  });
}

class TimeLogEntry {
  final String timestamp;
  final String event;
  final bool isAlert;

  const TimeLogEntry({
    required this.timestamp,
    required this.event,
    this.isAlert = false,
  });
}

class SimCommLog {
  final String timestamp;
  final bool isTx; // true: TX (App -> Bike), false: RX (Bike -> App)
  final String command; // e.g. "SET_LOCK(1)" or "HW_CMD('X')"
  final String hexData; // e.g. "53 4D 01 02 ..."
  final String status; // e.g. "SUCCESS", "ACK", "TRIGGERED"

  const SimCommLog({
    required this.timestamp,
    required this.isTx,
    required this.command,
    required this.hexData,
    this.status = "OK",
  });
}

class RegisteredUser {
  final String slotKey; // 'a', 'b', 'c', 'd'
  final String name;
  final String dob; // e.g. "2000-05-14"
  final int age;
  final String bloodGroup; // e.g. "O+", "A+", "B+", etc.
  final String aadharNumber; // e.g. "XXXX-XXXX-1234"
  final String mobileNumber; // e.g. "+91 9876543210"
  final String licenceNumber; // e.g. "DL-0420110012345"
  final String emergencyNumber; // e.g. "+91 9123456780"
  final bool isBiometricEnabled;
  final bool isUserEnabled;
  final bool isActive;
  final String role;
  final double geoFenceRadiusKm; // Allowed travel boundary radius for this specific user

  const RegisteredUser({
    required this.slotKey,
    required this.name,
    required this.dob,
    required this.age,
    required this.bloodGroup,
    required this.aadharNumber,
    this.licenceNumber = "TN-01-2019-0045612",
    required this.mobileNumber,
    required this.emergencyNumber,
    this.isBiometricEnabled = true,
    this.isUserEnabled = true,
    this.isActive = false,
    this.role = "Authorized Rider",
    this.geoFenceRadiusKm = 5.0,
  });

  RegisteredUser copyWith({
    String? slotKey,
    String? name,
    String? dob,
    int? age,
    String? bloodGroup,
    String? aadharNumber,
    String? licenceNumber,
    String? mobileNumber,
    String? emergencyNumber,
    bool? isBiometricEnabled,
    bool? isUserEnabled,
    bool? isActive,
    String? role,
    double? geoFenceRadiusKm,
  }) {
    return RegisteredUser(
      slotKey: slotKey ?? this.slotKey,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isUserEnabled: isUserEnabled ?? this.isUserEnabled,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      geoFenceRadiusKm: geoFenceRadiusKm ?? this.geoFenceRadiusKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'slotKey': slotKey,
        'name': name,
        'dob': dob,
        'age': age,
        'bloodGroup': bloodGroup,
        'aadharNumber': aadharNumber,
        'licenceNumber': licenceNumber,
        'mobileNumber': mobileNumber,
        'emergencyNumber': emergencyNumber,
        'isBiometricEnabled': isBiometricEnabled,
        'isUserEnabled': isUserEnabled,
        'isActive': isActive,
        'role': role,
        'geoFenceRadiusKm': geoFenceRadiusKm,
      };

  factory RegisteredUser.fromJson(Map<String, dynamic> json) => RegisteredUser(
        slotKey: json['slotKey'] as String? ?? 'a',
        name: json['name'] as String? ?? 'Rider',
        dob: json['dob'] as String? ?? '2000-01-01',
        age: json['age'] as int? ?? 24,
        bloodGroup: json['bloodGroup'] as String? ?? 'O+',
        aadharNumber: json['aadharNumber'] as String? ?? 'Pending',
        licenceNumber: json['licenceNumber'] as String? ?? 'TN-01-2019-0045612',
        mobileNumber: json['mobileNumber'] as String? ?? 'Not Provided',
        emergencyNumber: json['emergencyNumber'] as String? ?? '108',
        isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? true,
        isUserEnabled: json['isUserEnabled'] as bool? ?? true,
        isActive: json['isActive'] as bool? ?? false,
        role: json['role'] as String? ?? 'Authorized Rider',
        geoFenceRadiusKm: (json['geoFenceRadiusKm'] as num?)?.toDouble() ?? 5.0,
      );

  static List<RegisteredUser> defaultUsers() => [
        const RegisteredUser(
          slotKey: 'a',
          name: 'Bala (Primary Admin)',
          dob: '1998-04-12',
          age: 28,
          bloodGroup: 'O+',
          aadharNumber: '4589 1204 8832',
          licenceNumber: 'TN-02-1998-0012894',
          mobileNumber: '+91 98765 43210',
          emergencyNumber: '+91 94444 11223',
          isBiometricEnabled: true,
          isUserEnabled: true,
          isActive: true, // Slot 'a' is default active rider
          role: 'Admin / Owner',
          geoFenceRadiusKm: 15.0, // Admin has wide 15 KM travel radius
        ),
        const RegisteredUser(
          slotKey: 'b',
          name: 'Karthik',
          dob: '2001-08-20',
          age: 25,
          bloodGroup: 'A+',
          aadharNumber: '7823 4519 9012',
          licenceNumber: 'TN-07-2001-0087123',
          mobileNumber: '+91 98401 23456',
          emergencyNumber: '+91 98765 43210',
          isBiometricEnabled: true,
          isUserEnabled: true,
          isActive: false,
          role: 'Authorized Rider',
          geoFenceRadiusKm: 10.0, // 10 KM travel radius
        ),
        const RegisteredUser(
          slotKey: 'c',
          name: 'Suresh',
          dob: '1995-11-03',
          age: 30,
          bloodGroup: 'B+',
          aadharNumber: '6120 9945 3318',
          licenceNumber: 'KA-03-1995-0044567',
          mobileNumber: '+91 97910 88234',
          emergencyNumber: '+91 98765 43210',
          isBiometricEnabled: false,
          isUserEnabled: true,
          isActive: false,
          role: 'Family Member',
          geoFenceRadiusKm: 5.0, // 5 KM travel radius
        ),
        const RegisteredUser(
          slotKey: 'd',
          name: 'Dinesh',
          dob: '2003-02-17',
          age: 23,
          bloodGroup: 'AB+',
          aadharNumber: '9081 2234 5567',
          licenceNumber: 'DL-04-2003-0099812',
          mobileNumber: '+91 99620 11987',
          emergencyNumber: '+91 94444 11223',
          isBiometricEnabled: true,
          isUserEnabled: true,
          isActive: false,
          role: 'Authorized Rider',
          geoFenceRadiusKm: 3.0, // 3 KM restricted travel radius
        ),
      ];
}

class TripHistoryItem {
  final String day;
  final String drivingTime;
  final String distance;
  final List<List<double>> routeCoordinates;

  const TripHistoryItem({
    required this.day,
    required this.drivingTime,
    required this.distance,
    required this.routeCoordinates,
  });
}

class RenewalDetails {
  final String insuranceExpiry;
  final String insuranceProvider;
  final String licensePlate;
  final String licenseExpiry;
  final String serviceDueDate;
  final int serviceDueKm;

  const RenewalDetails({
    required this.insuranceExpiry,
    required this.insuranceProvider,
    required this.licensePlate,
    required this.licenseExpiry,
    required this.serviceDueDate,
    required this.serviceDueKm,
  });

  factory RenewalDetails.defaultDetails() => const RenewalDetails(
        insuranceExpiry: "2026-11-15",
        insuranceProvider: "CyberShield Comprehensive",
        licensePlate: "KA-04-EB-2026",
        licenseExpiry: "2030-03-02",
        serviceDueDate: "2026-10-10",
        serviceDueKm: 25000,
      );

  RenewalDetails copyWith({
    String? insuranceExpiry,
    String? insuranceProvider,
    String? licensePlate,
    String? licenseExpiry,
    String? serviceDueDate,
    int? serviceDueKm,
  }) {
    return RenewalDetails(
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      licensePlate: licensePlate ?? this.licensePlate,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      serviceDueDate: serviceDueDate ?? this.serviceDueDate,
      serviceDueKm: serviceDueKm ?? this.serviceDueKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'insuranceExpiry': insuranceExpiry,
        'insuranceProvider': insuranceProvider,
        'licensePlate': licensePlate,
        'licenseExpiry': licenseExpiry,
        'serviceDueDate': serviceDueDate,
        'serviceDueKm': serviceDueKm,
      };

  factory RenewalDetails.fromJson(Map<String, dynamic> json) => RenewalDetails(
        insuranceExpiry: json['insuranceExpiry'] as String? ?? "2026-11-15",
        insuranceProvider: json['insuranceProvider'] as String? ?? "CyberShield Comprehensive",
        licensePlate: json['licensePlate'] as String? ?? "KA-04-EB-2026",
        licenseExpiry: json['licenseExpiry'] as String? ?? "2030-03-02",
        serviceDueDate: json['serviceDueDate'] as String? ?? "2026-10-10",
        serviceDueKm: json['serviceDueKm'] as int? ?? 25000,
      );

  /// Check if insurance expiry date has passed
  bool isInsuranceOverdue([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final parsed = _tryParseDate(insuranceExpiry);
    if (parsed == null) return false;
    return now.isAfter(parsed);
  }

  /// Check if license expiry date has passed
  bool isLicenseOverdue([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final parsed = _tryParseDate(licenseExpiry);
    if (parsed == null) return false;
    return now.isAfter(parsed);
  }

  /// Check if service due date has passed or current KM exceeded
  bool isServiceOverdue(double currentOdoKm, [DateTime? referenceDate]) {
    if (currentOdoKm >= serviceDueKm && serviceDueKm > 0) return true;
    final now = referenceDate ?? DateTime.now();
    final parsed = _tryParseDate(serviceDueDate);
    if (parsed == null) return false;
    return now.isAfter(parsed);
  }

  /// Any renewal overdue check
  bool isAnyOverdue(double currentOdoKm) {
    return isInsuranceOverdue() || isLicenseOverdue() || isServiceOverdue(currentOdoKm);
  }

  static DateTime? _tryParseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr.trim());
    } catch (_) {
      // Try parsing formats like "15 Nov 2026" or "15-11-2026"
      try {
        final parts = dateStr.trim().split(RegExp(r'[\s\-\/]+'));
        if (parts.length == 3) {
          // Check if year is 3rd part
          int? y = int.tryParse(parts[2]);
          int? d = int.tryParse(parts[0]);
          if (y != null && d != null) {
            int m = _monthNameToNum(parts[1]) ?? int.tryParse(parts[1]) ?? 1;
            return DateTime(y, m, d);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static int? _monthNameToNum(String m) {
    final lower = m.toLowerCase();
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    for (int i = 0; i < months.length; i++) {
      if (lower.startsWith(months[i])) return i + 1;
    }
    return null;
  }
}

class GeoFenceConfig {
  final bool isEnabled;
  final String zoneName;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusKm;
  final bool restrictMotorWhenBreached;
  final bool alertAdmin;

  const GeoFenceConfig({
    required this.isEnabled,
    required this.zoneName,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    this.restrictMotorWhenBreached = true,
    this.alertAdmin = true,
  });

  factory GeoFenceConfig.defaultConfig() => const GeoFenceConfig(
        isEnabled: true,
        zoneName: "Authorized City Perimeter",
        centerLatitude: 12.9716, // Bangalore Central
        centerLongitude: 77.5946,
        radiusKm: 5.0, // 5 KM Allowed Radius
        restrictMotorWhenBreached: true,
        alertAdmin: true,
      );

  GeoFenceConfig copyWith({
    bool? isEnabled,
    String? zoneName,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusKm,
    bool? restrictMotorWhenBreached,
    bool? alertAdmin,
  }) {
    return GeoFenceConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      zoneName: zoneName ?? this.zoneName,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusKm: radiusKm ?? this.radiusKm,
      restrictMotorWhenBreached:
          restrictMotorWhenBreached ?? this.restrictMotorWhenBreached,
      alertAdmin: alertAdmin ?? this.alertAdmin,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'zoneName': zoneName,
        'centerLatitude': centerLatitude,
        'centerLongitude': centerLongitude,
        'radiusKm': radiusKm,
        'restrictMotorWhenBreached': restrictMotorWhenBreached,
        'alertAdmin': alertAdmin,
      };

  factory GeoFenceConfig.fromJson(Map<String, dynamic> json) => GeoFenceConfig(
        isEnabled: json['isEnabled'] as bool? ?? true,
        zoneName: json['zoneName'] as String? ?? "Authorized City Perimeter",
        centerLatitude: (json['centerLatitude'] as num?)?.toDouble() ?? 12.9716,
        centerLongitude: (json['centerLongitude'] as num?)?.toDouble() ?? 77.5946,
        radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 5.0,
        restrictMotorWhenBreached: json['restrictMotorWhenBreached'] as bool? ?? true,
        alertAdmin: json['alertAdmin'] as bool? ?? true,
      );
}
