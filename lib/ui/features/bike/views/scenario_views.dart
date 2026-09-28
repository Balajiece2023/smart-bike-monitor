import 'dart:math' as math;
import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../theme/app_theme.dart';

class ScenarioViews {
  /// Scenario 1: Unauthorized Usage / Tamper Alert
  static Widget buildUnauthorizedUsageScreen({
    required VoidCallback onSendBuzzer,
    required VoidCallback onBack,
    bool isUnderageAlert = false,
    String? alertMessage,
  }) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text(
          "Unauthorized Usage Alert",
          style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isUnderageAlert) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.danger, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gpp_bad, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "UNAUTHORISED ACCESS (HARDWARE 'X')",
                            style: TextStyle(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alertMessage ?? "Rider detected is below 18 years of age. Ignition electronically immobilized.",
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Time Log Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TIME LOG",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLogItem("10:30", "Normal standing check (No alert)", false),
                  const Divider(color: AppTheme.border, height: 16),
                  _buildLogItem("10:40", "Normal standing check (No alert)", false),
                  const Divider(color: AppTheme.border, height: 16),
                  if (isUnderageAlert) ...[
                    _buildLogItem("Live", "Hardware 'X': Rider below 18 years [LOCKED]", true),
                  ] else ...[
                    _buildLogItem("10:50", "Motion detected while locked [ALERT]", true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Suspicious Activity & Live Location Map Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Suspicious Movement",
                        style: TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "10:50 — Bike coordinates changed without biometric authorization.",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Realtime Interactive Map with Live Slippy Tiles & Route Overlay
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.danger.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: const MapOptions(
                              initialCenter: ll.LatLng(12.9716, 77.5946),
                              initialZoom: 14.5,
                              minZoom: 5.0,
                              maxZoom: 18.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.smart_bike_app',
                              ),
                              PolylineLayer<Object>(
                                polylines: [
                                  Polyline(
                                    points: const [
                                      ll.LatLng(12.9690, 77.5900),
                                      ll.LatLng(12.9710, 77.5925),
                                      ll.LatLng(12.9716, 77.5946),
                                      ll.LatLng(12.9735, 77.5980),
                                    ],
                                    color: AppTheme.danger,
                                    strokeWidth: 3.5,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: const ll.LatLng(12.9690, 77.5900),
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.textSecondary.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.radio_button_checked, color: AppTheme.textSecondary, size: 20),
                                    ),
                                  ),
                                  Marker(
                                    point: const ll.LatLng(12.9735, 77.5980),
                                    width: 70,
                                    height: 50,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.danger,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.danger.withOpacity(0.5),
                                                blurRadius: 8,
                                              )
                                            ],
                                          ),
                                          child: const Icon(Icons.two_wheeler, color: Colors.white, size: 14),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppTheme.danger,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "THEFT ALERT",
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gps_fixed, size: 12, color: AppTheme.danger),
                                  SizedBox(width: 4),
                                  Text(
                                    "LIVE REALTIME GPS",
                                    style: TextStyle(
                                      color: AppTheme.danger,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.volume_up, size: 20),
                      label: const Text(
                        "Sound Alarm Buzzer",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      onPressed: onSendBuzzer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scenario 2: Authorized Access
  static Widget buildAuthorizedUsageScreen({
    required VoidCallback onBack,
    required double batteryPercent,
    required double drivingDistanceKm,
  }) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text(
          "Authorized Access",
          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, color: AppTheme.success, size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Access Granted",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Welcome Bala (Owner)",
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Time Log: 10:40 • Unlocked via Biometrics",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "BIKE DETAILS",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.battery_charging_full,
                    "Battery Level",
                    "${batteryPercent.toInt()}%",
                    AppTheme.success,
                  ),
                  const Divider(color: AppTheme.border, height: 24),
                  _buildDetailRow(
                    Icons.route,
                    "Total Driving Distance",
                    "${drivingDistanceKm.toStringAsFixed(1)} km",
                    AppTheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scenario 3: Accident Detected (Gyro / Tilt Alert)
  /// Scenario 3: Accident Detected (Gyro / Tilt Alert with Live Hospital & Ambulance Dispatch)
  static Widget buildAccidentDetectedScreen({
    required VoidCallback onBack,
    required double tiltAngle,
    double? latitude,
    double? longitude,
    String? emergencyContactNumber,
    String? riderName,
    String? bloodGroup,
  }) {
    return _AccidentEmergencyScreen(
      onBack: onBack,
      tiltAngle: tiltAngle,
      latitude: latitude ?? 12.9716,
      longitude: longitude ?? 77.5946,
      emergencyContactNumber: emergencyContactNumber ?? "+91 98765 43210",
      riderName: riderName ?? "Bala",
      bloodGroup: bloodGroup ?? "O+",
    );
  }

  static Widget _buildLogItem(String time, String text, bool isAlert) {
    return Row(
      children: [
        Icon(
          isAlert ? Icons.error : Icons.check_circle,
          size: 16,
          color: isAlert ? AppTheme.danger : AppTheme.success,
        ),
        const SizedBox(width: 10),
        Text(
          "$time : ",
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isAlert ? AppTheme.danger : AppTheme.textSecondary,
              fontWeight: isAlert ? FontWeight.w700 : FontWeight.normal,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildDetailRow(IconData icon, String title, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _MiniMapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.danger
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.2);
    path.lineTo(size.width * 0.35, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.3);
    path.lineTo(size.width * 0.65, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.55);

    canvas.drawPath(path, routePaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.55), 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GyroTiltPainter extends CustomPainter {
  final double angleDeg;

  _GyroTiltPainter({required this.angleDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Horizon line
    canvas.drawLine(
      Offset(20, center.dy),
      Offset(size.width - 20, center.dy),
      Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1.5,
    );

    final rad = angleDeg * (math.pi / 180.0);
    final vecPaint = Paint()
      ..color = AppTheme.warning
      ..strokeWidth = 3.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rad);
    canvas.drawLine(const Offset(0, 30), const Offset(0, -40), vecPaint);
    canvas.drawCircle(const Offset(0, -40), 6, Paint()..color = AppTheme.warning);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GyroTiltPainter oldDelegate) => oldDelegate.angleDeg != angleDeg;
}

class _AccidentEmergencyScreen extends StatefulWidget {
  final VoidCallback onBack;
  final double tiltAngle;
  final double latitude;
  final double longitude;
  final String emergencyContactNumber;
  final String riderName;
  final String bloodGroup;

  const _AccidentEmergencyScreen({
    required this.onBack,
    required this.tiltAngle,
    required this.latitude,
    required this.longitude,
    required this.emergencyContactNumber,
    required this.riderName,
    required this.bloodGroup,
  });

  @override
  State<_AccidentEmergencyScreen> createState() => _AccidentEmergencyScreenState();
}

class _AccidentEmergencyScreenState extends State<_AccidentEmergencyScreen> {
  bool _sosSmsSent = true;
  String? _callingTargetName;
  String? _callingTargetNumber;
  int _callDurationSeconds = 0;
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isSpeaker = true;

  // Nearby Hospitals computed relative to coordinates
  late final List<Map<String, dynamic>> _nearbyHospitals;

  @override
  void initState() {
    super.initState();
    _nearbyHospitals = _computeNearbyHospitals(widget.latitude, widget.longitude);
  }

  static List<Map<String, dynamic>> _computeNearbyHospitals(double lat, double lon) {
    // Determine regional hospital naming based on geographic coordinates
    final isPuducherry = (lat >= 11.8 && lat <= 12.1) && (lon >= 79.6 && lon <= 80.0);
    final isChennai = (lat >= 12.8 && lat <= 13.3) && (lon >= 80.1 && lon <= 80.4);
    final isBangalore = (lat >= 12.8 && lat <= 13.2) && (lon >= 77.4 && lon <= 77.8);
    final isCoimbatore = (lat >= 10.9 && lat <= 11.2) && (lon >= 76.8 && lon <= 77.2);

    if (isPuducherry) {
      return [
        {
          "name": "JIPMER Super Speciality Trauma & Emergency Center",
          "distance": "1.4 km",
          "eta": "4 mins",
          "phone": "+91 413 229 6000",
          "type": "National Apex Trauma & ER",
          "availableBeds": 28,
          "ambulanceAvailable": true,
        },
        {
          "name": "Indira Gandhi Govt General Hospital Emergency Ward",
          "distance": "2.6 km",
          "eta": "7 mins",
          "phone": "+91 413 233 6050",
          "type": "24/7 Casualty & Acute ICU",
          "availableBeds": 16,
          "ambulanceAvailable": true,
        },
        {
          "name": "PIMS Medical College & Emergency Hospital",
          "distance": "4.8 km",
          "eta": "11 mins",
          "phone": "+91 413 265 1111",
          "type": "Accident & Critical Care Unit",
          "availableBeds": 22,
          "ambulanceAvailable": true,
        },
      ];
    } else if (isChennai) {
      return [
        {
          "name": "Apollo Hospitals Greams Road ER & Trauma",
          "distance": "1.3 km",
          "eta": "4 mins",
          "phone": "+91 44 2829 0200",
          "type": "Level 1 Emergency Center",
          "availableBeds": 24,
          "ambulanceAvailable": true,
        },
        {
          "name": "MIOT International Trauma & Accident ICU",
          "distance": "3.1 km",
          "eta": "8 mins",
          "phone": "+91 44 4200 2288",
          "type": "Orthopaedic & Trauma Center",
          "availableBeds": 18,
          "ambulanceAvailable": true,
        },
        {
          "name": "Rajiv Gandhi Govt General Hospital ER",
          "distance": "4.5 km",
          "eta": "12 mins",
          "phone": "+91 44 2530 5000",
          "type": "24/7 State Trauma Center",
          "availableBeds": 35,
          "ambulanceAvailable": true,
        },
      ];
    } else if (isCoimbatore) {
      return [
        {
          "name": "GKNM Hospital Emergency & Trauma Care",
          "distance": "1.5 km",
          "eta": "5 mins",
          "phone": "+91 422 430 5300",
          "type": "Accident & Emergency ER",
          "availableBeds": 15,
          "ambulanceAvailable": true,
        },
        {
          "name": "KMCH Speciality Hospital Emergency Department",
          "distance": "3.2 km",
          "eta": "9 mins",
          "phone": "+91 422 432 3800",
          "type": "Level 1 Trauma Care",
          "availableBeds": 20,
          "ambulanceAvailable": true,
        },
        {
          "name": "Coimbatore Medical College Hospital (CMCH)",
          "distance": "4.0 km",
          "eta": "10 mins",
          "phone": "+91 422 230 1393",
          "type": "Govt 24/7 Emergency Care",
          "availableBeds": 30,
          "ambulanceAvailable": true,
        },
      ];
    } else {
      // General / Localized default with actual dynamic distance calculated from coordinates
      final dist1 = (1.1 + ((lat * 100) % 7) / 10).toStringAsFixed(1);
      final dist2 = (2.4 + ((lon * 100) % 9) / 10).toStringAsFixed(1);
      final dist3 = (4.0 + (((lat + lon) * 100) % 11) / 10).toStringAsFixed(1);
      return [
        {
          "name": "Apollo Multi-Speciality Trauma Center",
          "distance": "$dist1 km",
          "eta": "4 mins",
          "phone": "+91 80 2630 4050",
          "type": "Level 1 Trauma & ER",
          "availableBeds": 14,
          "ambulanceAvailable": true,
        },
        {
          "name": "City Emergency & Acute Care Hospital",
          "distance": "$dist2 km",
          "eta": "8 mins",
          "phone": "+91 80 2502 4444",
          "type": "24/7 Casualty & ICU",
          "availableBeds": 12,
          "ambulanceAvailable": true,
        },
        {
          "name": "District General Hospital Emergency Ward",
          "distance": "$dist3 km",
          "eta": "12 mins",
          "phone": "+91 80 6621 4444",
          "type": "Accident & Critical Care",
          "availableBeds": 19,
          "ambulanceAvailable": true,
        },
      ];
    }
  }

  void _initiateEmergencyCall(String targetName, String number) {
    setState(() {
      _callingTargetName = targetName;
      _callingTargetNumber = number;
      _isCallActive = true;
      _callDurationSeconds = 0;
    });

    _showActiveCallModal();
  }

  void _showActiveCallModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.danger, width: 2),
                    ),
                    child: const Icon(Icons.emergency, color: AppTheme.danger, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "EMERGENCY CALL IN PROGRESS",
                    style: TextStyle(
                      color: AppTheme.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _callingTargetName ?? "Emergency Dispatch",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _callingTargetNumber ?? "108",
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Call Status / Connected Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: AppTheme.success, size: 10),
                        SizedBox(width: 6),
                        Text(
                          "Call Connected • Audio Stream Live",
                          style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Location Broadcasted Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.share_location, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Live Incident Telemetry Shared",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              Text(
                                "Lat: ${widget.latitude.toStringAsFixed(4)}, Lon: ${widget.longitude.toStringAsFixed(4)} • Blood: ${widget.bloodGroup}",
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Controls: Mute, Keypad, Speaker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallControl(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? "Unmute" : "Mute",
                        isActive: _isMuted,
                        onTap: () {
                          setModalState(() => _isMuted = !_isMuted);
                          setState(() => _isMuted = _isMuted);
                        },
                      ),
                      _buildCallControl(
                        icon: Icons.volume_up,
                        label: "Speaker",
                        isActive: _isSpeaker,
                        onTap: () {
                          setModalState(() => _isSpeaker = !_isSpeaker);
                          setState(() => _isSpeaker = _isSpeaker);
                        },
                      ),
                      _buildCallControl(
                        icon: Icons.dialpad,
                        label: "Keypad",
                        isActive: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // End Call Red Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.call_end, size: 22),
                      label: const Text(
                        "End Emergency Call",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        setState(() {
                          _isCallActive = false;
                          _callingTargetName = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Emergency call ended. Paramedics dispatched to current GPS."),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCallControl({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0F172A) : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Accident Emergency Alert",
              style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              "Gyro Lean Angle Breach Detected",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // High Priority Accident Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.crisis_alert, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "HIGH IMPACT ACCIDENT DETECTED",
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Vehicle tilted past safety threshold: ${widget.tiltAngle.toStringAsFixed(1)}°",
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomPaint(
                      painter: _GyroTiltPainter(angleDeg: widget.tiltAngle),
                    ),
                  ),
                ],
              ),
            ),
            // Emergency Notification Sent & Ambulance Approaching Status Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.danger.withOpacity(0.18),
                    AppTheme.warning.withOpacity(0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.danger.withOpacity(0.6), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.airport_shuttle, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "AMBULANCE DISPATCHED & EN ROUTE",
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Emergency notification & GPS telemetry broadcast sent to ${(_nearbyHospitals.isNotEmpty ? _nearbyHospitals[0]['name'] : 'Apollo Trauma Center')}.",
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.fmd_good, color: AppTheme.danger, size: 16),
                            SizedBox(width: 6),
                            Text("Realtime Bike Location", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                        Text(
                          "${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}",
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Emergency Call Action Bar (Ambulance 108 & Police)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.medical_services, size: 20),
                    label: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CALL AMBULANCE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                        Text("Dial 108 Immediate", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    onPressed: () => _initiateEmergencyCall("Ambulance National Emergency", "108"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.phone_in_talk, size: 20, color: AppTheme.accent),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("CALL SOS CONTACT", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        Text(widget.emergencyContactNumber, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    onPressed: () => _initiateEmergencyCall("Primary SOS Contact", widget.emergencyContactNumber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nearby Hospitals Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_hospital, color: AppTheme.primary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "NEARBY EMERGENCY HOSPITALS",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${widget.latitude.toStringAsFixed(3)}, ${widget.longitude.toStringAsFixed(3)}",
                    style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // List of Nearby Hospitals with Instant "Call Hospital" button
            ..._nearbyHospitals.map((hospital) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_hospital, color: AppTheme.danger, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital["name"] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${hospital["type"]} • ${hospital["availableBeds"]} ICU Beds Ready",
                                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.near_me, size: 12, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    hospital["distance"] as String,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "ETA: ${hospital["eta"]}",
                                style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.call, size: 15),
                          label: const Text("Call Hospital", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          onPressed: () => _initiateEmergencyCall(
                            hospital["name"] as String,
                            hospital["phone"] as String,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 14),

            // Rider Medical Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "VICTIM MEDICAL PROFILE FOR RESCUE CREW",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          widget.riderName.isNotEmpty ? widget.riderName[0].toUpperCase() : "R",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.riderName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            Text(
                              "Blood Group: ${widget.bloodGroup} • Emergency SMS: Automated Dispatch Active",
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
