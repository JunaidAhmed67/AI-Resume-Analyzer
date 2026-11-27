import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shown to users who are signed in but have not verified their email yet.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _sending = false;
  String? _info;

  @override
  void initState() {
    super.initState();
    // Auto-check every 3 seconds, so the app continues as soon as the
    // user clicks the link in their email.
    _timer = Timer.periodic(
        const Duration(seconds: 3), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check({bool silent = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (verified) {
        // Refresh the token so the app (and Firestore rules) see the change.
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        return; // main.dart switches to HomeScreen automatically
      }
      if (!silent && mounted) {
        setState(() => _info =
            'Email is not verified yet. Open the link we sent you, then try again.');
      }
    } catch (_) {}
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _info = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        setState(() =>
            _info = 'Verification email sent. Check Inbox and also Spam.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _info = e.code == 'too-many-requests'
            ? 'Too many requests. Please wait a few minutes and try again.'
            : (e.message ?? e.code));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    size: 80, color: cs.primary),
                const SizedBox(height: 16),
                Text('Verify your email',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to\n$email\n\n'
                  'Open that email (check Spam too) and tap the link. '
                  'This page continues automatically after you verify.',
                  textAlign: TextAlign.center,
                ),
                if (_info != null) ...[
                  const SizedBox(height: 16),
                  Text(_info!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _check(),
                    child: const Text('I have verified'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _sending ? null : _resend,
                    child: Text(_sending ? 'Sending...' : 'Resend email'),
                  ),
                ),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Wrong email? Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
