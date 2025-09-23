import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../splash_screen.dart';
import '../views/auth/change-pass-otp.dart';
import '../views/auth/change_pass_home.dart';
import '../views/auth/reset_password.dart';
import '../views/auth/vendor_creation_otp.dart';
import '../views/dashboard/FBOAcknowledgmentScreen.dart';
import '../views/dashboard/FBO_cartpage.dart';
import '../views/dashboard/edit_profile_screen.dart';
import '../views/intro_screen.dart';
import '../views/screens/chatbot_screen.dart';
import '../views/screens/fbo_voucher.dart';
import '../views/screens/monthly_screen/monthly_view_screen.dart';
import '../views/screens/oil_place_screen.dart';
import '../views/screens/user_notification.dart';
import '../views/start_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/dashboard/restaurant_bottom_navigation.dart';
import '../vendor_app/vendor_screen/vendor_bottombar.dart';
import '../views/dashboard/agent_Bottom_Navigation_bar.dart';
import '../views/role_screen.dart';
import '../views/auth/create_account.dart';
import '../views/auth/create_account_users.dart';
import '../views/auth/create_account_vendor.dart';
import '../views/resetpass.dart';
import '../views/otpscreen.dart';
import '../views/new_password_view.dart';
import '../views/vendor_home.dart';
import '../agent/agent_screen/CartPage.dart';
import '../vendor_app/vendor_screen/vendor_order_screen.dart';
import '../agent/agent_home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', pageBuilder: (context, state) => slideTransition(const SplashScreen(), state)),
    GoRoute(path: '/intro', pageBuilder: (context, state) => slideTransition(const IntroScreen(), state)),
    GoRoute(path: '/start', pageBuilder: (context, state) => slideTransition(StartScreen(), state)),
    GoRoute(path: '/login', pageBuilder: (context, state) => slideTransition(const LoginPage(), state)),
    GoRoute(
      path: '/UserHome',
      builder: (context, state) {
        final userDetails = state.extra as Map<String, dynamic>? ?? {};
        return BottomNavigation(userDetails: userDetails);
      },
    ),
    GoRoute(
      path: '/monthly-view',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final newMonth = extra['month'];
        return slideTransition(MonthlyViewPage(month: newMonth), state);
      },
    ),
    GoRoute(
      path: '/fbo-cart',
      pageBuilder: (context, state) => slideTransition(const FboCartScreen(), state),
    ),
    GoRoute(
      path: '/fbo-notification',
      pageBuilder: (context, state) => slideTransition(const FboNotificationScreen(), state),
    ),

    GoRoute(path: '/VendorPage', pageBuilder: (context, state) => slideTransition(const VendorBottomNavigation(), state)),
    GoRoute(
      path: '/AgentPage',
      builder: (context, state) {
        final userDetails = state.extra as Map<String, dynamic>?;
        return AgentBottomNavigation(userDetails: userDetails);
      },
    ),
    GoRoute(path: '/RoleScreen', pageBuilder: (context, state) => slideTransition( RoleScreen(), state)),
    GoRoute(path: '/CreateAccount', pageBuilder: (context, state) => slideTransition( CreateAccount(), state)),
    GoRoute(path: '/UserCreation', pageBuilder: (context, state) => slideTransition(const UserCreation(), state)),
    GoRoute(path: '/VendorCreation', pageBuilder: (context, state) => slideTransition(const VendorCreation(), state)),
    GoRoute(path: '/reset-password', pageBuilder: (context, state) => slideTransition(const ResetPasswordScreen(), state)),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null || (!data.containsKey('email') && !data.containsKey('phone'))) {
          throw Exception("Email or Phone is required for OTP verification.");
        }
        return OtpVerificationScreen(
          email: data["email"]?.toString() ?? "",
          phone: data["phone"]?.toString() ?? "",
          verificationId: data["verificationId"]?.toString() ?? "",
        );
      },
    ),
    GoRoute(
      path: '/ChangePassOtpScreen',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null || (!data.containsKey('email') && !data.containsKey('phone'))) {
          throw Exception("Email or Phone is required for OTP verification.");
        }
        return ChangePassOtpScreen(
          email: data["email"]?.toString() ?? "",
          phone: data["phone"]?.toString() ?? "",
          verificationId: data["verificationId"]?.toString() ?? "",
        );
      },
    ),
    GoRoute(
      path: '/new-password',
      builder: (context, state) {
        final email = state.extra as String?;
        return email == null ? LoginPage() : NewPassword(email: email);
      },
    ),
    GoRoute(
      path: '/OTPVerificationScreen',
      builder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>? ?? {};
        return OTPVerificationScreen(
          email: extraData["email"] ?? "",
          phone: extraData["phone"] ?? "",
          verificationId: extraData["verificationId"] ?? "",
        );
      },
    ),
    GoRoute(path: '/VendorPage', builder: (context, state) {final vendorDetails = state.extra as Map<String, dynamic>? ?? {};return VendorPage(vendorDetails: vendorDetails);},),
    GoRoute(path: '/cart', pageBuilder: (context, state) => slideTransition(const AgentCartPage(), state)),
    GoRoute(path: '/voucherPage', pageBuilder: (context, state) => slideTransition(const VoucherHistoryScreen(), state)),
    GoRoute(path: '/ForgotPasswordScreen', pageBuilder: (context, state) => slideTransition(const ForgotPasswordScreen(), state)),
    GoRoute(path: '/Vendor_cart', pageBuilder: (context, state) => slideTransition(const VendorCartPage(), state)),
    GoRoute(path: '/FboAcknowledgmentScreen', pageBuilder: (context, state) => slideTransition(const FboAcknowledgmentScreen(), state)),
    GoRoute(path: '/OilPlacedScreen', pageBuilder: (context, state) => slideTransition(const OilPlacedScreen(), state)),
    GoRoute(
      path: '/AgentHomeScreen',
      builder: (context, state) {
        final String token = state.extra as String? ?? "token";
        return AgentHomeScreen(token: token);
      },
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) {
        return slideTransition(const EditProfileScreen(), state);
      },
    ),
    GoRoute(
      path: '/change-password',
      pageBuilder: (context, state) => slideTransition(const ChangePasswordScreen(), state),
    ),
    GoRoute(
      path: '/chatbot',
      pageBuilder: (context, state) => slideTransition(const ChatbotScreen(), state),
    ),

    GoRoute(path: '/VendorCartPage', pageBuilder: (context, state) => slideTransition(const VendorCartPage(), state)),
  ],
);


CustomTransitionPage slideTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

