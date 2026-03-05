import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/diagnostics_service.dart';
import 'credential_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _dashboardUrlController;
  late TextEditingController _webminUrlController;
  late TextEditingController _piholeUrlController;
  late TextEditingController _fileConvertorUrlController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsService>(context, listen: false);
    _nameController = TextEditingController(text: settings.userName);
    _ipController = TextEditingController(text: settings.serverIp);
    _dashboardUrlController = TextEditingController(
      text: settings.dashboardUrl,
    );
    _webminUrlController = TextEditingController(text: settings.webminUrl);
    _piholeUrlController = TextEditingController(text: settings.piholeUrl);
    _fileConvertorUrlController = TextEditingController(
      text: settings.fileConvertorUrl,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _dashboardUrlController.dispose();
    _webminUrlController.dispose();
    _piholeUrlController.dispose();
    _fileConvertorUrlController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final settings = Provider.of<SettingsService>(context, listen: false);
      await settings.saveSettings(
        userName: _nameController.text.trim(),
        serverIp: _ipController.text.trim(),
        dashboardUrl: _dashboardUrlController.text.trim(),
        webminUrl: _webminUrlController.text.trim(),
        piholeUrl: _piholeUrlController.text.trim(),
        fileConvertorUrl: _fileConvertorUrlController.text.trim(),
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
      _dashboardUrlController.text = settings.dashboardUrl;
      _webminUrlController.text = settings.webminUrl;
      _piholeUrlController.text = settings.piholeUrl;
      _fileConvertorUrlController.text = settings.fileConvertorUrl;
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
                'Service URLs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dashboardUrlController,
                decoration: const InputDecoration(
                  labelText: 'Dashboard URL',
                  prefixIcon: Icon(Icons.dashboard),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _webminUrlController,
                decoration: const InputDecoration(
                  labelText: 'Webmin URL',
                  prefixIcon: Icon(Icons.terminal),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _piholeUrlController,
                decoration: const InputDecoration(
                  labelText: 'Pi-hole URL',
                  prefixIcon: Icon(Icons.shield),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fileConvertorUrlController,
                decoration: const InputDecoration(
                  labelText: 'File Convertor URL',
                  prefixIcon: Icon(Icons.link),
                ),
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
              Text('Security', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Credential Manager'),
                subtitle: const Text('Manage saved logins for auto-fill'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CredentialManagerScreen(),
                    ),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
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

    // Helper to extract port from URL string
    int getPort(String urlStr, int defaultPort) {
      try {
        final uri = Uri.parse(urlStr);
        if (uri.hasPort) return uri.port;
        if (uri.isScheme('https')) return 443;
        if (uri.isScheme('http')) return 80;
      } catch (_) {}
      return defaultPort;
    }

    // Helper to extract host from URL string
    String getHost(String urlStr, String defaultHost) {
      try {
        final uri = Uri.parse(urlStr);
        if (uri.host.isNotEmpty) return uri.host;
      } catch (_) {}
      return defaultHost;
    }

    // Test Dashboard
    final dashHost = getHost(settings.dashboardUrl, settings.serverIp);
    final dashPort = getPort(settings.dashboardUrl, 3000);
    final dashResult = await _diagnostics.testConnection(dashHost, dashPort);
    if (mounted) setState(() => _results['Dashboard TCP'] = dashResult);

    // Test Webmin
    final webminHost = getHost(settings.webminUrl, settings.serverIp);
    final webminPort = getPort(settings.webminUrl, 10000);
    final webminResult = await _diagnostics.testConnection(
      webminHost,
      webminPort,
    );
    if (mounted) setState(() => _results['Webmin TCP'] = webminResult);

    // Test Webmin HTTP (to check if SSL/HTTP is responding even if TCP is open)
    final webminUrl = settings.webminUrl;
    final webminHttpResult = await _diagnostics.testHttp(webminUrl);
    if (mounted) setState(() => _results['Webmin HTTP'] = webminHttpResult);

    // Test Pi-hole
    final piholeHost = getHost(settings.piholeUrl, settings.serverIp);
    final piholePort = getPort(settings.piholeUrl, 80);
    final piholeResult = await _diagnostics.testConnection(
      piholeHost,
      piholePort,
    );
    if (mounted) setState(() => _results['Pi-hole TCP'] = piholeResult);

    // Test File Convertor
    final fileConvertorHost = getHost(
      settings.fileConvertorUrl,
      settings.serverIp,
    );
    final fileConvertorPort = getPort(settings.fileConvertorUrl, 80);
    final fileConvertorResult = await _diagnostics.testConnection(
      fileConvertorHost,
      fileConvertorPort,
    );
    if (mounted) {
      setState(() => _results['File Convertor TCP'] = fileConvertorResult);
      setState(() => _testing = false);
    }
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
