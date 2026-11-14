import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/icones.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/comuns.dart';
import 'mapa_screen.dart';

class RotasScreen extends StatefulWidget {
  const RotasScreen({super.key});

  @override
  State<RotasScreen> createState() => _RotasScreenState();
}

class _RotasScreenState extends State<RotasScreen> {
  String _busca = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context)
        ..registrar('recurso', 'rotas')
        ..anunciar('Para onde você quer ir? Escolha um destino na lista.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = Paleta.of(context);
    final destinos = s.zonas.where((z) => z.destino).toList()..sort((a, b) => a.ordem.compareTo(b.ordem));
    final filtrados = destinos
        .where((z) => _busca.isEmpty || z.nome.toLowerCase().contains(_busca.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: p.fundo,
      body: Column(
        children: [
          const Cabecalho(titulo: 'Para onde você quer ir?', subtitulo: 'Saindo do totem da Entrada Principal'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v),
              style: TextStyle(fontSize: 17, color: p.texto),
              decoration: InputDecoration(
                hintText: 'Buscar destino',
                hintStyle: TextStyle(color: p.textoSuave),
                prefixIcon: Icon(Icons.search, color: p.textoSuave),
                filled: true,
                fillColor: p.cartao,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: p.ac ? BorderSide(color: Cores.amareloAC, width: 2) : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: p.ac ? BorderSide(color: Cores.amareloAC, width: 2) : BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
              itemCount: filtrados.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _CartaoDestino(
                zona: filtrados[i],
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => MapaScreen(destino: filtrados[i]))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoDestino extends StatelessWidget {
  const _CartaoDestino({required this.zona, required this.onTap});

  final Zona zona;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    final cor = Color(zona.cor);
    final subtitulo = zona.andar == 0 ? 'Térreo · mesmo andar' : '${zona.nomeAndar} · via elevador';
    return Semantics(
      button: true,
      label: '${zona.nome}. $subtitulo',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.cartao,
              borderRadius: BorderRadius.circular(20),
              border: p.borda,
              boxShadow: p.sombra,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: p.ac ? Colors.black : cor,
                    borderRadius: BorderRadius.circular(16),
                    border: p.ac ? Border.all(color: Cores.amareloAC) : null,
                  ),
                  child: Icon(iconeDe(zona.icone), color: p.ac ? Cores.amareloAC : Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zona.nome,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.texto)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(zona.andar == 0 ? Icons.layers_outlined : Icons.elevator,
                            size: 16, color: p.textoSuave),
                        const SizedBox(width: 4),
                        Text(subtitulo, style: TextStyle(fontSize: 14, color: p.textoSuave)),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 30, color: p.ac ? Cores.amareloAC : p.textoSuave),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
