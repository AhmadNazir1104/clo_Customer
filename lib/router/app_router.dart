import 'package:khayyat/features/auth/screens/auth_gate_screen.dart';
import 'package:khayyat/features/auth/screens/otp_verification_screen.dart';
import 'package:khayyat/features/auth/screens/phone_input_screen.dart';
import 'package:khayyat/features/auth/screens/profile_setup_screen.dart';
import 'package:khayyat/features/chat/screens/chat_screen.dart';
import 'package:khayyat/features/chat/screens/chats_list_screen.dart';
import 'package:khayyat/features/discover/screens/discover_screen.dart';
import 'package:khayyat/features/discover/screens/tailor_detail_screen.dart';
import 'package:khayyat/features/measurement/screens/add_measurement_screen.dart';
import 'package:khayyat/features/home/screens/home_shell_screen.dart';
import 'package:khayyat/features/measurement/screens/measurement_view_screen.dart';
import 'package:khayyat/features/measurement/screens/measurements_home_screen.dart';
import 'package:khayyat/features/order/screens/order_detail_screen.dart';
import 'package:khayyat/features/order/screens/orders_list_screen.dart';
import 'package:khayyat/features/profile/screens/profile_screen.dart';
import 'package:khayyat/features/review/screens/leave_review_screen.dart';
import 'package:khayyat/features/shop/screens/shop_detail_screen.dart';
import 'package:khayyat/model/measurement_entry_model.dart';
import 'package:khayyat/model/order_model.dart';
import 'package:khayyat/model/shop_model.dart';
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
    // ── Home shell (bottom nav — 5 tabs) ──────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShellScreen(navigationShell: navigationShell),
      branches: [
        // Tab 0 — Orders
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/orders',
              builder: (context, state) => const OrdersListScreen(),
            ),
          ],
        ),
        // Tab 1 — Measurements
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/measurements',
              builder: (context, state) => const MeasurementsHomeScreen(),
            ),
          ],
        ),
        // Tab 2 — Discover
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/discover',
              builder: (context, state) => const DiscoverScreen(),
            ),
          ],
        ),
        // Tab 3 — Chats
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/chats',
              builder: (context, state) => const ChatsListScreen(),
            ),
          ],
        ),
        // Tab 4 — Profile
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
    // ── Orders ────────────────────────────────────────────────────────
    GoRoute(
      path: '/orders/detail',
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return OrderDetailScreen(order: order);
      },
    ),
    // ── Shops ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/shops/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return ShopDetailScreen(shopId: shopId);
      },
    ),
    // ── Discover ──────────────────────────────────────────────────────
    GoRoute(
      path: '/discover/:shopId',
      builder: (context, state) {
        final shop = state.extra as ShopModel;
        return TailorDetailScreen(shop: shop);
      },
    ),
    // ── Review ────────────────────────────────────────────────────────
    GoRoute(
      path: '/review/:shopId',
      builder: (context, state) {
        final shopId   = state.pathParameters['shopId']!;
        final shopName = state.extra as String? ?? '';
        return LeaveReviewScreen(shopId: shopId, shopName: shopName);
      },
    ),
    // ── Chat ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/chat/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return ChatScreen(shopId: shopId);
      },
    ),
    // ── Measurements ──────────────────────────────────────────────────
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
