import 'package:campus_event_app/core/router/app_router.dart';
import 'package:campus_event_app/core/theme/app_theme.dart';
import 'package:campus_event_app/core/theme/theme_provider.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/features/events/providers/event_dashboard_provider.dart';
import 'package:campus_event_app/features/events/providers/event_list_provider.dart';
import 'package:campus_event_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // The AuthProvider is created once and shared between the widget tree and the
  // router: go_router's redirect gates on its state and uses it as the
  // refreshListenable, so the same instance must be registered via
  // ChangeNotifierProvider.value below.
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider()..initialize();
    _router = createAppRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Top-level providers are registered once here. Add new feature providers
    // to this MultiProvider rather than creating a second registration point.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadThemeMode()),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => EventListProvider()),
        ChangeNotifierProvider(create: (_) => EventDashboardProvider()),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Campus Event App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.watch<ThemeProvider>().themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
