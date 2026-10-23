import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<bool>(
      future:
          AdminService()
              .isCurrentUserAdmin(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const AdminDashboardScreen();
        }

        return const AdminLoginScreen();
      },
    );
  }
}
