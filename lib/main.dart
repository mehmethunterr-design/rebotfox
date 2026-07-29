import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'core/brand.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android, Firebase ayarını google-services.json dosyasından okur.
  // Web yapılandırması henüz eklenmemişse uygulamanın tasarım ön izlemesi
  // yine de açılır. Firebase kullanan ekranlar web ayarı tamamlanana kadar
  // çalışmayabilir.
  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    debugPrint('Firebase başlatılamadı: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const BlueTechApp());
}

class BlueTechApp extends StatelessWidget {
  const BlueTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppBrand.appTitle,
      theme: AppTheme.dark(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
