import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/api_service.dart';

/// Auth Screen — Login / Register with gender selection.
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  bool _loading = false;
  bool _obscurePass = true;
  String _gender = 'unspecified';
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (_isRegister && pass.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (_isRegister && _gender == 'unspecified') {
      _showError('Please select a gender');
      return;
    }

    setState(() => _loading = true);

    try {
      // Wake up the Render server if it's cold-starting
      _showInfo('Connecting to server...');
      await ApiService.wakeUpServer();

      Map<String, dynamic> result;
      if (_isRegister) {
        result = await ApiService.register(email, pass, _gender);
      } else {
        result = await ApiService.login(email, pass);
      }

      if (result.containsKey('error')) {
        _showError(result['error']);
      } else {
        // Clear the "Connecting" snackbar
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        widget.onAuthenticated();
      }
    } on TimeoutException {
      _showError('Server is taking too long to respond. Please try again.');
    } on SocketException {
      _showError('No internet connection. Check your network.');
    } catch (e) {
      _showError('Connection failed. Please try again later.');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: LibassTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(msg),
          ],
        ),
        backgroundColor: LibassTheme.accentPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showServerConfigDialog() {
    final ctrl = TextEditingController(text: ApiService.baseUrl);
    bool testing = false;
    String? testResult;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Server Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure the backend API URL. Useful for connecting to a local dev server.',
                style: TextStyle(fontSize: 12, color: LibassTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              if (testResult != null)
                Text(
                  testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    color: testResult!.startsWith('✅')
                        ? LibassTheme.success
                        : LibassTheme.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      ctrl.text = 'https://libass-backend.onrender.com';
                    },
                    child: const Text('Reset to Default'),
                  ),
                  ElevatedButton(
                    onPressed: testing
                        ? null
                        : () async {
                            setState(() {
                              testing = true;
                              testResult = null;
                            });
                            final url = ctrl.text.trim();
                            final ok = await ApiService.testConnection(url);
                            setState(() {
                              testing = false;
                              testResult = ok
                                  ? '✅ Server is reachable!'
                                  : '❌ Server unreachable. Check URL or network.';
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Test Connection', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final url = ctrl.text.trim();
                if (url.isNotEmpty) {
                  await ApiService.updateBaseUrl(url);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Server updated to $url'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: LibassTheme.accentPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LibassTheme.accentPrimary.withValues(alpha: 0.05),
              LibassTheme.bgSurface,
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),

                      // Logo
                      Image.asset(
                        'assets/logo.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ).animate().fadeIn(duration: 800.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                          ),
                      const SizedBox(height: 8),
                      Text(
                        'AI Personal Stylist',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: LibassTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 48),

                      // Email
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 14),

                      // Password
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 14),

                      // Gender (only for register)
                      if (_isRegister) ...[
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gender,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'unspecified', child: Text('Select...')),
                                DropdownMenuItem(
                                    value: 'male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'non-binary',
                                    child: Text('Non-Binary')),
                              ],
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                        ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                        const SizedBox(height: 14),
                      ],

                      if (!_isRegister)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: LibassTheme.accentSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(),
                      const SizedBox(height: 12),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRegister ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 16),

                      // Toggle mode
                      TextButton(
                        onPressed: () => setState(() {
                          _isRegister = !_isRegister;
                          _gender = 'unspecified';
                        }),
                        child: Text(
                          _isRegister
                              ? 'Already have an account? Sign In'
                              : "Don't have an account? Register",
                          style: const TextStyle(
                            color: LibassTheme.accentPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.dns_rounded, color: LibassTheme.accentPrimary),
                tooltip: 'Server Connection',
                onPressed: _showServerConfigDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
