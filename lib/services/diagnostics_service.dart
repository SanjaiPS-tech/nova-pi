import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../utils/theme.dart';

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
      client.badCertificateCallback = (cert, host, port) => true;
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

  void runConnectionTests(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _DiagnosticsSheet(settings: settings, service: this),
    );
  }
}

class _DiagnosticsSheet extends StatefulWidget {
  final SettingsService settings;
  final DiagnosticsService service;
  const _DiagnosticsSheet({required this.settings, required this.service});

  @override
  State<_DiagnosticsSheet> createState() => _DiagnosticsSheetState();
}

class _DiagnosticsSheetState extends State<_DiagnosticsSheet> {
  final List<Map<String, dynamic>> _results = [];
  bool _isTesting = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final s = widget.settings;
    final d = widget.service;

    int getPort(String url, int def) =>
        Uri.tryParse(url)?.port ?? (url.startsWith('https') ? 443 : def);
    String getHost(String url) => Uri.tryParse(url)?.host ?? '';

    final targets = [
      {'name': 'Dashboard', 'url': s.dashboardUrl1, 'port': 80},
      {'name': 'Webmin', 'url': s.webminUrl1, 'port': 10000},
      {'name': 'Pi-hole', 'url': s.piholeUrl1, 'port': 80},
      {'name': 'File Convertor', 'url': s.fileConvertorUrl1, 'port': 80},
      {
        'name': 'SSH Terminal',
        'url': 'http://\${s.sshHost}',
        'port': s.sshPort,
      },
    ];

    for (var t in targets) {
      final name = t['name'] as String;
      final portFallback = t['port'] as int;

      String host;
      int port;

      if (name == 'SSH Terminal') {
        host = s.sshHost;
        port = s.sshPort;
      } else {
        final url = t['url'] as String;
        if (url.isEmpty) continue;
        host = getHost(url);
        port = getPort(url, portFallback);
      }

      final res = await d.testConnection(host, port);
      if (mounted) {
        setState(() {
          _results.add({
            'name': t['name'],
            'success': res['status'] == 'ok',
            'latency': res['latency'],
            'msg': res['message'],
          });
        });
      }
    }
    if (mounted) setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: NovaTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Network Diagnostics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_isTesting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ..._results.map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (r['success'] as bool ? NovaTheme.secondary : Colors.red)
                          .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  r['success'] as bool
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: r['success'] as bool
                      ? NovaTheme.secondary
                      : Colors.red,
                  size: 20,
                ),
              ),
              title: Text(
                r['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${r['msg']} (${r['latency']}ms)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
