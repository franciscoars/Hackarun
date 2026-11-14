import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/aranha_overlay.dart';
import '../widgets/comuns.dart';
import '../widgets/halloween.dart';
import '../widgets/phone_frame.dart';
import '../config.dart';
import 'home_screen.dart';
import 'mapa_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  bool _aranha = false;

  @override
  void initState() {
    super.initState();
    statusBarEscura.value = false;
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _comecar() {
    if (_aranha) return;
    setState(() => _aranha = true);
    AppScope.read(context).anunciar('Bem-vindo ao Capim Dourado Shopping.');
  }

  /// O link do QR Code (`?destino=`) só é usado na primeira abertura.
  static bool _linkUsado = false;

  void _irParaMenu() {
    statusBarEscura.value = false;
    final nav = Navigator.of(context);
    nav.pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => const HomeScreen(),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
    if (!modoTotem && !_linkUsado && destinoInicial != null) {
      _linkUsado = true;
      final zona = AppScope.read(context).zonas.where((z) => z.id == destinoInicial).firstOrNull;
      if (zona != null) nav.push(MaterialPageRoute(builder: (_) => MapaScreen(destino: zona)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final largura = MediaQuery.of(context).size.width.clamp(280.0, 460.0);
    return Scaffold(
      backgroundColor: Cores.verdeLogo,
      body: Semantics(
        button: true,
        label: 'Capim Dourado Shopping. Toque em qualquer lugar para começar.',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _comecar,
          child: Stack(
            children: [
              // Fundo no mesmo verde da logo oficial
              const Positioned.fill(child: ColoredBox(color: Cores.verdeLogo)),
              // Capim dourado balançando no rodapé
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 190,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) => CustomPaint(painter: _CapimPainter(_anim.value)),
                ),
              ),
              if (s.halloween) ...[
                const Positioned(left: 18, bottom: 26, child: Abobora(tamanho: 54)),
                const Positioned(right: 26, bottom: 40, child: Abobora(tamanho: 40)),
                const Positioned(left: 150, bottom: 14, child: Abobora(tamanho: 30, rosto: false)),
              ],
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo oficial, idêntica; as bordas se fundem ao fundo verde.
                      ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (r) => const RadialGradient(
                          radius: 0.7,
                          colors: [Colors.white, Colors.white, Colors.transparent],
                          stops: [0, 0.8, 1],
                        ).createShader(r),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: largura,
                          semanticLabel: 'Logo do Capim Dourado Shopping',
                          errorBuilder: (_, _, _) => LogoCapim(tamanho: largura / 300),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (_, child) => Opacity(
                          opacity: 0.55 + 0.45 * (0.5 + 0.5 * sin(_anim.value * 2 * pi * 2)),
                          child: child,
                        ),
                        child: AnimatedOpacity(
                          opacity: _aranha ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: const Column(
                            children: [
                              Icon(Icons.touch_app_rounded, size: 40, color: Cores.cremeLogo),
                              SizedBox(height: 8),
                              Text('Toque em qualquer lugar para começar',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Cores.cremeLogo)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 10,
                child: const Text('Guia acessível · Grupo 18 ENTEI',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xCCF6E3C8), fontSize: 12)),
              ),
              if (_aranha) Positioned.fill(child: AranhaOverlay(aoTerminar: _irParaMenu)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapimPainter extends CustomPainter {
  _CapimPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 46;
    for (var i = 0; i < n; i++) {
      final semente = sin(i * 12.9898) * 43758.5453;
      final r = semente - semente.floorToDouble();
      final x = (i + 0.5) / n * size.width + (r - 0.5) * 10;
      final altura = 70 + r * 110;
      final balanco = sin(t * 2 * pi + i * 0.6) * (6 + r * 6);
      final topo = Offset(x + balanco + (r - 0.5) * 30, size.height - altura);
      final ctrl = Offset(x + balanco * 0.3, size.height - altura * 0.5);

      final cor = Color.lerp(const Color(0xFFC8961E), const Color(0xFFE9C46A), r)!;
      final haste = Path()
        ..moveTo(x, size.height)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, topo.dx, topo.dy);
      canvas.drawPath(
        haste,
        Paint()
          ..color = cor.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      // "Flor" dourada na ponta, típica do capim dourado do Jalapão
      canvas.drawCircle(topo, 3.2 + r * 2.2, Paint()..color = const Color(0xFFDDA92A));
    }
  }

  @override
  bool shouldRepaint(_CapimPainter old) => old.t != t;
}
