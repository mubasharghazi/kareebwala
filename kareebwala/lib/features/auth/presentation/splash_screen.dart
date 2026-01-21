import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kareebwala/core/services/local_storage_service.dart';
import 'package:kareebwala/features/auth/data/user_service.dart';
import 'package:kareebwala/features/auth/presentation/login_screen.dart';
import 'package:kareebwala/features/home_map/presentation/home_screen.dart';
import 'package:kareebwala/features/onboarding/onboarding_screen.dart';
import 'package:kareebwala/features/provider/presentation/provider_dashboard.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppStart();
  }

  void _checkAppStart() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    bool seenOnboarding = await LocalStorageService().isOnboardingSeen();

    if (!seenOnboarding) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? role = await UserService().getUserRole(user.uid);

      if (!mounted) return;

      if (role == 'provider') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProviderDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.location_on,
                    size: 80, color: Color(0xFF007AFF));
              },
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF007AFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
