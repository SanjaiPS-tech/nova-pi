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

  ConnectionProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
  }) {
    return ConnectionProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
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
  static const String _keyDashboardUrl1 = 'dashboardUrl1';
  static const String _keyDashboardUrl2 = 'dashboardUrl2';
  static const String _keyWebminUrl1 = 'webminUrl1';
  static const String _keyWebminUrl2 = 'webminUrl2';
  static const String _keyPiholeUrl1 = 'piholeUrl1';
  static const String _keyPiholeUrl2 = 'piholeUrl2';
  static const String _keyFileConvertorUrl1 = 'file_convertor_url1';
  static const String _keyFileConvertorUrl2 = 'file_convertor_url2';
  static const String _keySshHost = 'sshHost';
  static const String _keySshPort = 'sshPort';
  static const String _keySshUsername = 'sshUsername';
  static const String _keySshPassword = 'sshPassword';
  static const String _keyConnections = 'saved_connections';
  static const String _keyCredentials = 'saved_credentials';

  late SharedPreferences _prefs;
  bool _initialized = false;

  String _userName = '';
  String _serverIp = '';
  String _dashboardUrl1 = 'http://{serverIp}:3000/login';
  String _dashboardUrl2 = 'http://grafana.home/';
  String _webminUrl1 = 'https://{serverIp}:10000';
  String _webminUrl2 = '';
  String _piholeUrl1 = 'http://pi.home/';
  String _piholeUrl2 = '';
  String _fileConvertorUrl1 = 'http://pdf.home/';
  String _fileConvertorUrl2 = '';
  String _sshHost = 'nova';
  int _sshPort = 22;
  String _sshUsername = 'rebel';
  String _sshPassword = '123';

  List<ConnectionProfile> _connections = [];
  List<SavedCredential> _credentials = [];

  bool get initialized => _initialized;
  String get userName => _userName;
  String get serverIp => _serverIp;
  String get dashboardUrl1 =>
      _dashboardUrl1.replaceAll('{serverIp}', _serverIp);
  String get dashboardUrl2 =>
      _dashboardUrl2.replaceAll('{serverIp}', _serverIp);
  String get webminUrl1 => _webminUrl1.replaceAll('{serverIp}', _serverIp);
  String get webminUrl2 => _webminUrl2.replaceAll('{serverIp}', _serverIp);
  String get piholeUrl1 => _piholeUrl1.replaceAll('{serverIp}', _serverIp);
  String get piholeUrl2 => _piholeUrl2.replaceAll('{serverIp}', _serverIp);
  String get fileConvertorUrl1 =>
      _fileConvertorUrl1.replaceAll('{serverIp}', _serverIp);
  String get fileConvertorUrl2 =>
      _fileConvertorUrl2.replaceAll('{serverIp}', _serverIp);
  String get sshHost => _sshHost.isEmpty ? _serverIp : _sshHost;
  int get sshPort => _sshPort;
  String get sshUsername => _sshUsername;
  String get sshPassword => _sshPassword;

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
    _dashboardUrl1 =
        _prefs.getString(_keyDashboardUrl1) ?? 'http://{serverIp}:3000/login';
    _dashboardUrl2 =
        _prefs.getString(_keyDashboardUrl2) ?? 'http://grafana.home/';
    _webminUrl1 =
        _prefs.getString(_keyWebminUrl1) ?? 'https://{serverIp}:10000';
    _webminUrl2 = _prefs.getString(_keyWebminUrl2) ?? '';
    _piholeUrl1 = _prefs.getString(_keyPiholeUrl1) ?? 'http://pi.home/';
    _piholeUrl2 = _prefs.getString(_keyPiholeUrl2) ?? '';
    _fileConvertorUrl1 =
        _prefs.getString(_keyFileConvertorUrl1) ?? 'http://pdf.home/';
    _fileConvertorUrl2 = _prefs.getString(_keyFileConvertorUrl2) ?? '';
    _sshHost = _prefs.getString(_keySshHost) ?? 'nova';
    _sshPort = _prefs.getInt(_keySshPort) ?? 22;
    _sshUsername = _prefs.getString(_keySshUsername) ?? 'rebel';
    _sshPassword = _prefs.getString(_keySshPassword) ?? '123';

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
    String? dashboardUrl1,
    String? dashboardUrl2,
    String? webminUrl1,
    String? webminUrl2,
    String? piholeUrl1,
    String? piholeUrl2,
    String? fileConvertorUrl1,
    String? fileConvertorUrl2,
    String? sshHost,
    int? sshPort,
    String? sshUsername,
    String? sshPassword,
  }) async {
    _userName = userName;
    _serverIp = serverIp;
    await _prefs.setString(_keyUserName, userName);
    await _prefs.setString(_keyServerIp, serverIp);

    if (dashboardUrl1 != null) {
      _dashboardUrl1 = dashboardUrl1;
      await _prefs.setString(_keyDashboardUrl1, dashboardUrl1);
    }
    if (dashboardUrl2 != null) {
      _dashboardUrl2 = dashboardUrl2;
      await _prefs.setString(_keyDashboardUrl2, dashboardUrl2);
    }
    if (webminUrl1 != null) {
      _webminUrl1 = webminUrl1;
      await _prefs.setString(_keyWebminUrl1, webminUrl1);
    }
    if (webminUrl2 != null) {
      _webminUrl2 = webminUrl2;
      await _prefs.setString(_keyWebminUrl2, webminUrl2);
    }
    if (piholeUrl1 != null) {
      _piholeUrl1 = piholeUrl1;
      await _prefs.setString(_keyPiholeUrl1, piholeUrl1);
    }
    if (piholeUrl2 != null) {
      _piholeUrl2 = piholeUrl2;
      await _prefs.setString(_keyPiholeUrl2, piholeUrl2);
    }
    if (fileConvertorUrl1 != null) {
      _fileConvertorUrl1 = fileConvertorUrl1;
      await _prefs.setString(_keyFileConvertorUrl1, fileConvertorUrl1);
    }
    if (fileConvertorUrl2 != null) {
      _fileConvertorUrl2 = fileConvertorUrl2;
      await _prefs.setString(_keyFileConvertorUrl2, fileConvertorUrl2);
    }
    if (sshHost != null) {
      _sshHost = sshHost;
      await _prefs.setString(_keySshHost, sshHost);
    }
    if (sshPort != null) {
      _sshPort = sshPort;
      await _prefs.setInt(_keySshPort, sshPort);
    }
    if (sshUsername != null) {
      _sshUsername = sshUsername;
      await _prefs.setString(_keySshUsername, sshUsername);
    }
    if (sshPassword != null) {
      _sshPassword = sshPassword;
      await _prefs.setString(_keySshPassword, sshPassword);
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
    _dashboardUrl1 = 'http://{serverIp}:3000/login';
    _dashboardUrl2 = 'http://grafana.home/';
    _webminUrl1 = 'https://{serverIp}:10000';
    _webminUrl2 = '';
    _piholeUrl1 = 'http://pi.home/';
    _piholeUrl2 = '';
    _fileConvertorUrl1 = 'http://pdf.home/';
    _fileConvertorUrl2 = '';
    _sshHost = 'nova';
    _sshPort = 22;
    _sshUsername = 'rebel';
    _sshPassword = '123';

    await _prefs.setString(_keyDashboardUrl1, _dashboardUrl1);
    await _prefs.setString(_keyDashboardUrl2, _dashboardUrl2);
    await _prefs.setString(_keyWebminUrl1, _webminUrl1);
    await _prefs.setString(_keyWebminUrl2, _webminUrl2);
    await _prefs.setString(_keyPiholeUrl1, _piholeUrl1);
    await _prefs.setString(_keyPiholeUrl2, _piholeUrl2);
    await _prefs.setString(_keyFileConvertorUrl1, _fileConvertorUrl1);
    await _prefs.setString(_keyFileConvertorUrl2, _fileConvertorUrl2);
    await _prefs.setString(_keySshHost, _sshHost);
    await _prefs.setInt(_keySshPort, _sshPort);
    await _prefs.setString(_keySshUsername, _sshUsername);
    await _prefs.setString(_keySshPassword, _sshPassword);

    notifyListeners();
  }
}
