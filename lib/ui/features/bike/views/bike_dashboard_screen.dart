import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../view_models/bike_controller.dart';
import '../../../../data/services/ble_service.dart';
import '../../../../domain/models/bike_models.dart';
import 'interactive_3d_bike_view.dart';
import 'scenario_views.dart';
import 'secondary_views.dart';
import 'device_pairing_screen.dart';
import 'geofencing_screen.dart';
import 'user_management_screen.dart';
import 'settings_screen.dart';

class BikeDashboardScreen extends ConsumerStatefulWidget {
  const BikeDashboardScreen({super.key});

  @override
  ConsumerState<BikeDashboardScreen> createState() => _BikeDashboardScreenState();
}

class _BikeDashboardScreenState extends ConsumerState<BikeDashboardScreen> {
  String _selectedPartName = "Smart Lock";
  String _selectedPartDetails = "Electronic motor actuator locking the rear wheel hub.";

  @override
  Widget build(BuildContext context) {
    final bikeState = ref.watch(bikeControllerProvider);
    final controller = ref.read(bikeControllerProvider.notifier);

    final isConnected = bikeState.connectionState == BleConnectionState.connected;
    final isLocked = bikeState.telemetry.lockState == LockState.locked;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Smart Bike Monitor",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isConnected ? AppTheme.success : AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isConnected ? "Connected • Apex One" : "Offline",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Connection status chip
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.success.withOpacity(0.08)
                  : AppTheme.textMuted.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isConnected ? "Active" : "Disconnected",
              style: TextStyle(
                color: isConnected ? AppTheme.success : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildCleanDrawer(context, controller, isConnected, bikeState),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 3D Interactive Rotating Wireframe Model
            Interactive3dBikeView(
              isLocked: isLocked,
              onPartSelected: (name, details) {
                setState(() {
                  _selectedPartName = name;
                  _selectedPartDetails = details;
                });
              },
            ),
            const SizedBox(height: 12),

            // Part highlight card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$_selectedPartName — $_selectedPartDetails",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Accident Detected Alert Notification Banner with Siren & Hospital Dispatch
            if (bikeState.accidentAlertActive) ...[
              _buildAccidentAlertBanner(context, controller, bikeState),
              const SizedBox(height: 14),
            ],

            // Underage Unauthorised Alert Notification Banner with Sound
            if (bikeState.underageAlertActive) ...[
              _buildUnderageAlertBanner(context, controller, bikeState.underageAlertMessage),
              const SizedBox(height: 14),
            ],

            // Active Rider Bar
            _buildActiveUserDashboardCard(context, bikeState),
            const SizedBox(height: 14),

            // 2. Main Lock / Unlock Minimalist Control Card
            _buildLockCard(isLocked, isConnected, bikeState, controller),
            const SizedBox(height: 16),

            // Geo-Fencing Live Perimeter Alert / Status Card
            _buildGeoFenceDashboardBanner(context, bikeState),
            const SizedBox(height: 16),

            // 3. Clean Metric Numbers (Speed, Battery, Range)
            _buildTelemetryGrid(bikeState),
            const SizedBox(height: 16),

            // 4. Quick Scenario Jump Navigation Cards
            _buildScenariosSection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Clean slide-out Menu Bar without mentioning (i), (ii), etc.
  Widget _buildCleanDrawer(
    BuildContext context,
    BikeController controller,
    bool isConnected,
    BikeState state,
  ) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Smart Bike Monitor",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isConnected ? "Bike Connected" : "No Active Link",
                        style: TextStyle(
                          color: isConnected ? AppTheme.success : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),

            // Clean Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerTile(
                    icon: Icons.bluetooth,
                    title: "Connect to Bike",
                    subtitle: isConnected ? "Tap to disconnect" : "Pair a new device",
                    onTap: () {
                      Navigator.pop(context);
                      if (isConnected) {
                        controller.disconnect();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DevicePairingScreen()),
                        );
                      }
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.person_add_alt_1,
                    title: "Add User",
                    subtitle: "Register new rider details & permissions",
                    onTap: () {
                      Navigator.pop(context);
                      UserManagementScreen.openUserEditor(context, controller, null);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.manage_accounts_outlined,
                    title: "User Management",
                    subtitle: "All rider profiles, Aadhaar & permissions",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.history,
                    title: "Usage History",
                    subtitle: "Driving time & route traces",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SecondaryViews.buildTrackHistoryScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.share_location_outlined,
                    title: "Admin Geo-Fencing",
                    subtitle: "Set allowed location & radius KM limits",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GeoFencingScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.verified_outlined,
                    title: "Bike Details",
                    subtitle: "Insurance & service schedule",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SecondaryViews.buildBikeRenewalDetailsScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    subtitle: "Preferences & Factory Reset",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom disconnect / close
            Padding(
              padding: const EdgeInsets.all(20),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  foregroundColor: AppTheme.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close Menu"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLockCard(
    bool isLocked,
    bool isConnected,
    BikeState state,
    BikeController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLocked ? AppTheme.border : AppTheme.success.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: (isConnected && !state.isOperationInProgress)
              ? () => controller.toggleLock()
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? AppTheme.primary.withOpacity(0.06)
                        : AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline : Icons.lock_open,
                    color: isLocked ? AppTheme.primary : AppTheme.success,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLocked ? "Bike is Locked" : "Bike is Unlocked",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLocked ? "Tap to unlock electronic deadbolt" : "Tap to secure motorized lock",
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isOperationInProgress)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccidentAlertBanner(BuildContext context, BikeController controller, BikeState state) {
    final activeRider = state.activeUser;
    final lat = state.geoFence.centerLatitude;
    final lon = state.geoFence.centerLongitude;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger, width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.crisis_alert, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          "ACCIDENT DETECTED (CMD '1')",
                          style: TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.volume_up, color: AppTheme.danger, size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Realtime bike location locked: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}\nNotification sent to nearby hospital & ambulance arriving!",
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Dismiss Alert",
                icon: const Icon(Icons.close, color: AppTheme.danger, size: 18),
                onPressed: () => controller.dismissAccidentAlert(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.local_hospital, size: 16),
                  label: const Text("View Nearby Hospitals & Ambulance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScenarioViews.buildAccidentDetectedScreen(
                          onBack: () => Navigator.pop(context),
                          tiltAngle: 72.0,
                          latitude: lat,
                          longitude: lon,
                          emergencyContactNumber: activeRider?.emergencyNumber ?? "+91 94444 11223",
                          riderName: activeRider?.name ?? "Bala",
                          bloodGroup: activeRider?.bloodGroup ?? "O+",
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnderageAlertBanner(BuildContext context, BikeController controller, String? message) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      "UNAUTHORISED ACCESS",
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.volume_up, color: AppTheme.danger, size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message ?? "User is below 18 years. Bike locked.",
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Dismiss Alert",
            icon: const Icon(Icons.close, color: AppTheme.danger, size: 18),
            onPressed: () => controller.dismissUnderageAlert(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUserDashboardCard(BuildContext context, BikeState state) {
    final activeUser = state.activeUser;
    final slotKey = state.activeUserSlot.toUpperCase();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserManagementScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: Text(
                slotKey,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
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
                        activeUser != null ? activeUser.name : "Active Rider: Slot $slotKey",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "ACTIVE RIDER",
                          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 8.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeUser != null
                        ? "Blood: ${activeUser.bloodGroup} • Age: ${activeUser.age} • Hardware [Cmd '${state.activeUserSlot}']"
                        : "Tap to manage users & hardware commands",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildGeoFenceDashboardBanner(BuildContext context, BikeState state) {
    final fence = state.geoFence;
    final isBreached = state.isGeoFenceBreached;
    final dist = state.distanceToFenceCenterKm;
    final radius = fence.radiusKm;

    final bannerColor = !fence.isEnabled
        ? AppTheme.textMuted
        : (isBreached ? AppTheme.accent : AppTheme.success);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GeoFencingScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isBreached ? AppTheme.accent.withOpacity(0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBreached ? AppTheme.accent : AppTheme.border,
            width: isBreached ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bannerColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBreached ? Icons.warning_amber_rounded : Icons.share_location,
                color: bannerColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        !fence.isEnabled
                            ? "Geo-Fencing Inactive"
                            : (isBreached ? "RESTRICTED ZONE BREACH" : "Admin Perimeter Active"),
                        style: TextStyle(
                          color: bannerColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: bannerColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${radius.toStringAsFixed(1)} KM Limit",
                          style: TextStyle(
                            color: bannerColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !fence.isEnabled
                        ? "Tap to configure admin perimeter boundaries"
                        : (isBreached
                            ? "Rider exceeded ${radius.toStringAsFixed(1)} km limit (${dist.toStringAsFixed(2)} km). Motor restricted."
                            : "${dist.toStringAsFixed(2)} km from base • Allowed: ${fence.zoneName}"),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.tune, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGrid(BikeState state) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: "SPEED",
            value: state.telemetry.speedKmh.toStringAsFixed(1),
            unit: "km/h",
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            label: "BATTERY",
            value: "${state.telemetry.batterySocPercentage}",
            unit: "%",
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            label: "TRIP",
            value: (state.telemetry.tripDistanceMeters / 1000.0).toStringAsFixed(0),
            unit: "km",
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenariosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SAFETY & MONITORING SCENARIOS",
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildScenarioCard(
                title: "Unauthorized\nUsage",
                subtitle: "Tamper & map",
                icon: Icons.shield_outlined,
                color: AppTheme.danger,
                onTap: () {
                  final state = ref.read(bikeControllerProvider);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScenarioViews.buildUnauthorizedUsageScreen(
                        isUnderageAlert: state.underageAlertActive,
                        alertMessage: state.underageAlertMessage,
                        onSendBuzzer: () {
                          ref.read(bikeControllerProvider.notifier).triggerAlarm();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Buzzer siren activated!"),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        },
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildScenarioCard(
                title: "Authorised\nAccess",
                subtitle: "Owner verify",
                icon: Icons.verified_user_outlined,
                color: AppTheme.success,
                onTap: () {
                  final state = ref.read(bikeControllerProvider);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScenarioViews.buildAuthorizedUsageScreen(
                        onBack: () => Navigator.pop(context),
                        batteryPercent: state.telemetry.batterySocPercentage.toDouble(),
                        drivingDistanceKm: (state.telemetry.tripDistanceMeters / 1000.0),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildScenarioCard(
                title: "Accident\nDetected",
                subtitle: "Gyro lean tilt",
                icon: Icons.screen_rotation,
                color: AppTheme.warning,
                onTap: () {
                  final state = ref.read(bikeControllerProvider);
                  final activeRider = state.activeUser;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScenarioViews.buildAccidentDetectedScreen(
                        onBack: () => Navigator.pop(context),
                        tiltAngle: 68.5,
                        latitude: state.gps.latitude,
                        longitude: state.gps.longitude,
                        emergencyContactNumber: activeRider?.emergencyNumber ?? "+91 94444 11223",
                        riderName: activeRider?.name ?? "Bala",
                        bloodGroup: activeRider?.bloodGroup ?? "O+",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
