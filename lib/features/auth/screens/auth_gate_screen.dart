import 'package:khayyat/features/auth/view_model/auth_provider.dart';
import 'package:khayyat/features/auth/view_model/linked_shops_provider.dart';
import 'package:khayyat/utils/phone_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Checks Firebase auth state on app open and routes accordingly:
///   Not logged in             → /login
///   Logged in, no profile     → /setup
///   Logged in, profile done   → /home/orders
class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth      = ref.watch(firebaseAuthProvider);
    final firestore = ref.watch(firestoreProvider);

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final user = snapshot.data;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const _LoadingScaffold();
        }

        // User is signed in — trigger shop linking (non-blocking).
        // Normalize to local format (03001234567) — Firestore stores phones this way.
        final phone = normalizeToLocal(user.phoneNumber ?? '');
        if (phone.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(linkedShopsProvider.notifier).loadAndLink(
                  phone,
                  ref.read(firestoreProvider),
                );
          });
        }

        // Check if profile setup is complete
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: firestore.collection('users').doc(user.uid).get(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScaffold();
            }

            if (docSnap.hasError) {
              return _ErrorScaffold(
                message: 'Failed to load profile: ${docSnap.error}',
                onRetry: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/login');
                },
              );
            }

            final hasName = docSnap.data?.data()?['name'] != null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              if (hasName) {
                context.go('/home/orders');
              } else {
                context.go('/setup');
              }
            });

            return const _LoadingScaffold();
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Log Out & Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
