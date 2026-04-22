import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/savings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
      ],
      child: MaterialApp(
        title: 'Reverse Expense Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      )
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    final loggedIn = await authProvider.tryAutoLogin();
    setState(() {
      _isLoggedIn = loggedIn;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn ? const SavingsScreen() : const LoginScreen();
  }
}