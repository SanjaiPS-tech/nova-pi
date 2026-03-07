import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../services/connectivity_service.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';
import 'webview_screen.dart';
import 'file_explorer_screen.dart';
import 'ssh_terminal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
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
    if (await Permission.storage.request().isDenied) {}
    if (await Permission.manageExternalStorage.status.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  void _openWebView(
    BuildContext context,
    String url,
    String? secondaryUrl,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            WebViewScreen(url: url, secondaryUrl: secondaryUrl, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'NOVA',
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NovaTheme.background,
              NovaTheme.background.withBlue(60),
              NovaTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(settings, connectivity),
                const SizedBox(height: 24),
                StaggeredGrid.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    StaggeredGridTile.count(
                      crossAxisCellCount: 4,
                      mainAxisCellCount: 1.5,
                      child: _buildBentoItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        info: 'Main Server Control',
                        color: NovaTheme.primary,
                        isHorizontal: true,
                        onTap: () => _openWebView(
                          context,
                          settings.dashboardUrl1,
                          settings.dashboardUrl2,
                          'Dashboard',
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    ),
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 3,
                      child:
                          _buildBentoItem(
                                icon: Icons.terminal_rounded,
                                label: 'Webmin',
                                info: 'System Admin',
                                color: Colors.purpleAccent,
                                isHorizontal: false,
                                iconSize: 64,
                                onTap: () => _openWebView(
                                  context,
                                  settings.webminUrl1,
                                  settings.webminUrl2,
                                  'Webmin',
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 100.ms)
                              .slideY(begin: 0.1),
                    ),
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 1.5,
                      child:
                          _buildBentoItem(
                                icon: Icons.folder_rounded,
                                label: 'Files',
                                info: 'SMB / SFTP',
                                color: Colors.amber,
                                isHorizontal: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FileExplorerScreen(),
                                    ),
                                  );
                                },
                              )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: 0.1),
                    ),
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 1.5,
                      child:
                          _buildBentoItem(
                                icon: Icons.shield_rounded,
                                label: 'Pi-hole',
                                info: 'Ad Blocker',
                                color: Colors.redAccent,
                                isHorizontal: true,
                                onTap: () => _openWebView(
                                  context,
                                  settings.piholeUrl1,
                                  settings.piholeUrl2,
                                  'Pi-hole',
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 700.ms, delay: 300.ms)
                              .slideY(begin: 0.1),
                    ),
                    StaggeredGridTile.count(
                      crossAxisCellCount: 4,
                      mainAxisCellCount: 1.5,
                      child:
                          _buildBentoItem(
                                icon: Icons.code_rounded,
                                label: 'Terminal',
                                info: 'SSH Access',
                                color: Colors.blueAccent,
                                isHorizontal: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SSHTerminalScreen(),
                                    ),
                                  );
                                },
                              )
                              .animate()
                              .fadeIn(duration: 750.ms, delay: 350.ms)
                              .slideY(begin: 0.1),
                    ),
                    StaggeredGridTile.count(
                      crossAxisCellCount: 4,
                      mainAxisCellCount: 1.5,
                      child:
                          _buildBentoItem(
                                icon: Icons.insert_drive_file_rounded,
                                label: 'File Convertor',
                                info: 'Convert Docs & PDFs',
                                color: Colors.orangeAccent,
                                isHorizontal: true,
                                onTap: () => _openWebView(
                                  context,
                                  settings.fileConvertorUrl1,
                                  settings.fileConvertorUrl2,
                                  'File Convertor',
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 800.ms, delay: 400.ms)
                              .slideY(begin: 0.1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    SettingsService settings,
    ConnectivityService connectivity,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            color: NovaTheme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          settings.userName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color:
                  (connectivity.isOnline
                          ? NovaTheme.secondary
                          : Colors.redAccent)
                      .withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connectivity.isOnline
                      ? NovaTheme.secondary
                      : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (connectivity.isOnline
                                  ? NovaTheme.secondary
                                  : Colors.redAccent)
                              .withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                connectivity.isOnline ? 'System Online' : 'System Offline',
                style: TextStyle(
                  color: connectivity.isOnline
                      ? NovaTheme.secondary
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (connectivity.isOnline) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(width: 1, height: 12, color: Colors.white10),
                ),
                Text(
                  settings.serverIp,
                  style: TextStyle(
                    color: NovaTheme.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildBentoItem({
    required IconData icon,
    required String label,
    required String info,
    required Color color,
    required VoidCallback onTap,
    bool isHorizontal = false,
    double? iconSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: NovaTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isHorizontal
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: iconSize ?? 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info,
                              style: TextStyle(
                                fontSize: 12,
                                color: NovaTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconSize != null ? 16 : 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            iconSize != null ? 24 : 16,
                          ),
                        ),
                        child: Icon(icon, color: color, size: iconSize ?? 30),
                      ),
                      const Spacer(),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info,
                        style: TextStyle(
                          fontSize: 12,
                          color: NovaTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
