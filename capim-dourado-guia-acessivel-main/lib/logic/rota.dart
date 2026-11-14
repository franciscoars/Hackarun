import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';

/// ~19.400 m² por pavimento → 1 unidade do mapa ≈ 0,18 m.
const double metrosPorUnidade = 0.18;
const Offset pontoTotem = Offset(350, 880);
const double corredorX = 350;
const Offset portaElevador = Offset(400, 490);

class PassoRota {
  const PassoRota(this.icone, this.texto, this.andar);

  final IconData icone;
  final String texto;
  final int andar;
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

/// Porta de entrada da zona (sempre voltada para o corredor central).
Offset portaDa(Zona z) {
  final cy = z.y + z.h / 2;
  return z.x < corredorX ? Offset(z.x + z.w, cy) : Offset(z.x, cy);
}

RotaCalculada calcularRota(Zona destino) {
  final porta = portaDa(destino);
  final naColunaEsquerda = destino.x < corredorX;
  final passos = <PassoRota>[];
  final caminhos = <int, List<Offset>>{};

  double m(Offset a, Offset b) => (a - b).distance * metrosPorUnidade;
  String fmt(double v) => '${max(5, (v / 5).round() * 5)} metros';

  passos.add(const PassoRota(Icons.my_location,
      'Você está no totem da Entrada Principal, no Térreo. Fique de frente para o corredor central.', 0));

  double metros;
  if (destino.andar == 0) {
    final curva = Offset(corredorX, porta.dy);
    caminhos[0] = [pontoTotem, curva, porta];
    final d1 = m(pontoTotem, curva);
    metros = d1 + m(curva, porta);
    passos.add(PassoRota(Icons.straight, 'Siga em frente pelo corredor central por cerca de ${fmt(d1)}.', 0));
    final lado = naColunaEsquerda ? 'esquerda' : 'direita';
    passos.add(PassoRota(naColunaEsquerda ? Icons.turn_left : Icons.turn_right,
        '${destino.nome} fica à sua $lado. Entre por ali.', 0));
  } else {
    final cruzamento = Offset(corredorX, portaElevador.dy);
    caminhos[0] = [pontoTotem, cruzamento, portaElevador];
    final d1 = m(pontoTotem, cruzamento);
    passos.add(PassoRota(Icons.straight, 'Siga em frente pelo corredor central por cerca de ${fmt(d1)}.', 0));
    passos.add(const PassoRota(Icons.turn_right, 'Os elevadores ficam à sua direita.', 0));
    passos.add(PassoRota(Icons.elevator,
        'Pegue o elevador acessível, ou a escada rolante, e suba para o Piso ${destino.andar}.', 0));

    final curva = Offset(corredorX, porta.dy);
    caminhos[destino.andar] = [portaElevador, cruzamento, curva, porta];
    final d3 = m(cruzamento, curva);
    metros = d1 + 2 * m(cruzamento, portaElevador) + d3 + m(curva, porta);

    // Ao sair do elevador o visitante está de frente para o oeste (corredor):
    // o norte (topo do mapa) fica à direita.
    final subindoNoMapa = porta.dy < cruzamento.dy;
    passos.add(PassoRota(Icons.elevator,
        'Ao sair do elevador no Piso ${destino.andar}, caminhe até o corredor central.', destino.andar));
    final virar = subindoNoMapa ? 'direita' : 'esquerda';
    passos.add(PassoRota(subindoNoMapa ? Icons.turn_right : Icons.turn_left,
        'Vire à $virar e siga pelo corredor por cerca de ${fmt(d3)}.', destino.andar));
    final ladoDestino = naColunaEsquerda == subindoNoMapa ? 'esquerda' : 'direita';
    passos.add(PassoRota(ladoDestino == 'esquerda' ? Icons.turn_left : Icons.turn_right,
        '${destino.nome} fica à sua $ladoDestino.', destino.andar));
  }

  passos.add(PassoRota(Icons.flag_rounded, 'Você chegou: ${destino.nome}!', destino.andar));

  return RotaCalculada(destino: destino, caminhos: caminhos, passos: passos, metros: metros);
}
