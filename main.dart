import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob
  await MobileAds.instance.initialize();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SnapLoadApp());
}

class SnapLoadApp extends StatelessWidget {
  const SnapLoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapLoad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFF06B6D4),
          surface: const Color(0xFF1A1A26),
          background: const Color(0xFF0A0A0F),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0F),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
