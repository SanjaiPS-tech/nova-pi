import 'dart:async';
import 'dart:io';

class DiagnosticsService {
  Future<Map<String, dynamic>> testConnection(String host, int port) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      stopwatch.stop();
      return {
        'status': 'ok',
        'latency': stopwatch.elapsedMilliseconds,
        'message': 'Connected successfully',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'status': 'error',
        'latency': stopwatch.elapsedMilliseconds,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> testHttp(String url) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) =>
          true; // Ignore SSL errors for diagnostics
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      final response = await request.close();
      stopwatch.stop();
      return {
        'status': 'ok',
        'statusCode': response.statusCode,
        'latency': stopwatch.elapsedMilliseconds,
        'message': 'HTTP ${response.statusCode}',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'status': 'error',
        'latency': stopwatch.elapsedMilliseconds,
        'message': e.toString(),
      };
    }
  }
}
