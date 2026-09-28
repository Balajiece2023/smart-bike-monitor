import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../domain/models/bike_models.dart';
import '../view_models/bike_controller.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  /// Opens the rider registration or editing bottom sheet dialog
  static void openUserEditor(BuildContext context, BikeController controller, [RegisteredUser? existing]) {
    _UserManagementScreenState.openUserEditor(context, controller, existing);
  }

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final bikeState = ref.watch(bikeControllerProvider);
    final controller = ref.read(bikeControllerProvider.notifier);
    final users = bikeState.users;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "User Management",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              "Profiles, Permissions & Hardware Sync",
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Add User",
            icon: const Icon(Icons.person_add_alt_1, color: AppTheme.primary),
            onPressed: () => openUserEditor(context, controller, null),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Underage alert warning card if active
            if (bikeState.underageAlertActive) ...[
              _buildUnderageAlertCard(context, controller, bikeState.underageAlertMessage),
              const SizedBox(height: 16),
            ],

            // Hardware Command Live Test / Simulator Bar
            _buildHardwareSimulatorCard(controller, bikeState),
            const SizedBox(height: 16),

            // Active Rider Summary Card
            _buildActiveRiderHero(bikeState.activeUser),
            const SizedBox(height: 20),

            // Registered Users Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "REGISTERED RIDERS & HARDWARE KEYS",
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  "${users.length} Slots Configured",
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // User Cards List
            ...users.map((user) => _buildUserCard(context, controller, user)),

            const SizedBox(height: 20),

            // Add User Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                "+ Register New Bike Rider",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () => openUserEditor(context, controller, null),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderageAlertCard(BuildContext context, BikeController controller, String? message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withOpacity(0.5), width: 1.5),
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
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "UNAUTHORISED ACCESS ALERT",
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      "Hardware Flag: 'X' Received",
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.danger, size: 20),
                onPressed: () => controller.dismissUnderageAlert(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message ?? "Unauthorised access - user is below 18 years. Bike ignition is locked.",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.volume_up, size: 16),
                  label: const Text("Re-sound Alert"),
                  onPressed: () => controller.playAlertSound(),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => controller.dismissUnderageAlert(),
                child: const Text("Dismiss"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareSimulatorCard(BikeController controller, BikeState state) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.developer_board, size: 18, color: AppTheme.accent),
                  SizedBox(width: 8),
                  Text(
                    "Hardware Signals (ESP32 / BLE)",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
                  "Active Slot: [${state.activeUserSlot.toUpperCase()}]",
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Test incoming hardware single-character serial/BLE frames: 'a','b','c','d' switches active user, 'X' triggers underage warning with audio alert.",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Action Buttons: a, b, c, d and X
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCmdButton(controller, 'a', "Slot [a]", state.activeUserSlot == 'a'),
              _buildCmdButton(controller, 'b', "Slot [b]", state.activeUserSlot == 'b'),
              _buildCmdButton(controller, 'c', "Slot [c]", state.activeUserSlot == 'c'),
              _buildCmdButton(controller, 'd', "Slot [d]", state.activeUserSlot == 'd'),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.crisis_alert, size: 16),
                label: const Text("Cmd '1' (Accident)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                onPressed: () {
                  controller.simulateHardwareCommand('1');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Hardware command '1' received! Accident detected, realtime location fetched & ambulance dispatched."),
                      backgroundColor: AppTheme.danger,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.gpp_bad, size: 16),
                label: const Text("Cmd 'X' (Underage)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                onPressed: () {
                  controller.simulateHardwareCommand('X');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Hardware command 'X' triggered! Unauthorised access alert activated."),
                      backgroundColor: AppTheme.danger,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live RX / TX Hardware Communication Log (Simulator only)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
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
                        Icon(Icons.terminal, size: 15, color: AppTheme.accent),
                        SizedBox(width: 6),
                        Text(
                          "HARDWARE RX / TX COMMUNICATION LOG",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "SIMULATOR ONLY",
                        style: TextStyle(fontSize: 8.5, color: AppTheme.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.simCommLogs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "No serial frames yet. Tap Slot [a-d] or Cmd 'X' above to generate RX/TX frames.",
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  Column(
                    children: state.simCommLogs.take(5).map((log) {
                      final isTx = log.isTx;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isTx ? AppTheme.primary.withOpacity(0.12) : AppTheme.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isTx ? "TX ➔" : "RX ⬅",
                                style: TextStyle(
                                  color: isTx ? AppTheme.primary : AppTheme.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              log.timestamp,
                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log.command,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.hexData,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCmdButton(BikeController controller, String cmd, String label, bool isActive) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? AppTheme.primary : AppTheme.surfaceMuted,
        foregroundColor: isActive ? Colors.white : AppTheme.textPrimary,
        side: BorderSide(color: isActive ? AppTheme.primary : AppTheme.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => controller.simulateHardwareCommand(cmd),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActiveRiderHero(RegisteredUser? activeUser) {
    if (activeUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.12),
            AppTheme.accent.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "ACTIVE RIDER FOR BIKE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  "Hardware Slot: ${activeUser.slotKey.toUpperCase()}",
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary,
                child: Text(
                  activeUser.name.isNotEmpty ? activeUser.name[0].toUpperCase() : "U",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeUser.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${activeUser.role} • Age: ${activeUser.age} yrs • Blood: ${activeUser.bloodGroup}",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),

          // Detail badges
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMiniBadge(Icons.share_location, "Fence Radius: ${activeUser.geoFenceRadiusKm.toStringAsFixed(1)} KM"),
              _buildMiniBadge(Icons.phone, activeUser.mobileNumber),
              _buildMiniBadge(Icons.contact_emergency, "SOS: ${activeUser.emergencyNumber}"),
              _buildMiniBadge(Icons.fingerprint, activeUser.isBiometricEnabled ? "Biometric Enabled" : "Biometric Off"),
              _buildMiniBadge(Icons.badge, "Aadhar: ${activeUser.aadharNumber}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, BikeController controller, RegisteredUser user) {
    final isActive = user.isActive;
    final isEnabled = user.isUserEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.border,
          width: isActive ? 1.8 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: isActive
              ? AppTheme.primary
              : (isEnabled ? AppTheme.surfaceMuted : Colors.grey.withOpacity(0.2)),
          child: Text(
            user.slotKey.toUpperCase(),
            style: TextStyle(
              color: isActive ? Colors.white : (isEnabled ? AppTheme.primary : Colors.grey),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(
                  color: isEnabled ? AppTheme.textPrimary : AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  decoration: isEnabled ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "ACTIVE",
                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "INACTIVE",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "Radius: ${user.geoFenceRadiusKm.toStringAsFixed(1)} KM • Age: ${user.age} • Blood: ${user.bloodGroup} • ${user.isBiometricEnabled ? "Biometric ON" : "Biometric OFF"}",
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppTheme.border, height: 16),
                _buildInfoLine("Geo-Fence Radius", "${user.geoFenceRadiusKm.toStringAsFixed(1)} KM Allowed Travel Limit"),
                _buildInfoLine("Hardware Slot", "Command Key '${user.slotKey}' (ESP32 Frame)"),
                _buildInfoLine("Date of Birth", "${user.dob} (${user.age} years old)"),
                _buildInfoLine("Blood Group", user.bloodGroup),
                _buildInfoLine("Aadhar Number", user.aadharNumber),
                _buildInfoLine("Driving Licence", user.licenceNumber),
                _buildInfoLine("Mobile Number", user.mobileNumber),
                _buildInfoLine("Emergency Contact", user.emergencyNumber),
                const SizedBox(height: 12),

                // Toggles Row: User Enable/Disable and Biometric
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isEnabled ? Icons.check_circle : Icons.block,
                                size: 18,
                                color: isEnabled ? AppTheme.success : AppTheme.danger,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "User Account Access",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Switch(
                            value: isEnabled,
                            activeColor: AppTheme.success,
                            onChanged: (val) {
                              controller.toggleUserEnabled(user.slotKey, val);
                            },
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.border, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                user.isBiometricEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                                size: 18,
                                color: user.isBiometricEnabled ? AppTheme.primary : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Biometric Authentication",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Switch(
                            value: user.isBiometricEnabled,
                            activeColor: AppTheme.primary,
                            onChanged: (val) {
                              controller.updateUser(user.copyWith(isBiometricEnabled: val));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: Edit, Set Active, Delete
                Row(
                  children: [
                    if (!isActive)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.power_settings_new, size: 16),
                          label: const Text("Set Active"),
                          onPressed: () {
                            controller.simulateHardwareCommand(user.slotKey);
                          },
                        ),
                      ),
                    if (!isActive) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Edit Details"),
                        onPressed: () => openUserEditor(context, controller, user),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: "Remove Rider",
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                      onPressed: () => _confirmDeleteUser(context, controller, user),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, BikeController controller, RegisteredUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Delete User", style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text("Are you sure you want to remove ${user.name} (Slot ${user.slotKey.toUpperCase()}) from the bike?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () {
              controller.deleteUser(user.slotKey);
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  static void openUserEditor(BuildContext context, BikeController controller, [RegisteredUser? existing]) {
    final isEditing = existing != null;

    final nameController = TextEditingController(text: existing?.name ?? "");
    final dobController = TextEditingController(text: existing?.dob ?? "2000-01-01");
    final ageController = TextEditingController(text: existing?.age.toString() ?? "24");
    final bloodGroupController = TextEditingController(text: existing?.bloodGroup ?? "O+");
    final aadharController = TextEditingController(text: existing?.aadharNumber ?? "");
    final licenceController = TextEditingController(text: existing?.licenceNumber ?? "TN-01-2022-0034125");
    final mobileController = TextEditingController(text: existing?.mobileNumber ?? "");
    final emergencyController = TextEditingController(text: existing?.emergencyNumber ?? "");
    final slotController = TextEditingController(text: existing?.slotKey ?? "e");
    double userRadiusKm = existing?.geoFenceRadiusKm ?? 5.0;
    bool biometricEnabled = existing?.isBiometricEnabled ?? true;
    bool userEnabled = existing?.isUserEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? "Edit Rider Details" : "Register New Rider",
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 8),

                    // Slot Key & Name
                    Row(
                      children: [
                        SizedBox(
                          width: 85,
                          child: TextField(
                            controller: slotController,
                            maxLength: 1,
                            readOnly: isEditing,
                            decoration: InputDecoration(
                              labelText: "Slot",
                              hintText: "a-z",
                              counterText: "",
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: "Full Name",
                              hintText: "e.g. Bala",
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // DOB & Age
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: dobController,
                            decoration: InputDecoration(
                              labelText: "Date of Birth",
                              hintText: "YYYY-MM-DD",
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Age",
                              hintText: "24",
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: bloodGroupController,
                            decoration: InputDecoration(
                              labelText: "Blood",
                              hintText: "O+",
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Aadhar & Licence Numbers
                    TextField(
                      controller: aadharController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Aadhar Number",
                        hintText: "XXXX-XXXX-XXXX",
                        filled: true,
                        fillColor: AppTheme.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: licenceController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: "Driving Licence Number",
                        hintText: "TN-02-1998-0012894",
                        filled: true,
                        fillColor: AppTheme.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mobile & Emergency
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Mobile Number",
                        hintText: "+91 XXXXX XXXXX",
                        filled: true,
                        fillColor: AppTheme.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emergencyController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Emergency SOS Number",
                        hintText: "+91 XXXXX XXXXX",
                        filled: true,
                        fillColor: AppTheme.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // User-Specific Geo-Fencing Travel Radius Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.share_location, size: 18, color: AppTheme.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    "Travel Geo-Fence Radius",
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${userRadiusKm.toStringAsFixed(1)} KM",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Maximum distance this rider is permitted to ride from the home/base location.",
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primary,
                              thumbColor: AppTheme.primary,
                              overlayColor: AppTheme.primary.withOpacity(0.12),
                            ),
                            child: Slider(
                              value: userRadiusKm,
                              min: 0.5,
                              max: 30.0,
                              divisions: 59,
                              label: "${userRadiusKm.toStringAsFixed(1)} km",
                              onChanged: (val) {
                                setModalState(() => userRadiusKm = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggles
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Biometric Sensor Access", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text("Enable handlebar fingerprint scan to unlock", style: TextStyle(fontSize: 12)),
                      value: biometricEnabled,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setModalState(() => biometricEnabled = val);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Enable Rider Account", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text("Allow this profile to drive the bike", style: TextStyle(fontSize: 12)),
                      value: userEnabled,
                      activeColor: AppTheme.success,
                      onChanged: (val) {
                        setModalState(() => userEnabled = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final age = int.tryParse(ageController.text.trim()) ?? 18;
                        final slotKey = slotController.text.trim().toLowerCase();

                        final user = RegisteredUser(
                          slotKey: slotKey.isNotEmpty ? slotKey : 'a',
                          name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : "Rider",
                          dob: dobController.text.trim(),
                          age: age,
                          bloodGroup: bloodGroupController.text.trim().isNotEmpty ? bloodGroupController.text.trim() : "O+",
                          aadharNumber: aadharController.text.trim().isNotEmpty ? aadharController.text.trim() : "Pending",
                          licenceNumber: licenceController.text.trim().isNotEmpty ? licenceController.text.trim() : "TN-01-2022-0034125",
                          mobileNumber: mobileController.text.trim().isNotEmpty ? mobileController.text.trim() : "Not Provided",
                          emergencyNumber: emergencyController.text.trim().isNotEmpty ? emergencyController.text.trim() : "Not Provided",
                          isBiometricEnabled: biometricEnabled,
                          isUserEnabled: userEnabled,
                          isActive: existing?.isActive ?? false,
                          role: isEditing ? (existing?.role ?? "Authorized Rider") : "Authorized Rider",
                          geoFenceRadiusKm: userRadiusKm,
                        );

                        if (isEditing) {
                          controller.updateUser(user);
                        } else {
                          controller.addUser(user);
                        }

                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("User '${user.name}' successfully saved!"),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                      child: Text(
                        isEditing ? "Save Changes" : "Register User",
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
