import 'dart:math';

import 'package:flutter/material.dart';

import '../data/geometria.dart';
import '../data/models.dart';

/// ~19.400 m² por pavimento → 1 unidade do mapa ≈ 0,18 m.
const double metrosPorUnidade = 0.18;

/// Totem da entrada principal (sul), de frente para o corredor circular.
final Offset pontoTotem = Geo.ponto(1.2, 90);

/// Direção relativa ao visitante, mostrada no indicador (HUD) e falada pela voz.
enum Direcao { inicio, frente, esquerda, direita, elevador, chegada }

class PassoRota {
  const PassoRota({
    required this.icone,
    required this.texto,
    required this.andar,
    required this.direcao,
    required this.rumo,
  });

  final IconData icone;
  final String texto;
  final int andar;
  final Direcao direcao;

  /// Rumo de bússola em graus (0 = Norte, 90 = Leste) ao cumprir o passo.
  final double rumo;

  String get sentido => Geo.cardinal(rumo);
}

class RotaCalculada {
  const RotaCalculada({
    required this.destino,
    required this.caminhos,
    required this.passos,
    required this.metros,
  });

  final Zona destino;

  /// Pontos do trajeto por andar.
  final Map<int, List<Offset>> caminhos;
  final List<PassoRota> passos;
  final double metros;

  bool get usaElevador => destino.andar != 0;
  int get minutos => max(1, (metros / 1.1 / 60).ceil());
  int get metrosArredondados => max(5, (metros / 5).round() * 5);
}

/// Porta da zona: na fachada, voltada para o corredor circular.
Offset portaDa(Zona z) => z.ehSetor ? Geo.ponto(Geo.kFachada, z.angMeio) : Geo.centro;

double _comprimento(List<Offset> pts) {
  var d = 0.0;
  for (var i = 1; i < pts.length; i++) {
    d += (pts[i] - pts[i - 1]).distance;
  }
  return d * metrosPorUnidade;
}

String _fmt(double metros) => '${max(5, (metros / 5).round() * 5)} metros';

RotaCalculada calcularRota(Zona destino) {
  final porta = portaDa(destino);
  final passos = <PassoRota>[];
  final caminhos = <int, List<Offset>>{};
  final anelSul = Geo.ponto(Geo.kCorredor, 90);

  passos.add(const PassoRota(
    icone: Icons.my_location,
    texto: 'Você está no totem da Entrada Principal, no Térreo, de frente para o corredor circular, sentido Norte.',
    andar: 0,
    direcao: Direcao.inicio,
    rumo: 0,
  ));

  if (destino.andar == 0) {
    final arco = Geo.arco(Geo.kCorredor, 90, destino.angMeio);
    caminhos[0] = [pontoTotem, ...arco, porta];
    final d = Geo.delta(90, destino.angMeio);
    final esquerda = d > 0; // sentido horário na tela = à esquerda de quem entra
    final rumoArco = Geo.rumo(arco[0], arco[1]);

    passos.add(PassoRota(
      icone: Icons.straight,
      texto: 'Siga em frente, sentido Norte, por cerca de ${_fmt(_comprimento([pontoTotem, anelSul]))} até o corredor circular.',
      andar: 0,
      direcao: Direcao.frente,
      rumo: 0,
    ));
    passos.add(PassoRota(
      icone: esquerda ? Icons.turn_left : Icons.turn_right,
      texto: 'Vire à ${esquerda ? 'esquerda' : 'direita'}, sentido ${Geo.cardinal(rumoArco)}, '
          'e acompanhe a curva do corredor por cerca de ${_fmt(_comprimento(arco))}.',
      andar: 0,
      direcao: esquerda ? Direcao.esquerda : Direcao.direita,
      rumo: rumoArco,
    ));
    final lado = esquerda ? 'esquerda' : 'direita';
    final rumoFinal = Geo.rumo(arco.last, porta);
    passos.add(PassoRota(
      icone: esquerda ? Icons.turn_left : Icons.turn_right,
      texto: '${destino.nome} fica à sua $lado, sentido ${Geo.cardinal(rumoFinal)}. Vire à $lado para entrar.',
      andar: 0,
      direcao: esquerda ? Direcao.esquerda : Direcao.direita,
      rumo: rumoFinal,
    ));
  } else {
    // Térreo: entrada → passarela sul → elevador panorâmico no centro.
    final elevadorSul = Geo.ponto(Geo.kElevador, 90);
    caminhos[0] = [pontoTotem, anelSul, elevadorSul];
    passos.add(PassoRota(
      icone: Icons.straight,
      texto: 'Siga em frente, sentido Norte, atravesse o corredor circular e continue pela passarela '
          'até o elevador panorâmico, no centro (cerca de ${_fmt(_comprimento(caminhos[0]!))}).',
      andar: 0,
      direcao: Direcao.frente,
      rumo: 0,
    ));
    passos.add(PassoRota(
      icone: Icons.elevator,
      texto: 'Pegue o elevador acessível e suba para o Piso ${destino.andar}.',
      andar: 0,
      direcao: Direcao.elevador,
      rumo: 0,
    ));

    // Piso de destino: sai pela passarela mais próxima do destino.
    final ponte = Geo.passarelas.reduce(
        (a, b) => Geo.delta(a, destino.angMeio).abs() <= Geo.delta(b, destino.angMeio).abs() ? a : b);
    final saida = Geo.ponto(Geo.kElevador, ponte);
    final anel = Geo.ponto(Geo.kCorredor, ponte);
    final d = Geo.delta(ponte, destino.angMeio);
    final arco = d.abs() < 6 ? [anel] : Geo.arco(Geo.kCorredor, ponte, destino.angMeio);
    caminhos[destino.andar] = [saida, ...arco, porta];
    final rumoPonte = Geo.rumo(saida, anel);

    passos.add(PassoRota(
      icone: Icons.straight,
      texto: 'Ao sair do elevador no Piso ${destino.andar}, siga pela passarela sentido ${Geo.cardinal(rumoPonte)} '
          'até o corredor circular (cerca de ${_fmt(_comprimento([saida, anel]))}).',
      andar: destino.andar,
      direcao: Direcao.frente,
      rumo: rumoPonte,
    ));

    if (arco.length == 1) {
      passos.add(PassoRota(
        icone: Icons.straight,
        texto: '${destino.nome} fica logo à sua frente, do outro lado do corredor.',
        andar: destino.andar,
        direcao: Direcao.frente,
        rumo: rumoPonte,
      ));
    } else {
      // Vindo de dentro para fora, o sentido horário fica à direita.
      final direita = d > 0;
      final rumoArco = Geo.rumo(arco[0], arco[1]);
      passos.add(PassoRota(
        icone: direita ? Icons.turn_right : Icons.turn_left,
        texto: 'Vire à ${direita ? 'direita' : 'esquerda'}, sentido ${Geo.cardinal(rumoArco)}, '
            'e acompanhe a curva do corredor por cerca de ${_fmt(_comprimento(arco))}.',
        andar: destino.andar,
        direcao: direita ? Direcao.direita : Direcao.esquerda,
        rumo: rumoArco,
      ));
      // No sentido horário, as lojas (lado de fora do anel) ficam à esquerda.
      final lado = d > 0 ? 'esquerda' : 'direita';
      final rumoFinal = Geo.rumo(arco.last, porta);
      passos.add(PassoRota(
        icone: lado == 'esquerda' ? Icons.turn_left : Icons.turn_right,
        texto: '${destino.nome} fica à sua $lado, sentido ${Geo.cardinal(rumoFinal)}.',
        andar: destino.andar,
        direcao: lado == 'esquerda' ? Direcao.esquerda : Direcao.direita,
        rumo: rumoFinal,
      ));
    }
  }

  passos.add(PassoRota(
    icone: Icons.flag_rounded,
    texto: 'Você chegou: ${destino.nome}!',
    andar: destino.andar,
    direcao: Direcao.chegada,
    rumo: passos.last.rumo,
  ));

  final metros = caminhos.values.fold(0.0, (s, c) => s + _comprimento(c));
  return RotaCalculada(destino: destino, caminhos: caminhos, passos: passos, metros: metros);
}
