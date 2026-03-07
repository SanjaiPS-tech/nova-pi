import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../utils/theme.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Store context in a local variable before async gap to avoid lint warning
      final currentContext = context;
      final settings = Provider.of<SettingsService>(
        currentContext,
        listen: false,
      );
      await settings.saveSettings(
        userName: _nameController.text.trim(),
        serverIp: _ipController.text.trim(),
      );

      if (mounted) {
        Navigator.of(currentContext).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradients
          Container(
            decoration: const BoxDecoration(color: NovaTheme.background),
          ),
          Positioned(
            top: -100,
            right: -100,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NovaTheme.primary.withOpacity(0.15),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(
                      begin: const Offset(0, 0),
                      end: const Offset(-20, 30),
                      duration: 4.seconds,
                    ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child:
                Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NovaTheme.secondary.withOpacity(0.1),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(
                      begin: const Offset(0, 0),
                      end: const Offset(30, -20),
                      duration: 5.seconds,
                    ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NovaTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: NovaTheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        size: 40,
                        color: NovaTheme.primary,
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'NOVA',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        height: 1,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                    const SizedBox(height: 12),

                    Text(
                      'Your premium home server control hub. Fast, secure, and beautiful.',
                      style: TextStyle(
                        fontSize: 16,
                        color: NovaTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                    const SizedBox(height: 60),

                    // Form Fields
                    _buildInputField(
                      controller: _nameController,
                      label: 'Your Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    _buildInputField(
                      controller: _ipController,
                      label: 'Server IP / Hostname',
                      icon: Icons.dns_outlined,
                      hint: 'e.g. 192.168.1.100',
                      validator: (v) => v == null || v.isEmpty
                          ? 'Server IP is required'
                          : null,
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                    const SizedBox(height: 48),

                    SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Connect to Server'),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 1.seconds)
                        .scale(begin: const Offset(0.95, 0.95)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 22,
              color: NovaTheme.primary.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
