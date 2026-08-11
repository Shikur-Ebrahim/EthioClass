import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/update_password_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EthioClassApp());
}

class EthioClassApp extends StatefulWidget {
  const EthioClassApp({super.key});

  @override
  State<EthioClassApp> createState() => _EthioClassAppState();
}

class _EthioClassAppState extends State<EthioClassApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was cold started
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial deep link: $e");
    }

    // Listen to incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep link error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'ethioclass' && uri.host == 'reset-password') {
      // Supabase returns the tokens in the URL fragment (#access_token=...)
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        final params = Uri.splitQueryString(fragment);
        final accessToken = params['access_token'];
        
        if (accessToken != null && accessToken.isNotEmpty) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => UpdatePasswordScreen(accessToken: accessToken),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

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
      home: const OnboardingScreen(),
    );
  }
}
