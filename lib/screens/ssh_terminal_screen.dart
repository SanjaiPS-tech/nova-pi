import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../services/settings_service.dart';
import '../services/ssh_service.dart';
import '../utils/theme.dart';

class SSHTerminalScreen extends StatefulWidget {
  const SSHTerminalScreen({super.key});

  @override
  State<SSHTerminalScreen> createState() => _SSHTerminalScreenState();
}

class _SSHTerminalScreenState extends State<SSHTerminalScreen> {
  final _sshService = SSHService();
  final _terminalController = TerminalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connect();
    });
  }

  Future<void> _connect() async {
    if (!mounted) return;
    final settings = Provider.of<SettingsService>(context, listen: false);
    await _sshService.connect(settings);
  }

  @override
  void dispose() {
    _terminalController.dispose();
    _sshService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SSHService>.value(
      value: _sshService,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Consumer<SSHService>(
            builder: (context, ssh, child) {
              if (ssh.isConnected) {
                return Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 8),
                    const Text('Terminal (Connected)'),
                  ],
                );
              }
              if (ssh.error.isNotEmpty) {
                return const Text(
                  'Terminal (Error)',
                  style: TextStyle(color: Colors.red),
                );
              }
              return Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NovaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Terminal (Connecting...)'),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () async {
                _sshService.disconnect();
                _sshService.terminal.eraseDisplay();
                await Future.delayed(const Duration(milliseconds: 100));
                if (mounted) {
                  _connect();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Consumer<SSHService>(
            builder: (context, ssh, child) {
              if (ssh.error.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Connection Failed',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ssh.error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: NovaTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _connect,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: TerminalView(
                      ssh.terminal,
                      controller: _terminalController,
                      autofocus: true,
                      textStyle: const TerminalStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
