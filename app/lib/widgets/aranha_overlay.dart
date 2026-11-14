import 'dart:math';

import 'package:flutter/material.dart';

/// Detalhe de Halloween: uma aranha desce pelo fio até o centro,
/// balança por 1,5 s e sobe desaparecendo. Não bloqueia nada depois.
class AranhaOverlay extends StatefulWidget {
  const AranhaOverlay({super.key, required this.aoTerminar});

  final VoidCallback aoTerminar;

  @override
  State<AranhaOverlay> createState() => _AranhaOverlayState();
}

class _AranhaOverlayState extends State<AranhaOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3300),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.aoTerminar();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            size: Size.infinite,
            painter: _AranhaPainter(_c.value),
          ),
        ),
      ),
    );
  }
}

class _AranhaPainter extends CustomPainter {
  _AranhaPainter(this.t);

  final double t;

  static const _fimDescida = 1000 / 3300;
  static const _fimPausa = 2500 / 3300;

  @override
  void paint(Canvas canvas, Size size) {
    final alvo = size.height * 0.42;
    double y;
    double balanco;
    double opacidade = 1;
    double teia;
    double pernas = 0;

    if (t < _fimDescida) {
      final k = t / _fimDescida;
      y = -170 + (alvo + 170) * Curves.easeOutBack.transform(k);
      balanco = sin(k * pi) * 0.05;
      teia = k;
    } else if (t < _fimPausa) {
      final k = (t - _fimDescida) / (_fimPausa - _fimDescida);
      y = alvo + sin(k * pi * 3) * 6;
      balanco = sin(k * pi * 2) * 0.06;
      pernas = sin(k * pi * 8);
      teia = 1;
    } else {
      final k = Curves.easeIn.transform((t - _fimPausa) / (1 - _fimPausa));
      y = alvo - (alvo + 220) * k;
      balanco = 0;
      opacidade = 1 - k;
      teia = 1 - k;
    }

    // Teia no canto superior direito
    final teiaPaint = Paint()
      ..color = const Color(0xFF3A3A3A).withValues(alpha: 0.55 * teia)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    _teia(canvas, Offset(size.width, 0), 130, pi / 2, pi, teiaPaint);
    _teia(canvas, Offset.zero, 80, 0, pi / 2, teiaPaint);

    final cor = const Color(0xFF111111).withValues(alpha: opacidade);

    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.rotate(balanco);

    // Fio
    canvas.drawLine(
      Offset.zero,
      Offset(0, y - 58),
      Paint()
        ..color = const Color(0xFF222222).withValues(alpha: opacidade)
        ..strokeWidth = 2,
    );

    canvas.translate(0, y);
    canvas.scale(0.85);
    _aranha(canvas, cor, pernas);
    canvas.restore();
  }

  void _aranha(Canvas canvas, Color cor, double mexer) {
    final corpo = Paint()..color = cor;

    const pernas = [
      [Offset(12, 6), Offset(38, -34), Offset(46, -112)],
      [Offset(17, 12), Offset(78, 8), Offset(128, -28)],
      [Offset(17, 20), Offset(72, 40), Offset(108, 112)],
      [Offset(12, 26), Offset(42, 78), Offset(48, 150)],
    ];

    for (final lado in [-1.0, 1.0]) {
      for (var i = 0; i < pernas.length; i++) {
        final p = pernas[i];
        final ajuste = Offset(0, mexer * (i.isEven ? 4 : -4));
        final a = Offset(p[0].dx * lado, p[0].dy);
        final b = Offset(p[1].dx * lado, p[1].dy) + ajuste * 0.5;
        final c = Offset(p[2].dx * lado, p[2].dy) + ajuste;
        canvas.drawLine(a, b, Paint()
          ..color = cor
          ..strokeWidth = 6.5
          ..strokeCap = StrokeCap.round);
        canvas.drawLine(b, c, Paint()
          ..color = cor
          ..strokeWidth = 3.8
          ..strokeCap = StrokeCap.round);
      }
    }

    // Abdômen, cefalotórax e cabeça
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -28), width: 54, height: 64), corpo);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 18), width: 38, height: 34), corpo);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 38), width: 20, height: 13), corpo);

    // Brilho sutil e olhinhos
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-11, -42), width: 12, height: 18),
      Paint()..color = Colors.white.withValues(alpha: 0.12 * cor.a),
    );
    final olho = Paint()..color = Colors.white.withValues(alpha: 0.8 * cor.a);
    canvas.drawCircle(const Offset(-4, 39), 1.8, olho);
    canvas.drawCircle(const Offset(4, 39), 1.8, olho);
  }

  void _teia(Canvas canvas, Offset canto, double raio, double angIni, double angFim, Paint p) {
    const n = 6;
    final angs = List.generate(n, (i) => angIni + (angFim - angIni) * i / (n - 1));
    for (final a in angs) {
      canvas.drawLine(canto, canto + Offset(cos(a), sin(a)) * raio, p);
    }
    for (var r = raio * 0.25; r <= raio; r += raio * 0.22) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final pt = canto + Offset(cos(angs[i]), sin(angs[i])) * r;
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          final am = (angs[i - 1] + angs[i]) / 2;
          final ctrl = canto + Offset(cos(am), sin(am)) * r * 0.82;
          path.quadraticBezierTo(ctrl.dx, ctrl.dy, pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_AranhaPainter old) => old.t != t;
}
