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

class SavedCredential {
  String id;
  String title;
  String uid;
  String password;

  SavedCredential({
    required this.id,
    required this.title,
    required this.uid,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'uid': uid,
    'password': password,
  };

  factory SavedCredential.fromJson(Map<String, dynamic> json) {
    return SavedCredential(
      id: json['id'] as String,
      title: json['title'] as String,
      uid: json['uid'] as String,
      password: json['password'] as String,
    );
  }
}

class SettingsService extends ChangeNotifier {
  static const String _keyUserName = 'userName';
  static const String _keyServerIp = 'serverIp';
  static const String _keyDashboardUrl = 'dashboardUrl';
  static const String _keyWebminUrl = 'webminUrl';
  static const String _keyPiholeUrl = 'piholeUrl';
  static const String _keyFileConvertorUrl = 'file_convertor_url';
  static const String _keyConnections = 'saved_connections';
  static const String _keyCredentials = 'saved_credentials';

  late SharedPreferences _prefs;
  bool _initialized = false;

  String _userName = '';
  String _serverIp = '';
  String _dashboardUrl = 'http://192.168.1.100:3000/login';
  String _webminUrl = 'https://192.168.1.100:10000';
  String _piholeUrl = 'http://192.168.1.100/admin/login';
  String _fileConvertorUrl = 'http://pdf.home/';

  List<ConnectionProfile> _connections = [];
  List<SavedCredential> _credentials = [];

  bool get initialized => _initialized;
  String get userName => _userName;
  String get serverIp => _serverIp;
  String get dashboardUrl => _dashboardUrl;
  String get webminUrl => _webminUrl;
  String get piholeUrl => _piholeUrl;
  String get fileConvertorUrl => _fileConvertorUrl;
  List<ConnectionProfile> get connections => _connections;
  List<SavedCredential> get credentials => _credentials;

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
    _dashboardUrl =
        _prefs.getString(_keyDashboardUrl) ?? 'http://$_serverIp:3000/login';
    _webminUrl = _prefs.getString(_keyWebminUrl) ?? 'https://$_serverIp:10000';
    _piholeUrl =
        _prefs.getString(_keyPiholeUrl) ?? 'http://$_serverIp/admin/login';
    _fileConvertorUrl =
        _prefs.getString(_keyFileConvertorUrl) ?? 'http://pdf.home/';

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

    final credString = _prefs.getString(_keyCredentials);
    if (credString != null) {
      try {
        final List<dynamic> list = jsonDecode(credString);
        _credentials = list.map((e) => SavedCredential.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading credentials: $e');
        _credentials = [];
      }
    }
  }

  Future<void> saveSettings({
    required String userName,
    required String serverIp,
    String? dashboardUrl,
    String? webminUrl,
    String? piholeUrl,
    String? fileConvertorUrl,
  }) async {
    _userName = userName;
    _serverIp = serverIp;
    await _prefs.setString(_keyUserName, userName);
    await _prefs.setString(_keyServerIp, serverIp);

    if (dashboardUrl != null) {
      _dashboardUrl = dashboardUrl;
      await _prefs.setString(_keyDashboardUrl, dashboardUrl);
    }
    if (webminUrl != null) {
      _webminUrl = webminUrl;
      await _prefs.setString(_keyWebminUrl, webminUrl);
    }
    if (piholeUrl != null) {
      _piholeUrl = piholeUrl;
      await _prefs.setString(_keyPiholeUrl, piholeUrl);
    }
    if (fileConvertorUrl != null) {
      _fileConvertorUrl = fileConvertorUrl;
      await _prefs.setString(_keyFileConvertorUrl, fileConvertorUrl);
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

  Future<void> saveCredential(SavedCredential credential) async {
    final index = _credentials.indexWhere((c) => c.id == credential.id);
    if (index >= 0) {
      _credentials[index] = credential;
    } else {
      _credentials.add(credential);
    }
    await _saveCredentials();
    notifyListeners();
  }

  Future<void> removeCredential(String id) async {
    _credentials.removeWhere((c) => c.id == id);
    await _saveCredentials();
    notifyListeners();
  }

  Future<void> _saveCredentials() async {
    final String data = jsonEncode(
      _credentials.map((e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyCredentials, data);
  }

  Future<void> resetDefaults() async {
    _dashboardUrl = 'http://$_serverIp:3000/login';
    _webminUrl = 'https://$_serverIp:10000';
    _piholeUrl = 'http://$_serverIp/admin/login';

    await _prefs.setString(_keyDashboardUrl, _dashboardUrl);
    await _prefs.setString(_keyWebminUrl, _webminUrl);
    await _prefs.setString(_keyPiholeUrl, _piholeUrl);

    notifyListeners();
  }
}
