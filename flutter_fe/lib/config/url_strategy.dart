import 'package:flutter_fe/view/business_acc/create_escrow_token.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomePageViewMain(),
    ),
  ],
);

final apiUrl = dotenv.env['API_URL'];
