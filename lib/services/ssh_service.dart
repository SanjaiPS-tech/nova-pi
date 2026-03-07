import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'settings_service.dart';

class SSHService extends ChangeNotifier {
  SSHClient? _client;
  SSHSession? _session;
  final Terminal terminal = Terminal(maxLines: 10000);

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _error = '';
  String get error => _error;

  Future<void> connect(SettingsService settings) async {
    _error = '';
    _isConnected = false;
    notifyListeners();

    try {
      final host = settings.sshHost;
      final port = settings.sshPort;
      final username = settings.sshUsername;
      final password = settings.sshPassword;

      if (host.isEmpty) {
        throw Exception('SSH Host is required');
      }

      _client = SSHClient(
        await SSHSocket.connect(
          host,
          port,
          timeout: const Duration(seconds: 10),
        ),
        username: username,
        onPasswordRequest: () => password,
      );

      _session = await _client!.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      _isConnected = true;
      notifyListeners();

      terminal.onOutput = (data) {
        _session?.write(utf8.encode(data));
      };

      _session!.stdout.listen(
        (data) {
          terminal.write(utf8.decode(data));
        },
        onDone: disconnect,
        onError: (e) {
          _error = 'Session Error: \$e';
          disconnect();
        },
      );
    } catch (e) {
      _error = 'Connection failed: \$e';
      _client?.close();
      _isConnected = false;
      notifyListeners();
      debugPrint('SSH Error: \$e');
    }
  }

  void resizeTerminal(int width, int height) {
    if (_isConnected) {
      _session?.resizeTerminal(width, height);
    }
  }

  void disconnect() {
    _session?.close();
    _client?.close();
    _session = null;
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
