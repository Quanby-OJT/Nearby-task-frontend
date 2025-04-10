import 'package:flutter/material.dart';
import 'package:flutter_fe/view/auth/email_verification_page.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomePageViewMain(),
      //builder: (context, state) => const EscrowTokenScreen()
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

final apiUrl = dotenv.env['API_URL'];