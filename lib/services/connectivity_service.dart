import 'dart:async';
import 'dart:io';
// import 'package:http/http.dart' as http; // Unused now
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

    try {
      // Try to connect to port 80, 443, or the user configured dashboard port
      // Since we don't have easy access to the configured port here without passing it,
      // we'll try a generic reachability check or we can pass the port in startMonitoring.
      // For now, let's try a Socket connect to the IP on proper ports.
      // Detailed logic: Try connecting to the IP.

      // We will try to connect to the IP on port 80 first (common).
      // If that fails, we might be on a custom port.
      // Ideally this service should know the port.

      // Since we just want to know if "Server is reachable",
      // ICMP is hard. Socket connect to a likely open port is best.
      // Let's try port 22 (SSH) as it's a Pi, or 80/443.

      // Better approach: resolving the address alone proves DNS/Net (if hostname),
      // but we have an IP.

      // Let's try to connect to the dashboard port if we could, but here we only have IP.
      // Let's assume port 80 for general availability, or 22 since it's a Pi.
      // Let's try 80 first.

      final socket = await Socket.connect(
        ipAddress,
        80,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();

      if (!_isOnline) {
        _isOnline = true;
        notifyListeners();
      }
    } catch (_) {
      // If 80 fails, try 22 (SSH) which is almost always open on Pis
      try {
        final socket = await Socket.connect(
          ipAddress,
          22,
          timeout: const Duration(seconds: 2),
        );
        socket.destroy();
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
}
