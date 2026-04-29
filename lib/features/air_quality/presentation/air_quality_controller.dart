import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../location/location_service.dart';
import '../../notifications/data/notification_settings_storage.dart';
import '../data/air_quality_cache.dart';
import '../data/air_quality_repository.dart';
import '../domain/air_quality_model.dart';

enum AirQualityViewState { initial, loading, loaded, error }

class AirQualityController extends ChangeNotifier with WidgetsBindingObserver {
  AirQualityController({
    required AirQualityRepository repository,
    required LocationService locationService,
  }) : _repository = repository,
       _locationService = locationService,
       _notificationStorage = NotificationSettingsStorage() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AirQualityRepository _repository;
  final LocationService _locationService;
  final NotificationSettingsStorage _notificationStorage;

  AirQualityViewState state = AirQualityViewState.initial;
  AirQualityModel? data;
  String? errorMessage;
  DateTime? lastUpdatedAt;
  String? infoMessage;
  String? debugLocationSource;
  String? debugCacheKey;
  bool? debugCacheReused;
  bool? debugApiFetched;

  LocationFetchStatus? locationStatus;
  bool usingDefaultLocation = true;
  String locationLabel = LocationService.defaultCityLabel;
  double _latitude = LocationService.defaultLatitude;
  double _longitude = LocationService.defaultLongitude;

  StreamSubscription<LocationFetchResult>? _locationSubscription;
  Timer? _debugForegroundRecheckTimer;
  DateTime? _lastAreaRefreshAt;
  DateTime? _lastResumeRefreshAt;
  bool _hasValidDisplayedLocation = false;
  bool isInitialLoading = true;
  bool isRefreshing = false;

  bool get isLoading => isInitialLoading;

  Duration get remainingThrottleDuration {
    if (lastUpdatedAt == null) {
      return Duration.zero;
    }
    final elapsed = DateTime.now().difference(lastUpdatedAt!);
    final remaining = AirQualityCache.throttleDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get canRefresh => remainingThrottleDuration == Duration.zero;

  String get locationStatusText {
    if (state == AirQualityViewState.loading && locationStatus == null) {
      return 'Getting current location...';
    }
    if (kDebugMode && debugLocationSource == 'debugOverride') {
      return 'Using emulator/debug location';
    }
    if (locationStatus == LocationFetchStatus.granted) {
      return 'Using your current area';
    }
    if (locationStatus == LocationFetchStatus.recentArea) {
      return 'Using recent area';
    }
    if (locationStatus == LocationFetchStatus.fallbackDefault) {
      return 'Using default city';
    }
    if (locationStatus == LocationFetchStatus.denied ||
        locationStatus == LocationFetchStatus.deniedForever ||
        locationStatus == LocationFetchStatus.serviceDisabled) {
      return 'Location unavailable. Tap Re-check Location.';
    }
    return 'Using default city';
  }

  bool get shouldShowRetryLocation {
    return locationStatus == LocationFetchStatus.denied ||
        locationStatus == LocationFetchStatus.deniedForever ||
        locationStatus == LocationFetchStatus.serviceDisabled ||
        locationStatus == LocationFetchStatus.fallbackDefault;
  }

  Future<void> initialize() async {
    final snapshot = await _repository.getPersistedSnapshot();
    if (snapshot != null) {
      data = snapshot.data;
      lastUpdatedAt = snapshot.lastUpdatedAt;
      _latitude = _roundTo2(snapshot.data.latitude);
      _longitude = _roundTo2(snapshot.data.longitude);
      locationLabel = snapshot.data.cityLabel;
      usingDefaultLocation = snapshot.data.usingDefaultLocation;
      locationStatus = snapshot.data.usingDefaultLocation
          ? LocationFetchStatus.fallbackDefault
          : LocationFetchStatus.recentArea;
      debugLocationSource = 'persistedCache';
      state = AirQualityViewState.loaded;
      isInitialLoading = false;
      isRefreshing = true;
      _hasValidDisplayedLocation = true;
      notifyListeners();
      unawaited(_initializeFastFirst(nonBlocking: true));
      _startLocationListener();
      return;
    }

    await _initializeFastFirst();
    _startLocationListener();
  }

  Future<void> retryLocation() async {
    isRefreshing = true;
    notifyListeners();
    await _refreshFromCurrentLocationUserInitiated();
    isRefreshing = false;
    notifyListeners();
    _startLocationListener();
  }

  Future<void> forceRecheckDeviceLocation() async {
    final key = _repository.cacheKeyFor(_latitude, _longitude);
    if (kDebugMode) {
      debugPrint('[AQ CTRL] forceRecheck start key=$key');
    }
    _repository.invalidateCacheFor(_latitude, _longitude);
    data = null;
    errorMessage = null;
    state = AirQualityViewState.initial;
    locationStatus = null;
    usingDefaultLocation = true;
    locationLabel = 'Your area';
    debugLocationSource = null;
    debugCacheKey = null;
    debugCacheReused = null;
    debugApiFetched = null;
    notifyListeners();

    await _refreshFromCurrentLocationUserInitiated(forceRefresh: true);
    _startLocationListener();
  }

  Future<void> applyDebugLocationOverride({
    required String label,
    required double latitude,
    required double longitude,
  }) async {
    final roundedLat = _roundTo2(latitude);
    final roundedLon = _roundTo2(longitude);
    _latitude = roundedLat;
    _longitude = roundedLon;
    usingDefaultLocation = false;
    locationStatus = LocationFetchStatus.granted;
    locationLabel = label;
    debugLocationSource = 'debugOverride';
    infoMessage = null;
    if (kDebugMode) {
      debugPrint(
        '[AQ CTRL] debug override label=$label lat=${roundedLat.toStringAsFixed(2)} lon=${roundedLon.toStringAsFixed(2)}',
      );
    }
    await _load(requestLocation: false, forceRefresh: true, silent: false);
    _startLocationListener();
  }

  Future<void> manualRefresh() async {
    isRefreshing = true;
    notifyListeners();
    LocationFetchResult? latestLocation;
    try {
      latestLocation = await _locationService.getLocation();
    } catch (_) {
      latestLocation = null;
    }

    var locationChanged = false;
    if (latestLocation != null) {
      final newLat = _roundTo2(latestLocation.point.latitude);
      final newLon = _roundTo2(latestLocation.point.longitude);
      locationChanged = newLat != _latitude || newLon != _longitude;

      locationStatus = latestLocation.status;
      usingDefaultLocation = latestLocation.usingDefault;
      locationLabel = latestLocation.cityLabel;
      _latitude = newLat;
      _longitude = newLon;
    }

    if (!locationChanged && !canRefresh) {
      infoMessage =
          'Data was refreshed recently. Please try again in ${_minutesAndSeconds(remainingThrottleDuration)}.';
      isRefreshing = false;
      notifyListeners();
      return;
    }

    await _load(requestLocation: false, forceRefresh: true, silent: true);
    isRefreshing = false;
    notifyListeners();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLocationListener();
      final now = DateTime.now();
      if (_lastResumeRefreshAt != null &&
          now.difference(_lastResumeRefreshAt!) < const Duration(minutes: 2)) {
        return;
      }
      _lastResumeRefreshAt = now;
      isRefreshing = true;
      notifyListeners();
      _refreshFreshInBackground();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopLocationListener();
    }
  }

  @override
  void dispose() {
    _stopLocationListener();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startLocationListener() {
    if (_locationSubscription != null) {
      if (kDebugMode) {
        debugPrint('[LOC_STREAM] refresh skipped reason=already_started');
      }
      return;
    }
    if (kDebugMode) {
      debugPrint('[LOC_STREAM] started');
    }

    _locationSubscription = _locationService.watchApproximateAreaChanges().listen(
      (result) {
        _onLocationStreamUpdate(result);
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[LOC_STREAM] error=$error');
        }
      },
      cancelOnError: false,
    );
    _startDebugForegroundRecheck();
  }

  void _stopLocationListener() {
    if (kDebugMode && _locationSubscription != null) {
      debugPrint('[LOC_STREAM] cancelled');
    }
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _stopDebugForegroundRecheck();
  }

  void _onLocationStreamUpdate(LocationFetchResult result) {
    if (kDebugMode) {
      debugPrint('[LOC_STREAM] event received');
    }
    final nextLat = _roundTo2(result.point.latitude);
    final nextLon = _roundTo2(result.point.longitude);
    if (kDebugMode) {
      debugPrint(
        '[LOC_STREAM] rounded coordinate lat=${nextLat.toStringAsFixed(2)} lon=${nextLon.toStringAsFixed(2)}',
      );
    }
    if (nextLat == _latitude && nextLon == _longitude) {
      if (kDebugMode) {
        debugPrint('[LOC_STREAM] coordinate changed=no');
        debugPrint('[LOC_STREAM] refresh triggered=no');
        debugPrint('[LOC_STREAM] refresh skipped reason=same_coordinate');
      }
      return;
    }
    if (kDebugMode) {
      debugPrint('[LOC_STREAM] coordinate changed=yes');
    }

    final now = DateTime.now();
    if (_lastAreaRefreshAt != null &&
        now.difference(_lastAreaRefreshAt!) < const Duration(seconds: 30)) {
      if (kDebugMode) {
        debugPrint('[LOC_STREAM] refresh triggered=no');
        debugPrint('[LOC_STREAM] refresh skipped reason=debounced');
      }
      return;
    }

    _lastAreaRefreshAt = now;
    _latitude = nextLat;
    _longitude = nextLon;
    locationStatus = result.status;
    usingDefaultLocation = result.usingDefault;
    locationLabel = result.cityLabel;
    debugLocationSource = result.source;
    infoMessage = 'Area changed. Updating air quality data…';
    isRefreshing = true;
    if (kDebugMode) {
      debugPrint(
        '[LOC_STREAM] refresh triggered=yes source=${result.source} lat=${nextLat.toStringAsFixed(2)} lon=${nextLon.toStringAsFixed(2)}',
      );
    }
    notifyListeners();

    // TODO: Background air quality alert requires separate opt-in permission
    // and background task design.
    _load(requestLocation: false, forceRefresh: true, silent: true);
    unawaited(
      _notificationStorage.saveLastKnownRoundedCoordinate(
        latitude: _latitude,
        longitude: _longitude,
      ),
    );
  }

  void _startDebugForegroundRecheck() {
    if (!kDebugMode || _debugForegroundRecheckTimer != null) {
      return;
    }
    _debugForegroundRecheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _runDebugForegroundRecheck(),
    );
    if (kDebugMode) {
      debugPrint('[LOC_STREAM] debug foreground recheck started');
    }
  }

  void _stopDebugForegroundRecheck() {
    if (!kDebugMode) {
      return;
    }
    if (_debugForegroundRecheckTimer != null) {
      debugPrint('[LOC_STREAM] debug foreground recheck stopped');
    }
    _debugForegroundRecheckTimer?.cancel();
    _debugForegroundRecheckTimer = null;
  }

  Future<void> _runDebugForegroundRecheck() async {
    if (!kDebugMode || _locationSubscription == null) {
      return;
    }
    final result = await _locationService.getFreshCurrentLocation(
      allowRecentLastKnownFallback: true,
      fallbackMaxAge: const Duration(minutes: 3),
    );
    if (result == null) {
      debugPrint('[LOC_STREAM] refresh triggered=no');
      debugPrint('[LOC_STREAM] refresh skipped reason=debug_recheck_no_location');
      return;
    }

    final nextLat = _roundTo2(result.point.latitude);
    final nextLon = _roundTo2(result.point.longitude);
    debugPrint(
      '[LOC_STREAM] rounded coordinate lat=${nextLat.toStringAsFixed(2)} lon=${nextLon.toStringAsFixed(2)}',
    );
    if (nextLat == _latitude && nextLon == _longitude) {
      debugPrint('[LOC_STREAM] coordinate changed=no');
      debugPrint('[LOC_STREAM] refresh triggered=no');
      debugPrint('[LOC_STREAM] refresh skipped reason=debug_recheck_same_coordinate');
      return;
    }

    debugPrint('[LOC_STREAM] coordinate changed=yes');
    _onLocationStreamUpdate(result);
  }

  Future<void> _load({
    required bool requestLocation,
    required bool forceRefresh,
    required bool silent,
  }) async {
    if (!silent && data == null) {
      state = AirQualityViewState.loading;
      isInitialLoading = true;
    }
    errorMessage = null;
    if (!forceRefresh) {
      infoMessage = null;
    }
    notifyListeners();

    try {
      if (requestLocation || state == AirQualityViewState.initial) {
        final locationResult = await _locationService.getLocation();
        locationStatus = locationResult.status;
        usingDefaultLocation = locationResult.usingDefault;
        locationLabel = locationResult.cityLabel;
        debugLocationSource = locationResult.source;
        _latitude = _roundTo2(locationResult.point.latitude);
        _longitude = _roundTo2(locationResult.point.longitude);
        _hasValidDisplayedLocation = true;
        if (kDebugMode) {
          debugPrint(
            '[AQ CTRL] location status=$locationStatus label=$locationLabel lat=${_latitude.toStringAsFixed(2)} lon=${_longitude.toStringAsFixed(2)}',
          );
        }
      }

      final result = await _repository.fetch(
        latitude: _latitude,
        longitude: _longitude,
        cityLabel: locationLabel,
        usingDefaultLocation: usingDefaultLocation,
        forceRefresh: forceRefresh,
      );

      data = result.data;
      debugCacheKey = _repository.cacheKeyFor(_latitude, _longitude);
      debugCacheReused = result.fromCache;
      debugApiFetched = !result.fromCache;
      if (kDebugMode) {
        debugPrint(
          '[LOC_STREAM] api cacheReused=${result.fromCache} apiFetched=${!result.fromCache} key=$debugCacheKey',
        );
      }
      lastUpdatedAt = result.lastUpdatedAt;
      unawaited(
        _notificationStorage.saveLastKnownRoundedCoordinate(
          latitude: _latitude,
          longitude: _longitude,
        ),
      );
      state = AirQualityViewState.loaded;
      isInitialLoading = false;

      if (result.throttled) {
        infoMessage =
            'Data was refreshed recently. Please try again in ${_minutesAndSeconds(result.remainingThrottle)}.';
      } else if (result.fromCache && infoMessage == null) {
        infoMessage = 'Showing cached data from the last update.';
      }
    } catch (e) {
      state = AirQualityViewState.error;
      isInitialLoading = false;
      errorMessage = e.toString();
      if (data != null) {
        state = AirQualityViewState.loaded;
        infoMessage = 'Could not refresh. Showing previously cached data.';
      }
    }

    isRefreshing = false;
    notifyListeners();
  }

  Future<void> _initializeFastFirst({bool nonBlocking = false}) async {
    if (!nonBlocking) {
      state = AirQualityViewState.loading;
      isInitialLoading = true;
      locationStatus = null;
      notifyListeners();
    }
    isRefreshing = nonBlocking;

    final recent = await _locationService.getRecentLastKnownForStartup();
    if (recent != null) {
      locationStatus = recent.status;
      usingDefaultLocation = recent.usingDefault;
      locationLabel = recent.cityLabel;
      debugLocationSource = recent.source;
      _latitude = _roundTo2(recent.point.latitude);
      _longitude = _roundTo2(recent.point.longitude);
      _hasValidDisplayedLocation = true;
      await _load(
        requestLocation: false,
        forceRefresh: false,
        silent: nonBlocking,
      );
      unawaited(_refreshFreshInBackground());
      return;
    }

    await _load(
      requestLocation: true,
      forceRefresh: false,
      silent: nonBlocking,
    );
  }

  Future<void> _refreshFreshInBackground() async {
    final fresh = await _locationService.getFreshCurrentLocation(
      allowRecentLastKnownFallback: false,
    );
    if (fresh == null) {
      isRefreshing = false;
      notifyListeners();
      return;
    }

    final nextLat = _roundTo2(fresh.point.latitude);
    final nextLon = _roundTo2(fresh.point.longitude);
    final changed = nextLat != _latitude || nextLon != _longitude;

    locationStatus = LocationFetchStatus.granted;
    usingDefaultLocation = false;
    locationLabel = fresh.cityLabel;
    debugLocationSource = fresh.source;

    if (!changed) {
      isRefreshing = false;
      notifyListeners();
      return;
    }

    _latitude = nextLat;
    _longitude = nextLon;
    _hasValidDisplayedLocation = true;
    await _load(requestLocation: false, forceRefresh: true, silent: true);
  }

  Future<void> _refreshFromCurrentLocationUserInitiated({
    bool forceRefresh = false,
  }) async {
    if (data == null) {
      state = AirQualityViewState.loading;
      isInitialLoading = true;
      locationStatus = null;
      notifyListeners();
    }

    final fresh = await _locationService.getFreshCurrentLocation(
      allowRecentLastKnownFallback: false,
    );
    if (fresh == null) {
      if (_hasValidDisplayedLocation && data != null) {
        state = AirQualityViewState.loaded;
        infoMessage = 'Location unavailable. Tap Re-check Location.';
        isInitialLoading = false;
        isRefreshing = false;
        notifyListeners();
        return;
      }
      await _load(requestLocation: true, forceRefresh: forceRefresh, silent: false);
      return;
    }

    locationStatus = fresh.status;
    usingDefaultLocation = fresh.usingDefault;
    locationLabel = fresh.cityLabel;
    debugLocationSource = fresh.source;
    _latitude = _roundTo2(fresh.point.latitude);
    _longitude = _roundTo2(fresh.point.longitude);
    _hasValidDisplayedLocation = true;
    await _load(requestLocation: false, forceRefresh: forceRefresh, silent: false);
  }

  String get lastUpdatedRelativeText {
    final value = lastUpdatedAt;
    if (value == null) {
      return 'Updated -';
    }
    final diff = DateTime.now().difference(value);
    if (diff.inSeconds < 60) {
      return 'Updated just now';
    }
    if (diff.inMinutes < 60) {
      return 'Updated ${diff.inMinutes} minutes ago';
    }
    return 'Updated ${diff.inHours} hours ago';
  }

  String _minutesAndSeconds(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    return '$seconds second${seconds == 1 ? '' : 's'}';
  }

  double _roundTo2(double value) => (value * 100).roundToDouble() / 100;
}
