import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'bike_renewal_screen.dart';

class SecondaryViews {
  /// Track History View
  static Widget buildTrackHistoryScreen({required VoidCallback onBack}) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text(
          "Usage History",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHistoryCard(
              day: "Tuesday",
              drivingTime: "45 mins",
              distance: "22 km",
              routeVariant: 1,
            ),
            const SizedBox(height: 16),
            _buildHistoryCard(
              day: "Wednesday",
              drivingTime: "25 mins",
              distance: "10 km",
              routeVariant: 2,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHistoryCard({
    required String day,
    required String drivingTime,
    required String distance,
    required int routeVariant,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  distance,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Duration: $drivingTime",
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/satellite_map.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _RouteLoopPainter(variant: routeVariant),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Google Maps Satellite",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Add User / Fingerprint Enrollment View
  static Widget buildAddUserScreen({
    required VoidCallback onBack,
    required VoidCallback onAddFingerprint,
  }) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text(
          "Manage Users & Access",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    "AUTHORIZED RIDERS",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildUserItem(1, "Bala (Owner)", "Slot 1 • Full Access Key"),
                  const Divider(color: AppTheme.border, height: 20),
                  _buildUserItem(2, "Family Member 1", "Slot 2 • Authorized Key"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add Fingerprint Button
            InkWell(
              onTap: onAddFingerprint,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.5), width: 1.5),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.fingerprint, color: AppTheme.accent, size: 40),
                    SizedBox(height: 10),
                    Text(
                      "+ Add New Biometric Fingerprint",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Touch the bike sensor on the handlebar to calibrate",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildUserItem(int id, String name, String subtitle) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.surfaceMuted,
          child: Text("$id", style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.fingerprint, color: AppTheme.success, size: 20),
      ],
    );
  }

  /// Bike Details / Insurance & Service Renewal View
  static Widget buildBikeRenewalDetailsScreen({required VoidCallback onBack}) {
    return BikeRenewalScreen(onBack: onBack);
  }
}

class _RouteLoopPainter extends CustomPainter {
  final int variant;

  _RouteLoopPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final c = Offset(size.width / 2, size.height / 2);

    if (variant == 1) {
      path.moveTo(c.dx - 80, c.dy - 30);
      path.cubicTo(c.dx - 40, c.dy - 50, c.dx, c.dy - 10, c.dx + 40, c.dy - 40);
      path.cubicTo(c.dx + 80, c.dy - 20, c.dx + 60, c.dy + 30, c.dx + 20, c.dy + 45);
      path.cubicTo(c.dx - 30, c.dy + 50, c.dx - 70, c.dy + 20, c.dx - 80, c.dy - 30);
    } else {
      path.addOval(Rect.fromCenter(center: c, width: 140, height: 70));
    }

    canvas.drawPath(path, routePaint);
    canvas.drawCircle(Offset(c.dx - 60, c.dy - 20), 4, Paint()..color = AppTheme.success);
    canvas.drawCircle(Offset(c.dx + 40, c.dy + 20), 4, Paint()..color = AppTheme.danger);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
