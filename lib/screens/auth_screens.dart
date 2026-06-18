/// Auth — login + signup. Forgot-password is a deep link to web.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: LuenWordmark()),
            const SizedBox(height: 8),
            const Center(child: Text('MAISON DE LUXE', style: TextStyle(color: LuenColors.primary, fontSize: 9, letterSpacing: 4))),
            const SizedBox(height: 64),
            const Text('Welcome back', style: GoogleFonts.playfairDisplay(fontSize: 30, color: LuenColors.foreground)),
            const SizedBox(height: 4),
            const Text('Sign in to your account', style: TextStyle(color: LuenColors.mutedFg, fontSize: 13)),
            const SizedBox(height: 28),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'EMAIL'), keyboardType: TextInputType.emailAddress, autocorrect: false),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'PASSWORD'), obscureText: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: LuenColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SIGN IN')),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => launchUrl(Uri.parse('https://houseofluen.com/forgot-password'), mode: LaunchMode.externalApplication),
                child: const Text('Forgot password?', style: TextStyle(color: LuenColors.primary, fontSize: 12, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => context.push('/signup'), child: const Text('CREATE AN ACCOUNT')),
          ]),
        ),
      ),
    );
  }
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signup(name: _name.text.trim(), email: _email.text.trim(), password: _password.text);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = 'Could not create your account. Please verify the details and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JOIN LUÉN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'FULL NAME')),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'EMAIL'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'PASSWORD (8+ CHARACTERS)'), obscureText: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: LuenColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('CREATE ACCOUNT')),
          ]),
        ),
      ),
    );
  }
}
