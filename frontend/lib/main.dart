import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pesa Pay',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/login',
      routes: routes,
    );
  }
}
