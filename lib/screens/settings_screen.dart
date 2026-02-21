import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/diagnostics_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _dashboardPortController;
  late TextEditingController _webminPortController;
  late TextEditingController _piholePathController;
  late TextEditingController _converterPortController;

  String _dashboardScheme = 'http';
  String _webminScheme = 'https';
  String _converterScheme = 'http';

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsService>(context, listen: false);
    _nameController = TextEditingController(text: settings.userName);
    _ipController = TextEditingController(text: settings.serverIp);
    _dashboardPortController = TextEditingController(
      text: settings.dashboardPort,
    );
    _webminPortController = TextEditingController(text: settings.webminPort);
    _piholePathController = TextEditingController(text: settings.piholePath);
    _converterPortController = TextEditingController(
      text: settings.converterPort,
    );
    _dashboardScheme = settings.dashboardScheme;
    _webminScheme = settings.webminScheme;
    _converterScheme = settings.converterScheme;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _dashboardPortController.dispose();
    _webminPortController.dispose();
    _piholePathController.dispose();
    _converterPortController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final settings = Provider.of<SettingsService>(context, listen: false);
      await settings.saveSettings(
        userName: _nameController.text.trim(),
        serverIp: _ipController.text.trim(),
        dashboardPort: _dashboardPortController.text.trim(),
        dashboardScheme: _dashboardScheme,
        webminPort: _webminPortController.text.trim(),
        webminScheme: _webminScheme,
        piholePath: _piholePathController.text.trim(),
        converterPort: _converterPortController.text.trim(),
        converterScheme: _converterScheme,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        Navigator.pop(context);
      }
    }
  }

  void _reset() async {
    final settings = Provider.of<SettingsService>(context, listen: false);
    await settings.resetDefaults();
    setState(() {
      _dashboardPortController.text = settings.dashboardPort;
      _webminPortController.text = settings.webminPort;
      _piholePathController.text = settings.piholePath;
      _converterPortController.text = settings.converterPort;
      _dashboardScheme = settings.dashboardScheme;
      _webminScheme = settings.webminScheme;
      _converterScheme = settings.converterScheme;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Defaults restored')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connection Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'User Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Server IP',
                  prefixIcon: Icon(Icons.dns),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              Text(
                'Port Configuration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Dashboard Configuration
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _dashboardScheme,
                      decoration: const InputDecoration(labelText: 'Protocol'),
                      items: ['http', 'https']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _dashboardScheme = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dashboardPortController,
                      decoration: const InputDecoration(
                        labelText: 'Dashboard Port',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Webmin Configuration
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _webminScheme,
                      decoration: const InputDecoration(labelText: 'Protocol'),
                      items: ['http', 'https']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _webminScheme = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _webminPortController,
                      decoration: const InputDecoration(
                        labelText: 'Webmin Port',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _piholePathController,
                decoration: const InputDecoration(labelText: 'Pi-hole Path'),
              ),
              const SizedBox(height: 16),
              // Converter Configuration
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _converterScheme,
                      decoration: const InputDecoration(labelText: 'Protocol'),
                      items: ['http', 'https']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _converterScheme = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _converterPortController,
                      decoration: const InputDecoration(
                        labelText: 'Converter Port',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text('Reset Component Defaults'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              Text(
                'Troubleshooting',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _runDiagnostics,
                icon: const Icon(Icons.build),
                label: const Text('Test Connections'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runDiagnostics() {
    showDialog(context: context, builder: (ctx) => const DiagnosticsDialog());
  }
}

class DiagnosticsDialog extends StatefulWidget {
  const DiagnosticsDialog({super.key});

  @override
  State<DiagnosticsDialog> createState() => _DiagnosticsDialogState();
}

class _DiagnosticsDialogState extends State<DiagnosticsDialog> {
  final _diagnostics = DiagnosticsService();
  Map<String, Map<String, dynamic>> _results = {};
  bool _testing = true;

  @override
  void initState() {
    super.initState();
    _startTests();
  }

  Future<void> _startTests() async {
    final settings = Provider.of<SettingsService>(context, listen: false);

    // Test Server Reachability (Ping-like check via port 22 or 80 usually, but let's try the configured ports)

    // Test Dashboard
    final dashResult = await _diagnostics.testConnection(
      settings.serverIp,
      int.tryParse(settings.dashboardPort) ?? 3000,
    );
    if (mounted) setState(() => _results['Dashboard TCP'] = dashResult);

    // Test Webmin
    final webminResult = await _diagnostics.testConnection(
      settings.serverIp,
      int.tryParse(settings.webminPort) ?? 10000,
    );
    if (mounted) setState(() => _results['Webmin TCP'] = webminResult);

    // Test Webmin HTTP (to check if SSL/HTTP is responding even if TCP is open)
    final webminUrl = settings.webminUrl;
    final webminHttpResult = await _diagnostics.testHttp(webminUrl);
    if (mounted) setState(() => _results['Webmin HTTP'] = webminHttpResult);

    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Network Diagnostics'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_testing) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            ..._results.entries.map((e) {
              final success = e.value['status'] == 'ok';
              return ListTile(
                leading: Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                title: Text(e.key),
                subtitle: Text(
                  '${e.value['message']} (${e.value['latency']}ms)',
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
