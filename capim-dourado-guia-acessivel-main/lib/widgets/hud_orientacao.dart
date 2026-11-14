import 'package:flutter/material.dart';

import '../data/geometria.dart';
import '../logic/rota.dart';
import '../theme.dart';

/// Indicador de orientação sobre o mapa (estilo HUD de jogo):
/// - faixa de bússola que gira com o rumo do passo (N, NE, L, SE, S, SO, O, NO);
/// - selo com a direção relativa: FRENTE, ESQUERDA, DIREITA, ELEVADOR, CHEGOU.
class HudOrientacao extends StatelessWidget {
  const HudOrientacao({super.key, required this.rumo, required this.direcao, required this.altoContraste});

  /// Rumo em graus (pode passar de 360; é normalizado ao desenhar).
  final double rumo;
  final Direcao direcao;
  final bool altoContraste;

  @override
  Widget build(BuildContext context) {
    final ac = altoContraste;
    final fundo = ac ? Colors.black : Colors.white.withValues(alpha: 0.94);
    final tinta = ac ? Colors.white : const Color(0xFF1C1C1C);
    final destaque = ac ? Cores.amareloAC : Cores.laranjaRota;

    final (icone, rotulo) = switch (direcao) {
      Direcao.inicio => (Icons.my_location, 'INÍCIO'),
      Direcao.frente => (Icons.arrow_upward_rounded, 'FRENTE'),
      Direcao.esquerda => (Icons.turn_left_rounded, 'ESQUERDA'),
      Direcao.direita => (Icons.turn_right_rounded, 'DIREITA'),
      Direcao.elevador => (Icons.elevator, 'ELEVADOR'),
      Direcao.chegada => (Icons.flag_rounded, 'CHEGOU'),
    };

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: fundo,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ac ? Cores.amareloAC : Colors.black12, width: ac ? 2 : 1),
              boxShadow: ac ? null : const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: rumo),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                builder: (_, r, _) => CustomPaint(
                  painter: _BussolaPainter(r, tinta, destaque),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: destaque,
            borderRadius: BorderRadius.circular(14),
            boxShadow: ac ? null : const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
          ),
          child: Row(children: [
            Icon(icone, color: ac ? Colors.black : Colors.white, size: 26),
            const SizedBox(width: 4),
            Text(rotulo,
                style: TextStyle(color: ac ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
          ]),
        ),
      ],
    );
  }
}

class _BussolaPainter extends CustomPainter {
  _BussolaPainter(this.rumo, this.tinta, this.destaque);

  final double rumo;
  final Color tinta, destaque;

  @override
  void paint(Canvas canvas, Size size) {
    const campo = 180.0; // graus visíveis na faixa
    final pxPorGrau = size.width / campo;
    final centro = size.width / 2;
    final r = Geo.norm(rumo);

    final traco = Paint()
      ..color = tinta.withValues(alpha: 0.45)
      ..strokeWidth = 1.5;
    for (var g = 0; g < 360; g += 15) {
      final dx = Geo.delta(r, g.toDouble()) * pxPorGrau;
      if (dx.abs() > size.width / 2 + 10) continue;
      final x = centro + dx;
      final ehCardeal = g % 45 == 0;
      if (ehCardeal) {
        final sigla = Geo.siglas[g ~/ 45];
        final tp = TextPainter(
          text: TextSpan(
            text: sigla,
            style: TextStyle(
              color: g == 0 ? destaque : tinta,
              fontSize: sigla.length == 1 ? 17 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height / 2 - tp.height / 2 - 4));
        canvas.drawLine(Offset(x, size.height - 9), Offset(x, size.height - 2), traco..strokeWidth = 2);
      } else {
        canvas.drawLine(Offset(x, size.height - 7), Offset(x, size.height - 2), traco..strokeWidth = 1.5);
      }
    }

    // Marcador central = para onde o visitante está indo
    final m = Path()
      ..moveTo(centro - 8, 0)
      ..lineTo(centro + 8, 0)
      ..lineTo(centro, 9)
      ..close();
    canvas.drawPath(m, Paint()..color = destaque);
    canvas.drawLine(Offset(centro, 9), Offset(centro, size.height),
        Paint()
          ..color = destaque.withValues(alpha: 0.5)
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_BussolaPainter old) => old.rumo != rumo || old.tinta != tinta;
}
