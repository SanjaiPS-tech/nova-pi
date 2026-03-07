import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../utils/theme.dart';

class CredentialManagerScreen extends StatelessWidget {
  const CredentialManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Keypad')),
      body: Consumer<SettingsService>(
        builder: (context, settings, child) {
          if (settings.credentials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 64,
                    color: NovaTheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No credentials saved',
                    style: TextStyle(color: NovaTheme.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: settings.credentials.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final cred = settings.credentials[index];
              return _buildCredentialCard(context, settings, cred);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, null),
        label: const Text('Add Login'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildCredentialCard(
    BuildContext context,
    SettingsService settings,
    SavedCredential cred,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: NovaTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NovaTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_person_rounded,
            color: NovaTheme.primary,
          ),
        ),
        title: Text(
          cred.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'UID: ${cred.uid}',
          style: const TextStyle(fontSize: 12, color: NovaTheme.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
          onPressed: () => _confirmDelete(context, settings, cred.id),
        ),
        onTap: () => _showEditDialog(context, cred),
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
        title: const Text('Remove access?'),
        content: const Text(
          'This login info will be permanently deleted from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('KEEP'),
          ),
          TextButton(
            onPressed: () {
              settings.removeCredential(id);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, SavedCredential? credential) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        password: _passwordController.text,
      );
      settings.saveCredential(cred);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 32,
        left: 32,
        right: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: NovaTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.credential == null ? 'New Login' : 'Edit Login',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildField(
              controller: _titleController,
              label: 'Service Name',
              icon: Icons.label_important_outline_rounded,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _uidController,
              label: 'UID / Username',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.key_outlined,
              obscure: _obscurePassword,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Keep Secure'),
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
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: NovaTheme.primary.withOpacity(0.7)),
        suffixIcon: suffix,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
