import 'dart:math';

import 'package:flutter/material.dart';

import '../data/icones.dart';
import '../data/models.dart';
import '../logic/rota.dart';
import '../theme.dart';

/// Mapa ilustrado de um pavimento, com rota animada.
class MapaShopping extends StatefulWidget {
  const MapaShopping({
    super.key,
    required this.zonas,
    required this.andar,
    required this.altoContraste,
    this.destino,
    this.caminho,
    this.onTapZona,
  });

  final List<Zona> zonas;
  final int andar;
  final bool altoContraste;
  final Zona? destino;
  final List<Offset>? caminho;
  final ValueChanged<Zona>? onTapZona;

  @override
  State<MapaShopping> createState() => _MapaShoppingState();
}

class _MapaShoppingState extends State<MapaShopping> with TickerProviderStateMixin {
  late final AnimationController _tracejado =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final AnimationController _pulso =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  late final AnimationController _caminhada =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();
  final _transformacao = TransformationController();

  @override
  void didUpdateWidget(MapaShopping old) {
    super.didUpdateWidget(old);
    if (old.andar != widget.andar || old.caminho != widget.caminho) {
      _caminhada
        ..reset()
        ..repeat();
      _transformacao.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _tracejado.dispose();
    _pulso.dispose();
    _caminhada.dispose();
    _transformacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = min(c.maxWidth, c.maxHeight * 0.7);
      final h = w / 0.7;
      final escala = w / 700;
      return InteractiveViewer(
        transformationController: _transformacao,
        minScale: 1,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(60),
        child: SizedBox(
          width: c.maxWidth,
          height: c.maxHeight,
          child: Center(
            child: GestureDetector(
              onTapUp: widget.onTapZona == null
                  ? null
                  : (d) {
                      final pt = d.localPosition / escala;
                      for (final z in widget.zonas.where((z) => z.andar == widget.andar)) {
                        if (z.rect.contains(pt)) {
                          widget.onTapZona!(z);
                          break;
                        }
                      }
                    },
              child: SizedBox(
                width: w,
                height: h,
                child: CustomPaint(
                  painter: _MapaPainter(
                    zonas: widget.zonas.where((z) => z.andar == widget.andar).toList(),
                    andar: widget.andar,
                    destino: widget.destino,
                    caminho: widget.caminho,
                    ac: widget.altoContraste,
                    tracejado: _tracejado,
                    pulso: _pulso,
                    caminhada: _caminhada,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _MapaPainter extends CustomPainter {
  _MapaPainter({
    required this.zonas,
    required this.andar,
    required this.destino,
    required this.caminho,
    required this.ac,
    required this.tracejado,
    required this.pulso,
    required this.caminhada,
  }) : super(repaint: Listenable.merge([tracejado, pulso, caminhada]));

  final List<Zona> zonas;
  final int andar;
  final Zona? destino;
  final List<Offset>? caminho;
  final bool ac;
  final Animation<double> tracejado, pulso, caminhada;

  Color get _corRota => ac ? Cores.amareloAC : Cores.laranjaRota;
  static const _azul = Color(0xFF1E88E5);
  bool get _temRota => caminho != null && caminho!.length > 1;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 700, size.height / 1000);
    _fundo(canvas);
    _predio(canvas);
    for (final z in zonas) {
      _zona(canvas, z);
    }
    if (_temRota) _rota(canvas);
    if (andar == 0) {
      _voceEstaAqui(canvas);
    } else if (_temRota) {
      _saidaElevador(canvas, caminho!.first);
    }
    if (destino != null && destino!.andar == andar) _pino(canvas, portaDa(destino!));
    canvas.restore();
  }

  // ── Fundo "lúdico": gramado, árvores e praça de entrada ──
  void _fundo(Canvas c) {
    c.drawRect(const Rect.fromLTWH(0, 0, 700, 1000),
        Paint()..color = ac ? Colors.black : const Color(0xFFCFE6B4));
    if (ac) return;
    final copa = Paint()..color = const Color(0xFF7CB860);
    final copaEscura = Paint()..color = const Color(0xFF5E9A48);
    for (var y = 70.0; y < 900; y += 85) {
      for (final x in [14.0, 686.0]) {
        c.drawCircle(Offset(x, y + 4), 13, copaEscura);
        c.drawCircle(Offset(x, y), 12, copa);
      }
    }
    if (andar == 0) {
      // Praça da entrada com canteiros
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(200, 925, 300, 80), const Radius.circular(30)),
          Paint()..color = const Color(0xFFEADBB8));
      for (final x in [120.0, 580.0]) {
        c.drawCircle(Offset(x, 965), 22, copaEscura);
        c.drawCircle(Offset(x, 960), 20, copa);
      }
    }
  }

  void _predio(Canvas c) {
    final rr = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 40, 640, 890), const Radius.circular(30));
    if (!ac) {
      c.drawRRect(rr.shift(const Offset(0, 10)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    }
    c.drawRRect(rr, Paint()..color = ac ? const Color(0xFF111111) : const Color(0xFFFFF4DA));
    c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = ac ? Colors.white : const Color(0xFFB88A3A));

    // Corredor central
    final corredor = RRect.fromRectAndRadius(const Rect.fromLTWH(305, 55, 90, 860), const Radius.circular(22));
    c.drawRRect(corredor, Paint()..color = ac ? const Color(0xFF2B2B2B) : const Color(0xFFF1E1BA));
    if (!ac) {
      final piso = Paint()
        ..color = const Color(0xFFE6D2A0)
        ..strokeWidth = 2;
      for (var y = 90.0; y < 910; y += 45) {
        c.drawLine(Offset(315, y), Offset(385, y), piso);
      }
    }

    // Porta da entrada principal
    if (andar == 0) {
      c.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(310, 918, 80, 24), const Radius.circular(8)),
          Paint()..color = ac ? Colors.white : Cores.dourado);
    }
  }

  void _zona(Canvas c, Zona z) {
    final ehDestino = destino?.id == z.id;
    final ehElevadorDaRota = z.icone == 'elevator' && _temRota && (destino?.andar ?? 0) != 0;
    final apagada = destino != null && !ehDestino && !ehElevadorDaRota;
    final rr = RRect.fromRectAndRadius(z.rect.deflate(5), const Radius.circular(18));

    Color base = Color(z.cor);
    if (ac) {
      base = ehDestino ? Cores.amareloAC : (ehElevadorDaRota ? Colors.white : const Color(0xFF333333));
    } else if (apagada) {
      base = Color.lerp(base, const Color(0xFFEDE6D6), 0.62)!;
    }

    if (!apagada && !ac) {
      c.drawRRect(rr.shift(const Offset(0, 5)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    c.drawRRect(rr, Paint()..color = base);
    c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ac ? 2 : 3
          ..color = ac ? Colors.white54 : Colors.white.withValues(alpha: 0.7));

    if (ehDestino) {
      final p = pulso.value;
      final corBrilho = ac ? Colors.white : Cores.laranjaRota;
      c.drawRRect(
          rr.inflate(3 + p * 16),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..color = corBrilho.withValues(alpha: (1 - p) * 0.8));
      c.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..color = corBrilho);
    }

    final icone = iconeDe(z.icone);
    final corIcone = ac
        ? (ehDestino ? Colors.black : (ehElevadorDaRota ? Colors.black : Colors.white70))
        : Color.lerp(Color(z.cor), Colors.black, 0.35)!.withValues(alpha: apagada ? 0.45 : 1);
    final circulo = ac
        ? (ehDestino || ehElevadorDaRota ? Colors.white : Colors.black)
        : Colors.white.withValues(alpha: apagada ? 0.6 : 0.95);

    if (z.icone == 'elevator') {
      // Elevador: ícone à esquerda, rótulo à direita (zona baixa)
      final centro = Offset(z.x + 50, z.y + z.h / 2);
      c.drawCircle(centro, 26, Paint()..color = circulo);
      _icone(c, icone, centro, 32, corIcone);
      if (ehElevadorDaRota || destino == null) {
        _texto(c, 'Elevador', Offset(z.x + 155, z.y + z.h / 2),
            tamanho: 28, cor: ac ? Colors.black : Colors.white, peso: FontWeight.w800, larguraMax: 150);
      }
      return;
    }

    if (ehDestino) {
      final centro = z.rect.center - Offset(0, z.h > 140 ? 34 : 24);
      c.drawCircle(centro, z.h > 140 ? 36 : 28, Paint()..color = circulo);
      _icone(c, icone, centro, z.h > 140 ? 44 : 34, corIcone);
      _texto(c, z.nome, z.rect.center + Offset(0, z.h > 140 ? 42 : 34),
          tamanho: 28,
          cor: ac ? Cores.amareloAC : Colors.white,
          peso: FontWeight.w900,
          larguraMax: z.w - 30,
          fundo: ac ? Colors.black : const Color(0xE6202020));
    } else {
      final centro = z.rect.center;
      c.drawCircle(centro, 26, Paint()..color = circulo);
      _icone(c, icone, centro, 32, corIcone);
    }
  }

  void _rota(Canvas c) {
    final pts = caminho!;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    Paint linha(Color cor, double largura) => Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    c.drawPath(path, linha(ac ? Colors.black : Colors.white, 26));
    c.drawPath(path, linha(_corRota.withValues(alpha: 0.25), 16));

    const traco = 26.0, ciclo = 46.0;
    final tracoPaint = linha(_corRota, 13);
    for (final metrica in path.computeMetrics()) {
      var inicio = -ciclo + tracejado.value * ciclo;
      while (inicio < metrica.length) {
        final s = max(0.0, inicio);
        final e = min(metrica.length, inicio + traco);
        if (e > s) c.drawPath(metrica.extractPath(s, e), tracoPaint);
        inicio += ciclo;
      }
      // "Caminhante" percorrendo a rota
      final tg = metrica.getTangentForOffset(metrica.length * Curves.easeInOut.transform(caminhada.value));
      if (tg != null) {
        c.drawCircle(tg.position, 24, Paint()..color = _corRota.withValues(alpha: 0.28));
        c.drawCircle(tg.position, 15, Paint()..color = Colors.white);
        c.drawCircle(tg.position, 10, Paint()..color = _corRota);
      }
    }
  }

  void _voceEstaAqui(Canvas c) {
    const pos = pontoTotem;
    final p = pulso.value;
    final cor = ac ? Colors.white : _azul;
    c.drawCircle(pos, 20 + p * 40, Paint()..color = cor.withValues(alpha: (1 - p) * 0.5));
    c.drawCircle(pos, 22, Paint()..color = ac ? Colors.black : Colors.white);
    c.drawCircle(pos, 15, Paint()..color = cor);
    _texto(c, 'VOCÊ ESTÁ AQUI', const Offset(350, 968),
        tamanho: 26,
        cor: ac ? Colors.black : Colors.white,
        peso: FontWeight.w900,
        larguraMax: 400,
        fundo: cor);
  }

  void _saidaElevador(Canvas c, Offset pos) {
    final cor = ac ? Colors.white : _azul;
    c.drawCircle(pos, 22, Paint()..color = ac ? Colors.black : Colors.white);
    c.drawCircle(pos, 17, Paint()..color = cor);
    _icone(c, Icons.elevator, pos, 22, ac ? Colors.black : Colors.white);
  }

  void _pino(Canvas c, Offset ponta) {
    final sobe = sin(pulso.value * 2 * pi) * 6;
    final cor = ac ? Cores.amareloAC : const Color(0xFFD32F2F);
    c.drawOval(Rect.fromCenter(center: ponta, width: 30, height: 10),
        Paint()..color = Colors.black.withValues(alpha: 0.25));
    final topo = ponta.translate(0, -58 + sobe);
    final path = Path()
      ..moveTo(ponta.dx, ponta.dy + sobe * 0.2)
      ..quadraticBezierTo(topo.dx - 30, topo.dy + 22, topo.dx - 28, topo.dy)
      ..arcToPoint(Offset(topo.dx + 28, topo.dy), radius: const Radius.circular(28))
      ..quadraticBezierTo(topo.dx + 30, topo.dy + 22, ponta.dx, ponta.dy + sobe * 0.2)
      ..close();
    c.drawPath(path, Paint()..color = cor);
    c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = ac ? Colors.black : Colors.white);
    _icone(c, Icons.flag_rounded, topo, 28, ac ? Colors.black : Colors.white);
  }

  void _icone(Canvas c, IconData i, Offset centro, double tamanho, Color cor) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(i.codePoint),
        style: TextStyle(fontSize: tamanho, fontFamily: i.fontFamily, package: i.fontPackage, color: cor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centro - Offset(tp.width / 2, tp.height / 2));
  }

  void _texto(Canvas c, String t, Offset centro,
      {double tamanho = 24,
      Color cor = Colors.white,
      FontWeight peso = FontWeight.w700,
      double larguraMax = 300,
      Color? fundo}) {
    final tp = TextPainter(
      text: TextSpan(
          text: t, style: TextStyle(fontSize: tamanho, color: cor, fontWeight: peso, height: 1.1)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: larguraMax);
    if (fundo != null) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: centro, width: tp.width + 28, height: tp.height + 14),
              const Radius.circular(14)),
          Paint()..color = fundo);
    }
    tp.paint(c, centro - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MapaPainter old) => true;
}
