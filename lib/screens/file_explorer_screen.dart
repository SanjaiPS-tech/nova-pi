import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  bool _isRemote = false;

  // Local State
  Directory? _currentLocalDir;
  List<FileSystemEntity> _localFiles = [];

  // Remote State (SFTP)
  SSHClient? _sshClient;
  SftpClient? _sftp;
  String _currentRemotePath = '/home';
  List<SftpName> _remoteFiles = [];
  bool _isLoading = false;

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
    final appDir = await getApplicationDocumentsDirectory();
    _currentLocalDir = appDir;
    await _listLocalFiles();
    setState(() => _isLoading = false);
  }

  Future<void> _listLocalFiles() async {
    if (_currentLocalDir == null) return;
    try {
      final files = _currentLocalDir!.listSync();
      setState(() {
        _localFiles = files;
        _localFiles.sort((a, b) => a.path.compareTo(b.path));
      }); // Simple sort
    } catch (e) {
      debugPrint('Error listing local files: $e');
    }
  }

  Future<void> _connectRemote({
    required String username,
    required String password,
    required String ip,
    required int port,
  }) async {
    setState(() => _isLoading = true);
    // final settings = Provider.of<SettingsService>(context, listen: false);
    // We use provided IP/Port instead of settings directly, though defaults come from settings.

    try {
      final socket = await SSHSocket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 10),
      );
      _sshClient = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      await _sshClient!.authenticated; // Wait for auth

      _sftp = await _sshClient!.sftp();
      await _listRemoteFiles(_currentRemotePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
        // Switch back to local if failed
        setState(() => _isRemote = false);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _listRemoteFiles(String path) async {
    if (_sftp == null) return;
    try {
      final files = await _sftp!.listdir(path);
      setState(() {
        _currentRemotePath = path;
        _remoteFiles = files;
        _remoteFiles.sort((a, b) => a.filename.compareTo(b.filename));
      });
    } catch (e) {
      debugPrint('Remote list error: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showLoginDialog() {
    final settings = Provider.of<SettingsService>(context, listen: false);
    final userController = TextEditingController(text: settings.userName);
    final passController = TextEditingController();
    final ipController = TextEditingController(text: settings.serverIp);
    final portController = TextEditingController(text: '22');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('SSH Connection'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address / Host',
                ),
              ),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isRemote = false); // Cancelled
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _connectRemote(
                username: userController.text.trim(),
                password: passController.text.trim(),
                ip: ipController.text.trim(),
                port: int.tryParse(portController.text.trim()) ?? 22,
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  // Navigation Logic
  void _onLocalFolderTap(Directory dir) {
    setState(() => _currentLocalDir = dir);
    _listLocalFiles();
  }

  void _onRemoteFolderTap(String name) {
    if (name == '.' || name == '..') {
      // Handle parent dir
      if (name == '..' && _currentRemotePath != '/') {
        // Naive parent resolution
        final parts = _currentRemotePath.split('/');
        parts.removeLast();
        final newPath = parts.isEmpty ? '/' : parts.join('/');
        _listRemoteFiles(newPath.isEmpty ? '/' : newPath);
      }
      return;
    }
    final newPath = _currentRemotePath.endsWith('/')
        ? '$_currentLocalDir$name'
        : '$_currentRemotePath/$name';
    _listRemoteFiles(newPath);
  }

  Future<void> _uploadFile() async {
    if (_sftp == null) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final localFile = File(result.files.single.path!);
      final fileName = result.files.single.name;

      setState(() => _isLoading = true);
      try {
        final remoteFile = await _sftp!.open(
          '$_currentRemotePath/$fileName',
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
        );
        await remoteFile.write(localFile.openRead().cast());
        await remoteFile.close(); // Important to flush

        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Upload complete')));
        _listRemoteFiles(_currentRemotePath);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // UI Construction
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Explorer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Local'),
                        icon: Icon(Icons.smartphone),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Remote'),
                        icon: Icon(Icons.cloud),
                      ),
                    ],
                    selected: {_isRemote},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isRemote = newSelection.first;
                      });
                      if (_isRemote && _sshClient == null) {
                        _showLoginDialog();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_isRemote)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _uploadFile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isRemote
          ? _buildRemoteList()
          : _buildLocalList(),
    );
  }

  Widget _buildLocalList() {
    if (_localFiles.isEmpty) return const Center(child: Text('No files found'));
    return ListView.builder(
      itemCount: _localFiles.length + 1, // +1 for parent ..
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('..'),
            onTap: () {
              if (_currentLocalDir?.parent != null) {
                _onLocalFolderTap(_currentLocalDir!.parent);
              }
            },
          );
        }
        final file = _localFiles[index - 1];
        final isDir = FileSystemEntity.isDirectorySync(file.path);
        return ListTile(
          leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
          title: Text(file.uri.pathSegments.lastWhere((e) => e.isNotEmpty)),
          onTap: () {
            if (isDir) {
              _onLocalFolderTap(Directory(file.path));
            } else {
              // Open file?
            }
          },
        );
      },
    );
  }

  Widget _buildRemoteList() {
    if (_remoteFiles.isEmpty)
      return const Center(child: Text('Empty directory or loading...'));
    return ListView.builder(
      itemCount: _remoteFiles.length,
      itemBuilder: (context, index) {
        final file = _remoteFiles[index];
        final isDir = file.attr.isDirectory;
        return ListTile(
          leading: Icon(
            isDir ? Icons.folder : Icons.insert_drive_file,
            color: Colors.amberAccent,
          ),
          title: Text(file.filename),
          subtitle: Text(
            file.attr.mode != null ? file.attr.mode.toString() : '',
          ),
          onTap: () {
            if (isDir) {
              _onRemoteFolderTap(file.filename);
            } else {
              _downloadFile(file.filename);
            }
          },
        );
      },
    );
  }

  Future<void> _downloadFile(String filename) async {
    if (_sftp == null || _currentLocalDir == null) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download File'),
        content: Text('Download "$filename" to local storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      setState(() => _isLoading = true);
      try {
        final remoteFile = await _sftp!.open('$_currentRemotePath/$filename');
        final localFile = File('${_currentLocalDir!.path}/$filename');
        final sink = localFile.openWrite();

        final bytes = await remoteFile.readBytes();
        sink.add(bytes);

        await sink.flush();
        await sink.close();
        await remoteFile.close();

        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to ${localFile.path}')));
        _listLocalFiles(); // Refresh local view
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
