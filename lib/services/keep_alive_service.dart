import 'dart:async';
import 'package:http/http.dart' as http;

class KeepAliveService {
  static const _pingUrl =
      'https://flux-virtual-backend.onrender.com/pricing';
  static const _interval = Duration(minutes: 14);

  static Timer? _timer;

  static void start() {
    if (_timer != null) return; // already running
    _ping(); // ping immediately on start
    _timer = Timer.periodic(_interval, (_) => _ping());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _ping() async {
    try {
      await http.get(Uri.parse(_pingUrl)).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Silently ignore — this is best-effort only
    }
  }
}
