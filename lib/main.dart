/// SpotSaku — application entry point.
///
/// Wires up the [MultiProvider] (spot, theme, settings), initialises the
/// notification service, and launches the [HomeScreen].
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/spot_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'utils/notification_service.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise services that must be ready before the first frame.
  _bootstrap();

  runApp(const SpotSakuApp());
}

Future<void> _bootstrap() async {
  // Fire-and-forget: notification init can happen in the background.
  NotificationService.instance.init();
}

class SpotSakuApp extends StatelessWidget {
  const SpotSakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => SpotProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SpotSaku',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
