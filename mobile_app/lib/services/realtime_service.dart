/// RealtimeService provides real-time updates for the smart home app.
/// The actual sensor data comes from Firebase through DeviceProvider.
/// This service can be used for additional real-time features like
/// connection monitoring or background sync.
class RealtimeService {
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  static bool get isInitialized => _isInitialized;

  static void dispose() {
    _isInitialized = false;
  }
}
