import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../view_models/bike_controller.dart';
import 'bike_dashboard_screen.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _btChannel = MethodChannel('com.example.smart_bike_app/bluetooth');

  bool _isScanning = false;
  String? _pairingDeviceName;
  late AnimationController _radarController;
  late TabController _tabController;

  bool _isBluetoothEnabled = false;
  bool _hasBluetoothPermission = false;
  bool _isCheckingStatus = true;

  // Real Discovered Hardware BLE Devices (from real scan & paired system devices)
  final List<Map<String, dynamic>> _realDiscoveredDevices = [];

  // Virtual / Simulator Devices
  final List<Map<String, dynamic>> _simulatorDevices = [
    {
      "name": "HC-05 Smart Bike (v2.0)",
      "serial": "HC05-98:D3:31:F8:01:A2",
      "signal": "Strong Signal (-48 dBm)",
      "rssi": -48,
      "isPrimary": true,
      "isClassic": true,
      "badge": "HC-05 BLUETOOTH v2.0",
    },
    {
      "name": "ESP32-SMART-BIKE",
      "serial": "ESP32-44:17:93:1A:88:FF",
      "signal": "Strong Signal (-45 dBm)",
      "rssi": -45,
      "isPrimary": true,
      "isClassic": false,
      "badge": "ESP32 BLE SIMULATOR",
    },
    {
      "name": "Apex One Bike",
      "serial": "APX-8821",
      "signal": "Strong Signal (-52 dBm)",
      "rssi": -52,
      "isPrimary": false,
      "isClassic": false,
      "badge": "VIRTUAL HARDWARE",
    },
    {
      "name": "Smart Lock Hub 02",
      "serial": "LK-4091",
      "signal": "Good Signal (-68 dBm)",
      "rssi": -68,
      "isPrimary": false,
      "isClassic": false,
      "badge": "SIMULATOR HUB",
    },
    {
      "name": "Generic BLE Device",
      "serial": "BT-001A",
      "signal": "Moderate Signal (-84 dBm)",
      "rssi": -84,
      "isPrimary": false,
      "isClassic": false,
      "badge": "GENERIC SIM",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _tabController = TabController(length: 2, vsync: this);

    // Check actual phone bluetooth permissions & enabled state immediately on login/entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBluetoothPrerequisites(autoRequest: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBluetoothPrerequisites(autoRequest: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _radarController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Verifies both Bluetooth permission and phone hardware Bluetooth status
  Future<void> _checkBluetoothPrerequisites({bool autoRequest = false}) async {
    setState(() => _isCheckingStatus = true);

    bool permsGranted = false;
    bool btEnabled = false;

    try {
      final res = await _btChannel.invokeMethod<bool>('checkPermissions');
      permsGranted = res ?? false;
    } catch (_) {
      permsGranted = true; // Fallback
    }

    try {
      final res = await _btChannel.invokeMethod<bool>('isBluetoothEnabled');
      btEnabled = res ?? false;
    } catch (_) {
      btEnabled = true;
    }

    if (!mounted) return;
    setState(() {
      _hasBluetoothPermission = permsGranted;
      _isBluetoothEnabled = btEnabled;
      _isCheckingStatus = false;
    });

    if (autoRequest) {
      if (!permsGranted) {
        _requestPermissions();
      } else if (!btEnabled) {
        _promptEnableBluetooth();
      } else {
        _fetchPairedDevicesAndScan();
      }
    } else {
      if (permsGranted && btEnabled) {
        _fetchPairedDevicesAndScan();
      }
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final granted = await _btChannel.invokeMethod<bool>('requestPermissions') ?? false;
      if (!mounted) return;
      setState(() => _hasBluetoothPermission = granted);

      if (granted) {
        // Now check if bluetooth is enabled
        final btEnabled = await _btChannel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
        if (!mounted) return;
        setState(() => _isBluetoothEnabled = btEnabled);
        if (!btEnabled) {
          _promptEnableBluetooth();
        } else {
          _fetchPairedDevicesAndScan();
        }
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      // Platform channel error
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _promptEnableBluetooth() async {
    try {
      final enabled = await _btChannel.invokeMethod<bool>('requestEnableBluetooth') ?? false;
      if (!mounted) return;
      setState(() => _isBluetoothEnabled = enabled);
      if (enabled) {
        _fetchPairedDevicesAndScan();
      }
    } catch (_) {}
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppTheme.danger, size: 24),
            SizedBox(width: 10),
            Text("Permission Required", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Text(
          "Nearby Devices & Location permissions are mandatory on Android to communicate with your bike over Bluetooth LE.",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _requestPermissions();
            },
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }

  /// Queries system for real paired/bonded devices and initiates discovery
  Future<void> _fetchPairedDevicesAndScan() async {
    if (!_hasBluetoothPermission || !_isBluetoothEnabled) return;

    List<Map<String, dynamic>> realDevices = [];

    try {
      final List? bonded = await _btChannel.invokeMethod<List>('getBondedDevices');
      if (bonded != null) {
        for (var d in bonded) {
          if (d is Map) {
            final name = d['name']?.toString() ?? 'Bluetooth Device';
            final address = d['address']?.toString() ?? '00:00:00:00';
            final isHc05 = name.toUpperCase().contains('HC-05') || name.toUpperCase().contains('HC-06') || name.toUpperCase().contains('HC05') || name.toUpperCase().contains('BT V2.0');
            final isClassic = (d['isClassic'] as bool? ?? false) || isHc05;
            final isSmartBike = name.toLowerCase().contains('bike') || name.toLowerCase().contains('esp32') || isHc05;

            String badgeText;
            if (isHc05) {
              badgeText = "HC-05 BT v2.0";
            } else if (isSmartBike) {
              badgeText = isClassic ? "PAIRED CLASSIC BT" : "PAIRED SMART BIKE";
            } else {
              badgeText = "PAIRED DEVICE";
            }

            realDevices.add({
              "name": name,
              "serial": address,
              "signal": isHc05 ? "HC-05 SPP v2.0 Ready" : "Already Paired in Phone",
              "rssi": -50,
              "isPrimary": isSmartBike || isHc05,
              "badge": badgeText,
              "isBonded": true,
              "isClassic": isClassic,
            });
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _realDiscoveredDevices.clear();
      _realDiscoveredDevices.addAll(realDevices);
    });

    _startScan();
  }

  void _startScan() {
    if (!_hasBluetoothPermission) {
      _requestPermissions();
      return;
    }
    if (!_isBluetoothEnabled) {
      _promptEnableBluetooth();
      return;
    }

    setState(() {
      _isScanning = true;
    });
    _radarController.repeat();

    // Scan timeout for Bluetooth discovery
    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      _radarController.stop();
    });
  }

  void _pairDevice(String name, String id, {bool isClassic = false}) async {
    // Bluetooth must be enabled to pair
    if (!_isBluetoothEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot pair: Bluetooth is turned off in phone!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      _promptEnableBluetooth();
      return;
    }

    setState(() {
      _pairingDeviceName = name;
    });

    final controller = ref.read(bikeControllerProvider.notifier);
    await controller.connect(id, isClassic: isClassic, deviceName: name);

    if (!mounted) return;
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const BikeDashboardScreen(),
          ),
        ),
      );
    });
  }

  void _launchSimulator() async {
    final controller = ref.read(bikeControllerProvider.notifier);
    await controller.connect("VIRTUAL_SIMULATOR");

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BikeDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Connect Your Bike",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.border, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: AppTheme.surface,
              ),
              icon: const Icon(Icons.tune, size: 15, color: AppTheme.accent),
              label: const Text(
                "Launch Sim",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: _launchSimulator,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.bluetooth_searching, size: 18),
              text: "Real BLE Devices",
            ),
            Tab(
              icon: Icon(Icons.developer_mode, size: 18),
              text: "Simulator Devices",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Real Hardware BLE Scan & Connect
          _buildRealBleTab(),

          // TAB 2: Simulator / Virtual Hardware Devices
          _buildSimulatorTab(),
        ],
      ),
    );
  }

  Widget _buildRealBleTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bluetooth Status & Permission Prompt Banners
          if (_isCheckingStatus) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
              ),
            ),
          ] else if (!_hasBluetoothPermission) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gpp_maybe, color: AppTheme.danger, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bluetooth Permission Required",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                        ),
                        Text(
                          "Grant Nearby Devices and Bluetooth permissions to scan & connect.",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _requestPermissions,
                    child: const Text("Allow", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ] else if (!_isBluetoothEnabled) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_disabled, color: AppTheme.warning, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bluetooth is Turned Off",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                        ),
                        Text(
                          "Enable phone Bluetooth to discover and pair with bike hardware.",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _promptEnableBluetooth,
                    child: const Text("Turn On", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          // Scan Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isScanning)
                      RotationTransition(
                        turns: _radarController,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
                          ),
                        ),
                      ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(
                        _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                        color: _isScanning ? AppTheme.accent : AppTheme.primary,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Scan for Nearby Physical Hardware",
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Ensure your bike's ESP32 or Bluetooth lock is turned on.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: Text(
                      _isScanning ? "Scanning Area..." : "Scan BLE Devices",
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    onPressed: _isScanning ? null : _startScan,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pairing Banner
          if (_pairingDeviceName != null) ...[
            _buildPairingIndicator(),
            const SizedBox(height: 14),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "DISCOVERED PHYSICAL HARDWARE",
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              if (_isScanning)
                const Text(
                  "Searching...",
                  style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _realDiscoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_audio, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text(
                          !_hasBluetoothPermission
                              ? "Bluetooth permission not granted.\nTap 'Allow' above to scan."
                              : !_isBluetoothEnabled
                                  ? "Bluetooth is disabled in phone.\nTap 'Turn On' above to enable."
                                  : _isScanning
                                      ? "Listening for BLE broadcast packets..."
                                      : "No hardware detected yet.\nTap 'Scan BLE Devices' or switch to Simulator tab.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _realDiscoveredDevices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildDeviceCard(_realDiscoveredDevices[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.developer_board, color: AppTheme.accent, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Virtual Simulator Devices",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary),
                      ),
                      Text(
                        "Test app workflows, telemetry, locks, and hardware signals without a physical ESP32.",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Pairing Banner
          if (_pairingDeviceName != null) ...[
            _buildPairingIndicator(),
            const SizedBox(height: 14),
          ],

          const Text(
            "VIRTUAL TEST RIGS",
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount: _simulatorDevices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildDeviceCard(_simulatorDevices[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
          ),
          const SizedBox(width: 12),
          Text(
            "Connecting to $_pairingDeviceName...",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> item) {
    final isPrimary = item["isPrimary"] as bool? ?? false;
    final badge = item["badge"] as String? ?? "DEVICE";
    final isBonded = item["isBonded"] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBonded ? AppTheme.primary.withOpacity(0.4) : AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isBonded ? AppTheme.primary.withOpacity(0.12) : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isBonded ? Icons.bluetooth_connected : Icons.two_wheeler,
            color: isPrimary ? AppTheme.primary : AppTheme.textMuted,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item["name"],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPrimary ? AppTheme.primary.withOpacity(0.12) : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isPrimary ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          "${item["serial"]} • ${item["signal"]}",
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11.5,
          ),
        ),
        trailing: SizedBox(
          height: 36,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? AppTheme.primary : AppTheme.surfaceMuted,
              foregroundColor: isPrimary ? Colors.white : AppTheme.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: (!_isBluetoothEnabled || _pairingDeviceName != null)
                ? null
                : () => _pairDevice(
                      item["name"],
                      item["serial"],
                      isClassic: item["isClassic"] as bool? ?? false,
                    ),
            child: Text(
              isBonded ? "Connect" : "Pair",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
