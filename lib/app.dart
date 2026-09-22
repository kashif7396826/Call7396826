import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/calls/call_provider.dart';
import 'features/home/home_shell.dart';

class CallDragApp extends StatelessWidget {
  const CallDragApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: MaterialApp(
        title: 'CallDrag',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        darkTheme: ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.dark, useMaterial3: true),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Switches between the login flow and the authenticated app shell based on the REAL session
/// state (AuthProvider._restoreSession() actually calls GET /auth/me against stored tokens —
/// this never just trusts "a token exists in storage" as proof of being logged in).
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.awaitingTotp:
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
