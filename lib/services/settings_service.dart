import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyUserName = 'userName';
  static const String _keyServerIp = 'serverIp';
  static const String _keyDashboardPort = 'dashboardPort';
  static const String _keyDashboardScheme = 'dashboardScheme';
  static const String _keyWebminPort = 'webminPort';
  static const String _keyWebminScheme = 'webminScheme';
  static const String _keyPiholePath = 'piholePath';

  late SharedPreferences _prefs;
  bool _initialized = false;

  String _userName = '';
  String _serverIp = '';
  String _dashboardPort = '3000';
  String _dashboardScheme = 'http';
  String _webminPort = '10000';
  String _webminScheme = 'https';
  String _piholePath = '/admin/login';

  bool get initialized => _initialized;
  String get userName => _userName;
  String get serverIp => _serverIp;
  String get dashboardPort => _dashboardPort;
  String get dashboardScheme => _dashboardScheme;
  String get webminPort => _webminPort;
  String get webminScheme => _webminScheme;
  String get piholePath => _piholePath;

  bool get isConfigured => _userName.isNotEmpty && _serverIp.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    _initialized = true;
    notifyListeners();
  }

  void _loadSettings() {
    _userName = _prefs.getString(_keyUserName) ?? '';
    _serverIp = _prefs.getString(_keyServerIp) ?? '';
    _dashboardPort = _prefs.getString(_keyDashboardPort) ?? '3000';
    _dashboardScheme = _prefs.getString(_keyDashboardScheme) ?? 'http';
    _webminPort = _prefs.getString(_keyWebminPort) ?? '10000';
    _webminScheme = _prefs.getString(_keyWebminScheme) ?? 'https';
    _piholePath = _prefs.getString(_keyPiholePath) ?? '/admin/login';
  }

  Future<void> saveSettings({
    required String userName,
    required String serverIp,
    String? dashboardPort,
    String? dashboardScheme,
    String? webminPort,
    String? webminScheme,
    String? piholePath,
  }) async {
    _userName = userName;
    _serverIp = serverIp;
    await _prefs.setString(_keyUserName, userName);
    await _prefs.setString(_keyServerIp, serverIp);

    if (dashboardPort != null) {
      _dashboardPort = dashboardPort;
      await _prefs.setString(_keyDashboardPort, dashboardPort);
    }
    if (dashboardScheme != null) {
      _dashboardScheme = dashboardScheme;
      await _prefs.setString(_keyDashboardScheme, dashboardScheme);
    }
    if (webminPort != null) {
      _webminPort = webminPort;
      await _prefs.setString(_keyWebminPort, webminPort);
    }
    if (webminScheme != null) {
      _webminScheme = webminScheme;
      await _prefs.setString(_keyWebminScheme, webminScheme);
    }
    if (piholePath != null) {
      _piholePath = piholePath;
      await _prefs.setString(_keyPiholePath, piholePath);
    }

    notifyListeners();
  }

  Future<void> resetDefaults() async {
    _dashboardPort = '3000';
    _dashboardScheme = 'http';
    _webminPort = '10000';
    _webminScheme = 'https';
    _piholePath = '/admin/login';

    await _prefs.setString(_keyDashboardPort, _dashboardPort);
    await _prefs.setString(_keyDashboardScheme, _dashboardScheme);
    await _prefs.setString(_keyWebminPort, _webminPort);
    await _prefs.setString(_keyWebminScheme, _webminScheme);
    await _prefs.setString(_keyPiholePath, _piholePath);

    notifyListeners();
  }

  // Getters for full URLs
  String get dashboardUrl =>
      '$_dashboardScheme://$_serverIp:$_dashboardPort/login';
  String get webminUrl => '$_webminScheme://$_serverIp:$_webminPort';
  String get piholeUrl => 'http://$_serverIp$_piholePath';
}
