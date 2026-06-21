import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/stock_list_screen.dart';

void main() {
  runApp(const PlantSalesApp());
}

class PlantSalesApp extends StatelessWidget {
  const PlantSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '植物販売在庫管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return FutureBuilder<String?>(
            future: AuthService.getRole(),
            builder: (context, roleSnapshot) {
              if (!roleSnapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return StockListScreen(role: roleSnapshot.data ?? 'employee');
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
