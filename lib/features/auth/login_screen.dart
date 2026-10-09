import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';
import 'totp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.login(_emailController.text.trim(), _passwordController.text);
    if (!ok || !mounted) return;
    if (auth.status == AuthStatus.awaitingTotp) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TotpScreen()));
    }
    // AuthStatus.authenticated is handled by the app root's Consumer<AuthProvider> switching
    // screens automatically — nothing else to do here.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.3, colors: [Color(0xFF14213F), AppColors.navyDeep]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) => Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                          child: const Icon(Icons.call, color: AppColors.navyDeep, size: 34),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('CallDrag', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      const Text('TRACK · ROUTE · CONNECT', style: TextStyle(color: AppColors.textDim, fontSize: 11, letterSpacing: 1.5), textAlign: TextAlign.center),
                      const SizedBox(height: 40),
                      const Text('Email Address', style: TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(hintText: 'you@company.com', prefixIcon: Icon(Icons.mail_outline)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text('Password', style: TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textDim),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                        onFieldSubmitted: (_) => _submit(auth),
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(auth.errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ],
                      const SizedBox(height: 28),
                      DecoratedBox(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: auth.isLoading ? null : AppColors.gradient),
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: auth.isLoading ? AppColors.navySurfaceAlt : Colors.transparent, shadowColor: Colors.transparent),
                          onPressed: auth.isLoading ? null : () => _submit(auth),
                          child: auth.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan))
                              : const Text('Sign In', style: TextStyle(color: AppColors.navyDeep, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
