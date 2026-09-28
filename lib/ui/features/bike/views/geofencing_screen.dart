import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../theme/app_theme.dart';
import '../../../../domain/models/bike_models.dart';
import '../view_models/bike_controller.dart';

class GeoFencingScreen extends ConsumerStatefulWidget {
  const GeoFencingScreen({super.key});

  @override
  ConsumerState<GeoFencingScreen> createState() => _GeoFencingScreenState();
}

class _GeoFencingScreenState extends ConsumerState<GeoFencingScreen> {
  late TextEditingController _zoneNameController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late double _selectedRadiusKm;
  late bool _isEnabled;
  late bool _restrictMotor;
  late bool _alertAdmin;

  @override
  void initState() {
    super.initState();
    final config = ref.read(bikeControllerProvider).geoFence;
    _zoneNameController = TextEditingController(text: config.zoneName);
    _latController = TextEditingController(text: config.centerLatitude.toStringAsFixed(4));
    _lonController = TextEditingController(text: config.centerLongitude.toStringAsFixed(4));
    _selectedRadiusKm = config.radiusKm;
    _isEnabled = config.isEnabled;
    _restrictMotor = config.restrictMotorWhenBreached;
    _alertAdmin = config.alertAdmin;
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _saveConfig({bool showSnackbar = true}) {
    final lat = double.tryParse(_latController.text.trim()) ?? 12.9716;
    final lon = double.tryParse(_lonController.text.trim()) ?? 77.5946;

    final updated = GeoFenceConfig(
      isEnabled: _isEnabled,
      zoneName: _zoneNameController.text.trim().isEmpty
          ? "Authorized Zone"
          : _zoneNameController.text.trim(),
      centerLatitude: lat,
      centerLongitude: lon,
      radiusKm: _selectedRadiusKm,
      restrictMotorWhenBreached: _restrictMotor,
      alertAdmin: _alertAdmin,
    );

    ref.read(bikeControllerProvider.notifier).updateGeoFenceConfig(updated);

    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Admin Geo-Fence perimeter & restriction settings saved!"),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _useCurrentBikeGps() {
    final bikeGps = ref.read(bikeControllerProvider).gps;
    setState(() {
      _latController.text = bikeGps.latitude.toStringAsFixed(5);
      _lonController.text = bikeGps.longitude.toStringAsFixed(5);
    });
    _saveConfig();
  }

  void _simulateInside() {
    final lat = double.tryParse(_latController.text.trim()) ?? 12.9716;
    final lon = double.tryParse(_lonController.text.trim()) ?? 77.5946;
    // Offset by ~0.5 km
    ref.read(bikeControllerProvider.notifier).simulateBikeLocation(lat + 0.003, lon + 0.003);
  }

  void _simulateBreach() {
    final lat = double.tryParse(_latController.text.trim()) ?? 12.9716;
    final lon = double.tryParse(_lonController.text.trim()) ?? 77.5946;
    // Offset well beyond radius (e.g. + 0.1 deg lat is ~11 km)
    ref.read(bikeControllerProvider.notifier).simulateBikeLocation(lat + 0.09, lon + 0.09);
  }

  int _secretTapCount = 0;

  void _onSecretTitleTap() {
    _secretTapCount++;
    if (_secretTapCount >= 3) {
      _secretTapCount = 0;
      _showSecretLocationDialog();
    }
  }

  void _showSecretLocationDialog() {
    final bikeGps = ref.read(bikeControllerProvider).gps;
    final secretLatCtrl = TextEditingController(text: bikeGps.latitude.toStringAsFixed(5));
    final secretLonCtrl = TextEditingController(text: bikeGps.longitude.toStringAsFixed(5));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 10),
            Text(
              "Secret GPS Teleport",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ADMIN OVERRIDE: Manually spoof/teleport the live bike GPS coordinates anywhere on the globe.",
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: secretLatCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Bike Latitude",
                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secretLonCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Bike Longitude",
                prefixIcon: Icon(Icons.explore_outlined, size: 18),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "💡 Pro tip: You can also LONG-PRESS anywhere on the map to teleport the bike instantly!",
              style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newLat = double.tryParse(secretLatCtrl.text.trim()) ?? bikeGps.latitude;
              final newLon = double.tryParse(secretLonCtrl.text.trim()) ?? bikeGps.longitude;
              ref.read(bikeControllerProvider.notifier).simulateBikeLocation(newLat, newLon);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Bike teleported to $newLat, $newLon"),
                  backgroundColor: AppTheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Teleport Bike"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bikeState = ref.watch(bikeControllerProvider);
    final isBreached = bikeState.isGeoFenceBreached;
    final distKm = bikeState.distanceToFenceCenterKm;
    final activeRider = bikeState.activeUser;
    final activeRiderRadius = bikeState.effectiveGeoFenceRadiusKm;
    final allowedKm = activeRiderRadius;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onSecretTitleTap,
          child: const Text(
            "Admin Geo-Fencing",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, size: 20, color: AppTheme.textSecondary),
            tooltip: "Secret Location Override",
            onPressed: _showSecretLocationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primary),
            tooltip: "Save Configuration",
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Rider Geo-Fence Limit Card
            if (activeRider != null) ...[
              _buildActiveRiderRadiusCard(activeRider, activeRiderRadius),
              const SizedBox(height: 14),
            ],

            // 1. Live Geo-Fence Status Banner
            _buildLiveStatusCard(isBreached, distKm, allowedKm),
            const SizedBox(height: 16),

            // 2. Interactive Visual Radar Map Canvas
            _buildPerimeterRadarMap(bikeState, isBreached),
            const SizedBox(height: 16),

            // 3. Per-User Travel Radius Settings Card
            _buildPerUserRadiusManagerCard(bikeState),
            const SizedBox(height: 16),

            // 4. Admin Base Location & Global Radius Controls
            _buildAdminLocationCard(),
            const SizedBox(height: 16),

            // 5. Admin Security & Restriction Enforcement Toggles
            _buildEnforcementCard(),
            const SizedBox(height: 16),

            // 6. Simulation / Test Trigger Controls
            _buildSimulationTestingCard(isBreached),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRiderRadiusCard(RegisteredUser rider, double radiusKm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary,
            child: Text(
              rider.slotKey.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rider.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "ACTIVE RIDER",
                        style: TextStyle(color: AppTheme.success, fontSize: 8.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Assigned Travel Boundary: ${radiusKm.toStringAsFixed(1)} KM (Command '${rider.slotKey}')",
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${radiusKm.toStringAsFixed(1)} KM",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerUserRadiusManagerCard(BikeState state) {
    final controller = ref.read(bikeControllerProvider.notifier);
    final users = state.users;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "User Travel Radius Limits",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Text(
                "Respective Per-User",
                style: TextStyle(color: AppTheme.primary.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Configure distinct travel radius limits for each rider. When a user is chosen (or commanded by hardware a,b,c,d), their limit is applied immediately.",
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          ...users.map((u) {
            final isUserActive = u.slotKey == state.activeUserSlot;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUserActive ? AppTheme.primary.withOpacity(0.06) : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUserActive ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: isUserActive ? AppTheme.primary : Colors.grey.shade400,
                            child: Text(
                              u.slotKey.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            u.name,
                            style: TextStyle(
                              fontWeight: isUserActive ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUserActive ? AppTheme.primary : AppTheme.textMuted.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${u.geoFenceRadiusKm.toStringAsFixed(1)} KM",
                          style: TextStyle(
                            color: isUserActive ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: u.geoFenceRadiusKm,
                    min: 0.5,
                    max: 30.0,
                    divisions: 59,
                    activeColor: isUserActive ? AppTheme.primary : AppTheme.textMuted,
                    label: "${u.geoFenceRadiusKm.toStringAsFixed(1)} KM",
                    onChanged: (val) {
                      controller.updateUser(u.copyWith(geoFenceRadiusKm: val));
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLiveStatusCard(bool isBreached, double currentDist, double maxRadius) {
    final color = isBreached ? AppTheme.accent : AppTheme.success;
    final statusText = !_isEnabled
        ? "GEO-FENCING DISABLED"
        : (isBreached ? "PERIMETER BREACH DETECTED!" : "INSIDE AUTHORIZED ZONE");
    final subtitle = !_isEnabled
        ? "Admin has turned off zone boundaries."
        : (isBreached
            ? "Bike is ${currentDist.toStringAsFixed(2)} km from center (Limit: ${maxRadius.toStringAsFixed(1)} km). Motor lock enforced."
            : "Bike is ${currentDist.toStringAsFixed(2)} km from center within allowable ${maxRadius.toStringAsFixed(1)} km boundary.");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBreached ? AppTheme.accent.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBreached ? AppTheme.accent : AppTheme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBreached ? Icons.warning_amber_rounded : Icons.shield_outlined,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _mapLayerType = 0; // 0: Google Satellite Map, 1: Vector Clean Grid

  Widget _buildPerimeterRadarMap(BikeState state, bool isBreached) {
    final centerLat = double.tryParse(_latController.text.trim()) ?? 12.9716;
    final centerLon = double.tryParse(_lonController.text.trim()) ?? 77.5946;
    final centerPoint = ll.LatLng(centerLat, centerLon);
    final bikePoint = ll.LatLng(state.gps.latitude, state.gps.longitude);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBreached ? AppTheme.accent : AppTheme.border,
          width: isBreached ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Interactive Realtime Map with Live Slippy Tiles
            FlutterMap(
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onLongPress: (tapPosition, point) {
                  ref.read(bikeControllerProvider.notifier).simulateBikeLocation(
                        point.latitude,
                        point.longitude,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text("⚡ Bike teleported to (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})"),
                        ],
                      ),
                      backgroundColor: AppTheme.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smart_bike_app',
                ),

                // Geo-Fence Circle & Vector Line
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: centerPoint,
                      radius: state.effectiveGeoFenceRadiusKm * 1000, // in meters for active rider
                      useRadiusInMeter: true,
                      color: (isBreached ? AppTheme.accent : const Color(0xFF06B6D4))
                          .withOpacity(0.18),
                      borderColor:
                          isBreached ? AppTheme.accent : const Color(0xFF06B6D4),
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),

                // Polyline connecting Center to Bike
                PolylineLayer<Object>(
                  polylines: [
                    Polyline(
                      points: [centerPoint, bikePoint],
                      color: isBreached ? AppTheme.accent : AppTheme.primary,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),

                // Markers (Admin Center & Live Bike)
                MarkerLayer(
                  markers: [
                    // Admin Center Base Marker
                    Marker(
                      point: centerPoint,
                      width: 70,
                      height: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.4),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                            child: const Icon(Icons.home, color: Colors.white, size: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Text(
                              "Base",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Live Bike Position Marker
                    Marker(
                      point: bikePoint,
                      width: 80,
                      height: 55,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isBreached ? AppTheme.accent : AppTheme.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isBreached ? AppTheme.accent : AppTheme.success)
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.two_wheeler,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isBreached ? AppTheme.accent : AppTheme.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isBreached ? "BREACH!" : "BIKE",
                              style: const TextStyle(
                                fontSize: 9,
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

            // Top-left: Radius & Live Status Badge
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isBreached ? AppTheme.accent : AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Boundary: ${_selectedRadiusKm.toStringAsFixed(1)} KM Radius",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            // Top-right: Realtime GPS Live Indicator
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 12, color: AppTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      "Realtime Map",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-right: Live bike distance badge
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isBreached ? AppTheme.accent : AppTheme.success,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isBreached ? AppTheme.accent : AppTheme.success)
                          .withOpacity(0.4),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.two_wheeler, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      "${state.distanceToFenceCenterKm.toStringAsFixed(2)} KM from base",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildMapTypeButton(String label, int index) {
    final isSelected = _mapLayerType == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mapLayerType = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Admin Restricted Perimeter",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _useCurrentBikeGps,
                icon: const Icon(Icons.my_location, size: 14),
                label: const Text("Use Bike GPS", style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Zone Name
          TextField(
            controller: _zoneNameController,
            decoration: const InputDecoration(
              labelText: "Restricted Zone Label",
              hintText: "e.g. Campus Boundary, City Limits",
              prefixIcon: Icon(Icons.label_outline, size: 18),
              isDense: true,
            ),
            onChanged: (_) => _saveConfig(showSnackbar: false),
          ),
          const SizedBox(height: 12),

          // Coordinates inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Center Latitude",
                    prefixIcon: Icon(Icons.navigation_outlined, size: 18),
                    isDense: true,
                  ),
                  onChanged: (_) => _saveConfig(showSnackbar: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Center Longitude",
                    prefixIcon: Icon(Icons.explore_outlined, size: 18),
                    isDense: true,
                  ),
                  onChanged: (_) => _saveConfig(showSnackbar: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Radius Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Allowed Fencing Radius (KM)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_selectedRadiusKm.toStringAsFixed(1)} KM",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _selectedRadiusKm,
            min: 0.5,
            max: 30.0,
            divisions: 59,
            activeColor: AppTheme.primary,
            label: "${_selectedRadiusKm.toStringAsFixed(1)} KM",
            onChanged: (val) {
              setState(() {
                _selectedRadiusKm = val;
              });
              _saveConfig(showSnackbar: false);
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0.5 KM (Campus)", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text("15 KM (Metro)", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text("30 KM (Suburbs)", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnforcementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "User Restriction & Security Enforcement",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Master Enable Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Enable Geo-Fence Enforcement", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text("Actively tracks distance against admin perimeter", style: TextStyle(fontSize: 11)),
            value: _isEnabled,
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() {
                _isEnabled = val;
              });
              _saveConfig(showSnackbar: false);
            },
          ),
          const Divider(height: 1),

          // Restrict Motor Lock Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Auto-Lock / Restrict User Motor", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text("Locks bike & cuts motor if user breaches designated KM", style: TextStyle(fontSize: 11)),
            value: _restrictMotor,
            activeColor: AppTheme.accent,
            onChanged: (val) {
              setState(() {
                _restrictMotor = val;
              });
              _saveConfig(showSnackbar: false);
            },
          ),
          const Divider(height: 1),

          // Admin Alert Notification
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Admin Immediate Alert", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text("Sends high-priority breach telemetry warning", style: TextStyle(fontSize: 11)),
            value: _alertAdmin,
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() {
                _alertAdmin = val;
              });
              _saveConfig(showSnackbar: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationTestingCard(bool isBreached) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                "Live Testing & Simulation",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Test how the app and bike controller react when the rider moves inside vs outside the admin boundary.",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceMuted,
                    foregroundColor: AppTheme.success,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.success),
                  ),
                  onPressed: _simulateInside,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text("Simulate Inside", style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: _simulateBreach,
                  icon: const Icon(Icons.report_problem_outlined, size: 16),
                  label: const Text("Simulate Breach", style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeoFenceRadarPainter extends CustomPainter {
  final double radiusKm;
  final double distToCenterKm;
  final bool isBreached;
  final bool isSatelliteMap;

  _GeoFenceRadarPainter({
    required this.radiusKm,
    required this.distToCenterKm,
    required this.isBreached,
    this.isSatelliteMap = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background grid circles
    final gridColor = isSatelliteMap
        ? Colors.white.withOpacity(0.18)
        : const Color(0xFFE2E8F0);

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 35, gridPaint);
    canvas.drawCircle(center, 60, gridPaint);
    canvas.drawCircle(center, 85, gridPaint);

    // Permitted perimeter boundary circle
    final perimeterPaint = Paint()
      ..color = (isBreached ? AppTheme.accent : const Color(0xFF06B6D4))
          .withOpacity(isSatelliteMap ? 0.22 : 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 70, perimeterPaint);

    final perimeterStroke = Paint()
      ..color = isBreached ? AppTheme.accent : const Color(0xFF06B6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 70, perimeterStroke);

    // Compute bike marker relative offset
    // 70 px represents the radiusKm
    final scale = 70.0 / (radiusKm > 0 ? radiusKm : 1.0);
    final bikePxDist = (distToCenterKm * scale).clamp(0.0, size.width / 2 - 20);

    // Position bike at 45 degree angle for visualization
    const angle = 0.8;
    final bikePos = Offset(
      center.dx + (bikePxDist * math.cos(angle)),
      center.dy + (bikePxDist * math.sin(angle)),
    );

    // Line connecting center to bike
    final linePaint = Paint()
      ..color = (isBreached ? AppTheme.accent : Colors.white).withOpacity(0.7)
      ..strokeWidth = 1.8;
    canvas.drawLine(center, bikePos, linePaint);

    // Bike pulse marker
    final bikeColor = isBreached ? AppTheme.accent : AppTheme.success;
    final bikeGlow = Paint()
      ..color = bikeColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bikePos, 14, bikeGlow);

    final bikePaint = Paint()
      ..color = bikeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bikePos, 7, bikePaint);

    final bikeInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bikePos, 3, bikeInner);
  }

  @override
  bool shouldRepaint(covariant _GeoFenceRadarPainter oldDelegate) {
    return oldDelegate.radiusKm != radiusKm ||
        oldDelegate.distToCenterKm != distToCenterKm ||
        oldDelegate.isBreached != isBreached ||
        oldDelegate.isSatelliteMap != isSatelliteMap;
  }
}
