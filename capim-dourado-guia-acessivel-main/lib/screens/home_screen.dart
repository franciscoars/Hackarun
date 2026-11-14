import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/halloween.dart';
import 'caa_screen.dart';
import 'mapa_screen.dart';
import 'relatorio_screen.dart';
import 'rotas_screen.dart';
import 'sos_screen.dart';
import 'voz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).anunciar(
          'Menu principal. Opções: Rotas, Guia por voz, Alto contraste, Ajuda, Comunicação por imagens, Voz e Mapa.');
    });
  }

  void _abrir(Widget tela) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = Paleta.of(context);
    final topo = MediaQuery.of(context).padding.top;
    final base = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: p.fundo,
      body: Column(
        children: [
          // Cabeçalho com logo e localização
          Container(
            decoration: BoxDecoration(
              color: p.cabecalho,
              border: p.ac ? Border(bottom: BorderSide(color: Cores.amareloAC, width: 2)) : null,
              borderRadius: p.ac ? null : const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, topo + 6, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Logo oficial (recorte do "O" com os laços)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.ac ? Cores.amareloAC : Cores.cremeLogo, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        fit: BoxFit.cover,
                        scale: 0.55,
                        alignment: Alignment(0, -0.25),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Olá! Como posso ajudar?',
                          style: TextStyle(
                              color: p.cabecalhoTexto, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  if (s.halloween) const Abobora(tamanho: 34),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: p.ac ? 0 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: p.ac ? Border.all(color: Colors.white54) : null,
                  ),
                  child: Row(children: [
                    Icon(Icons.my_location, size: 20, color: p.ac ? Cores.amareloAC : Cores.douradoClaro),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Você está: ${s.localAtual}',
                          style: TextStyle(color: p.cabecalhoTexto, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 16 + base),
              children: [
                _CartaoRotas(onTap: () => _abrir(const RotasScreen())),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.08,
                  children: [
                    BotaoAcao(
                      icone: s.guiaVoz ? Icons.record_voice_over : Icons.voice_over_off,
                      titulo: 'Guia por Voz',
                      subtitulo: s.guiaVoz ? 'Ligado' : 'Desligado',
                      cor: const Color(0xFF1E88E5),
                      ligado: s.guiaVoz,
                      onTap: s.alternarGuiaVoz,
                    ),
                    BotaoAcao(
                      icone: Icons.contrast,
                      titulo: 'Alto Contraste',
                      subtitulo: s.halloween
                          ? 'Modo Halloween'
                          : (s.altoContraste ? 'Ligado · 2 toques: Halloween' : 'Desligado · 2 toques: Halloween'),
                      cor: const Color(0xFF263238),
                      ligado: s.altoContraste,
                      selo: s.halloween ? const Abobora(tamanho: 22) : null,
                      onTap: s.tocarContraste,
                    ),
                    BotaoAcao(
                      icone: Icons.sos,
                      titulo: 'Ajuda / SOS',
                      subtitulo: 'Chamar atendente',
                      cor: const Color(0xFFD32F2F),
                      onTap: () => _abrir(const SosScreen()),
                    ),
                    BotaoAcao(
                      icone: Icons.grid_view_rounded,
                      titulo: 'Comunicação por Imagens',
                      subtitulo: 'CAA',
                      cor: const Color(0xFF8E24AA),
                      onTap: () => _abrir(const CaaScreen()),
                    ),
                    BotaoAcao(
                      icone: Icons.campaign,
                      titulo: 'Voz',
                      subtitulo: 'Escreva e eu falo',
                      cor: const Color(0xFF00897B),
                      onTap: () => _abrir(const VozScreen()),
                    ),
                    BotaoAcao(
                      icone: Icons.map_rounded,
                      titulo: 'Mapa',
                      subtitulo: 'Térreo e Piso 1',
                      cor: Cores.verdeMedio,
                      onTap: () => _abrir(const MapaScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _abrir(const RelatorioScreen()),
                    icon: Icon(Icons.insights_rounded, color: p.textoSuave),
                    label: Text('Painel da gestão do shopping',
                        style: TextStyle(color: p.textoSuave, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoRotas extends StatelessWidget {
  const _CartaoRotas({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Semantics(
      button: true,
      label: 'Rotas. Escolha um destino e eu te guio passo a passo.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: p.borda,
              color: p.ac ? Colors.black : null,
              gradient: p.ac
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFE0A526), Color(0xFFE2711D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: p.ac
                  ? null
                  : const [BoxShadow(color: Color(0x55E2711D), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: p.ac ? Cores.amareloAC : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.directions_walk_rounded,
                      size: 38, color: p.ac ? Colors.black : Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rotas',
                          style: TextStyle(
                              color: p.ac ? Cores.amareloAC : Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                      Text('Escolha um destino e eu te guio passo a passo',
                          style: TextStyle(
                              color: p.ac ? Colors.white : Colors.white.withValues(alpha: 0.95),
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: p.ac ? Cores.amareloAC : Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BotaoAcao extends StatelessWidget {
  const BotaoAcao({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.onTap,
    this.ligado,
    this.selo,
  });

  /// Enfeite opcional ao lado do ON/OFF (ex.: abóbora no modo Halloween).
  final Widget? selo;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final Color cor;
  final VoidCallback onTap;

  /// null = botão normal; true/false = interruptor.
  final bool? ligado;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    final corIcone = p.ac ? Cores.amareloAC : cor;
    return Semantics(
      button: true,
      toggled: ligado,
      label: '$titulo. $subtitulo',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.cartao,
              borderRadius: BorderRadius.circular(22),
              border: p.borda,
              boxShadow: p.sombra,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: p.ac ? Colors.black : cor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: p.ac ? Border.all(color: Cores.amareloAC) : null,
                      ),
                      child: Icon(icone, color: corIcone, size: 28),
                    ),
                    if (selo != null) ...[const Spacer(), selo!, const SizedBox(width: 4)],
                    if (ligado != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ligado!
                              ? (p.ac ? Cores.amareloAC : const Color(0xFF2E7D32))
                              : (p.ac ? Colors.black : const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(10),
                          border: p.ac ? Border.all(color: Cores.amareloAC) : null,
                        ),
                        child: Text(ligado! ? 'ON' : 'OFF',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ligado!
                                    ? (p.ac ? Colors.black : Colors.white)
                                    : (p.ac ? Colors.white : Colors.black54))),
                      ),
                  ],
                ),
                const Spacer(),
                Text(titulo,
                    maxLines: 2,
                    style: TextStyle(
                        color: p.texto, fontSize: 16, fontWeight: FontWeight.w800, height: 1.15)),
                const SizedBox(height: 2),
                Text(subtitulo, maxLines: 2, style: TextStyle(color: p.textoSuave, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
