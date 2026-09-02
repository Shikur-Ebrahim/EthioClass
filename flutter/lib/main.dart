import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth/update_password_screen.dart';
import 'screens/user/main_layout.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/session_service.dart';

import 'services/progress_service.dart';
import 'services/offline_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await ProgressService.instance.init();
  await OfflineCacheService.init();
  runApp(const EthioClassApp());
}

class EthioClassApp extends StatefulWidget {
  const EthioClassApp({super.key});

  @override
  State<EthioClassApp> createState() => _EthioClassAppState();
}

class _EthioClassAppState extends State<EthioClassApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'EthioClass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFBB024)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const _StartupScreen(),
    );
  }
}

/// Splash/startup screen that checks for existing session.
/// If logged in â†’ go to MainLayout. If not â†’ go to OnboardingScreen.
class _StartupScreen extends StatefulWidget {
  const _StartupScreen();

  @override
  State<_StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<_StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Small delay to show splash naturally
    await Future.delayed(const Duration(milliseconds: 800));

    final session = await SessionService.loadSession();

    if (!mounted) return;

    if (session != null) {
      final userRole = session['userRole'] ?? 'user';

      if (userRole == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminHomeScreen(
              userName: session['userName'] ?? '',
              userEmail: session['userEmail'] ?? '',
            ),
          ),
        );
      } else {
        // Session exists â†’ go directly to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainLayout(
              userName: session['userName'] ?? '',
              userEmail: session['userEmail'] ?? '',
              userPhone: session['userPhone'] ?? '',
              accessToken: session['token'] ?? '',
            ),
          ),
        );
      }
    } else {
      // No session â†’ go to home as guest
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainLayout(
            userName: '',
            userEmail: '',
            userPhone: '',
            accessToken: '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 72, color: Color(0xFFFBB024)),
            SizedBox(height: 16),
            Text(
              'EthioClass',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B4A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Color(0xFFFBB024),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
