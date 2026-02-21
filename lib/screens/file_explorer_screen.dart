import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// removed duplicate import
import 'package:dartssh2/dartssh2.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

enum ClipboardSource { local, remote }

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  // Enum to track current view mode
  bool _isRemote = false;

  // Clipboard State
  String? _clipboardFile;
  ClipboardSource? _clipboardSource;
  // TODO: Add support for cut/move later
  // ClipboardType _clipboardType = ClipboardType.copy;

  // Local State
  Directory? _currentLocalDir;
  List<FileSystemEntity> _localFiles = [];

  // Remote State (SFTP)
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
        _localFiles.sort((a, b) => a.path.compareTo(b.path));
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
      // Determine initial path? Usually /home/user or /root.
      // We start at /home by default in state.
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
      _isRemote = false; // Or stay in remote tab but show list
    });
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

  // --- Copy / Paste Logic ---

  void _copyFile(String path, ClipboardSource source) {
    setState(() {
      _clipboardFile = path;
      _clipboardSource = source;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied ${path.split('/').last}')));
  }

  Future<void> _pasteFile() async {
    if (_clipboardFile == null || _clipboardSource == null) return;

    if (_clipboardSource == ClipboardSource.local && _isRemote) {
      // Local -> Remote (Upload)
      if (_sftp == null) return;
      await _uploadFile(File(_clipboardFile!), _currentRemotePath);
    } else if (_clipboardSource == ClipboardSource.remote && !_isRemote) {
      // Remote -> Local (Download)
      if (_sftp == null) return;
      // We need the full remote path. _clipboardFile should store full path.
      if (_currentLocalDir == null) return;
      await _downloadFile(_clipboardFile!, _currentLocalDir!.path);
    } else {
      // Local->Local or Remote->Remote
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Same-source copy not implemented yet')),
      );
    }

    // Clear clipboard after paste? Optional. Keeping it allows multiple pastes.
    // setState(() { _clipboardFile = null; _clipboardSource = null; });
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

      await remoteFile.write(
        fileStream.cast(),
      ); // write() takes Stream<List<int>>
      // OR: writeStream(fileStream); depending on dartssh2 version
      // Checking dartssh2 API... SftpFile.write takes Stream<List<int>>

      await remoteFile.close();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Uploaded $fileName')));
      _listRemoteFiles(_currentRemotePath); // Refresh
    } catch (e) {
      debugPrint("Upload error: $e");
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

      // Fix: Cast or use addStream for better type safety
      await sink.addStream(remoteFile.read().cast<List<int>>());
      await sink.close();

      await remoteFile.close();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded $fileName')));
      _listLocalFiles(); // Refresh
    } catch (e) {
      debugPrint("Download error: $e");
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Network Place'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. My Server)',
                ),
              ),
              TextField(
                controller: hostCtrl,
                decoration: const InputDecoration(labelText: 'Host / IP'),
              ),
              TextField(
                controller: portCtrl,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Default Username (Optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(ConnectionProfile profile) {
    final userCtrl = TextEditingController(text: profile.username);
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect to ${profile.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (profile.username.isEmpty)
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Update profile username if provided now
              final updatedProfile = ConnectionProfile(
                id: profile.id,
                name: profile.name,
                host: profile.host,
                port: profile.port,
                username: userCtrl.text.trim(),
              );
              _connectToProfile(updatedProfile, passCtrl.text.trim());
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
      if (name == '..' && _currentRemotePath != '/') {
        final parts = _currentRemotePath.split('/');
        parts.removeLast();
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

  // UI Construction
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRemote
              ? (_activeProfile != null
                    ? '${_activeProfile!.name} : $_currentRemotePath'
                    : 'Network Places')
              : 'Local Storage',
        ),
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
                        label: Text('Network'),
                        icon: Icon(Icons.dns),
                      ),
                    ],
                    selected: {_isRemote},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isRemote = newSelection.first;
                        // If switching to remote and no active connection, we show the list automatically
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_isRemote && _sshClient == null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddConnectionDialog,
            ),
          if (_isRemote && _sshClient != null) ...[
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () {
                /* reuse upload logic */
              },
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: _disconnect),
          ],
        ],
      ),
      floatingActionButton: _clipboardFile != null
          ? FloatingActionButton(
              onPressed: _pasteFile,
              tooltip: 'Paste ${_clipboardFile!.split('/').last}',
              child: const Icon(Icons.paste),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isRemote
          ? _buildRemoteView(settings.connections)
          : _buildLocalList(),
    );
  }

  Widget _buildRemoteView(List<ConnectionProfile> connections) {
    if (_sshClient != null) {
      return _buildRemoteFileList();
    }
    // Show Connection List
    if (connections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dns_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No network places added.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddConnectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Connection'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final profile = connections[index];
        return ListTile(
          leading: const Icon(Icons.computer, color: Colors.blue),
          title: Text(profile.name),
          subtitle: Text('${profile.username}@${profile.host}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              Provider.of<SettingsService>(
                context,
                listen: false,
              ).removeConnection(profile.id);
            },
          ),
          onTap: () => _showPasswordDialog(profile),
        );
      },
    );
  }

  Widget _buildLocalList() {
    if (_localFiles.isEmpty) return const Center(child: Text('No files found'));
    return ListView.builder(
      itemCount: _localFiles.length + 1,
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
          onLongPress: () {
            if (!isDir) {
              _copyFile(file.path, ClipboardSource.local);
            }
          },
          onTap: () {
            if (isDir) {
              _onLocalFolderTap(Directory(file.path));
            }
          },
        );
      },
    );
  }

  Widget _buildRemoteFileList() {
    if (_remoteFiles.isEmpty)
      return const Center(child: Text('Empty directory'));
    return ListView.builder(
      itemCount: _remoteFiles.length,
      itemBuilder: (context, index) {
        final file = _remoteFiles[index];
        final isDir = file.attr.isDirectory;
        final fullPath = _currentRemotePath.endsWith('/')
            ? '$_currentRemotePath${file.filename}'
            : '$_currentRemotePath/${file.filename}';

        return ListTile(
          leading: Icon(
            isDir ? Icons.folder : Icons.insert_drive_file,
            color: Colors.amber,
          ),
          title: Text(file.filename),
          onLongPress: () {
            if (!isDir) {
              // Allow copying files only for now
              _copyFile(fullPath, ClipboardSource.remote);
            }
          },
          onTap: () {
            if (isDir) {
              _onRemoteFolderTap(file.filename);
            } else {
              // Download logic (simplified for now to match previous impl but clean)
            }
          },
        );
      },
    );
  }
}
