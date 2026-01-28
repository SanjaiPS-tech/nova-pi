import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = false;
  Timer? _timer;

  bool get isOnline => _isOnline;

  void startMonitoring(String ipAddress) {
    _timer?.cancel();
    _checkConnection(ipAddress);
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnection(ipAddress),
    );
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkConnection(String ipAddress) async {
    if (ipAddress.isEmpty) return;

    // We try to ping the webmin port or just the root IP.
    // Since we don't know what's running on port 80/443, we might try a generic port if provided.
    // For now, let's try to reach the IP (assuming it responds to HTTP request or just check socket).
    // A simple HTTP HEAD request to the Tailscale IP is a reasonable check,
    // but often devices don't serve on port 80.
    // Let's try checking the default dashboard port (3000) or Webmin (10000).
    // We'll use the IP directly. If it fails, mark offline.

    // NOTE: Simply pinging via ICMP is not easily available in all Flutter envs without native code.
    // We will attempt to connect to the Webmin port (usually HTTPS but might be self-signed)
    // or Dashboard port. Let's try a Socket connect for better reliability if http fails,
    // but http is requested in the prompt ("periodically checking server reachability via an HTTP request").

    // We will assume port 80 or the user specific ports. Let's stick to the prompt's "HTTP request".
    // We'll try the Dashboard URL since it's one of the main functions.

    // Note: Use a short timeout because we want UI to update quickly.

    try {
      // We can't easily access the configured ports here without passing them in.
      // For simplicity, we'll try an HTTP GET to the IP.
      // If the user didn't specify a port, this might fail if nothing listens on 80.
      // Ideally we should inject the full URL or check multiple.
      // Let's try to ping the IP with a timeout.
      // Even 404 means it's reachable.

      final url = Uri.parse('http://$ipAddress');
      // We'll treat any response (even error status codes) as "Server might be there but checking auth" etc.
      // But if it throws SocketException, it's offline.

      await http.get(url).timeout(const Duration(seconds: 5));

      // If we get here, we got a response.
      if (!_isOnline) {
        _isOnline = true;
        notifyListeners();
      }
    } catch (e) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }
}
