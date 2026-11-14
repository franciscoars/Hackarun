import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'data/database.dart';
import 'data/models.dart';

/// Texto-para-fala (TTS). No navegador usa a Web Speech API.
class Fala {
  final FlutterTts _tts = FlutterTts();

  Future<void> iniciar() async {
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> falar(String texto, {String idioma = 'pt-BR'}) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(idioma);
      await _tts.speak(texto);
    } catch (_) {}
  }

  Future<void> parar() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// Estado global: banco, preferências de acessibilidade e voz.
class AppState extends ChangeNotifier {
  AppState(this.db);

  final ShoppingDatabase db;
  final Fala fala = Fala();

  bool altoContraste = false;
  bool guiaVoz = false;
  List<Zona> zonas = const [];

  /// Local do totem onde o QR Code foi lido.
  final String localAtual = 'Totem da Entrada Principal · Térreo';

  Future<void> carregar() async {
    final prefs = await db.preferencias();
    altoContraste = (prefs['altoContraste'] as bool?) ?? false;
    guiaVoz = (prefs['guiaVoz'] as bool?) ?? false;
    zonas = await db.zonas();
    await fala.iniciar();
  }

  Future<void> alternarAltoContraste() async {
    altoContraste = !altoContraste;
    notifyListeners();
    await db.salvarPreferencia('altoContraste', altoContraste);
    await anunciar(altoContraste ? 'Alto contraste ativado' : 'Alto contraste desativado');
  }

  Future<void> alternarGuiaVoz() async {
    guiaVoz = !guiaVoz;
    notifyListeners();
    await db.salvarPreferencia('guiaVoz', guiaVoz);
    if (guiaVoz) {
      await fala.falar('Guia por voz ativado. Vou ler as telas e as rotas para você.');
    } else {
      await fala.falar('Guia por voz desativado.');
    }
  }

  /// Fala somente se o guia por voz estiver ligado.
  Future<void> anunciar(String texto) async {
    if (guiaVoz) await fala.falar(texto);
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Use no build (reconstrói quando o estado muda).
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Use em callbacks (não cria dependência).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
