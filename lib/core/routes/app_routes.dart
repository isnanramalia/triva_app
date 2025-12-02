import 'package:flutter/material.dart';

import '../../features/auth/splash_page.dart';
import '../../features/auth/auth_landing_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/trips/trips_list_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String authLanding = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String tripsList = '/trips';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case authLanding:
        return MaterialPageRoute(builder: (_) => const AuthLandingPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case tripsList:
        return MaterialPageRoute(builder: (_) => const TripsListPage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
