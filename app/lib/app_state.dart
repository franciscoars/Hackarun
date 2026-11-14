import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'config.dart';
import 'data/database.dart';
import 'data/models.dart';
import 'theme.dart';
import 'voz/voz_stub.dart' if (dart.library.js_interop) 'voz/voz_web.dart';

/// Texto-para-fala (TTS) em português, inglês e espanhol.
/// No navegador usa a Web Speech API diretamente (VozNavegador);
/// no Android usa o flutter_tts.
class Fala {
  final VozNavegador _navegador = VozNavegador();
  FlutterTts? _tts;

  bool get _usarNavegador => kIsWeb && _navegador.disponivel;

  Future<void> iniciar() async {
    if (kIsWeb) return;
    try {
      final tts = _tts = FlutterTts();
      await tts.setLanguage('pt-BR');
      await tts.setSpeechRate(0.5);
      await tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> falar(String texto, {String idioma = 'pt-BR'}) async {
    try {
      if (_usarNavegador) {
        await _navegador.falar(texto, idioma: idioma);
        return;
      }
      final tts = _tts ??= FlutterTts();
      await tts.stop();
      await tts.setLanguage(idioma);
      await tts.speak(texto);
    } catch (_) {}
  }

  /// Se o aparelho tem voz instalada no idioma (ex.: en-US, es-ES).
  /// Sem ela, o navegador lê com a voz padrão (sotaque de outra língua).
  Future<bool> temVoz(String idioma) async {
    try {
      if (_usarNavegador) return await _navegador.temVoz(idioma);
      final r = await (_tts ??= FlutterTts()).isLanguageAvailable(idioma);
      return r == true || r == 1;
    } catch (_) {
      return true;
    }
  }

  Future<void> parar() async {
    try {
      if (_usarNavegador) {
        _navegador.parar();
      } else {
        await _tts?.stop();
      }
    } catch (_) {}
  }
}

/// Estado global: banco, preferências de acessibilidade e voz.
class AppState extends ChangeNotifier {
  AppState(this.db) {
    // Guarda o horário real do último toque na tela (usado no duplo toque).
    GestureBinding.instance.pointerRouter.addGlobalRoute((e) {
      if (e is PointerDownEvent) _ultimoPointerDown = e.timeStamp;
    });
  }

  final ShoppingDatabase db;
  final Fala fala = Fala();

  bool altoContraste = false;

  /// Modo Halloween: alto contraste em laranja com abóboras, morcegos e teias.
  /// Ativado com 2 toques seguidos no botão Alto Contraste.
  bool halloween = false;
  bool guiaVoz = false;
  List<Zona> zonas = const [];
  Duration? _ultimoToqueContraste;
  Duration? _ultimoPointerDown;

  /// Local do totem onde o QR Code foi lido.
  final String localAtual = 'Totem da Entrada Principal · Térreo';

  Future<void> carregar() async {
    final prefs = await db.preferencias();
    altoContraste = (prefs['altoContraste'] as bool?) ?? false;
    halloween = altoContraste && ((prefs['halloween'] as bool?) ?? false);
    Cores.halloween = halloween;
    guiaVoz = (prefs['guiaVoz'] as bool?) ?? false;
    zonas = await db.zonas();
    await fala.iniciar();
  }

  /// Registra uso para o relatório de gestão (rotas mais buscadas e mapa de calor).
  Future<void> registrar(String tipo, String chave) async {
    try {
      await db.registrarEvento(tipo: tipo, chave: chave, origem: modoTotem ? 'totem' : 'celular');
    } catch (_) {}
  }

  /// Botão Alto Contraste:
  ///  - 1 toque: liga/desliga o alto contraste (preto e amarelo);
  ///  - 2 toques seguidos: ativa o modo Halloween (preto e laranja + decoração).
  ///
  /// O intervalo entre os toques é medido pelo horário do próprio toque
  /// (timestamp do evento), e não pela hora em que o código roda: a troca de
  /// tema pode travar a tela por um instante num aparelho lento, e o 2º toque
  /// ficaria "atrasado" na fila.
  Future<void> tocarContraste() async {
    final agora = _ultimoPointerDown ?? Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    _ultimoPointerDown = null;
    final duplo = _ultimoToqueContraste != null &&
        (agora - _ultimoToqueContraste!).abs() < const Duration(milliseconds: 700);
    _ultimoToqueContraste = duplo ? null : agora;

    if (duplo) {
      altoContraste = true;
      halloween = true;
    } else {
      altoContraste = !altoContraste;
      halloween = false;
    }
    Cores.halloween = halloween;
    notifyListeners();
    await db.salvarPreferencia('altoContraste', altoContraste);
    await db.salvarPreferencia('halloween', halloween);
    if (halloween) {
      registrar('recurso', 'halloween');
    } else if (altoContraste) {
      registrar('recurso', 'altoContraste');
    }
    await anunciar(halloween
        ? 'Modo Halloween ativado.'
        : (altoContraste ? 'Alto contraste ativado.' : 'Alto contraste desativado.'));
  }

  Future<void> alternarGuiaVoz() async {
    guiaVoz = !guiaVoz;
    notifyListeners();
    await db.salvarPreferencia('guiaVoz', guiaVoz);
    if (guiaVoz) registrar('recurso', 'guiaVoz');
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
