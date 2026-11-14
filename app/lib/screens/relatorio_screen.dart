import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/comuns.dart';
import '../widgets/mapa_shopping.dart';

/// Relatório gerencial: rotas e destinos mais buscados, mapa de calor das
/// buscas no mapa e mapa de calor de uso dos recursos de acessibilidade.
class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  List<Evento>? _eventos;
  String _origem = 'todos';
  int _andarCalor = 1;

  static const _recursos = {
    'rotas': 'Rotas',
    'mapa': 'Mapa',
    'guiaVoz': 'Guia por voz',
    'altoContraste': 'Alto contraste',
    'sos': 'Ajuda / SOS',
    'caa': 'Imagens (CAA)',
    'voz': 'Voz',
  };
  static const _faixas = [10, 12, 14, 16, 18, 20];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final e = await AppScope.read(context).db.eventos();
    if (mounted) setState(() => _eventos = e);
  }

  Future<void> _apagarDemo() async {
    await AppScope.read(context).db.apagarDemonstracao();
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = Paleta.of(context);
    final todos = _eventos;

    return Scaffold(
      backgroundColor: p.fundo,
      body: Column(
        children: [
          const Cabecalho(titulo: 'Painel da Gestão', subtitulo: 'Últimos 7 dias · totem e celular'),
          Expanded(
            child: todos == null
                ? const Center(child: CircularProgressIndicator())
                : _conteudo(context, s, p, todos),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(BuildContext context, AppState s, Paleta p, List<Evento> todos) {
    final limite = DateTime.now().subtract(const Duration(days: 7));
    final eventos = todos
        .where((e) => e.criadoEm.isAfter(limite) && (_origem == 'todos' || e.origem == _origem))
        .toList();
    final temDemo = todos.any((e) => e.demo);
    final nomes = {for (final z in s.zonas) z.id: z.nome};

    final rotas = eventos.where((e) => e.tipo == 'rota').toList();
    final porDestino = <String, int>{};
    for (final e in rotas) {
      porDestino[e.chave] = (porDestino[e.chave] ?? 0) + 1;
    }
    final ranking = porDestino.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final porHora = <int, int>{};
    for (final e in eventos) {
      final f = _faixa(e.criadoEm.hour);
      if (f != null) porHora[f] = (porHora[f] ?? 0) + 1;
    }
    final pico = porHora.entries.isEmpty ? null : porHora.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final recursos = eventos.where((e) => e.tipo == 'recurso').toList();
    final grade = <String, Map<int, int>>{for (final r in _recursos.keys) r: {}};
    for (final e in recursos) {
      final f = _faixa(e.criadoEm.hour);
      if (f == null || !grade.containsKey(e.chave)) continue;
      grade[e.chave]![f] = (grade[e.chave]![f] ?? 0) + 1;
    }
    final totalRecurso = {for (final r in grade.entries) r.key: r.value.values.fold(0, (a, b) => a + b)};

    final base = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + base),
      children: [
        // Filtro de origem (uma linha, acima de tudo)
        Wrap(spacing: 8, children: [
          for (final o in const {'todos': 'Todos', 'totem': 'Totem', 'celular': 'Celular'}.entries)
            ChoiceChip(
              label: Text(o.value),
              selected: _origem == o.key,
              onSelected: (_) => setState(() => _origem = o.key),
            ),
        ]),
        if (temDemo) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            decoration: BoxDecoration(
              color: p.ac ? Colors.black : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.ac ? Cores.amareloAC : const Color(0xFFFFB74D)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: p.ac ? Cores.amareloAC : const Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Inclui dados de demonstração para a apresentação.',
                    style: TextStyle(color: p.texto, fontSize: 13)),
              ),
              TextButton(onPressed: _apagarDemo, child: const Text('Apagar')),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        // Números principais
        Row(children: [
          _Numero(rotulo: 'Buscas de rota', valor: '${rotas.length}'),
          const SizedBox(width: 8),
          _Numero(
              rotulo: 'Destino nº 1',
              valor: ranking.isEmpty ? '—' : (nomes[ranking.first.key] ?? ranking.first.key),
              pequeno: true),
          const SizedBox(width: 8),
          _Numero(rotulo: 'Horário de pico', valor: pico == null ? '—' : '${pico}h–${pico + 2}h', pequeno: true),
        ]),

        _Titulo('Destinos mais buscados'),
        if (ranking.isEmpty)
          Text('Ainda não há buscas de rota.', style: TextStyle(color: p.textoSuave))
        else
          for (final e in ranking)
            _Barra(
              rotulo: nomes[e.key] ?? e.key,
              valor: e.value,
              maximo: ranking.first.value,
              total: rotas.length,
            ),

        _Titulo('Mapa de calor das buscas'),
        Text('Quanto mais escura a zona, mais buscada. Use para posicionar publicidade e lojas no caminho.',
            style: TextStyle(color: p.textoSuave, fontSize: 13)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Térreo')),
            ButtonSegment(value: 1, label: Text('Piso 1')),
          ],
          selected: {_andarCalor},
          onSelectionChanged: (v) => setState(() => _andarCalor = v.first),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: MapaShopping(
            key: ValueKey('calor$_andarCalor'),
            zonas: s.zonas,
            andar: _andarCalor,
            altoContraste: s.altoContraste,
            halloween: s.halloween,
            calor: porDestino,
          ),
        ),
        _LegendaSequencial(escuro: p.ac),

        _Titulo('Uso dos recursos por horário'),
        Text('Mapa de calor de uso (Design Thinking): mostra o que é mais usado e quando.',
            style: TextStyle(color: p.textoSuave, fontSize: 13)),
        const SizedBox(height: 10),
        _GradeCalor(grade: grade, nomes: _recursos, faixas: _faixas, escuro: p.ac),
        _LegendaSequencial(escuro: p.ac),

        _Titulo('Recomendações'),
        ..._recomendacoes(ranking, rotas.length, nomes, totalRecurso, eventos, p),
      ],
    );
  }

  int? _faixa(int hora) {
    for (final f in _faixas) {
      if (hora >= f && hora < f + 2) return f;
    }
    return null;
  }

  List<Widget> _recomendacoes(List<MapEntry<String, int>> ranking, int totalRotas, Map<String, String> nomes,
      Map<String, int> totalRecurso, List<Evento> eventos, Paleta p) {
    final itens = <(IconData, String)>[];
    if (ranking.isNotEmpty && totalRotas > 0) {
      final top = ranking.first;
      final pct = (top.value * 100 / totalRotas).round();
      itens.add((
        Icons.campaign_outlined,
        '${nomes[top.key] ?? top.key} concentra $pct% das buscas. O caminho até lá é o melhor ponto para publicidade e para lojas de impulso.'
      ));
    }
    final usados = totalRecurso.entries
        // SOS pouco usado é bom sinal (menos gente precisando de socorro): fica de fora.
        .where((e) => e.key != 'rotas' && e.key != 'sos' && _recursos.containsKey(e.key))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (usados.isNotEmpty) {
      final menos = usados.first;
      itens.add((
        Icons.psychology_alt_outlined,
        '${_recursos[menos.key]} é o recurso menos usado (${menos.value} usos). Próximo sprint: entrevistar usuários para entender a baixa adesão.'
      ));
    }
    final totem = eventos.where((e) => e.origem == 'totem').length;
    if (eventos.isNotEmpty) {
      final pct = (totem * 100 / eventos.length).round();
      itens.add((
        Icons.qr_code_2,
        '$pct% do uso vem do totem e ${100 - pct}% do celular (QR Code). Ajuda a decidir onde instalar novos totens.'
      ));
    }
    return [
      for (final i in itens)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i.$1, color: p.destaque),
            const SizedBox(width: 10),
            Expanded(child: Text(i.$2, style: TextStyle(color: p.texto, fontSize: 15, height: 1.35))),
          ]),
        ),
    ];
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(texto, style: TextStyle(color: p.texto, fontSize: 18, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.rotulo, required this.valor, this.pequeno = false});
  final String rotulo;
  final String valor;
  final bool pequeno;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Expanded(
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.cartao,
          borderRadius: BorderRadius.circular(16),
          border: p.borda,
          boxShadow: p.sombra,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rotulo, style: TextStyle(color: p.textoSuave, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(valor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: p.texto,
                  fontSize: pequeno ? 15 : 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      ),
    );
  }
}

/// Barra horizontal de uma só cor; o número fica na cor do texto.
class _Barra extends StatelessWidget {
  const _Barra({required this.rotulo, required this.valor, required this.maximo, required this.total});
  final String rotulo;
  final int valor, maximo, total;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    final pct = total == 0 ? 0 : (valor * 100 / total).round();
    return Tooltip(
      message: '$rotulo: $valor buscas ($pct%)',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
            width: 118,
            child: Text(rotulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.texto, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: max(4, c.maxWidth * valor / max(1, maximo)),
                  height: 16,
                  decoration: BoxDecoration(
                    color: p.ac ? Cores.amareloAC : Cores.laranjaRota,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text('$valor · $pct%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: p.textoSuave, fontSize: 12, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ]),
      ),
    );
  }
}

class _GradeCalor extends StatelessWidget {
  const _GradeCalor({required this.grade, required this.nomes, required this.faixas, required this.escuro});
  final Map<String, Map<int, int>> grade;
  final Map<String, String> nomes;
  final List<int> faixas;
  final bool escuro;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    final maximo = max(1, grade.values.expand((m) => m.values).fold(0, max));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const SizedBox(width: 112),
            for (final f in faixas)
              SizedBox(
                width: 44,
                child: Text('${f}h',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textoSuave, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 4),
          for (final r in grade.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                SizedBox(
                  width: 112,
                  child: Text(nomes[r.key] ?? r.key,
                      style: TextStyle(color: p.texto, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                for (final f in faixas)
                  Builder(builder: (_) {
                    final n = r.value[f] ?? 0;
                    final t = n / maximo;
                    final cor = corCalor(t, escuro: escuro);
                    final tintaClara = escuro ? t < 0.55 : t > 0.55;
                    return Tooltip(
                      message: '${nomes[r.key]} · ${f}h–${f + 2}h: $n usos',
                      child: Container(
                        width: 42,
                        height: 30,
                        margin: const EdgeInsets.only(right: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(4)),
                        child: Text('$n',
                            style: TextStyle(
                                color: tintaClara ? Colors.white : const Color(0xFF2B1600),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                    );
                  }),
              ]),
            ),
        ],
      ),
    );
  }
}

class _LegendaSequencial extends StatelessWidget {
  const _LegendaSequencial({required this.escuro});
  final bool escuro;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Text('menos', style: TextStyle(color: p.textoSuave, fontSize: 12)),
        const SizedBox(width: 6),
        Container(
          width: 120,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(colors: [corCalor(0, escuro: escuro), corCalor(1, escuro: escuro)]),
          ),
        ),
        const SizedBox(width: 6),
        Text('mais', style: TextStyle(color: p.textoSuave, fontSize: 12)),
      ]),
    );
  }
}
