import 'package:flutter/material.dart';
import 'package:stylish_admin/core/routes/route_names.dart';
import 'package:stylish_admin/features/auth/domain/entities/user_entity.dart';
import 'package:stylish_admin/features/auth/presentation/pages/login_page.dart';
import 'package:stylish_admin/features/auth/presentation/pages/manage_account_page.dart';
class DashboardRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return _buildRoute(const LoginPage(), settings);
      case RouteNames.dashboard:
        return _buildRoute(
          Center(child: Text("We are in dashboard screen")),
          settings,
        );
     
      case RouteNames.profile:
        final user = settings.arguments as UserEntity;
        return _buildRoute(ManageAccountPage(user: user), settings);

    
      default:
        return _buildRoute(Center(child: Text("No Pages")), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
