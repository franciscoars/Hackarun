import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// true = ícones escuros na barra de status (tela clara, ex.: Boas-vindas).
final statusBarEscura = ValueNotifier<bool>(false);

/// Emula um smartphone quando o app roda numa tela larga (PC / navegador).
/// Num celular de verdade (QR Code do totem) ou no emulador Android,
/// o app ocupa a tela inteira normalmente.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const tela = Size(393, 852); // iPhone 15 / Pixel 8 (pontos lógicos)
  static const bezel = 14.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 600) return child;

      final mq = MediaQuery.of(context);
      final larguraTotal = tela.width + bezel * 2;
      final alturaTotal = tela.height + bezel * 2;
      final escala = min(1.0, (c.maxHeight - 32) / alturaTotal);

      final telefone = SizedBox(
        width: larguraTotal,
        height: alturaTotal,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Botões laterais
            _botaoLateral(left: -4, top: 170, altura: 34),
            _botaoLateral(left: -4, top: 225, altura: 62),
            _botaoLateral(left: -4, top: 300, altura: 62),
            _botaoLateral(right: -4, top: 250, altura: 96),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0B),
                  borderRadius: BorderRadius.circular(62),
                  border: Border.all(color: const Color(0xFF3B3B3B), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x88000000), blurRadius: 40, offset: Offset(0, 20)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(bezel),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: MediaQuery(
                      data: mq.copyWith(
                        size: tela,
                        padding: const EdgeInsets.only(top: 54, bottom: 28),
                        viewPadding: const EdgeInsets.only(top: 54, bottom: 28),
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(child: child),
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Material(type: MaterialType.transparency, child: _BarraStatus()),
                            ),
                          ),
                          // Dynamic Island
                          Positioned(
                            top: 11,
                            left: (tela.width - 122) / 2,
                            child: IgnorePointer(
                              child: Container(
                                width: 122,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          // Indicador de "home"
                          Positioned(
                            bottom: 8,
                            left: (tela.width - 134) / 2,
                            child: IgnorePointer(
                              child: ValueListenableBuilder<bool>(
                                valueListenable: statusBarEscura,
                                builder: (_, escura, _) => Container(
                                  width: 134,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: escura ? Colors.black87 : Colors.black54,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF24533D), Color(0xFF0C1C14)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (c.maxWidth >= 1100) ...[
              const Material(type: MaterialType.transparency, child: _PainelLateral()),
              const SizedBox(width: 64),
            ],
            SizedBox(
              width: larguraTotal * escala,
              height: alturaTotal * escala,
              child: FittedBox(child: telefone),
            ),
          ],
        ),
      );
    });
  }

  Widget _botaoLateral({double? left, double? right, required double top, required double altura}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: 6,
        height: altura,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _BarraStatus extends StatefulWidget {
  const _BarraStatus();

  @override
  State<_BarraStatus> createState() => _BarraStatusState();
}

class _BarraStatusState extends State<_BarraStatus> {
  late Timer _timer;
  DateTime _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      setState(() => _agora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hora = '${_agora.hour.toString().padLeft(2, '0')}:${_agora.minute.toString().padLeft(2, '0')}';
    return ValueListenableBuilder<bool>(
      valueListenable: statusBarEscura,
      builder: (context, escura, _) {
        final cor = escura ? Colors.black : Colors.white;
        return SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Row(
              children: [
                Text(hora,
                    style: TextStyle(color: cor, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(Icons.signal_cellular_alt, size: 17, color: cor),
                const SizedBox(width: 5),
                Icon(Icons.wifi, size: 17, color: cor),
                const SizedBox(width: 5),
                RotatedBox(quarterTurns: 1, child: Icon(Icons.battery_full, size: 19, color: cor)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PainelLateral extends StatelessWidget {
  const _PainelLateral();

  @override
  Widget build(BuildContext context) {
    const branco = TextStyle(color: Colors.white70, fontSize: 15, height: 1.5);
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.qr_code_2, size: 96, color: Color(0xFFF2C14E)),
          const SizedBox(height: 16),
          const Text('Capim Dourado Shopping',
              style: TextStyle(color: Color(0xFFF2C14E), fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Guia Acessível · Web App do Totem',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const Text(
            'O visitante lê o QR Code no totem e o guia abre direto no celular: '
            'rotas passo a passo, guia por voz, alto contraste, comunicação por imagens e SOS.',
            style: branco,
          ),
          const SizedBox(height: 20),
          for (final linha in const [
            'Flutter · código único (totem + web mobile)',
            'Banco de dados local Sembast (IndexedDB)',
            'WCAG AAA · LBI 13.146/2015 · NBR 9050',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.check_circle, size: 18, color: Color(0xFFF2C14E)),
                const SizedBox(width: 8),
                Expanded(child: Text(linha, style: branco)),
              ]),
            ),
          const SizedBox(height: 24),
          const Text('Grupo 18 ENTEI · 1º Hackrun UniCatólica',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
