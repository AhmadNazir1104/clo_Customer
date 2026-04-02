import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:clocustomer/l10n/app_localizations.dart';
import 'package:clocustomer/router/app_router.dart';
import 'package:clocustomer/features/settings/view_model/locale_provider.dart';
import 'package:clocustomer/utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  // App Check: debug provider for local dev.
  // Switch to AndroidPlayIntegrityProvider + AppleAppAttestProvider before releasing.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );

  runApp(const ProviderScope(child: DarziCustomerApp()));
}

class DarziCustomerApp extends ConsumerWidget {
  const DarziCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'DarziPro',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy, // Gun Metal
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.navy.withValues(alpha: 0.12),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.navy);
            }
            return const IconThemeData(color: AppColors.gray);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600);
            }
            return const TextStyle(color: AppColors.gray, fontSize: 12);
          }),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.dark),
          titleTextStyle: TextStyle(
              color: AppColors.dark,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
