import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../services/firebase/auth_service.dart';
import 'sign_in_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user != null
            ? _SignedInCard(email: user.email ?? 'Signed in')
            : const _SignedOutCard(),
      ),
    );
  }
}

class _SignedInCard extends ConsumerWidget {
  final String email;
  const _SignedInCard({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(email, style: AppTextStyles.body(14, weight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No account', style: AppTextStyles.display(16)),
            const SizedBox(height: 8),
            Text(
              'Save trade plans and sync your journal across devices. '
              'The simulator itself never requires an account.',
              style: AppTextStyles.body(
                13,
              ).copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                ),
                child: const Text('Sign In / Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
