import 'package:campus_event_app/core/theme/app_theme.dart';
import 'package:campus_event_app/features/auth/presentation/screens/auth_gate.dart';
import 'package:campus_event_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:campus_event_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:campus_event_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/features/events/presentation/screens/events_screen.dart';
import 'package:campus_event_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:campus_event_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Options are generated per-platform (incl. web) by `flutterfire configure`,
  // which writes lib/firebase_options.dart.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Top-level providers are registered once here. Add new feature providers
    // to this MultiProvider rather than creating a second registration point.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = AuthProvider();
          provider.initialize();
          return provider;
        }),
      ],
      child: MaterialApp(
        title: 'Campus Event App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: AuthGate(),
        routes: {
          '/sign-in': (context) => const SignInScreen(),
          '/sign-up': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/events': (context) => const EventsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
