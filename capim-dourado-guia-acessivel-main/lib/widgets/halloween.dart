import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Desenha uma abóbora de Halloween centrada em [c], com altura [t].
void desenharAbobora(Canvas canvas, Offset c, double t, {bool rosto = true}) {
  final w = t * 1.25;
  final corpo = Paint()..color = const Color(0xFFFF7A00);
  final gomo = Paint()..color = const Color(0xFFE56500);
  final contorno = Paint()
    ..color = const Color(0xFF8A3A00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = t * 0.04;

  // Cabinho
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(t * 0.04, -t * 0.5), width: t * 0.14, height: t * 0.26),
        Radius.circular(t * 0.05)),
    Paint()..color = const Color(0xFF3E7D2C),
  );
  // Gomos laterais e central
  for (final dx in [-0.32, 0.32]) {
    final r = Rect.fromCenter(center: c.translate(w * dx, 0), width: w * 0.55, height: t * 0.9);
    canvas.drawOval(r, gomo);
    canvas.drawOval(r, contorno);
  }
  final centro = Rect.fromCenter(center: c, width: w * 0.6, height: t * 0.96);
  canvas.drawOval(centro, corpo);
  canvas.drawOval(centro, contorno);

  if (!rosto) return;
  final rostoPaint = Paint()..color = const Color(0xFF1A0E00);
  final brilho = Paint()..color = const Color(0xFFFFD54F);
  // Olhos triangulares
  for (final dx in [-0.17, 0.17]) {
    final o = c.translate(w * dx, -t * 0.1);
    final p = Path()
      ..moveTo(o.dx - t * 0.09, o.dy + t * 0.06)
      ..lineTo(o.dx + t * 0.09, o.dy + t * 0.06)
      ..lineTo(o.dx, o.dy - t * 0.09)
      ..close();
    canvas.drawPath(p, brilho);
    canvas.drawPath(p.shift(Offset(0, t * 0.015)), rostoPaint);
  }
  // Boca em zigue-zague
  final boca = Path()..moveTo(c.dx - w * 0.24, c.dy + t * 0.12);
  for (var i = 0; i <= 6; i++) {
    final x = c.dx - w * 0.24 + w * 0.48 * i / 6;
    boca.lineTo(x, c.dy + t * (i.isEven ? 0.12 : 0.2));
  }
  boca.quadraticBezierTo(c.dx, c.dy + t * 0.36, c.dx - w * 0.24, c.dy + t * 0.12);
  canvas.drawPath(boca, rostoPaint);
}

/// Morcego simples com asas batendo ([fase] 0..1).
void desenharMorcego(Canvas canvas, Offset c, double t, double fase, Color cor) {
  final asa = sin(fase * 2 * pi) * 0.35;
  final p = Paint()..color = cor;
  for (final lado in [-1.0, 1.0]) {
    final path = Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(c.dx + lado * t * 0.5, c.dy - t * (0.5 + asa), c.dx + lado * t, c.dy - t * asa)
      ..quadraticBezierTo(c.dx + lado * t * 0.75, c.dy + t * 0.05, c.dx + lado * t * 0.55, c.dy + t * 0.18)
      ..quadraticBezierTo(c.dx + lado * t * 0.35, c.dy + t * 0.02, c.dx, c.dy + t * 0.12)
      ..close();
    canvas.drawPath(path, p);
  }
  canvas.drawOval(Rect.fromCenter(center: c.translate(0, t * 0.05), width: t * 0.26, height: t * 0.34), p);
}

/// Teia num canto da tela.
void desenharTeia(Canvas canvas, Offset canto, double raio, double angIni, double angFim, Paint p) {
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

/// Abóbora como widget (para cabeçalhos e botões).
class Abobora extends StatelessWidget {
  const Abobora({super.key, this.tamanho = 40, this.rosto = true});

  final double tamanho;
  final bool rosto;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: tamanho * 1.3,
        height: tamanho * 1.2,
        child: CustomPaint(painter: _AboboraPainter(rosto)),
      ),
    );
  }
}

class _AboboraPainter extends CustomPainter {
  _AboboraPainter(this.rosto);
  final bool rosto;

  @override
  void paint(Canvas canvas, Size size) =>
      desenharAbobora(canvas, Offset(size.width / 2, size.height * 0.56), size.height / 1.2, rosto: rosto);

  @override
  bool shouldRepaint(_AboboraPainter old) => old.rosto != rosto;
}

/// Decoração do modo Halloween sobre todas as telas: teias nos cantos de cima
/// e dois morcegos voando. Não recebe toques nem é lida pelo leitor de tela.
class HalloweenOverlay extends StatefulWidget {
  const HalloweenOverlay({super.key});

  @override
  State<HalloweenOverlay> createState() => _HalloweenOverlayState();
}

class _HalloweenOverlayState extends State<HalloweenOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduzir = MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            size: Size.infinite,
            painter: _OverlayPainter(reduzir ? 0.3 : _c.value, MediaQuery.of(context).padding.top),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter(this.t, this.topo);
  final double t;
  final double topo;

  @override
  void paint(Canvas canvas, Size size) {
    final teia = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    desenharTeia(canvas, Offset(0, topo), 70, 0, pi / 2, teia);
    desenharTeia(canvas, Offset(size.width, topo), 70, pi / 2, pi, teia);

    // Dois morcegos cruzando a parte de cima da tela
    for (var i = 0; i < 2; i++) {
      final f = (t + i * 0.5) % 1.0;
      final x = -40 + (size.width + 80) * f;
      final y = topo + 40 + i * 26 + sin(f * 2 * pi * 3) * 10;
      desenharMorcego(canvas, Offset(x, y), 18 - i * 4.0, (t * 40 + i * 0.3) % 1.0,
          Cores.roxoHalloween.withValues(alpha: 0.85));
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.t != t;
}
