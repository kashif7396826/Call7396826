import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Shown only while AuthProvider's _restoreSession() is actually checking GET /auth/me against
/// stored tokens (AuthStatus.unknown) — a real loading state, not a fixed-duration fake splash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF14213F), AppColors.navyDeep],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                child: const Icon(Icons.call, color: AppColors.navyDeep, size: 40),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
                child: const Text(
                  'CallDrag',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'TRACK · ROUTE · CONNECT',
                style: TextStyle(color: AppColors.textDim, fontSize: 12, letterSpacing: 2),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cyan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
