import 'package:flutter/material.dart';

import '../theme.dart';

/// Cabeçalho escuro usado em todas as telas internas (fica atrás da barra de status).
class Cabecalho extends StatelessWidget {
  const Cabecalho({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.voltar = true,
    this.acoes = const [],
  });

  final String titulo;
  final String? subtitulo;
  final bool voltar;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    final topo = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: p.cabecalho,
        border: p.ac ? const Border(bottom: BorderSide(color: Cores.amareloAC, width: 2)) : null,
      ),
      padding: EdgeInsets.fromLTRB(voltar ? 4 : 20, topo + 4, 12, 14),
      child: Row(
        children: [
          if (voltar)
            IconButton(
              tooltip: 'Voltar',
              iconSize: 28,
              color: p.cabecalhoTexto,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          color: p.cabecalhoTexto, fontSize: 22, fontWeight: FontWeight.w800)),
                  if (subtitulo != null)
                    Text(subtitulo!,
                        style: TextStyle(
                            color: p.cabecalhoTexto.withValues(alpha: 0.8), fontSize: 14)),
                ],
              ),
            ),
          ),
          ...acoes,
        ],
      ),
    );
  }
}

/// Logo de reserva caso `assets/images/logo.png` ainda não exista.
class LogoCapim extends StatelessWidget {
  const LogoCapim({super.key, this.tamanho = 1});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120 * tamanho,
          height: 120 * tamanho,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Cores.douradoClaro, Cores.dourado],
            ),
            boxShadow: [BoxShadow(color: Color(0x55C8961E), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Icon(Icons.grass, size: 72 * tamanho, color: Colors.white),
        ),
        SizedBox(height: 16 * tamanho),
        Text('Capim Dourado',
            style: TextStyle(
                fontSize: 34 * tamanho, fontWeight: FontWeight.w800, color: Cores.verde)),
        Text('S H O P P I N G',
            style: TextStyle(
                fontSize: 14 * tamanho,
                fontWeight: FontWeight.w700,
                color: Cores.dourado,
                letterSpacing: 4)),
      ],
    );
  }
}

/// Logo oficial: coloque o arquivo em assets/images/logo.png.
class LogoOficial extends StatelessWidget {
  const LogoOficial({super.key, this.largura = 260});

  final double largura;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: largura,
      semanticLabel: 'Logo do Capim Dourado Shopping',
      errorBuilder: (_, _, _) => LogoCapim(tamanho: largura / 260),
    );
  }
}
