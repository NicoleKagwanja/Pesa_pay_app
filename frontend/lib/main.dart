import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_pay/screen/auth/login_screen.dart';
import 'package:pesa_pay/screen/dashboard/dashboard_screen.dart';
import 'package:pesa_pay/screen/admin/admin_dashboard.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? userEmail = prefs.getString('user_email');
  final bool isAdmin = prefs.getBool('is_admin') ?? false;

  Widget homeScreen;

  if (userEmail != null) {
    homeScreen = isAdmin
        ? const AdminDashboardScreen()
        : const DashboardScreen();
  } else {
    homeScreen = const LoginScreen();
  }

  runApp(MyApp(home: homeScreen));
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pesa Pay',
      theme: ThemeData(primarySwatch: Colors.green),
      home: home,
      routes: routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
