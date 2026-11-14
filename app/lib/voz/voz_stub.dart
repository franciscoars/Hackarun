/// Fora do navegador (Android) não há Web Speech API: o app usa o flutter_tts.
class VozNavegador {
  bool get disponivel => false;
  Future<bool> temVoz(String idioma) async => true;
  Future<void> falar(String texto, {required String idioma, double velocidade = 1.0}) async {}
  void parar() {}
}
