import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class Interactive3dBikeView extends StatefulWidget {
  final bool isLocked;
  final Function(String partName, String details) onPartSelected;

  const Interactive3dBikeView({
    super.key,
    required this.isLocked,
    required this.onPartSelected,
  });

  @override
  State<Interactive3dBikeView> createState() => _Interactive3dBikeViewState();
}

class _Interactive3dBikeViewState extends State<Interactive3dBikeView>
    with SingleTickerProviderStateMixin {
  // 0: Profile View, 1: Dynamic 3/4 Front Angle
  int _activeViewIndex = 0;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  String _selectedPart = "Smart Lock Actuator";
  late AnimationController _pulseAnim;

  final List<Map<String, dynamic>> _parts = [
    {
      "name": "Smart Lock Actuator",
      "details": "Motorized dual-pin deadbolt locking the rear wheel hub",
      "icon": Icons.lock_outline,
      "relX": 0.82,
      "relY": 0.72,
    },
    {
      "name": "Battery BMS Pack",
      "details": "High-density Lithium-ion pack with thermal and overvoltage BMS",
      "icon": Icons.battery_charging_full,
      "relX": 0.46,
      "relY": 0.54,
    },
    {
      "name": "GPS / GNSS Tracker",
      "details": "Sub-meter satellite positioning with 4G LTE-M beacon telemetry",
      "icon": Icons.location_on_outlined,
      "relX": 0.35,
      "relY": 0.28,
    },
    {
      "name": "Biometric Handlebar",
      "details": "Instant capacitive fingerprint authorization scanner",
      "icon": Icons.fingerprint,
      "relX": 0.30,
      "relY": 0.16,
    },
    {
      "name": "Gyro & Tilt IMU",
      "details": "6-Axis high-frequency sensor detecting theft tilt and road crash events",
      "icon": Icons.screen_rotation,
      "relX": 0.58,
      "relY": 0.50,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    super.dispose();
  }

  void _selectPart(Map<String, dynamic> part) {
    setState(() {
      _selectedPart = part['name'] as String;
    });
    widget.onPartSelected(part['name'] as String, part['details'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final activePart = _parts.firstWhere(
      (p) => p['name'] == _selectedPart,
      orElse: () => _parts[0],
    );

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _tiltY = (_tiltY + details.delta.dx * 0.005).clamp(-0.15, 0.15);
          _tiltX = (_tiltX - details.delta.dy * 0.005).clamp(-0.10, 0.10);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _tiltX = 0.0;
          _tiltY = 0.0;
        });
      },
      child: Container(
        height: 310,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border.all(color: AppTheme.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle background ambient gradient
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFBFBFD),
                        Color(0xFFF1F3F5),
                      ],
                    ),
                  ),
                ),
              ),

              // Realtime Photorealistic 3D Bike Model with 3D Tilt perspective
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 45, top: 25),
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(_tiltX)
                          ..rotateY(_tiltY),
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // High-res Realistic 3D Bike Asset
                        Image.asset(
                          _activeViewIndex == 0
                              ? 'assets/images/bike_profile.jpg'
                              : 'assets/images/bike_front_angle.jpg',
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.two_wheeler, size: 80, color: AppTheme.textMuted),
                            );
                          },
                        ),

                        // Interactive Part Radar Hotspots overlay
                        if (_activeViewIndex == 0)
                          ..._parts.map((p) {
                            final isSelected = p['name'] == _selectedPart;
                            final xRatio = p['relX'] as double;
                            final yRatio = p['relY'] as double;

                            return Positioned(
                              left: (340 * xRatio) - 16,
                              top: (200 * yRatio) - 16,
                              child: GestureDetector(
                                onTap: () => _selectPart(p),
                                child: AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (context, _) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (isSelected)
                                          Container(
                                            width: 32 + (_pulseAnim.value * 8),
                                            height: 32 + (_pulseAnim.value * 8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: (widget.isLocked
                                                      ? AppTheme.accent
                                                      : AppTheme.success)
                                                  .withOpacity(0.25 - (_pulseAnim.value * 0.15)),
                                            ),
                                          ),
                                        Container(
                                          width: isSelected ? 22 : 16,
                                          height: isSelected ? 22 : 16,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? (widget.isLocked
                                                    ? AppTheme.accent
                                                    : AppTheme.success)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.primary,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 4,
                                              )
                                            ],
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Status Badge & View Mode Angle Switcher
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Model Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isLocked ? AppTheme.accent : AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            "REALTIME 3D BIKE MODEL",
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Angle Selector (Side Profile / 3/4 Front Angle)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          _buildAngleTab("Side", 0),
                          _buildAngleTab("Front 3/4", 1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Live selected component info card
              Positioned(
                top: 50,
                left: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(activePart['icon'] as IconData, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        activePart['name'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Horizontal Component Hotspots List
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _parts.map((p) {
                      final isSelected = p['name'] == _selectedPart;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => _selectPart(p),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : AppTheme.border,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  p['icon'] as IconData,
                                  size: 13,
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  p['name'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAngleTab(String label, int index) {
    final isSelected = _activeViewIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeViewIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
