import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../utils/theme.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

enum ClipboardSource { local, remote }

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  bool _isRemote = false;
  String? _clipboardFile;
  ClipboardSource? _clipboardSource;

  Directory? _currentLocalDir;
  List<FileSystemEntity> _localFiles = [];

  SSHClient? _sshClient;
  SftpClient? _sftp;
  String _currentRemotePath = '/home';
  List<SftpName> _remoteFiles = [];
  bool _isLoading = false;
  ConnectionProfile? _activeProfile;

  @override
  void initState() {
    super.initState();
    _initLocal();
  }

  @override
  void dispose() {
    _sshClient?.close();
    super.dispose();
  }

  Future<void> _initLocal() async {
    setState(() => _isLoading = true);
    Directory? rootDir;
    if (Platform.isAndroid) {
      rootDir = Directory('/storage/emulated/0');
      if (!rootDir.existsSync()) {
        rootDir = await getExternalStorageDirectory();
      }
    } else {
      rootDir = await getApplicationDocumentsDirectory();
    }
    _currentLocalDir = rootDir;
    await _listLocalFiles();
    setState(() => _isLoading = false);
  }

  Future<void> _listLocalFiles() async {
    if (_currentLocalDir == null) return;
    try {
      final files = _currentLocalDir!.listSync();
      setState(() {
        _localFiles = files;
        _localFiles.sort((a, b) {
          final isADir = FileSystemEntity.isDirectorySync(a.path);
          final isBDir = FileSystemEntity.isDirectorySync(b.path);
          if (isADir && !isBDir) return -1;
          if (!isADir && isBDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
      });
    } catch (e) {
      debugPrint('Error listing local files: $e');
    }
  }

  Future<void> _connectToProfile(
    ConnectionProfile profile,
    String password,
  ) async {
    setState(() {
      _isLoading = true;
      _activeProfile = profile;
    });

    try {
      final socket = await SSHSocket.connect(
        profile.host,
        profile.port,
        timeout: const Duration(seconds: 10),
      );
      _sshClient = SSHClient(
        socket,
        username: profile.username.isEmpty ? 'root' : profile.username,
        onPasswordRequest: () => password,
      );

      await _sshClient!.authenticated;
      _sftp = await _sshClient!.sftp();
      await _listRemoteFiles(_currentRemotePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
        _disconnect();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _disconnect() {
    _sshClient?.close();
    setState(() {
      _sshClient = null;
      _sftp = null;
      _activeProfile = null;
      _isRemote = false;
    });
  }

  Future<void> _listRemoteFiles(String path) async {
    if (_sftp == null) return;
    try {
      final files = await _sftp!.listdir(path);
      setState(() {
        _currentRemotePath = path;
        _remoteFiles = files;
        _remoteFiles.sort((a, b) {
          if (a.attr.isDirectory && !b.attr.isDirectory) return -1;
          if (!a.attr.isDirectory && b.attr.isDirectory) return 1;
          return a.filename.toLowerCase().compareTo(b.filename.toLowerCase());
        });
      });
    } catch (e) {
      debugPrint('Remote list error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _copyFile(String path, ClipboardSource source) {
    setState(() {
      _clipboardFile = path;
      _clipboardSource = source;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${path.split('/').last}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pasteFile() async {
    if (_clipboardFile == null || _clipboardSource == null) return;

    if (_clipboardSource == ClipboardSource.local && _isRemote) {
      if (_sftp == null) return;
      await _uploadFile(File(_clipboardFile!), _currentRemotePath);
    } else if (_clipboardSource == ClipboardSource.remote && !_isRemote) {
      if (_sftp == null) return;
      if (_currentLocalDir == null) return;
      await _downloadFile(_clipboardFile!, _currentLocalDir!.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination must differ for now'),
        ),
      );
    }
  }

  Future<void> _uploadFile(File localFile, String remoteDir) async {
    setState(() => _isLoading = true);
    try {
      final fileName = localFile.uri.pathSegments.last;
      final remotePath = remoteDir.endsWith('/')
          ? '$remoteDir$fileName'
          : '$remoteDir/$fileName';
      final fileStream = localFile.openRead();
      final remoteFile = await _sftp!.open(
        remotePath,
        mode:
            SftpFileOpenMode.write |
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate,
      );
      await remoteFile.write(fileStream.cast());
      await remoteFile.close();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Uploaded $fileName')));
      _listRemoteFiles(_currentRemotePath);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile(String remotePath, String localDir) async {
    setState(() => _isLoading = true);
    try {
      final fileName = remotePath.split('/').last;
      final localPath = '$localDir/$fileName';
      final remoteFile = await _sftp!.open(
        remotePath,
        mode: SftpFileOpenMode.read,
      );
      final localFile = File(localPath);
      final sink = localFile.openWrite();
      await sink.addStream(remoteFile.read().cast<List<int>>());
      await sink.close();
      await remoteFile.close();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded $fileName')));
      _listLocalFiles();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddConnectionDialog() {
    final nameCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '22');
    final userCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 32,
          left: 32,
          right: 32,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        decoration: const BoxDecoration(
          color: NovaTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Network Place',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildField(
              controller: nameCtrl,
              label: 'Name',
              icon: Icons.label_important_outline_rounded,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: hostCtrl,
              label: 'Host / IP',
              icon: Icons.dns_outlined,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: portCtrl,
                    label: 'Port',
                    icon: Icons.numbers_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildField(
                    controller: userCtrl,
                    label: 'Username',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty || hostCtrl.text.isEmpty) return;
                  final profile = ConnectionProfile(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    host: hostCtrl.text.trim(),
                    port: int.tryParse(portCtrl.text) ?? 22,
                    username: userCtrl.text.trim(),
                  );
                  Provider.of<SettingsService>(
                    context,
                    listen: false,
                  ).addConnection(profile);
                  Navigator.pop(ctx);
                },
                child: const Text('Add Node'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: NovaTheme.primary.withOpacity(0.7)),
      ),
    );
  }

  void _showPasswordDialog(ConnectionProfile profile) {
    final userCtrl = TextEditingController(text: profile.username);
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Login to ${profile.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _connectToProfile(
                profile.copyWith(username: userCtrl.text.trim()),
                passCtrl.text.trim(),
              );
            },
            child: const Text(
              'CONNECT',
              style: TextStyle(color: NovaTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _onLocalFolderTap(Directory dir) {
    setState(() => _currentLocalDir = dir);
    _listLocalFiles();
  }

  void _onRemoteFolderTap(String name) {
    if (name == '.' || name == '..') {
      if (name == '..' && _currentRemotePath != '/') {
        final parts = _currentRemotePath.split('/');
        if (parts.isNotEmpty) parts.removeLast();
        final newPath = parts.isEmpty ? '/' : parts.join('/');
        _listRemoteFiles(newPath.isEmpty ? '/' : newPath);
      }
      return;
    }
    final newPath = _currentRemotePath.endsWith('/')
        ? '$_currentRemotePath$name'
        : '$_currentRemotePath/$name';
    _listRemoteFiles(newPath);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRemote ? (_activeProfile?.name ?? 'Network') : 'Local Explorer',
        ),
        actions: [
          if (_isRemote && _sshClient != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _disconnect,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: NovaTheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  _buildTab('Local', Icons.smartphone_rounded, !_isRemote),
                  _buildTab('Network', Icons.dns_rounded, _isRemote),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isRemote
                ? _buildRemoteView(settings.connections)
                : _buildLocalList(),
          ),
        ],
      ),
      floatingActionButton: _clipboardFile != null
          ? FloatingActionButton.extended(
              onPressed: _pasteFile,
              icon: const Icon(Icons.paste_rounded),
              label: Text('Paste into ${_isRemote ? "Remote" : "Local"}'),
            ).animate().scale().fadeIn()
          : null,
    );
  }

  Widget _buildTab(String label, IconData icon, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isRemote = label == 'Network'),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? NovaTheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? NovaTheme.primary : NovaTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? NovaTheme.primary : NovaTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _localFiles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildBackItem(true);
        final file = _localFiles[index - 1];
        final isDir = FileSystemEntity.isDirectorySync(file.path);
        return _buildFileItem(
          file.uri.pathSegments.lastWhere((e) => e.isNotEmpty),
          isDir,
          () => isDir ? _onLocalFolderTap(Directory(file.path)) : null,
          () => isDir ? null : _copyFile(file.path, ClipboardSource.local),
        );
      },
    );
  }

  Widget _buildRemoteView(List<ConnectionProfile> connections) {
    if (_sshClient != null) return _buildRemoteFileList();
    if (connections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns_rounded,
              size: 64,
              color: NovaTheme.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              'No connections added',
              style: TextStyle(color: NovaTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddConnectionDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Place'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: connections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final profile = connections[index];
        return Container(
          decoration: BoxDecoration(
            color: NovaTheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.computer_rounded,
              color: NovaTheme.secondary,
            ),
            title: Text(
              profile.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(profile.host, style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.grey,
              ),
              onPressed: () => Provider.of<SettingsService>(
                context,
                listen: false,
              ).removeConnection(profile.id),
            ),
            onTap: () => _showPasswordDialog(profile),
          ),
        );
      },
    );
  }

  Widget _buildRemoteFileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _remoteFiles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildBackItem(false);
        final file = _remoteFiles[index - 1];
        if (file.filename == '.' || file.filename == '..') {
          return const SizedBox.shrink();
        }
        final isDir = file.attr.isDirectory;
        final fullPath = _currentRemotePath.endsWith('/')
            ? '$_currentRemotePath${file.filename}'
            : '$_currentRemotePath/${file.filename}';
        return _buildFileItem(
          file.filename,
          isDir,
          () => isDir ? _onRemoteFolderTap(file.filename) : null,
          () => isDir ? null : _copyFile(fullPath, ClipboardSource.remote),
        );
      },
    );
  }

  Widget _buildBackItem(bool local) {
    if (local && _currentLocalDir?.path == '/') return const SizedBox.shrink();
    if (!local && _currentRemotePath == '/') return const SizedBox.shrink();

    return ListTile(
      leading: const Icon(
        Icons.arrow_upward_rounded,
        size: 20,
        color: NovaTheme.primary,
      ),
      title: const Text(
        '...',
        style: TextStyle(fontWeight: FontWeight.bold, color: NovaTheme.primary),
      ),
      onTap: () => local
          ? _onLocalFolderTap(_currentLocalDir!.parent)
          : _onRemoteFolderTap('..'),
    );
  }

  Widget _buildFileItem(
    String name,
    bool isDir,
    VoidCallback onTap,
    VoidCallback onLongPress,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
        color: isDir
            ? Colors.amber.withOpacity(0.8)
            : NovaTheme.textSecondary.withOpacity(0.5),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isDir ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
