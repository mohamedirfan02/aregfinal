import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../views/auth/login_screen.dart';
import '../views/resetpass.dart';


final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    // GoRoute(
    //   path: '/',
    //   builder: (BuildContext context, GoRouterState state) {
    //     return const LoginPage();
    //   },
    // ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ResetPasswordScreen();
      },
     ),
    // GoRoute(
    //   path: '/OtpVerificationScreen',
    //   builder: (BuildContext context, GoRouterState state) {
    //     return const OtpVerificationScreen();
    //   },
    // ),
    // GoRoute(
    //   path: '/New Password',
    //   builder: (BuildContext context, GoRouterState state) {
    //     return const NewPassword();
    //   },
    // ),
    // GoRoute(
    //   path: '/New Password',
    //   builder: (BuildContext context, GoRouterState state) {
    //     return const HomeScreen();
    //   },
    // ),
    // GoRoute(
    //   path: '/New Password',
    //   builder: (BuildContext context, GoRouterState state) {
    //     return const ProfileScreen();
    //   },
    // ),
    // GoRoute(
    //   path: '/New Password',
    //   builder: (BuildContext context, GoRouterState state) {
    //     return const EditProfile();
    //   },
    // ),

  ],
);
