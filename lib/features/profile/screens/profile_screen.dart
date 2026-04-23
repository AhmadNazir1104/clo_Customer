import 'package:libaas/features/auth/view_model/auth_provider.dart';
import 'package:libaas/features/auth/view_model/auth_state.dart';
import 'package:libaas/features/settings/view_model/locale_provider.dart';
import 'package:libaas/l10n/app_localizations.dart';
import 'package:libaas/utils/app_colors.dart';
import 'package:libaas/utils/phone_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n      = AppLocalizations.of(context)!;
    final auth      = ref.watch(firebaseAuthProvider);
    final firestore = ref.watch(firestoreProvider);
    final isBusy    = ref.watch(authProvider) is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthInitial) {
        context.go('/login');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firestore.collection('users').doc(user.uid).snapshots(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final data        = docSnap.data?.data();
            final name        = (data?['name'] ?? '').toString();
            final city        = (data?['city'] ?? '').toString();
            final rawPhone    = (data?['phone'] ?? user.phoneNumber ?? '').toString();
            final phone       = formatForDisplay(rawPhone);
            final photoUrl    = (data?['photoUrl'] ?? '').toString();

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Text(
                  l10n.profile,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: AppColors.dark),
                ),
                actions: [
                  IconButton(
                    tooltip: l10n.logout,
                    icon: const Icon(Icons.logout, color: AppColors.dark),
                    onPressed: isBusy
                        ? null
                        : () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // ── Avatar + name ──────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: photoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person,
                                  size: 52, color: AppColors.gray)
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name.isNotEmpty ? name : '—',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone.isNotEmpty ? phone : '—',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.gray),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Info card ──────────────────────────────────────────
                  _card(
                    child: Column(
                      children: [
                        _fieldRow('City', city.isNotEmpty ? city : '—'),
                        const Divider(height: 24),
                        _fieldRow('Phone', phone.isNotEmpty ? phone : '—'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Language toggle ────────────────────────────────────
                  _buildLanguageTile(context, ref, l10n),
                  const SizedBox(height: 16),
                  // ── Logout button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => ref.read(authProvider.notifier).logout(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        l10n.logout,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _fieldRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
        ),
      ],
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final locale = ref.watch(localeProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.language, color: AppColors.navy),
        title: Text(l10n.language,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
        trailing: GestureDetector(
          onTap: () => toggleLocale(ref),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _langChip('EN', !isUrdu),
                const SizedBox(width: 4),
                _langChip('اردو', isUrdu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _langChip(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}
