import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Voz no navegador direto pela Web Speech API.
///
/// Por que não usar só o flutter_tts aqui: no navegador ele reaproveita
/// uma única fala, ignora `speak` logo depois de `stop` e não troca de
/// idioma se a lista de vozes ainda não carregou. O resultado era inglês
/// e espanhol mudos. Aqui cada frase é uma fala nova, com a voz do idioma.
class VozNavegador {
  web.SpeechSynthesis get _synth => web.window.speechSynthesis;
  List<web.SpeechSynthesisVoice> _vozes = const [];
  Completer<void>? _carregando;

  bool get disponivel {
    try {
      return (web.window as JSObject).has('speechSynthesis');
    } catch (_) {
      return false;
    }
  }

  /// A lista de vozes chega de forma assíncrona (evento `voiceschanged`).
  Future<void> _carregarVozes() async {
    _vozes = _synth.getVoices().toDart;
    if (_vozes.isNotEmpty) return;
    if (_carregando != null) return _carregando!.future;
    final c = _carregando = Completer<void>();
    _synth.onvoiceschanged = ((web.Event _) {
      _vozes = _synth.getVoices().toDart;
      if (!c.isCompleted) c.complete();
    }).toJS;
    // Alguns navegadores nunca disparam o evento: segue sem lista.
    await c.future.timeout(const Duration(milliseconds: 1500), onTimeout: () {});
    _vozes = _synth.getVoices().toDart;
    _carregando = null;
  }

  /// Melhor voz para o idioma: mesmo código (en-US), depois mesma língua (en),
  /// preferindo vozes do aparelho (funcionam offline e não cortam a fala).
  web.SpeechSynthesisVoice? _vozPara(String idioma) {
    String norm(String s) => s.toLowerCase().replaceAll('_', '-');
    final alvo = norm(idioma);
    final lingua = alvo.split('-').first;
    final exatas = _vozes.where((v) => norm(v.lang) == alvo).toList();
    final mesmaLingua = _vozes.where((v) => norm(v.lang).split('-').first == lingua).toList();
    for (final lista in [exatas, mesmaLingua]) {
      if (lista.isEmpty) continue;
      return lista.firstWhere((v) => v.localService, orElse: () => lista.first);
    }
    return null;
  }

  /// true se o aparelho tem uma voz instalada na língua pedida.
  Future<bool> temVoz(String idioma) async {
    await _carregarVozes();
    if (_vozes.isEmpty) return true; // sem lista: não dá para saber, não avisa
    return _vozPara(idioma) != null;
  }

  Future<void> falar(String texto, {required String idioma, double velocidade = 1.0}) async {
    if (texto.trim().isEmpty) return;
    await _carregarVozes();
    final f = web.SpeechSynthesisUtterance(texto)
      ..lang = idioma
      ..rate = velocidade
      ..pitch = 1.0
      ..volume = 1.0;
    final voz = _vozPara(idioma);
    if (voz != null) {
      f.voice = voz;
      f.lang = voz.lang;
    }
    // O Chrome descarta a fala se speak() vem colado no cancel().
    final estavaFalando = _synth.speaking || _synth.pending;
    _synth.cancel();
    if (estavaFalando) await Future<void>.delayed(const Duration(milliseconds: 80));
    _synth.resume(); // destrava o Chrome se ficou em pausa
    _synth.speak(f);
  }

  void parar() => _synth.cancel();
}
