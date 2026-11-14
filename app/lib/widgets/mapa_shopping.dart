import 'dart:math';

import 'package:flutter/material.dart';

import '../data/geometria.dart';
import '../data/icones.dart';
import '../data/models.dart';
import '../logic/rota.dart';
import '../theme.dart';
import 'halloween.dart';

/// Mapa ilustrado de um pavimento do shopping circular, com rota animada.
/// Com [calor], pinta cada zona pela quantidade de buscas (mapa de calor).
class MapaShopping extends StatefulWidget {
  const MapaShopping({
    super.key,
    required this.zonas,
    required this.andar,
    required this.altoContraste,
    this.destino,
    this.caminho,
    this.onTapZona,
    this.calor,
    this.halloween = false,
  });

  final bool halloween;
  final List<Zona> zonas;
  final int andar;
  final bool altoContraste;
  final Zona? destino;
  final List<Offset>? caminho;
  final ValueChanged<Zona>? onTapZona;
  final Map<String, int>? calor;

  @override
  State<MapaShopping> createState() => _MapaShoppingState();
}

class _MapaShoppingState extends State<MapaShopping> with TickerProviderStateMixin {
  late final AnimationController _tracejado =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final AnimationController _pulso =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  late final AnimationController _caminhada =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5200))..repeat();
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
                        if (z.contem(pt)) {
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
                    calor: widget.calor,
                    ac: widget.altoContraste,
                    halloween: widget.halloween,
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

/// Escala sequencial de uma só matiz (claro → escuro) para o mapa de calor.
Color corCalor(double t, {bool escuro = false}) {
  if (escuro) return Color.lerp(const Color(0xFF3A2410), const Color(0xFFFFB04A), t)!;
  return Color.lerp(const Color(0xFFFCE8C8), const Color(0xFFB34700), t)!;
}

class _MapaPainter extends CustomPainter {
  _MapaPainter({
    required this.zonas,
    required this.andar,
    required this.destino,
    required this.caminho,
    required this.calor,
    required this.ac,
    required this.halloween,
    required this.tracejado,
    required this.pulso,
    required this.caminhada,
  }) : super(repaint: Listenable.merge([tracejado, pulso, caminhada]));

  final List<Zona> zonas;
  final int andar;
  final Zona? destino;
  final List<Offset>? caminho;
  final Map<String, int>? calor;
  final bool ac;
  final bool halloween;
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
    if (andar == 0 && calor == null) {
      _voceEstaAqui(canvas);
    } else if (_temRota) {
      _saidaElevador(canvas, caminho!.first);
    }
    if (destino != null && destino!.andar == andar) {
      _pino(canvas, portaDa(destino!));
      _rotuloDestino(canvas, destino!);
    }
    _rosaDosVentos(canvas, const Offset(68, 918));
    canvas.restore();
  }

  // ── Gramado, árvores (ou abóboras no modo Halloween) e praça de entrada ──
  void _fundo(Canvas c) {
    c.drawRect(const Rect.fromLTWH(0, 0, 700, 1000),
        Paint()..color = halloween ? const Color(0xFF0B0712) : (ac ? Colors.black : const Color(0xFFCFE6B4)));
    final copa = Paint()..color = const Color(0xFF7CB860);
    final copaEscura = Paint()..color = const Color(0xFF5E9A48);
    for (var g = 0.0; g < 360; g += 22.5) {
      if (g > 60 && g < 120) continue; // praça de entrada
      final p = Geo.ponto(1.56, g);
      if (p.dx < 20 || p.dx > 680 || p.dy < 18 || p.dy > 985) continue;
      if ((p - const Offset(68, 918)).distance < 70) continue; // rosa dos ventos
      if (halloween) {
        desenharAbobora(c, p, 26, rosto: g % 45 == 0);
      } else if (!ac) {
        c.drawCircle(p.translate(0, 4), 14, copaEscura);
        c.drawCircle(p, 13, copa);
      }
    }
    if (andar == 0) {
      final praca = Path()
        ..addOval(Rect.fromCenter(center: Geo.ponto(1.5, 90), width: 260, height: 90));
      c.drawPath(praca,
          Paint()..color = halloween ? const Color(0xFF1C1424) : (ac ? const Color(0xFF1A1A1A) : const Color(0xFFEADBB8)));
      if (halloween) {
        desenharAbobora(c, Geo.ponto(1.5, 90).translate(-150, 6), 34);
        desenharAbobora(c, Geo.ponto(1.5, 90).translate(150, 6), 34);
      }
    }
  }

  void _predio(Canvas c) {
    final parede = Geo.elipse(Geo.kParede);
    if (!ac) {
      c.drawOval(parede.shift(const Offset(0, 10)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    }
    c.drawOval(parede, Paint()..color = ac ? const Color(0xFF141414) : const Color(0xFFFFF4DA));
    c.drawOval(
        parede,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = ac ? Colors.white : const Color(0xFFB88A3A));

    // Hall de entrada (sul) no Térreo
    if (andar == 0) {
      c.drawPath(Geo.setor(Geo.kFachada, Geo.kParede, 75, 105),
          Paint()..color = ac ? const Color(0xFF2B2B2B) : const Color(0xFFF1E1BA));
      final porta = Geo.ponto(Geo.kParede, 90);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: porta, width: 90, height: 18), const Radius.circular(8)),
          Paint()..color = ac ? Cores.amareloAC : Cores.dourado);
    }

    // Corredor circular
    final corPiso = ac ? const Color(0xFF2B2B2B) : const Color(0xFFF1E1BA);
    c.drawOval(Geo.elipse(Geo.kFachada), Paint()..color = corPiso);
    if (!ac) {
      final junta = Paint()
        ..color = const Color(0xFFE6D2A0)
        ..strokeWidth = 2;
      for (var g = 0.0; g < 360; g += 12) {
        c.drawLine(Geo.ponto(Geo.kAtrio + 0.02, g), Geo.ponto(Geo.kFachada - 0.02, g), junta);
      }
    }

    // Átrio central: jardim
    c.drawOval(Geo.elipse(Geo.kAtrio),
        Paint()..color = halloween ? const Color(0xFF120B1C) : (ac ? const Color(0xFF0A0A0A) : const Color(0xFFDDEFC8)));
    if (!ac) {
      final folha = Paint()..color = const Color(0xFFB9DC9C);
      for (var g = 20.0; g < 360; g += 40) {
        c.drawCircle(Geo.ponto(0.5, g), 16, folha);
      }
    }

    // Passarelas até o elevador panorâmico
    for (final g in Geo.passarelas) {
      final a = Geo.ponto(Geo.kElevador * 0.6, g);
      final b = Geo.ponto(Geo.kAtrio + 0.02, g);
      c.drawLine(a, b, Paint()
        ..color = corPiso
        ..strokeWidth = 44
        ..strokeCap = StrokeCap.butt);
    }
  }

  void _zona(Canvas c, Zona z) {
    final ehDestino = destino?.id == z.id;
    final ehElevadorDaRota = z.icone == 'elevator' && _temRota && (destino?.andar ?? 0) != 0;
    final apagada = calor == null && destino != null && !ehDestino && !ehElevadorDaRota;

    Color base = Color(z.cor);
    if (calor != null) {
      final maximo = max(1, calor!.values.fold(0, max));
      final n = calor![z.id] ?? 0;
      base = z.destino ? corCalor(n / maximo, escuro: ac) : (ac ? const Color(0xFF222222) : const Color(0xFFEDE6D6));
    } else if (ac) {
      base = ehDestino ? Cores.amareloAC : (ehElevadorDaRota ? Colors.white : const Color(0xFF333333));
    } else if (apagada) {
      base = Color.lerp(base, const Color(0xFFEDE6D6), 0.62)!;
    }

    final forma = z.ehSetor
        ? Geo.setor(Geo.kFachada + 0.02, Geo.kFundo, z.ang0! + 1, z.ang1! - 1)
        : (Path()..addOval(Rect.fromCircle(center: z.rect.center, radius: z.w / 2)));

    if (!apagada && !ac) {
      c.drawPath(forma.shift(const Offset(0, 4)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
    c.drawPath(forma, Paint()..color = base);
    c.drawPath(
        forma,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ac ? 2 : 3
          ..strokeJoin = StrokeJoin.round
          ..color = ac ? Colors.white54 : Colors.white.withValues(alpha: 0.75));

    if (ehDestino) {
      final p = pulso.value;
      final brilho = ac ? Colors.white : Cores.laranjaRota;
      c.drawPath(
          forma,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7 + p * 14
            ..strokeJoin = StrokeJoin.round
            ..color = brilho.withValues(alpha: (1 - p) * 0.6));
      c.drawPath(
          forma,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeJoin = StrokeJoin.round
            ..color = brilho);
    }

    final centro = z.centroRotulo;
    final corIcone = ac
        ? (ehDestino || ehElevadorDaRota ? Colors.black : Colors.white70)
        : Color.lerp(Color(z.cor), Colors.black, 0.35)!.withValues(alpha: apagada ? 0.45 : 1);
    final circulo = ac
        ? (ehDestino || ehElevadorDaRota ? Colors.white : Colors.black)
        : Colors.white.withValues(alpha: apagada ? 0.6 : 0.95);
    final raio = ehDestino ? 32.0 : 25.0;
    c.drawCircle(centro, raio, Paint()..color = circulo);
    _icone(c, iconeDe(z.icone), centro, raio * 1.25, corIcone);

    if (calor != null && z.destino) {
      _texto(c, '${calor![z.id] ?? 0}', centro + const Offset(0, 40),
          tamanho: 24, cor: ac ? Colors.white : const Color(0xFF3B1E00), peso: FontWeight.w900, larguraMax: 120);
    }
    if (z.icone == 'elevator' && (ehElevadorDaRota || destino == null) && calor == null) {
      _texto(c, 'Elevador', centro + const Offset(0, 58),
          tamanho: 22,
          cor: ac ? Colors.black : Colors.white,
          peso: FontWeight.w800,
          larguraMax: 160,
          fundo: ac ? Cores.amareloAC : const Color(0xFF546E7A));
    }
  }

  /// Nome do destino num balão fora do prédio, ligado à zona por uma linha.
  void _rotuloDestino(Canvas c, Zona z) {
    if (!z.ehSetor) return;
    final tp = _layout(z.nome, 28, FontWeight.w900, ac ? Cores.amareloAC : Colors.white, 260);
    final larg = tp.width + 30, alt = tp.height + 16;
    var pos = Geo.ponto(1.66, z.angMeio);
    pos = Offset(pos.dx.clamp(larg / 2 + 8, 700 - larg / 2 - 8), pos.dy.clamp(alt / 2 + 6, 994 - alt / 2));
    c.drawLine(z.centroRotulo, pos, Paint()
      ..color = ac ? Cores.amareloAC : const Color(0xE6202020)
      ..strokeWidth = 3);
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: larg, height: alt), const Radius.circular(14));
    c.drawRRect(r, Paint()..color = ac ? Colors.black : const Color(0xF0202020));
    if (ac) {
      c.drawRRect(r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Cores.amareloAC);
    }
    tp.paint(c, pos - Offset(tp.width / 2, tp.height / 2));
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
      // Visitante andando pela rota, com seta apontando a frente
      final tg = metrica.getTangentForOffset(metrica.length * Curves.easeInOut.transform(caminhada.value));
      if (tg != null) {
        c.drawCircle(tg.position, 26, Paint()..color = _corRota.withValues(alpha: 0.28));
        c.drawCircle(tg.position, 17, Paint()..color = Colors.white);
        c.save();
        c.translate(tg.position.dx, tg.position.dy);
        c.rotate(-tg.angle);
        final seta = Path()
          ..moveTo(12, 0)
          ..lineTo(-8, -9)
          ..lineTo(-3, 0)
          ..lineTo(-8, 9)
          ..close();
        c.drawPath(seta, Paint()..color = _corRota);
        c.restore();
      }
    }
  }

  void _voceEstaAqui(Canvas c) {
    final pos = pontoTotem;
    final p = pulso.value;
    final cor = ac ? Colors.white : _azul;
    c.drawCircle(pos, 20 + p * 40, Paint()..color = cor.withValues(alpha: (1 - p) * 0.5));
    c.drawCircle(pos, 22, Paint()..color = ac ? Colors.black : Colors.white);
    c.drawCircle(pos, 15, Paint()..color = cor);
    _texto(c, 'VOCÊ ESTÁ AQUI', Geo.ponto(1.5, 90).translate(0, 14),
        tamanho: 26, cor: ac ? Colors.black : Colors.white, peso: FontWeight.w900, larguraMax: 400, fundo: cor);
  }

  void _saidaElevador(Canvas c, Offset pos) {
    final cor = ac ? Colors.white : _azul;
    c.drawCircle(pos, 20, Paint()..color = ac ? Colors.black : Colors.white);
    c.drawCircle(pos, 15, Paint()..color = cor);
  }

  void _pino(Canvas c, Offset ponta) {
    final sobe = sin(pulso.value * 2 * pi) * 6;
    final cor = ac ? Cores.amareloAC : const Color(0xFFD32F2F);
    c.drawOval(Rect.fromCenter(center: ponta, width: 30, height: 10), Paint()..color = Colors.black.withValues(alpha: 0.25));
    final topo = ponta.translate(0, -58 + sobe);
    final path = Path()
      ..moveTo(ponta.dx, ponta.dy + sobe * 0.2)
      ..quadraticBezierTo(topo.dx - 30, topo.dy + 22, topo.dx - 28, topo.dy)
      ..arcToPoint(Offset(topo.dx + 28, topo.dy), radius: const Radius.circular(28))
      ..quadraticBezierTo(topo.dx + 30, topo.dy + 22, ponta.dx, ponta.dy + sobe * 0.2)
      ..close();
    c.drawPath(path, Paint()..color = cor);
    c.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = ac ? Colors.black : Colors.white);
    _icone(c, Icons.flag_rounded, topo, 28, ac ? Colors.black : Colors.white);
  }

  /// Rosa dos ventos fixa (Norte para cima do mapa).
  void _rosaDosVentos(Canvas c, Offset o) {
    final fundo = ac ? Colors.black : Colors.white.withValues(alpha: 0.92);
    final tinta = ac ? Colors.white : const Color(0xFF263238);
    final norte = ac ? Cores.amareloAC : const Color(0xFFD32F2F);
    c.drawCircle(o, 50, Paint()..color = fundo);
    c.drawCircle(o, 50, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = tinta.withValues(alpha: 0.6));
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2;
      final ponta = o + Offset(sin(a), -cos(a)) * 34;
      final l1 = o + Offset(sin(a + pi / 2), -cos(a + pi / 2)) * 7;
      final l2 = o + Offset(sin(a - pi / 2), -cos(a - pi / 2)) * 7;
      c.drawPath(Path()
        ..moveTo(ponta.dx, ponta.dy)
        ..lineTo(l1.dx, l1.dy)
        ..lineTo(l2.dx, l2.dy)
        ..close(), Paint()..color = i == 0 ? norte : tinta.withValues(alpha: 0.75));
    }
    const letras = ['N', 'L', 'S', 'O'];
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2;
      _texto(c, letras[i], o + Offset(sin(a), -cos(a)) * 43,
          tamanho: 15, cor: i == 0 ? norte : tinta, peso: FontWeight.w900, larguraMax: 30);
    }
  }

  TextPainter _layout(String t, double tamanho, FontWeight peso, Color cor, double larguraMax) => TextPainter(
        text: TextSpan(text: t, style: TextStyle(fontSize: tamanho, color: cor, fontWeight: peso, height: 1.1)),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 3,
      )..layout(maxWidth: larguraMax);

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
      {double tamanho = 24, Color cor = Colors.white, FontWeight peso = FontWeight.w700, double larguraMax = 300, Color? fundo}) {
    final tp = _layout(t, tamanho, peso, cor, larguraMax);
    if (fundo != null) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: centro, width: tp.width + 28, height: tp.height + 14), const Radius.circular(14)),
          Paint()..color = fundo);
    }
    tp.paint(c, centro - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MapaPainter old) => true;
}
