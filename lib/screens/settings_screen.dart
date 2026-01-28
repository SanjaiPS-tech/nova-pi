import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

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

  String _dashboardScheme = 'http';
  String _webminScheme = 'https';

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
    _dashboardScheme = settings.dashboardScheme;
    _webminScheme = settings.webminScheme;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _dashboardPortController.dispose();
    _webminPortController.dispose();
    _piholePathController.dispose();
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
      _dashboardScheme = settings.dashboardScheme;
      _webminScheme = settings.webminScheme;
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
                      value: Provider.of<SettingsService>(
                        context,
                        listen: false,
                      ).dashboardScheme,
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
                        // We will handle saving differently or just track it in state if needed
                        // For now, we rely on the save method which needs these values.
                        // But wait, the _save method reads from controllers.
                        // We need state variables for these dropdowns.
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
                      value: Provider.of<SettingsService>(
                        context,
                        listen: false,
                      ).webminScheme,
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text('Reset Component Defaults'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
