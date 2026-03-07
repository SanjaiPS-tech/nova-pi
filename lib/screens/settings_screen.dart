import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../services/diagnostics_service.dart';
import '../utils/theme.dart';
import 'credential_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dashboardUrlController;
  late TextEditingController _webminUrlController;
  late TextEditingController _piholeUrlController;
  late TextEditingController _fileConvertorUrlController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsService>(context, listen: false);
    _nameController = TextEditingController(text: settings.userName);
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
    _dashboardUrlController.dispose();
    _webminUrlController.dispose();
    _piholeUrlController.dispose();
    _fileConvertorUrlController.dispose();
    super.dispose();
  }

  void _save(SettingsService settings) async {
    if (_formKey.currentState!.validate()) {
      await settings.saveSettings(
        userName: _nameController.text.trim(),
        serverIp: settings.serverIp,
        dashboardUrl: _dashboardUrlController.text.trim(),
        webminUrl: _webminUrlController.text.trim(),
        piholeUrl: _piholeUrlController.text.trim(),
        fileConvertorUrl: _fileConvertorUrlController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: () => _save(settings),
            child: const Text(
              'SAVE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: NovaTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Profile'),
                _buildCard([
                  _buildTextField(
                    controller: _nameController,
                    label: 'User Name',
                    icon: Icons.person_outline_rounded,
                  ),
                ]),
                const SizedBox(height: 32),

                _buildSectionTitle('Connectivity'),
                _buildCard([
                  _buildTextField(
                    controller: _dashboardUrlController,
                    label: 'Dashboard URL',
                    icon: Icons.dashboard_outlined,
                  ),
                  const Divider(height: 32, indent: 40, color: Colors.white10),
                  _buildTextField(
                    controller: _webminUrlController,
                    label: 'Webmin URL',
                    icon: Icons.terminal_outlined,
                  ),
                  const Divider(height: 32, indent: 40, color: Colors.white10),
                  _buildTextField(
                    controller: _piholeUrlController,
                    label: 'Pi-hole URL',
                    icon: Icons.shield_outlined,
                  ),
                  const Divider(height: 32, indent: 40, color: Colors.white10),
                  _buildTextField(
                    controller: _fileConvertorUrlController,
                    label: 'File Convertor URL',
                    icon: Icons.insert_drive_file_outlined,
                  ),
                ]),
                const SizedBox(height: 32),

                _buildSectionTitle('Security'),
                _buildCard([
                  ListTile(
                    leading: const Icon(
                      Icons.password_rounded,
                      color: NovaTheme.primary,
                    ),
                    title: const Text(
                      'Credential Manager',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Manage saved logins for auto-fill'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CredentialManagerScreen(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 32),

                _buildSectionTitle('Diagnostics'),
                _buildCard([
                  ListTile(
                    leading: const Icon(
                      Icons.network_check_rounded,
                      color: NovaTheme.secondary,
                    ),
                    title: const Text(
                      'Network Test',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Check reachability of all services'),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () => DiagnosticsService().runConnectionTests(
                      context,
                      settings,
                    ),
                  ),
                ]),
                const SizedBox(height: 32),

                Center(
                  child: TextButton.icon(
                    onPressed: () => _showResetDialog(settings),
                    icon: const Icon(Icons.restore_rounded, color: Colors.grey),
                    label: const Text(
                      'Reset All Settings',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: NovaTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: NovaTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: NovaTheme.primary.withOpacity(0.7)),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
      ),
    );
  }

  void _showResetDialog(SettingsService settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Settings?'),
        content: const Text(
          'This will clear all your configurations and credentials. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await settings.resetDefaults();
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              }
            },
            child: const Text('RESET', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
