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
        webminPort: _webminPortController.text.trim(),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dashboardPortController,
                      decoration: const InputDecoration(
                        labelText: 'Dashboard Port',
                      ),
                      keyboardType: TextInputType.number,
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
