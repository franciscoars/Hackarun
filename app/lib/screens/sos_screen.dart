import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/comuns.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  static const _tipos = [
    (Icons.explore_off, 'Estou perdido(a)'),
    (Icons.sign_language, 'Sou surdo(a) · preciso de Libras'),
    (Icons.visibility_off, 'Sou cego(a) · preciso de acompanhante'),
    (Icons.accessible, 'Preciso de cadeira de rodas'),
    (Icons.medical_services, 'Emergência médica'),
    (Icons.translate, 'Tourist · I need help'),
  ];

  int _tipo = 0;
  bool _enviando = false;
  int? _chamadoId;
  String _status = '';
  List<ChamadoSos> _historico = [];

  @override
  void initState() {
    super.initState();
    _carregar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).anunciar('Tela de ajuda. Escolha o motivo e toque em Chamar atendente.');
    });
  }

  Future<void> _carregar() async {
    final h = await AppScope.read(context).db.chamadosRecentes();
    if (mounted) setState(() => _historico = h);
  }

  Future<void> _chamar() async {
    final s = AppScope.read(context);
    setState(() => _enviando = true);
    final id = await s.db.registrarChamado(tipo: _tipos[_tipo].$2, local: s.localAtual);
    s.registrar('recurso', 'sos');
    setState(() {
      _enviando = false;
      _chamadoId = id;
      _status = 'Enviado';
    });
    await s.fala.falar('Chamado enviado. Um atendente está a caminho. Fique perto do totem.');
    await _carregar();

    // Simula a resposta da central de atendimento.
    await Future<void>.delayed(const Duration(seconds: 4));
    await s.db.atualizarStatus(id, 'Atendente a caminho');
    if (!mounted) return;
    setState(() => _status = 'Atendente a caminho');
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    const vermelho = Color(0xFFD32F2F);
    return Scaffold(
      backgroundColor: p.fundo,
      body: Column(
        children: [
          const Cabecalho(titulo: 'Ajuda / SOS', subtitulo: 'Um atendente vem até você'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              children: [
                Text('Qual é o motivo?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.texto)),
                const SizedBox(height: 10),
                for (var i = 0; i < _tipos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      selected: _tipo == i,
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _tipo = i),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _tipo == i
                                  ? (p.ac ? Cores.amareloAC : vermelho.withValues(alpha: 0.1))
                                  : p.cartao,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _tipo == i ? (p.ac ? Cores.amareloAC : vermelho) : (p.ac ? Colors.white38 : Colors.transparent),
                                width: 2,
                              ),
                            ),
                            child: Row(children: [
                              Icon(_tipos[i].$1,
                                  color: _tipo == i ? (p.ac ? Colors.black : vermelho) : p.textoSuave, size: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_tipos[i].$2,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _tipo == i && p.ac ? Colors.black : p.texto)),
                              ),
                              if (_tipo == i)
                                Icon(Icons.check_circle, color: p.ac ? Colors.black : vermelho),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 68,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.ac ? Cores.amareloAC : vermelho,
                      foregroundColor: p.ac ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _enviando ? null : _chamar,
                    icon: const Icon(Icons.sos, size: 32),
                    label: Text(_enviando ? 'Enviando...' : 'Chamar atendente',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ),
                if (_chamadoId != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: p.ac ? Colors.black : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.ac ? Cores.amareloAC : const Color(0xFF2E7D32), width: 2),
                      ),
                      child: Row(children: [
                        Icon(_status == 'Enviado' ? Icons.schedule_send : Icons.directions_run,
                            size: 40, color: p.ac ? Cores.amareloAC : const Color(0xFF2E7D32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Chamado #$_chamadoId · $_status',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: p.texto)),
                            const SizedBox(height: 4),
                            Text('Fique perto do Totem da Entrada Principal.',
                                style: TextStyle(fontSize: 15, color: p.texto)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ],
                if (_historico.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(children: [
                    Icon(Icons.storage_rounded, size: 18, color: p.textoSuave),
                    const SizedBox(width: 6),
                    Text('Chamados salvos no banco de dados',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textoSuave)),
                  ]),
                  const SizedBox(height: 8),
                  for (final c in _historico)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '#${c.id} · ${c.tipo} · ${c.criadoEm.hour.toString().padLeft(2, '0')}:${c.criadoEm.minute.toString().padLeft(2, '0')} · ${c.status}',
                        style: TextStyle(fontSize: 13, color: p.textoSuave),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
