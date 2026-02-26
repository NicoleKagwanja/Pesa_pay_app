import 'package:flutter/material.dart';
import 'package:pesa_pay/screen/activity/activity_screen.dart';
import 'package:pesa_pay/screen/admin/admin_dashboard.dart';
import 'package:pesa_pay/screen/auth/login_screen.dart';
import 'package:pesa_pay/screen/auth/signup_screen.dart';
import 'package:pesa_pay/screen/dashboard/dashboard_screen.dart';
import 'package:pesa_pay/screen/profile/profile_screen.dart';
import 'package:pesa_pay/screen/salary/salary_screen.dart';

Map<String, WidgetBuilder> routes = {
  '/dashboard': (context) => DashboardScreen(),
  '/profile': (context) => ProfileScreen(),
  '/activity': (context) => ActivityScreen(),
  '/login': (context) => LoginScreen(),
  '/signup': (context) => SignupScreen(),
  '/admin': (context) => AdminDashboardScreen(),
  '/salary': (context) => SalaryScreen(),
};
