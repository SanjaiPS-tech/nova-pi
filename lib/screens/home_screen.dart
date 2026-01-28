import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/settings_service.dart';
import '../services/connectivity_service.dart';
import 'settings_screen.dart';
import 'webview_screen.dart';
import 'file_explorer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start monitoring connectivity when Home Screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
      final settings = Provider.of<SettingsService>(context, listen: false);
      Provider.of<ConnectivityService>(
        context,
        listen: false,
      ).startMonitoring(settings.serverIp);
    });
  }

  Future<void> _checkPermissions() async {
    // Request storage permissions
    // On Android 13+, usage is different (images/video/audio), but generic 'storage' is good baseline.
    if (await Permission.storage.request().isDenied) {
      // Handle denial or show explanation
    }
    // Manage external storage for Android 11+ (optional, might be restricted)
    // if (await Permission.manageExternalStorage.request().isDenied) {}
  }

  @override
  void dispose() {
    // We don't stop monitoring here because we might want it to continue if settings is pushed?
    // But usually we should keep it running or stop. Let's keep running.
    super.dispose();
  }

  void _openWebView(BuildContext context, String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: connectivity.isOnline
                    ? Colors.green
                    : Colors.red.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: connectivity.isOnline ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (connectivity.isOnline ? Colors.green : Colors.red)
                                .withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    connectivity.isOnline
                        ? 'Connected to ${settings.serverIp}'
                        : 'Offline - Checking ${settings.serverIp}...',
                    style: TextStyle(
                      color: connectivity.isOnline ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildGridItem(
                  context,
                  icon: Icons.dashboard,
                  info: 'Port ${settings.dashboardPort}',
                  label: 'Dashboard',
                  color: Colors.blueAccent,
                  onTap: () =>
                      _openWebView(context, settings.dashboardUrl, 'Dashboard'),
                ),
                _buildGridItem(
                  context,
                  icon: Icons.terminal,
                  info: 'Port ${settings.webminPort}',
                  label: 'Webmin',
                  color: Colors.purpleAccent,
                  onTap: () =>
                      _openWebView(context, settings.webminUrl, 'Webmin'),
                ),
                _buildGridItem(
                  context,
                  icon: Icons.shield,
                  info: settings.piholePath,
                  label: 'Pi-hole',
                  color: Colors.redAccent,
                  onTap: () =>
                      _openWebView(context, settings.piholeUrl, 'Pi-hole'),
                ),
                _buildGridItem(
                  context,
                  icon: Icons.folder,
                  info: 'SMB / SFTP',
                  label: 'File Explorer',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FileExplorerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String info,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                info,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
