import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_state.dart';
import '../config.dart';
import '../screens/sos_screen.dart';
import '../screens/splash_screen.dart';
import '../theme.dart';

/// Emula o totem físico: tela touch vertical, QR Code, botões com relevo,
/// vão para cadeira de rodas e piso tátil. Reinicia após 90 s sem uso.
class TotemFrame extends StatefulWidget {
  const TotemFrame({super.key, required this.child});

  final Widget child;

  @override
  State<TotemFrame> createState() => _TotemFrameState();
}

class _TotemFrameState extends State<TotemFrame> {
  static const _app = Size(540, 810); // área do app na tela
  static const _rodape = 150.0; // faixa do QR Code
  static const _tempoOcioso = Duration(seconds: 90);

  Timer? _ocioso;

  @override
  void initState() {
    super.initState();
    _atividade();
  }

  @override
  void dispose() {
    _ocioso?.cancel();
    super.dispose();
  }

  void _atividade() {
    _ocioso?.cancel();
    _ocioso = Timer(_tempoOcioso, _reiniciar);
  }

  void _reiniciar() {
    AppScope.read(context).fala.parar();
    navegadorKey.currentState?.pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const SplashScreen(),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final totem = _totem(context);
        return Listener(
          onPointerDown: (_) => _atividade(),
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEDE3CB), Color(0xFFD9CBA8)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: max(200, c.maxHeight - 24),
                    child: FittedBox(child: totem),
                  ),
                  if (c.maxWidth >= 1150) ...[
                    const SizedBox(width: 56),
                    const _PainelInfo(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _totem(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SizedBox(
      width: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placa luminosa
          Container(
            width: 640,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(42),
                bottom: Radius.circular(8),
              ),
              gradient: LinearGradient(colors: [Cores.verdeMedio, Cores.verde]),
              boxShadow: [BoxShadow(color: Color(0x55F2C14E), blurRadius: 30)],
            ),
            child: const Text(
              '✦  GUIA ACESSÍVEL  ✦',
              style: TextStyle(
                color: Cores.douradoClaro,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Corpo com a tela
          Container(
            width: 640,
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F271C),
                  Cores.verde,
                  Cores.verdeMedio,
                  Cores.verde,
                  Color(0xFF0F271C),
                ],
                stops: [0, .12, .5, .88, 1],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: _app.width,
                      height: _app.height + _rodape,
                      child: Column(
                        children: [
                          SizedBox.fromSize(
                            size: _app,
                            child: MediaQuery(
                              data: mq.copyWith(
                                size: _app,
                                textScaler: const TextScaler.linear(1.15),
                                padding: const EdgeInsets.only(top: 10),
                                viewPadding: const EdgeInsets.only(top: 10),
                                viewInsets: EdgeInsets.zero,
                              ),
                              child: widget.child,
                            ),
                          ),
                          const _RodapeQr(altura: _rodape),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _painelFisico(context),
                const SizedBox(height: 12),
                const Text(
                  '⠛⠥⠊⠁ ⠁⠉⠑⠎⠎⠊⠧⠑⠇',
                  style: TextStyle(
                    color: Cores.douradoClaro,
                    fontSize: 22,
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
          // Pedestal com vão livre
          Container(
            width: 520,
            height: 230,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F271C),
                  Cores.verdeMedio,
                  Color(0xFF0F271C),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(36, 26, 36, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE4D8BA),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                border: Border.all(color: Colors.black26),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.accessible, size: 48, color: Color(0xFF9C8E6C)),
                  Text(
                    'vão livre 0,73 m',
                    style: TextStyle(color: Color(0xFF9C8E6C), fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 610,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 720,
            height: 40,
            child: CustomPaint(painter: _PisoTatilPainter()),
          ),
        ],
      ),
    );
  }

  Widget _painelFisico(BuildContext context) {
    final s = AppScope.of(context);
    return Row(
      children: [
        // Alto-falante
        Container(
          width: 120,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1E15), Color(0xFF24533D)],
              stops: [.5, .5],
              tileMode: TileMode.repeated,
              end: Alignment(-0.9, 0),
            ),
          ),
        ),
        const Spacer(),
        _BotaoFisico(
          icone: Icons.arrow_back_rounded,
          rotulo: 'Voltar',
          onTap: () => navegadorKey.currentState?.maybePop(),
        ),
        _BotaoFisico(
          icone: Icons.home_rounded,
          rotulo: 'Início',
          onTap: () => navegadorKey.currentState?.popUntil((r) => r.isFirst),
        ),
        _BotaoFisico(
          icone: s.guiaVoz ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          rotulo: 'Voz',
          ativo: s.guiaVoz,
          onTap: s.alternarGuiaVoz,
        ),
        _BotaoFisico(
          icone: Icons.sos,
          rotulo: 'SOS',
          cor: const Color(0xFFD32F2F),
          onTap: () => navegadorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const SosScreen()),
          ),
        ),
        const Spacer(),
        // Entrada de fone
        Tooltip(
          message: 'Entrada de fone de ouvido',
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF666666), width: 4),
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}

class _BotaoFisico extends StatelessWidget {
  const _BotaoFisico({
    required this.icone,
    required this.rotulo,
    required this.onTap,
    this.cor = Cores.douradoClaro,
    this.ativo = false,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;
  final Color cor;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final escuro = cor == Cores.douradoClaro;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Semantics(
        button: true,
        label: 'Botão físico $rotulo',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: cor,
              shape: CircleBorder(
                side: BorderSide(
                  color: ativo ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    icone,
                    size: 28,
                    color: escuro ? Cores.verde : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RodapeQr extends StatelessWidget {
  const _RodapeQr({required this.altura});

  final double altura;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = Paleta.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: rotaAtual,
      builder: (context, destino, _) {
        final zona = destino == null
            ? null
            : s.zonas.where((z) => z.id == destino).firstOrNull;
        final url = zona == null
            ? '$urlPublica/'
            : '$urlPublica/?destino=${zona.id}';
        return Container(
          height: altura,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: p.ac ? Colors.black : Colors.white,
            border: Border(
              top: BorderSide(
                color: p.ac ? Cores.amareloAC : Cores.dourado,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                color: Colors.white,
                child: QrImageView(
                  data: url,
                  size: 108,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Cores.verde,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Cores.verde,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: p.ac ? Cores.amareloAC : Cores.dourado,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            zona == null
                                ? 'Leve o guia no seu celular'
                                : 'Leve esta rota no celular',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: p.texto,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zona == null
                          ? 'Aponte a câmera para o QR Code. Funciona com voz e alto contraste.'
                          : '${zona.nome} · ${zona.nomeAndar}. Continue o passo a passo no seu celular.',
                      style: TextStyle(
                        fontSize: 15,
                        color: p.textoSuave,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PainelInfo extends StatelessWidget {
  const _PainelInfo();

  @override
  Widget build(BuildContext context) {
    const corpo = TextStyle(
      color: Color(0xFF4A4436),
      fontSize: 15,
      height: 1.5,
    );
    Widget item(IconData i, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 20, color: Cores.dourado),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: corpo)),
        ],
      ),
    );
    return SizedBox(
      width: 330,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modo Totem',
            style: TextStyle(
              color: Cores.verde,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Emulação do totem do Capim Dourado Shopping',
            style: TextStyle(
              color: Cores.verdeMedio,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          item(
            Icons.touch_app,
            'Toque na tela como no totem real, ou use os botões físicos: Voltar, Início, Voz e SOS.',
          ),
          item(
            Icons.qr_code_2,
            'Escaneie o QR Code com o seu celular (no mesmo Wi-Fi deste PC). Depois de escolher uma rota, o QR leva a rota pronta.',
          ),
          item(
            Icons.timer_outlined,
            'Após 90 segundos sem uso, o totem volta para a tela inicial.',
          ),
          item(Icons.link, urlPublica),
        ],
      ),
    );
  }
}

class _PisoTatilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFFF7D24A));
    final ponto = Paint()..color = const Color(0xFFDDA800);
    for (var y = 8.0; y < size.height; y += 12) {
      for (var x = 8.0; x < size.width; x += 14) {
        canvas.drawCircle(Offset(x + ((y ~/ 12).isOdd ? 7 : 0), y), 3.2, ponto);
      }
    }
  }

  @override
  bool shouldRepaint(_PisoTatilPainter old) => false;
}
