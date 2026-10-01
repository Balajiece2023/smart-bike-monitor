import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/bike_models.dart';
import '../../../../theme/app_theme.dart';
import '../view_models/bike_controller.dart';

class BikeRenewalScreen extends ConsumerWidget {
  final VoidCallback? onBack;

  const BikeRenewalScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeState = ref.watch(bikeControllerProvider);
    final controller = ref.read(bikeControllerProvider.notifier);
    final renewal = bikeState.renewal;
    final currentKm = bikeState.telemetry.tripDistanceMeters / 1000.0;

    final isInsuranceOverdue = renewal.isInsuranceOverdue();
    final isLicenseOverdue = renewal.isLicenseOverdue();
    final isServiceOverdue = renewal.isServiceOverdue(currentKm);
    final isAnyOverdue = isInsuranceOverdue || isLicenseOverdue || isServiceOverdue;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          "Bike Details & Renewal",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: "Edit Bike Details",
            icon: const Icon(Icons.edit_note, color: AppTheme.accent),
            onPressed: () => _openEditDialog(context, controller, renewal),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Overdue Notification Alert Banner
            if (isAnyOverdue) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.danger, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                "RENEWAL DUE CROSSED!",
                                style: TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.notifications_active, color: AppTheme.danger, size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildOverdueSummary(isInsuranceOverdue, isLicenseOverdue, isServiceOverdue),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Schedule & Documentation Container
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "SCHEDULE & DOCUMENTATION",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      InkWell(
                        onTap: () => _openEditDialog(context, controller, renewal),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 14, color: AppTheme.accent),
                              SizedBox(width: 4),
                              Text(
                                "Edit",
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Insurance
                  _buildRenewalCardTile(
                    icon: Icons.security,
                    title: "Insurance Renewal",
                    mainVal: "Expiry: ${renewal.insuranceExpiry}",
                    subVal: "Provider: ${renewal.insuranceProvider}",
                    statusText: isInsuranceOverdue ? "OVERDUE" : "ACTIVE",
                    color: isInsuranceOverdue ? AppTheme.danger : AppTheme.success,
                    isOverdue: isInsuranceOverdue,
                  ),
                  const Divider(color: AppTheme.border, height: 24),

                  // Registration & License
                  _buildRenewalCardTile(
                    icon: Icons.badge_outlined,
                    title: "Registration & License Plate",
                    mainVal: renewal.licensePlate,
                    subVal: "Valid through: ${renewal.licenseExpiry}",
                    statusText: isLicenseOverdue ? "OVERDUE" : "VALID",
                    color: isLicenseOverdue ? AppTheme.danger : AppTheme.accent,
                    isOverdue: isLicenseOverdue,
                  ),
                  const Divider(color: AppTheme.border, height: 24),

                  // Service Schedule
                  _buildRenewalCardTile(
                    icon: Icons.build_outlined,
                    title: "Periodic Service Schedule",
                    mainVal: "Due at ${renewal.serviceDueKm} km (or by ${renewal.serviceDueDate})",
                    subVal: "Current Odo: ${currentKm.toStringAsFixed(1)} km",
                    statusText: isServiceOverdue ? "SERVICE OVERDUE" : "SCHEDULED",
                    color: isServiceOverdue ? AppTheme.danger : AppTheme.success,
                    isOverdue: isServiceOverdue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Edit Action Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceMuted,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
              icon: const Icon(Icons.edit_calendar, color: AppTheme.accent),
              label: const Text(
                "Update Bike Details & Schedule",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () => _openEditDialog(context, controller, renewal),
            ),
          ],
        ),
      ),
    );
  }

  String _buildOverdueSummary(bool insurance, bool license, bool service) {
    final List<String> items = [];
    if (insurance) items.add("Insurance policy expired");
    if (license) items.add("License validity expired");
    if (service) items.add("Bike service interval due");
    return items.join(" • ");
  }

  Widget _buildRenewalCardTile({
    required IconData icon,
    required String title,
    required String mainVal,
    required String subVal,
    required String statusText,
    required Color color,
    required bool isOverdue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                mainVal,
                style: TextStyle(
                  color: isOverdue ? AppTheme.danger : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subVal,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _openEditDialog(
    BuildContext context,
    BikeController controller,
    RenewalDetails current,
  ) {
    final plateCtrl = TextEditingController(text: current.licensePlate);
    final providerCtrl = TextEditingController(text: current.insuranceProvider);
    final insExpiryCtrl = TextEditingController(text: current.insuranceExpiry);
    final licExpiryCtrl = TextEditingController(text: current.licenseExpiry);
    final serviceDateCtrl = TextEditingController(text: current.serviceDueDate);
    final serviceKmCtrl = TextEditingController(text: current.serviceDueKm.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Edit Bike Renewal Details",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFormField("License Plate Number", plateCtrl, Icons.badge_outlined),
                const SizedBox(height: 12),
                _buildFormField("Insurance Provider", providerCtrl, Icons.shield_outlined),
                const SizedBox(height: 12),
                _buildDatePickerField(ctx, "Insurance Expiry Date (YYYY-MM-DD)", insExpiryCtrl),
                const SizedBox(height: 12),
                _buildDatePickerField(ctx, "License Expiry Date (YYYY-MM-DD)", licExpiryCtrl),
                const SizedBox(height: 12),
                _buildDatePickerField(ctx, "Next Service Due Date (YYYY-MM-DD)", serviceDateCtrl),
                const SizedBox(height: 12),
                _buildFormField(
                  "Service Due at KM",
                  serviceKmCtrl,
                  Icons.speed,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final updated = current.copyWith(
                      licensePlate: plateCtrl.text.trim().isEmpty ? current.licensePlate : plateCtrl.text.trim(),
                      insuranceProvider: providerCtrl.text.trim().isEmpty ? current.insuranceProvider : providerCtrl.text.trim(),
                      insuranceExpiry: insExpiryCtrl.text.trim().isEmpty ? current.insuranceExpiry : insExpiryCtrl.text.trim(),
                      licenseExpiry: licExpiryCtrl.text.trim().isEmpty ? current.licenseExpiry : licExpiryCtrl.text.trim(),
                      serviceDueDate: serviceDateCtrl.text.trim().isEmpty ? current.serviceDueDate : serviceDateCtrl.text.trim(),
                      serviceDueKm: int.tryParse(serviceKmCtrl.text.trim()) ?? current.serviceDueKm,
                    );
                    controller.updateRenewalDetails(updated);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Bike details updated & saved!"),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  child: const Text(
                    "Save Bike Details",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
      ),
    );
  }

  static Widget _buildDatePickerField(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      readOnly: false,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.accent, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range, color: AppTheme.accent, size: 20),
          onPressed: () async {
            DateTime initial = DateTime.now();
            try {
              if (controller.text.trim().isNotEmpty) {
                initial = DateTime.parse(controller.text.trim());
              }
            } catch (_) {}
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2000),
              lastDate: DateTime(2045),
            );
            if (picked != null) {
              controller.text =
                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
            }
          },
        ),
        filled: true,
        fillColor: AppTheme.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
      ),
    );
  }
}
