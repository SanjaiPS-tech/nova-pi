import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ConnectionProfile {
  String id;
  String name;
  String host;
  int port;
  String username; // Optional default username

  ConnectionProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    this.username = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'username': username,
  };

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) {
    return ConnectionProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String? ?? '',
    );
  }
}

class SettingsService extends ChangeNotifier {
  static const String _keyUserName = 'userName';
  static const String _keyServerIp = 'serverIp';
  static const String _keyDashboardPort = 'dashboardPort';
  static const String _keyDashboardScheme = 'dashboardScheme';
  static const String _keyWebminPort = 'webminPort';
  static const String _keyWebminScheme = 'webminScheme';
  static const String _keyPiholePath = 'piholePath';
  static const String _keyConverterPort = 'converterPort';
  static const String _keyConverterScheme = 'converterScheme';
  static const String _keyConnections = 'saved_connections';

  late SharedPreferences _prefs;
  bool _initialized = false;

  String _userName = '';
  String _serverIp = '';
  String _dashboardPort = '3000';
  String _dashboardScheme = 'http';
  String _webminPort = '10000';
  String _webminScheme = 'https';
  String _piholePath = '/admin/login';
  String _converterPort = '8080';
  String _converterScheme = 'http';

  List<ConnectionProfile> _connections = [];

  bool get initialized => _initialized;
  String get userName => _userName;
  String get serverIp => _serverIp;
  String get dashboardPort => _dashboardPort;
  String get dashboardScheme => _dashboardScheme;
  String get webminPort => _webminPort;
  String get webminScheme => _webminScheme;
  String get piholePath => _piholePath;
  String get converterPort => _converterPort;
  String get converterScheme => _converterScheme;
  List<ConnectionProfile> get connections => _connections;

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
    _converterPort = _prefs.getString(_keyConverterPort) ?? '8080';
    _converterScheme = _prefs.getString(_keyConverterScheme) ?? 'http';

    final connString = _prefs.getString(_keyConnections);
    if (connString != null) {
      try {
        final List<dynamic> list = jsonDecode(connString);
        _connections = list.map((e) => ConnectionProfile.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading connections: $e');
        _connections = [];
      }
    }
  }

  Future<void> saveSettings({
    required String userName,
    required String serverIp,
    String? dashboardPort,
    String? dashboardScheme,
    String? webminPort,
    String? webminScheme,
    String? piholePath,
    String? converterPort,
    String? converterScheme,
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
    if (converterPort != null) {
      _converterPort = converterPort;
      await _prefs.setString(_keyConverterPort, converterPort);
    }
    if (converterScheme != null) {
      _converterScheme = converterScheme;
      await _prefs.setString(_keyConverterScheme, converterScheme);
    }

    notifyListeners();
  }

  Future<void> addConnection(ConnectionProfile profile) async {
    _connections.add(profile);
    await _saveConnections();
    notifyListeners();
  }

  Future<void> removeConnection(String id) async {
    _connections.removeWhere((c) => c.id == id);
    await _saveConnections();
    notifyListeners();
  }

  Future<void> _saveConnections() async {
    final String data = jsonEncode(
      _connections.map((e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyConnections, data);
  }

  Future<void> resetDefaults() async {
    _dashboardPort = '3000';
    _dashboardScheme = 'http';
    _webminPort = '10000';
    _webminScheme = 'https';
    _piholePath = '/admin/login';
    _converterPort = '8080';
    _converterScheme = 'http';

    await _prefs.setString(_keyDashboardPort, _dashboardPort);
    await _prefs.setString(_keyDashboardScheme, _dashboardScheme);
    await _prefs.setString(_keyWebminPort, _webminPort);
    await _prefs.setString(_keyWebminScheme, _webminScheme);
    await _prefs.setString(_keyPiholePath, _piholePath);
    await _prefs.setString(_keyConverterPort, _converterPort);
    await _prefs.setString(_keyConverterScheme, _converterScheme);

    notifyListeners();
  }

  // Getters for full URLs
  String get dashboardUrl =>
      '$_dashboardScheme://$_serverIp:$_dashboardPort/login';
  String get webminUrl => '$_webminScheme://$_serverIp:$_webminPort';
  String get piholeUrl => 'http://$_serverIp$_piholePath';
  String get converterUrl => '$_converterScheme://$_serverIp:$_converterPort';
}
