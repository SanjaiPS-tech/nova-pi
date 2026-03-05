import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class CredentialManagerScreen extends StatelessWidget {
  const CredentialManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Credentials')),
      body: Consumer<SettingsService>(
        builder: (context, settings, child) {
          if (settings.credentials.isEmpty) {
            return const Center(child: Text('No credentials saved yet.'));
          }
          return ListView.builder(
            itemCount: settings.credentials.length,
            itemBuilder: (context, index) {
              final cred = settings.credentials[index];
              return ListTile(
                leading: const Icon(Icons.security),
                title: Text(cred.title),
                subtitle: Text('UID: ${cred.uid}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, settings, cred.id),
                ),
                onTap: () => _showEditDialog(context, cred),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SettingsService settings,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Credential?'),
        content: const Text(
          'Are you sure you want to delete this saved credential?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.removeCredential(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, SavedCredential? credential) {
    showDialog(
      context: context,
      builder: (ctx) => _CredentialDialog(credential: credential),
    );
  }
}

class _CredentialDialog extends StatefulWidget {
  final SavedCredential? credential;
  const _CredentialDialog({this.credential});

  @override
  State<_CredentialDialog> createState() => _CredentialDialogState();
}

class _CredentialDialogState extends State<_CredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _uidController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.credential?.title ?? '',
    );
    _uidController = TextEditingController(text: widget.credential?.uid ?? '');
    _passwordController = TextEditingController(
      text: widget.credential?.password ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _uidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final settings = Provider.of<SettingsService>(context, listen: false);
      final cred = SavedCredential(
        id:
            widget.credential?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        uid: _uidController.text.trim(),
        password: _passwordController
            .text, // Don't trim password in case space is intentional
      );
      settings.saveCredential(cred);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.credential == null ? 'Add Credential' : 'Edit Credential',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (e.g. Webmin)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uidController,
                decoration: const InputDecoration(labelText: 'Username / UID'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
