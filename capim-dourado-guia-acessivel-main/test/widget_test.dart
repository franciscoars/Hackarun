import 'package:capim_dourado_app/data/seed.dart';
import 'package:capim_dourado_app/logic/rota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rota para a Praça de Alimentação usa o elevador e vira à direita no Piso 1', () {
    final praca = zonasIniciais.firstWhere((z) => z.id == 'praca');
    final rota = calcularRota(praca);
    expect(rota.usaElevador, isTrue);
    expect(rota.caminhos.keys, containsAll([0, 1]));
    expect(rota.passos.any((p) => p.texto.contains('Vire à direita')), isTrue);
    expect(rota.passos.last.texto, contains('Praça de Alimentação'));
  });

  test('Rota para Banheiros fica no Térreo, à esquerda', () {
    final banh = zonasIniciais.firstWhere((z) => z.id == 'banh0');
    final rota = calcularRota(banh);
    expect(rota.usaElevador, isFalse);
    expect(rota.passos.any((p) => p.texto.contains('à sua esquerda')), isTrue);
  });
}
