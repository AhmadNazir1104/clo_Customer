import 'package:clocustomer/features/auth/screens/auth_gate_screen.dart';
import 'package:clocustomer/features/auth/screens/otp_verification_screen.dart';
import 'package:clocustomer/features/auth/screens/phone_input_screen.dart';
import 'package:clocustomer/features/auth/screens/profile_setup_screen.dart';
import 'package:clocustomer/features/chat/screens/chat_screen.dart';
import 'package:clocustomer/features/chat/screens/chats_list_screen.dart';
import 'package:clocustomer/features/measurement/screens/add_measurement_screen.dart';
import 'package:clocustomer/features/home/screens/home_shell_screen.dart';
import 'package:clocustomer/features/measurement/screens/measurement_view_screen.dart';
import 'package:clocustomer/features/measurement/screens/measurements_home_screen.dart';
import 'package:clocustomer/features/order/screens/order_detail_screen.dart';
import 'package:clocustomer/features/order/screens/orders_list_screen.dart';
import 'package:clocustomer/features/profile/screens/profile_screen.dart';
import 'package:clocustomer/features/shop/screens/shop_detail_screen.dart';
import 'package:clocustomer/model/measurement_entry_model.dart';
import 'package:clocustomer/model/order_model.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const AuthGateScreen(),
  routes: [
    // ── Auth ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGateScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const PhoneInputScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String;
        return OtpVerificationScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    // ── Redirect /home → /home/orders ─────────────────────────────────
    GoRoute(
      path: '/home',
      redirect: (context, state) => '/home/orders',
    ),
    // ── Home shell (bottom nav) ────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/orders',
              builder: (context, state) => const OrdersListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/measurements',
              builder: (context, state) => const MeasurementsHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/chats',
              builder: (context, state) => const ChatsListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    // ── Detail screens ─────────────────────────────────────────────────
    GoRoute(
      path: '/orders/detail',
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return OrderDetailScreen(order: order);
      },
    ),
    GoRoute(
      path: '/shops/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return ShopDetailScreen(shopId: shopId);
      },
    ),
    GoRoute(
      path: '/chat/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return ChatScreen(shopId: shopId);
      },
    ),
    GoRoute(
      path: '/measurements/add',
      builder: (context, state) => const AddMeasurementScreen(),
    ),
    GoRoute(
      path: '/measurements/view',
      builder: (context, state) {
        final entry = state.extra as MeasurementEntry;
        return MeasurementViewScreen(entry: entry);
      },
    ),
  ],
);
