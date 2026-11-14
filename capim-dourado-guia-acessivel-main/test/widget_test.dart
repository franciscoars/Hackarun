import 'package:capim_dourado_app/data/geometria.dart';
import 'package:capim_dourado_app/data/models.dart';
import 'package:capim_dourado_app/data/seed.dart';
import 'package:capim_dourado_app/logic/rota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Zona zona(String id) => zonasIniciais.firstWhere((z) => z.id == id);

  test('Praça de Alimentação: elevador, passarela Norte e curva à esquerda', () {
    final rota = calcularRota(zona('praca'));
    expect(rota.usaElevador, isTrue);
    expect(rota.caminhos.keys, containsAll([0, 1]));
    expect(rota.passos.any((p) => p.direcao == Direcao.elevador), isTrue);
    expect(rota.passos.any((p) => p.texto.contains('passarela sentido Norte')), isTrue);
    expect(rota.passos.any((p) => p.direcao == Direcao.esquerda), isTrue);
    expect(rota.passos.last.texto, contains('Praça de Alimentação'));
  });

  test('Banheiros: Térreo, vira à esquerda e o destino fica à esquerda', () {
    final rota = calcularRota(zona('banh0'));
    expect(rota.usaElevador, isFalse);
    expect(rota.passos[2].texto, startsWith('Vire à esquerda'));
    expect(rota.passos.any((p) => p.texto.contains('fica à sua esquerda')), isTrue);
  });

  test('SAC: Térreo, lado leste, vira à direita', () {
    final rota = calcularRota(zona('sac'));
    expect(rota.passos[2].texto, startsWith('Vire à direita'));
    expect(rota.passos[2].sentido, anyOf('Leste', 'Nordeste', 'Sudeste'));
  });

  test('A rota segue a curva do corredor (não é linha reta)', () {
    final rota = calcularRota(zona('ancora'));
    final pontos = rota.caminhos[0]!;
    expect(pontos.length, greaterThan(10));
    for (final p in pontos.skip(1).take(pontos.length - 2)) {
      expect(Geo.kDe(p), closeTo(Geo.kCorredor, 0.01));
    }
  });

  test('Cada zona de destino contém o próprio rótulo (hit test do mapa)', () {
    for (final z in zonasIniciais.where((z) => z.ehSetor)) {
      expect(z.contem(z.centroRotulo), isTrue, reason: z.id);
    }
  });
}
