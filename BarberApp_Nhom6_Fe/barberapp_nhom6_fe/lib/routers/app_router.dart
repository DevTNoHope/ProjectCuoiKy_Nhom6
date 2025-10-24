// lib/routers/app_router.dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../screens/booking/booking_confirm_screen.dart';
import '../screens/booking/my_bookings_screen.dart';
import '../screens/booking/service_pick_screen.dart';
import '../screens/booking/shop_list_screen.dart';
import '../screens/booking/slot_pick_screen.dart';
import '../screens/booking/stylist_list_screen.dart';
import '../screens/review/my_reviews_screen.dart';
import '../screens/review/review_form_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../services/auth_service.dart';
import '../screens/booking/edit_booking_screen.dart';


class AppRouter {
  static final _auth = AuthService();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      // lib/routers/app_router.dart (thêm)
      GoRoute(path: '/shops', builder: (_,__)=> const ShopListScreen()),
      GoRoute(path: '/shops/:id/stylists', builder: (c,s){
        final shopId = int.parse(s.pathParameters['id']!);
        return StylistListScreen(shopId: shopId);
      }),
      GoRoute(path: '/stylists/:id/services', builder: (c,s){
        final stylistId = int.parse(s.pathParameters['id']!);
        final shopId = int.parse(s.uri.queryParameters['shopId']!);
        return ServicePickScreen(shopId: shopId, stylistId: stylistId);
      }),
      GoRoute(path: '/booking/slots', builder: (c,s){
        final extra = s.extra as Map<String,dynamic>; // shop, stylist, service
        return SlotPickScreen(
          shop: extra['shop'],
          stylist: extra['stylist'],
          service: extra['service'],
        );
      }),
      GoRoute(path: '/booking/confirm', builder: (c,s){
        final extra = s.extra as Map<String,dynamic>; // + selectedStart
        return BookingConfirmScreen(
          shop: extra['shop'],
          stylist: extra['stylist'],
          service: extra['service'],
          start: extra['start'],
        );
      }),
      GoRoute(
        path: '/bookings/me',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/booking/edit',
        builder: (context, state) {
          final booking = state.extra as Map<String, dynamic>;
          return EditBookingScreen(bookingId: booking['id']); // ✅ sửa đúng tham số
        },
      ),

      // ✅ Màn thêm / sửa Review
      GoRoute(
        path: '/review/add',
        builder: (context, state) {
          final booking = state.extra as Map<String, dynamic>?;
          return ReviewFormScreen(bookingId: booking?['id']);
        },
      ),
      GoRoute(
        path: '/review/my',
        builder: (context, state) => const MyReviewsScreen(),
      ),



// (tuỳ chọn) nếu bạn muốn có màn danh sách services tổng:
      GoRoute(
        path: '/services',
        builder: (context, state) {
          // có thể điều hướng về ServicePickScreen theo shop mặc định, hoặc tạo màn list tất cả dịch vụ
          // tạm thời mở ShopList để user chọn shop trước
          return const ShopListScreen(); // nếu đã import file shop_list_screen.dart
        },
      ),
    ],
    redirect: (context, state) async {
      // Chỉ redirect khi ở /splash để tránh loop
      if (state.fullPath == '/splash') {
        final logged = await _auth.isLoggedIn();
        if (!logged) return '/login';
        final role = await _auth.getRole();
        if (role == 'Admin') return '/admin';
        return '/home';
      }
      return null;
    },
  );
}
