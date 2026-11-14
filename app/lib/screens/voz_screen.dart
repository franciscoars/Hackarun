import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/comuns.dart';

/// Para quem não fala: digite e o celular fala em voz alta.
class VozScreen extends StatefulWidget {
  const VozScreen({super.key});

  @override
  State<VozScreen> createState() => _VozScreenState();
}

class _VozScreenState extends State<VozScreen> {
  final _texto = TextEditingController();
  String _idioma = 'pt-BR';
  bool _semVoz = false;

  Future<void> _escolherIdioma(String idioma) async {
    setState(() {
      _idioma = idioma;
      _semVoz = false;
    });
    final tem = await AppScope.read(context).fala.temVoz(idioma);
    if (mounted && _idioma == idioma) setState(() => _semVoz = !tem);
  }

  static const _idiomas = {'pt-BR': 'Português', 'en-US': 'English', 'es-ES': 'Español'};
  static const _rapidas = {
    'pt-BR': ['Olá, bom dia!', 'Onde fica o banheiro?', 'Quanto custa?', 'Obrigado!'],
    'en-US': ['Hello!', 'Where is the restroom?', 'How much is it?', 'Thank you!'],
    'es-ES': ['¡Hola!', '¿Dónde está el baño?', '¿Cuánto cuesta?', '¡Gracias!'],
  };

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _falar([String? t]) {
    final frase = (t ?? _texto.text).trim();
    if (frase.isEmpty) return;
    AppScope.read(context)
      ..fala.falar(frase, idioma: _idioma)
      ..registrar('recurso', 'voz');
  }

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Scaffold(
      backgroundColor: p.fundo,
      body: Column(
        children: [
          const Cabecalho(titulo: 'Voz', subtitulo: 'Escreva e eu falo por você'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _idiomas.entries)
                      ChoiceChip(
                        label: Text(e.value, style: const TextStyle(fontSize: 15)),
                        selected: _idioma == e.key,
                        onSelected: (_) => _escolherIdioma(e.key),
                      ),
                  ],
                ),
                if (_semVoz) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.ac ? Colors.black : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.ac ? Cores.amareloAC : const Color(0xFFFFB74D)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline, color: p.ac ? Cores.amareloAC : const Color(0xFFE65100)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Este aparelho não tem voz em ${_idiomas[_idioma]} instalada: a frase sai '
                            'com a voz padrão. Para a pronúncia certa, instale a voz nas configurações '
                            'de idioma/fala do aparelho.',
                            style: TextStyle(fontSize: 14, color: p.texto, height: 1.35),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _texto,
                  maxLines: 4,
                  style: TextStyle(fontSize: 22, color: p.texto, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Digite aqui o que você quer dizer...',
                    hintStyle: TextStyle(color: p.textoSuave),
                    filled: true,
                    fillColor: p.cartao,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: p.ac ? Cores.amareloAC : Colors.black12, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: p.ac ? Cores.amareloAC : Colors.black12, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.ac ? Cores.amareloAC : const Color(0xFF00897B),
                      foregroundColor: p.ac ? Colors.black : Colors.white,
                    ),
                    onPressed: _falar,
                    icon: const Icon(Icons.campaign, size: 30),
                    label: const Text('Falar em voz alta',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Frases rápidas',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.texto)),
                const SizedBox(height: 8),
                for (final f in _rapidas[_idioma]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: p.cartao,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: p.ac ? BorderSide(color: Cores.amareloAC) : BorderSide.none,
                      ),
                      leading: Icon(Icons.volume_up_rounded, color: p.destaque),
                      title: Text(f, style: TextStyle(fontSize: 17, color: p.texto, fontWeight: FontWeight.w600)),
                      onTap: () => _falar(f),
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
