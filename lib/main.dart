import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pixel_snap/pixel_snap.dart';

import 'constants/app_colors.dart';
import 'models/emergency_contact.dart';
import 'models/sos_event.dart';
import 'services/sos_service.dart';
import 'services/connectivity_service.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapter(EmergencyContactAdapter());
  Hive.registerAdapter(SosEventAdapter());

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  try {
    await initializeBackgroundService();
  } catch (_) {}

  await ConnectivityService().initialize();
  await SosService().initialize();

  runApp(const RescueAlertApp());
}

class RescueAlertApp extends StatelessWidget {
  const RescueAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PixelSnapApp(
      child: MaterialApp(
        title: 'RescueAlert',
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: AppColors.sosRed,
        secondary: AppColors.policeBlue,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.sosRed,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.sosRed),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}