import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/student/presentation/screens/student_home_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';

// Role-aware router — fetches profile after login to determine redirect
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final client = Supabase.instance.client;
    final isLoggedIn = client.auth.currentUser != null;

    final publicRoutes = ['/', '/onboarding', '/login', '/signup', '/forgot-password'];
    final isGoingToPublic = publicRoutes.contains(state.matchedLocation);

    // Not logged in and trying to access protected route → send to onboarding
    if (!isLoggedIn && !isGoingToPublic) return '/onboarding';

    // Logged in and trying to access public/auth routes → redirect by role
    if (isLoggedIn && isGoingToPublic) {
      try {
        final profile = await client
            .from('profiles')
            .select('role')
            .eq('id', client.auth.currentUser!.id)
            .single();

        final role = profile['role'] as String? ?? 'student';
        return role == 'admin' ? '/admin' : '/home';
      } catch (_) {
        return '/home'; // Default to student home if profile fetch fails
      }
    }

    return null; // No redirect needed
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    // Student Home
    GoRoute(
      path: '/home',
      builder: (context, state) => const StudentHomeScreen(),
    ),
    // Admin Dashboard
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    // Course Detail
    GoRoute(
      path: '/course/:id',
      builder: (context, state) {
        final courseId = state.pathParameters['id']!;
        return CourseDetailScreen(courseId: courseId);
      },
    ),
  ],
);
