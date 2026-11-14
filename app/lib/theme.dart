import 'package:flutter/material.dart';

import 'app_state.dart';

class Cores {
  static const verde = Color(0xFF17382A);
  static const verdeMedio = Color(0xFF24533D);
  static const dourado = Color(0xFFC8961E);
  static const douradoClaro = Color(0xFFF2C14E);
  static const creme = Color(0xFFFFF8E8);
  /// Ativado com 2 toques no botão Alto Contraste (ver AppState).
  static bool halloween = false;

  /// Destaque do Alto Contraste: amarelo (normal) ou laranja-abóbora (Halloween).
  /// Ambos passam de 7:1 sobre preto (WCAG AAA).
  static const amareloPuro = Color(0xFFFFD600);
  static const laranjaHalloween = Color(0xFFFF9A1F);
  static Color get amareloAC => halloween ? laranjaHalloween : amareloPuro;
  static const roxoHalloween = Color(0xFF9C4DFF);
  static const verdeLogo = Color(0xFF676E4F);
  static const cremeLogo = Color(0xFFF6E3C8);
  static const laranjaRota = Color(0xFFE65100);
}

ThemeData construirTema({required bool altoContraste}) {
  if (altoContraste) {
    final scheme = ColorScheme.dark(
      primary: Cores.amareloAC,
      onPrimary: Colors.black,
      secondary: Cores.amareloAC,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      error: Color(0xFFFF5252),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
    );
  }
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Cores.dourado,
      primary: Cores.verde,
      secondary: Cores.dourado,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Cores.creme,
  );
}

/// Cores semânticas que mudam com o modo Alto Contraste.
class Paleta {
  const Paleta(this.ac);
  final bool ac;

  static Paleta of(BuildContext context) => Paleta(AppScope.of(context).altoContraste);

  Color get cabecalho => ac ? Colors.black : Cores.verde;
  Color get cabecalhoTexto => ac ? Cores.amareloAC : Colors.white;
  Color get fundo => ac ? Colors.black : Cores.creme;
  Color get cartao => ac ? const Color(0xFF0D0D0D) : Colors.white;
  Color get texto => ac ? Colors.white : const Color(0xFF1C1C1C);
  Color get textoSuave => ac ? Colors.white70 : const Color(0xFF5B5B5B);
  Color get destaque => ac ? Cores.amareloAC : Cores.dourado;
  Color get rota => ac ? Cores.amareloAC : Cores.laranjaRota;
  Border? get borda => ac ? Border.all(color: Cores.amareloAC, width: 2) : null;

  List<BoxShadow> get sombra => ac
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ];
}
