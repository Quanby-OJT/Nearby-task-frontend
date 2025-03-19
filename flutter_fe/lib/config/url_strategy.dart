import 'package:flutter/material.dart';
import 'package:flutter_fe/view/auth/email_verification_page.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomePageViewMain(),
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        final email = state.uri.queryParameters['email'];

        if (token == null || email == null) {
          return const WelcomePageViewMain();
        }

        debugPrint('Token: $token, Email: $email');

        return EmailVerificationPage(
          token: token,
          email: email,
        );
      },
    ),
  ],
);
