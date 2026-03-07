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
  late TextEditingController _serverIpController;
  late TextEditingController _dashboardUrl1Controller;
  late TextEditingController _dashboardUrl2Controller;
  late TextEditingController _webminUrl1Controller;
  late TextEditingController _webminUrl2Controller;
  late TextEditingController _piholeUrl1Controller;
  late TextEditingController _piholeUrl2Controller;
  late TextEditingController _fileConvertorUrl1Controller;
  late TextEditingController _fileConvertorUrl2Controller;
  late TextEditingController _sshHostController;
  late TextEditingController _sshPortController;
  late TextEditingController _sshUsernameController;
  late TextEditingController _sshPasswordController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsService>(context, listen: false);
    _nameController = TextEditingController(text: settings.userName);
    _serverIpController = TextEditingController(text: settings.serverIp);
    _dashboardUrl1Controller = TextEditingController(
      text: settings.dashboardUrl1,
    );
    _dashboardUrl2Controller = TextEditingController(
      text: settings.dashboardUrl2,
    );
    _webminUrl1Controller = TextEditingController(text: settings.webminUrl1);
    _webminUrl2Controller = TextEditingController(text: settings.webminUrl2);
    _piholeUrl1Controller = TextEditingController(text: settings.piholeUrl1);
    _piholeUrl2Controller = TextEditingController(text: settings.piholeUrl2);
    _fileConvertorUrl1Controller = TextEditingController(
      text: settings.fileConvertorUrl1,
    );
    _fileConvertorUrl2Controller = TextEditingController(
      text: settings.fileConvertorUrl2,
    );
    _sshHostController = TextEditingController(text: settings.sshHost);
    _sshPortController = TextEditingController(
      text: settings.sshPort.toString(),
    );
    _sshUsernameController = TextEditingController(text: settings.sshUsername);
    _sshPasswordController = TextEditingController(text: settings.sshPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverIpController.dispose();
    _dashboardUrl1Controller.dispose();
    _dashboardUrl2Controller.dispose();
    _webminUrl1Controller.dispose();
    _webminUrl2Controller.dispose();
    _piholeUrl1Controller.dispose();
    _piholeUrl2Controller.dispose();
    _fileConvertorUrl1Controller.dispose();
    _fileConvertorUrl2Controller.dispose();
    _sshHostController.dispose();
    _sshPortController.dispose();
    _sshUsernameController.dispose();
    _sshPasswordController.dispose();
    super.dispose();
  }

  void _save(SettingsService settings) async {
    if (_formKey.currentState!.validate()) {
      await settings.saveSettings(
        userName: _nameController.text.trim(),
        serverIp: _serverIpController.text.trim(),
        dashboardUrl1: _dashboardUrl1Controller.text.trim(),
        dashboardUrl2: _dashboardUrl2Controller.text.trim(),
        webminUrl1: _webminUrl1Controller.text.trim(),
        webminUrl2: _webminUrl2Controller.text.trim(),
        piholeUrl1: _piholeUrl1Controller.text.trim(),
        piholeUrl2: _piholeUrl2Controller.text.trim(),
        fileConvertorUrl1: _fileConvertorUrl1Controller.text.trim(),
        fileConvertorUrl2: _fileConvertorUrl2Controller.text.trim(),
        sshHost: _sshHostController.text.trim(),
        sshPort: int.tryParse(_sshPortController.text.trim()) ?? 22,
        sshUsername: _sshUsernameController.text.trim(),
        sshPassword: _sshPasswordController.text.trim(),
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

                _buildSectionTitle('Server Connection'),
                _buildCard([
                  _buildTextField(
                    controller: _serverIpController,
                    label: 'Server Credential (IP/Hostname)',
                    icon: Icons.dns_outlined,
                  ),
                ]),
                const SizedBox(height: 32),

                _buildSectionTitle('Connectivity'),
                _buildCard([
                  _buildConnectivityTile(
                    title: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    primaryController: _dashboardUrl1Controller,
                    secondaryController: _dashboardUrl2Controller,
                  ),
                  const Divider(height: 1, indent: 56, color: Colors.white10),
                  _buildConnectivityTile(
                    title: 'Webmin',
                    icon: Icons.terminal_outlined,
                    primaryController: _webminUrl1Controller,
                    secondaryController: _webminUrl2Controller,
                  ),
                  const Divider(height: 1, indent: 56, color: Colors.white10),
                  _buildConnectivityTile(
                    title: 'Pi-hole',
                    icon: Icons.shield_outlined,
                    primaryController: _piholeUrl1Controller,
                    secondaryController: _piholeUrl2Controller,
                  ),
                  const Divider(height: 1, indent: 56, color: Colors.white10),
                  _buildConnectivityTile(
                    title: 'File Convertor',
                    icon: Icons.insert_drive_file_outlined,
                    primaryController: _fileConvertorUrl1Controller,
                    secondaryController: _fileConvertorUrl2Controller,
                  ),
                ]),
                const SizedBox(height: 32),

                _buildSectionTitle('Terminal (SSH)'),
                _buildCard([
                  _buildTextField(
                    controller: _sshHostController,
                    label: 'Host IP',
                    icon: Icons.computer_rounded,
                  ),
                  const Divider(height: 1, indent: 56, color: Colors.white10),
                  _buildTextField(
                    controller: _sshPortController,
                    label: 'Port',
                    icon: Icons.settings_ethernet_rounded,
                  ),
                  const Divider(height: 1, indent: 56, color: Colors.white10),
                  _buildTextField(
                    controller: _sshUsernameController,
                    label: 'Username',
                    icon: Icons.person_rounded,
                  ),
                  const Divider(height: 1, indent: 56, color: Colors.white10),
                  _buildTextField(
                    controller: _sshPasswordController,
                    label: 'Password',
                    icon: Icons.lock_rounded,
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
        color: NovaTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
          prefixIcon: Icon(
            icon,
            color: NovaTheme.primary.withValues(alpha: 0.7),
          ),
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

  Widget _buildConnectivityTile({
    required String title,
    required IconData icon,
    required TextEditingController primaryController,
    required TextEditingController secondaryController,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: NovaTheme.primary.withValues(alpha: 0.7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text(
          'Configure URLs',
          style: TextStyle(fontSize: 12, color: NovaTheme.textSecondary),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          _buildTextField(
            controller: primaryController,
            label: 'Primary URL',
            icon: Icons.looks_one_outlined,
          ),
          _buildTextField(
            controller: secondaryController,
            label: 'Secondary URL (Fallback)',
            icon: Icons.looks_two_outlined,
          ),
        ],
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
