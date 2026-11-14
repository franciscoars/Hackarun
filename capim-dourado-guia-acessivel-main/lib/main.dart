import 'package:flutter/material.dart';

import 'app_state.dart';
import 'data/database.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';
import 'config.dart';
import 'widgets/phone_frame.dart';
import 'widgets/totem_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await ShoppingDatabase.abrir();
  final estado = AppState(db);
  await estado.carregar();
  runApp(AppScope(state: estado, child: const CapimDouradoApp()));
}

class CapimDouradoApp extends StatelessWidget {
  const CapimDouradoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return MaterialApp(
      title: 'Capim Dourado Shopping · Guia Acessível',
      debugShowCheckedModeBanner: false,
      theme: construirTema(altoContraste: s.altoContraste),
      navigatorKey: navegadorKey,
      builder: (context, child) =>
          modoTotem ? TotemFrame(child: child!) : PhoneFrame(child: child!),
      home: const SplashScreen(),
    );
  }
}
