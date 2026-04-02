import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider is in legacy for Riverpod v3

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Toggles between English and Urdu.
void toggleLocale(WidgetRef ref) {
  final current = ref.read(localeProvider);
  ref.read(localeProvider.notifier).state =
      current.languageCode == 'en' ? const Locale('ur') : const Locale('en');
}
