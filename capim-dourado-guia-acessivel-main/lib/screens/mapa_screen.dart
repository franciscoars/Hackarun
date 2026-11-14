import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../data/geometria.dart';
import '../data/icones.dart';
import '../data/models.dart';
import '../logic/rota.dart';
import '../theme.dart';
import '../widgets/comuns.dart';
import '../widgets/hud_orientacao.dart';
import '../widgets/mapa_shopping.dart';

/// Mapa com rota passo a passo (quando há destino) ou modo exploração.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key, this.destino});

  final Zona? destino;

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  RotaCalculada? _rota;
  int _andar = 0;
  int _passo = 0;
  String? _aviso;

  /// Rumo exibido na bússola (acumulado para girar pelo caminho mais curto).
  double _rumo = 0;

  @override
  void initState() {
    super.initState();
    if (widget.destino != null) {
      _rota = calcularRota(widget.destino!);
      Future.microtask(() => rotaAtual.value = widget.destino!.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = AppScope.read(context);
      if (_rota != null) {
        s.registrar('rota', _rota!.destino.id);
        s.anunciar('Rota até ${_rota!.destino.nome}, ${_rota!.destino.nomeAndar}. '
            'Cerca de ${_rota!.metrosArredondados} metros. ${_textoFalado(_rota!.passos.first)}');
      } else {
        s.registrar('recurso', 'mapa');
        s.anunciar('Mapa do shopping. O Norte fica para cima. Toque em uma área para ver o nome.');
      }
    });
  }

  @override
  void dispose() {
    final id = widget.destino?.id;
    if (id != null) {
      Future.microtask(() {
        if (rotaAtual.value == id) rotaAtual.value = null;
      });
    }
    super.dispose();
  }

  /// Texto para a voz, com a referência de direção (HUD) incluída.
  String _textoFalado(PassoRota p) => switch (p.direcao) {
        Direcao.esquerda => 'À esquerda. ${p.texto}',
        Direcao.direita => 'À direita. ${p.texto}',
        Direcao.frente => 'Em frente. ${p.texto}',
        _ => p.texto,
      };

  void _irParaPasso(int i) {
    final rota = _rota!;
    final passo = rota.passos[i];
    final trocouAndar = passo.andar != _andar;
    setState(() {
      _passo = i;
      _andar = passo.andar;
      _rumo += Geo.delta(_rumo, passo.rumo);
    });
    AppScope.read(context).anunciar(_textoFalado(passo));
    if (trocouAndar) {
      setState(() => _aviso = 'Agora você está no ${passo.andar == 0 ? 'Térreo' : 'Piso ${passo.andar}'}');
      Future<void>.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _aviso = null);
      });
    }
  }

  void _tocouZona(Zona z) {
    final s = AppScope.read(context);
    final p = Paleta(s.altoContraste);
    s.anunciar(z.nome);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.cartao,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: p.ac ? Cores.amareloAC : Color(z.cor),
                child: Icon(iconeDe(z.icone), color: p.ac ? Colors.black : Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(z.nome, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.texto)),
                  Text(z.nomeAndar, style: TextStyle(fontSize: 15, color: p.textoSuave)),
                ]),
              ),
            ]),
            if (z.descricao.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(z.descricao, style: TextStyle(fontSize: 16, color: p.texto)),
            ],
            if (z.destino) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Traçar rota até aqui', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MapaScreen(destino: z)));
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = Paleta.of(context);
    final rota = _rota;

    return Scaffold(
      backgroundColor: p.fundo,
      body: Column(
        children: [
          Cabecalho(
            titulo: rota == null ? 'Mapa do Shopping' : rota.destino.nome,
            subtitulo: rota == null
                ? 'Toque em uma área para ver o nome'
                : '${rota.destino.nomeAndar} · ~${rota.metrosArredondados} m · ${rota.minutos} min a pé',
          ),
          if (rota != null && rota.usaElevador)
            Container(
              width: double.infinity,
              color: p.ac ? Colors.black : const Color(0xFFE3F2FD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Icon(Icons.accessible_forward, color: p.ac ? Cores.amareloAC : const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Rota acessível: usa o elevador panorâmico para o ${rota.destino.nomeAndar}',
                      style: TextStyle(color: p.ac ? Colors.white : const Color(0xFF0D47A1), fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final a in [0, 1])
                    ButtonSegment(
                      value: a,
                      label: Text(a == 0 ? 'Térreo' : 'Piso 1',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      icon: rota?.caminhos.containsKey(a) ?? false ? const Icon(Icons.route, size: 18) : null,
                    ),
                ],
                selected: {_andar},
                onSelectionChanged: (sel) => setState(() => _andar = sel.first),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: rota == null
                  ? 'Mapa ilustrado do ${_andar == 0 ? 'Térreo' : 'Piso 1'}, com o Norte para cima'
                  : 'Mapa com a rota até ${rota.destino.nome}',
              child: Stack(
                children: [
                  Positioned.fill(
                    top: rota != null ? 58 : 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: MapaShopping(
                        key: ValueKey(_andar),
                        zonas: s.zonas,
                        andar: _andar,
                        altoContraste: s.altoContraste,
                        halloween: s.halloween,
                        destino: rota?.destino,
                        caminho: rota?.caminhos[_andar],
                        onTapZona: rota == null ? _tocouZona : null,
                      ),
                    ),
                  ),
                  if (rota != null)
                    Positioned(
                      top: 6,
                      left: 8,
                      right: 8,
                      child: IgnorePointer(
                        child: HudOrientacao(
                          rumo: _rumo,
                          direcao: rota.passos[_passo].direcao,
                          altoContraste: s.altoContraste,
                        ),
                      ),
                    ),
                  Positioned(
                    top: rota != null ? 62 : 8,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _aviso == null ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: p.ac ? Cores.amareloAC : const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10)],
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.elevator, color: p.ac ? Colors.black : Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(_aviso ?? '',
                                  style: TextStyle(
                                      color: p.ac ? Colors.black : Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (rota != null) _cartaoPasso(context, rota, p),
          if (rota == null) SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _cartaoPasso(BuildContext context, RotaCalculada rota, Paleta p) {
    final passo = rota.passos[_passo];
    final ultimo = _passo == rota.passos.length - 1;
    final s = AppScope.read(context);
    return Container(
      decoration: BoxDecoration(
        color: p.cartao,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: p.ac ? Border(top: BorderSide(color: Cores.amareloAC, width: 2)) : null,
        boxShadow: p.ac ? null : const [BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_passo + 1) / rota.passos.length,
              minHeight: 6,
              color: p.rota,
              backgroundColor: p.rota.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: _textoFalado(passo),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: ultimo ? const Color(0xFF2E7D32) : p.rota,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(passo.icone, color: p.ac ? Colors.black : Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Passo ${_passo + 1} de ${rota.passos.length} · sentido ${passo.sentido}',
                          style: TextStyle(color: p.textoSuave, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(passo.texto,
                          style: TextStyle(color: p.texto, fontSize: 17, fontWeight: FontWeight.w700, height: 1.25)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _passo == 0 ? null : () => _irParaPasso(_passo - 1),
                  child: const Icon(Icons.chevron_left_rounded, size: 28),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => s.fala.falar(_textoFalado(passo)),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Ouvir'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ultimo ? const Color(0xFF2E7D32) : p.rota,
                      foregroundColor: p.ac ? Colors.black : Colors.white,
                    ),
                    onPressed: ultimo
                        ? () => Navigator.of(context).popUntil((r) => r.isFirst)
                        : () => _irParaPasso(_passo + 1),
                    icon: Icon(ultimo ? Icons.check_rounded : Icons.arrow_forward_rounded),
                    label: Text(ultimo ? 'Concluir' : 'Próximo',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
