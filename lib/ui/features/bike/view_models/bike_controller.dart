import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/services/ble_service.dart';
import '../../../../data/services/reactive_ble_service.dart';
import '../../../../data/services/classic_bluetooth_service.dart';
import '../../../../data/repositories/bike_repository_impl.dart';
import '../../../../domain/models/bike_models.dart';

// ----------------- DEPENDENCY INJECTION PROVIDERS -----------------

final bleServiceProvider = Provider<BleService>((ref) {
  final service = MockBleService();
  ref.onDispose(() => service.disconnect());
  return service;
});

final bikeRepositoryProvider = Provider<BikeRepository>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return BikeRepositoryImpl(bleService: bleService);
});

// ----------------- STATE MODEL -----------------

class BikeState {
  final BleConnectionState connectionState;
  final BikeTelemetry telemetry;
  final GpsData gps;
  final FingerprintEvent? lastFingerprintEvent;
  final bool isOperationInProgress;
  final GeoFenceConfig geoFence;
  final bool isGeoFenceBreached;
  final double distanceToFenceCenterKm;
  final List<RegisteredUser> users;
  final String activeUserSlot; // 'a', 'b', 'c', 'd'
  final RegisteredUser? activeUser;
  final bool underageAlertActive;
  final String? underageAlertMessage;
  final bool accidentAlertActive;
  final List<SimCommLog> simCommLogs;
  final RenewalDetails renewal;
  final bool isRenewalOverdue;

  BikeState({
    required this.connectionState,
    required this.telemetry,
    required this.gps,
    this.lastFingerprintEvent,
    this.isOperationInProgress = false,
    required this.geoFence,
    this.isGeoFenceBreached = false,
    this.distanceToFenceCenterKm = 0.0,
    required this.users,
    this.activeUserSlot = 'a',
    this.underageAlertActive = false,
    this.underageAlertMessage,
    this.accidentAlertActive = false,
    this.simCommLogs = const [],
    required this.renewal,
    this.isRenewalOverdue = false,
  }) : activeUser = _resolveActiveUser(users, activeUserSlot);

  static RegisteredUser? _resolveActiveUser(List<RegisteredUser> users, String slot) {
    try {
      return users.firstWhere((u) => u.slotKey == slot);
    } catch (_) {
      return users.isNotEmpty ? users.first : null;
    }
  }

  /// Effective travel radius for the current active rider
  double get effectiveGeoFenceRadiusKm {
    final rider = activeUser;
    if (rider != null && rider.geoFenceRadiusKm > 0) {
      return rider.geoFenceRadiusKm;
    }
    return geoFence.radiusKm;
  }

  BikeState copyWith({
    BleConnectionState? connectionState,
    BikeTelemetry? telemetry,
    GpsData? gps,
    FingerprintEvent? lastFingerprintEvent,
    bool? isOperationInProgress,
    GeoFenceConfig? geoFence,
    bool? isGeoFenceBreached,
    double? distanceToFenceCenterKm,
    List<RegisteredUser>? users,
    String? activeUserSlot,
    bool? underageAlertActive,
    String? underageAlertMessage,
    bool? accidentAlertActive,
    List<SimCommLog>? simCommLogs,
    RenewalDetails? renewal,
    bool? isRenewalOverdue,
  }) {
    return BikeState(
      connectionState: connectionState ?? this.connectionState,
      telemetry: telemetry ?? this.telemetry,
      gps: gps ?? this.gps,
      lastFingerprintEvent: lastFingerprintEvent ?? this.lastFingerprintEvent,
      isOperationInProgress: isOperationInProgress ?? this.isOperationInProgress,
      geoFence: geoFence ?? this.geoFence,
      isGeoFenceBreached: isGeoFenceBreached ?? this.isGeoFenceBreached,
      distanceToFenceCenterKm: distanceToFenceCenterKm ?? this.distanceToFenceCenterKm,
      users: users ?? this.users,
      activeUserSlot: activeUserSlot ?? this.activeUserSlot,
      underageAlertActive: underageAlertActive ?? this.underageAlertActive,
      underageAlertMessage: underageAlertMessage ?? this.underageAlertMessage,
      accidentAlertActive: accidentAlertActive ?? this.accidentAlertActive,
      simCommLogs: simCommLogs ?? this.simCommLogs,
      renewal: renewal ?? this.renewal,
      isRenewalOverdue: isRenewalOverdue ?? this.isRenewalOverdue,
    );
  }

  factory BikeState.initial() => BikeState(
        connectionState: BleConnectionState.disconnected,
        telemetry: BikeTelemetry.initial(),
        gps: GpsData.initial(),
        geoFence: GeoFenceConfig.defaultConfig(),
        isGeoFenceBreached: false,
        distanceToFenceCenterKm: 0.0,
        users: RegisteredUser.defaultUsers(),
        activeUserSlot: 'a',
        underageAlertActive: false,
        underageAlertMessage: null,
        accidentAlertActive: false,
        simCommLogs: const [],
        renewal: RenewalDetails.defaultDetails(),
        isRenewalOverdue: false,
      );
}

// ----------------- CONTROLLER / NOTIFIER -----------------

class BikeController extends StateNotifier<BikeState> {
  final BikeRepository _repository;
  StreamSubscription? _connSub;
  StreamSubscription? _telemetrySub;
  StreamSubscription? _gpsSub;
  StreamSubscription? _fingerprintSub;
  StreamSubscription? _hwCmdSub;

  final AudioPlayer? _audioPlayer;
  final bool _disableAudio;
  SharedPreferences? _prefs;

  BikeController({
    required BikeRepository repository,
    AudioPlayer? audioPlayer,
    bool disableAudio = false,
  })  : _repository = repository,
        _audioPlayer = audioPlayer,
        _disableAudio = disableAudio,
        super(BikeState.initial()) {
    _initSubscriptions();
    _loadPersistedSettings();
  }

  void _initSubscriptions() {
    _connSub = _repository.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
    });

    _telemetrySub = _repository.telemetryStream.listen((telemetry) {
      final isOverdue = _evaluateRenewalOverdue(state.renewal, telemetry.tripDistanceMeters);
      state = state.copyWith(
        telemetry: telemetry,
        isRenewalOverdue: isOverdue,
      );
    });

    _gpsSub = _repository.gpsStream.listen((gps) {
      _evaluateGeoFence(gps, state.geoFence);
    });

    _fingerprintSub = _repository.fingerprintStream.listen((event) {
      state = state.copyWith(lastFingerprintEvent: event);
    });

    _hwCmdSub = _repository.hardwareCommandStream.listen((cmd) {
      String status = "SLOT_SWITCHED";
      if (cmd == '1') {
        status = "ACCIDENT_DETECT";
      } else if (cmd == 'X') {
        status = "UNDERAGE_LOCK";
      }
      _logSimComm(
        isTx: false,
        cmd: "RX_HARDWARE_KEY('$cmd')",
        hex: "52 58 ${cmd.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(2, '0')}",
        status: status,
      );
      handleHardwareCommand(cmd);
    });
  }

  void _logSimComm({
    required bool isTx,
    required String cmd,
    required String hex,
    String status = "OK",
  }) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    final newLog = SimCommLog(
      timestamp: timeStr,
      isTx: isTx,
      command: cmd,
      hexData: hex,
      status: status,
    );
    final updatedLogs = [newLog, ...state.simCommLogs];
    if (updatedLogs.length > 30) {
      updatedLogs.removeLast();
    }
    state = state.copyWith(simCommLogs: updatedLogs);
  }

  Future<void> _loadPersistedSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load saved GeoFenceConfig
      final fenceStr = _prefs?.getString('smart_bike_geofence_v1');
      GeoFenceConfig loadedFence = state.geoFence;
      if (fenceStr != null && fenceStr.isNotEmpty) {
        try {
          loadedFence = GeoFenceConfig.fromJson(jsonDecode(fenceStr));
        } catch (_) {}
      }

      // Load saved RegisteredUsers
      final usersStr = _prefs?.getString('smart_bike_users_v1');
      List<RegisteredUser> loadedUsers = state.users;
      if (usersStr != null && usersStr.isNotEmpty) {
        try {
          final List decoded = jsonDecode(usersStr);
          loadedUsers = decoded.map((u) => RegisteredUser.fromJson(u)).toList();
        } catch (_) {}
      }

      // Load active user slot
      final savedSlot = _prefs?.getString('smart_bike_active_slot_v1') ?? state.activeUserSlot;

      // Load saved RenewalDetails
      final renewalStr = _prefs?.getString('smart_bike_renewal_v1');
      RenewalDetails loadedRenewal = state.renewal;
      if (renewalStr != null && renewalStr.isNotEmpty) {
        try {
          loadedRenewal = RenewalDetails.fromJson(jsonDecode(renewalStr));
        } catch (_) {}
      }

      final isOverdue = _evaluateRenewalOverdue(loadedRenewal, state.telemetry.tripDistanceMeters);

      state = state.copyWith(
        geoFence: loadedFence,
        users: loadedUsers,
        activeUserSlot: savedSlot,
        renewal: loadedRenewal,
        isRenewalOverdue: isOverdue,
      );
      _evaluateGeoFence(state.gps, loadedFence);
    } catch (_) {}
  }

  Future<void> _persistSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString('smart_bike_geofence_v1', jsonEncode(state.geoFence.toJson()));
      final usersJson = jsonEncode(state.users.map((u) => u.toJson()).toList());
      await _prefs?.setString('smart_bike_users_v1', usersJson);
      await _prefs?.setString('smart_bike_active_slot_v1', state.activeUserSlot);
      await _prefs?.setString('smart_bike_renewal_v1', jsonEncode(state.renewal.toJson()));
    } catch (_) {}
  }

  bool _evaluateRenewalOverdue(RenewalDetails renewal, num tripDistanceMeters) {
    final currentKm = tripDistanceMeters.toDouble() / 1000.0;
    return renewal.isAnyOverdue(currentKm);
  }

  void updateRenewalDetails(RenewalDetails newDetails) {
    final isOverdue = _evaluateRenewalOverdue(newDetails, state.telemetry.tripDistanceMeters);
    state = state.copyWith(
      renewal: newDetails,
      isRenewalOverdue: isOverdue,
    );
    _persistSettings();
    if (isOverdue) {
      playAlertSound();
    }
  }

  /// Factory Reset: Restores app and bike settings to default factory values
  Future<void> resetAppToFactoryDefaults() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.clear();
    } catch (_) {}

    final defaultFence = GeoFenceConfig.defaultConfig();
    final defaultUsers = RegisteredUser.defaultUsers();

    state = BikeState.initial().copyWith(
      geoFence: defaultFence,
      users: defaultUsers,
      activeUserSlot: 'a',
      simCommLogs: [
        SimCommLog(
          timestamp: "RESET",
          isTx: true,
          command: "FACTORY_RESET()",
          hexData: "52 53 54 00",
          status: "CLEARED",
        ),
      ],
    );

    _evaluateGeoFence(state.gps, defaultFence);
  }

  /// Haversine Formula for accurate distance in KM
  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  void _evaluateGeoFence(GpsData gps, GeoFenceConfig fence) {
    final distance = _calculateDistanceKm(
      fence.centerLatitude,
      fence.centerLongitude,
      gps.latitude,
      gps.longitude,
    );

    // Use user-specific radius if active rider has a set radius
    final effectiveRadius = state.effectiveGeoFenceRadiusKm;
    final isBreached = fence.isEnabled && (distance > effectiveRadius);

    final wasBreached = state.isGeoFenceBreached;

    state = state.copyWith(
      gps: gps,
      distanceToFenceCenterKm: distance,
      isGeoFenceBreached: isBreached,
    );

    // Audio notification & buzzer alarm when perimeter is breached
    if (isBreached && !wasBreached) {
      playAlertSound();
    }

    // Auto-restrict motor / enforce lock if breached and configured
    if (isBreached && fence.restrictMotorWhenBreached) {
      if (state.telemetry.lockState != LockState.locked) {
        _repository.setLock(true);
      }
    }
  }

  /// Admin method: Update Geo-Fence coordinates, radius KM, and restriction flags
  void updateGeoFenceConfig(GeoFenceConfig newConfig) {
    state = state.copyWith(geoFence: newConfig);
    _evaluateGeoFence(state.gps, newConfig);
    _persistSettings();
  }

  /// Simulator / Testing method: Move bike location to test in/out of boundary
  void simulateBikeLocation(double lat, double lon) {
    final newGps = GpsData(
      latitude: lat,
      longitude: lon,
      altitudeMeters: state.gps.altitudeMeters,
      speedKmh: state.gps.speedKmh,
      satellites: state.gps.satellites,
      fixQuality: state.gps.fixQuality,
      hdop: state.gps.hdop,
    );
    _evaluateGeoFence(newGps, state.geoFence);
  }

  Future<void> connect(String deviceId, {bool isClassic = false, String? deviceName}) async {
    state = state.copyWith(isOperationInProgress: true);
    try {
      final nameLower = (deviceName ?? "").toLowerCase();
      final idLower = deviceId.toLowerCase();
      final isMacAddress = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(deviceId);
      final isHc05 = nameLower.contains('hc-05') || nameLower.contains('hc-06') || nameLower.contains('hc05') || nameLower.contains('bt v2.0') || idLower.contains('hc05') || idLower.contains('hc-05') || isClassic;

      if (deviceId == "VIRTUAL_SIMULATOR" || deviceId.startsWith("APX") || deviceId.startsWith("LK") || deviceId.startsWith("BT-001A")) {
        // Virtual test rig / simulator
        _repository.setService(MockBleService());
      } else if (isHc05 || isMacAddress) {
        // Bluetooth Classic v2.0 SPP (e.g. HC-05 / HC-06 module)
        _repository.setService(ClassicBluetoothService());
      } else {
        // Standard BLE GATT peripheral (e.g. ESP32-BLE)
        _repository.setService(ReactiveBleService());
      }

      await _repository.connect(deviceId);
    } finally {
      state = state.copyWith(isOperationInProgress: false);
    }
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
  }

  Future<void> toggleLock() async {
    final nextLockState = state.telemetry.lockState != LockState.locked;
    state = state.copyWith(isOperationInProgress: true);
    try {
      await _repository.setLock(nextLockState);
    } finally {
      state = state.copyWith(isOperationInProgress: false);
    }
  }

  Future<void> triggerAlarm() async {
    await _repository.setAlarm(AlarmState.triggered);
  }

  Future<void> disarmAlarm() async {
    await _repository.setAlarm(AlarmState.disarmed);
  }

  Future<void> startFingerprintEnrollment(int slotId) async {
    await _repository.enrollFingerprint(slotId);
  }

  /// Handles single-character hardware commands from BLE/Hardware
  /// '1' -> Accident detected! Fetches realtime location from admin geofencing, alerts nearby hospital & ambulance
  /// 'X' -> Unauthorised access, user below 18 years, alert notification with sound
  /// 'a', 'b', 'c', 'd' -> sets corresponding user active, all others inactive
  void handleHardwareCommand(String cmd) {
    if (cmd == '1') {
      _triggerAccidentAlert();
      return;
    }

    if (cmd == 'X') {
      _triggerUnderageAlert();
      return;
    }

    if (cmd == 'a' || cmd == 'b' || cmd == 'c' || cmd == 'd') {
      _setActiveUserBySlot(cmd);
      return;
    }
  }

  void _triggerAccidentAlert() {
    // 1. Fetch realtime location of the bike from admin geofencing coordinates
    final fenceLat = state.geoFence.centerLatitude;
    final fenceLon = state.geoFence.centerLongitude;

    // Synchronize GPS coordinates to the bike's realtime admin geofencing location
    final updatedGps = GpsData(
      latitude: fenceLat,
      longitude: fenceLon,
      altitudeMeters: state.gps.altitudeMeters,
      speedKmh: 0.0,
      satellites: state.gps.satellites,
      fixQuality: state.gps.fixQuality,
      hdop: state.gps.hdop,
    );

    // 2. Play continuous emergency siren alert sound & strong haptic vibration
    playAlertSound();

    // 3. Update state with accident alert active
    state = state.copyWith(
      gps: updatedGps,
      accidentAlertActive: true,
    );
  }

  void dismissAccidentAlert() {
    state = state.copyWith(accidentAlertActive: false);
  }

  void _triggerUnderageAlert() {
    // Play alert sound and haptic vibration feedback
    playAlertSound();

    // Auto lock bike for security upon unauthorized access
    if (state.telemetry.lockState != LockState.locked) {
      _repository.setLock(true);
    }

    state = state.copyWith(
      underageAlertActive: true,
      underageAlertMessage: "UNAUTHORISED ACCESS: Rider detected is below 18 years of age. Ignition locked.",
    );
  }

  AudioPlayer? _activeAudioPlayer;

  void playAlertSound() {
    // 1. Play real audio file from assets/audio/alert.wav (when audio not disabled in tests)
    if (!_disableAudio) {
      try {
        _activeAudioPlayer ??= _audioPlayer ?? AudioPlayer();
        _activeAudioPlayer?.stop();
        _activeAudioPlayer?.play(AssetSource('audio/alert.wav')).catchError((_) {});
      } catch (_) {
        // Platform channel audio driver unavailable (e.g. headless unit tests)
      }
    }

    // 2. Play system alert sound and heavy haptic vibration feedback
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.vibrate();
    });
  }

  void dismissUnderageAlert() {
    state = state.copyWith(
      underageAlertActive: false,
      underageAlertMessage: null,
    );
  }

  void _setActiveUserBySlot(String slotKey) {
    final updatedUsers = state.users.map((user) {
      final isTarget = user.slotKey == slotKey;
      return user.copyWith(
        isActive: isTarget,
      );
    }).toList();

    state = state.copyWith(
      users: updatedUsers,
      activeUserSlot: slotKey,
      underageAlertActive: false,
    );

    // Re-evaluate geo-fencing with the newly selected user's travel radius
    _evaluateGeoFence(state.gps, state.geoFence);
    _persistSettings();
  }

  /// Update existing user profile details
  void updateUser(RegisteredUser updatedUser) {
    final updatedList = state.users.map((u) {
      return u.slotKey == updatedUser.slotKey ? updatedUser : u;
    }).toList();

    state = state.copyWith(users: updatedList);

    // Re-evaluate geo-fence in case radius or active user was updated
    _evaluateGeoFence(state.gps, state.geoFence);
    _persistSettings();
  }

  /// Update geo-fence travel radius for a specific user slot
  void updateUserRadius(String slotKey, double radiusKm) {
    final updatedList = state.users.map((u) {
      if (u.slotKey == slotKey) {
        return u.copyWith(geoFenceRadiusKm: radiusKm);
      }
      return u;
    }).toList();

    state = state.copyWith(users: updatedList);
    _evaluateGeoFence(state.gps, state.geoFence);
    _persistSettings();
  }

  /// Enable or disable a user
  void toggleUserEnabled(String slotKey, bool isEnabled) {
    final updatedList = state.users.map((u) {
      if (u.slotKey == slotKey) {
        return u.copyWith(isUserEnabled: isEnabled);
      }
      return u;
    }).toList();

    state = state.copyWith(users: updatedList);
    _persistSettings();
  }

  /// Add a new user following all profile specifications
  void addUser(RegisteredUser newUser) {
    // Check if slot already exists, replace or append
    final existsIndex = state.users.indexWhere((u) => u.slotKey == newUser.slotKey);
    List<RegisteredUser> newList;
    if (existsIndex >= 0) {
      newList = List<RegisteredUser>.from(state.users);
      newList[existsIndex] = newUser;
    } else {
      newList = [...state.users, newUser];
    }
    state = state.copyWith(users: newList);
    _persistSettings();
  }

  /// Delete a user
  void deleteUser(String slotKey) {
    final newList = state.users.where((u) => u.slotKey != slotKey).toList();
    state = state.copyWith(users: newList);
    _persistSettings();
  }

  /// Simulator trigger for hardware commands ('X', 'a', 'b', 'c', 'd')
  void simulateHardwareCommand(String cmd) {
    _repository.simulateHardwareCommand(cmd);
  }

  @override
  void dispose() {
    _activeAudioPlayer?.dispose();
    _audioPlayer?.dispose();
    _connSub?.cancel();
    _telemetrySub?.cancel();
    _gpsSub?.cancel();
    _fingerprintSub?.cancel();
    _hwCmdSub?.cancel();
    super.dispose();
  }
}

final bikeControllerProvider = StateNotifierProvider<BikeController, BikeState>((ref) {
  final repo = ref.watch(bikeRepositoryProvider);
  return BikeController(repository: repo);
});
