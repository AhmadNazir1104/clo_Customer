import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clocustomer/l10n/app_localizations.dart';
import 'package:clocustomer/utils/app_colors.dart';

class HomeShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        backgroundColor: AppColors.white,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.list_alt), label: l10n.myOrders),
          NavigationDestination(icon: const Icon(Icons.straighten), label: l10n.measurements),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: 'Chats'),
          NavigationDestination(icon: const Icon(Icons.person), label: l10n.profile),
        ],
      ),
    );
  }
}
