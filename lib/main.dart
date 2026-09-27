import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SwiftFinderApp());
}

class SwiftFinderApp extends StatelessWidget {
  const SwiftFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ItemProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ActivityProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..load(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SwiftFinder',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const HomeScreen();
  }
}
