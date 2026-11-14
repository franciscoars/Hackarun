import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/comuns.dart';

/// Comunicação Aumentativa e Alternativa: pictogramas que falam.
class CaaScreen extends StatelessWidget {
  const CaaScreen({super.key});

  static const _cartoes = [
    (Icons.wc, 'Banheiro', 'Eu quero ir ao banheiro.', Color(0xFF0288D1)),
    (Icons.restaurant, 'Comer', 'Estou com fome.', Color(0xFFF57C00)),
    (Icons.local_drink, 'Beber água', 'Estou com sede.', Color(0xFF0097A7)),
    (Icons.front_hand, 'Ajuda', 'Eu preciso de ajuda, por favor.', Color(0xFFD32F2F)),
    (Icons.explore_off, 'Perdido', 'Estou perdido. Pode me ajudar?', Color(0xFF6D4C41)),
    (Icons.healing, 'Dor', 'Estou sentindo dor.', Color(0xFFC2185B)),
    (Icons.elevator, 'Elevador', 'Onde fica o elevador?', Color(0xFF546E7A)),
    (Icons.exit_to_app, 'Ir embora', 'Eu quero ir embora.', Color(0xFF5E35B1)),
    (Icons.thumb_up, 'Sim', 'Sim.', Color(0xFF2E7D32)),
    (Icons.thumb_down, 'Não', 'Não.', Color(0xFFB71C1C)),
    (Icons.favorite, 'Obrigado', 'Obrigado!', Color(0xFFAD1457)),
    (Icons.help_outline, 'Não entendi', 'Não entendi. Pode repetir?', Color(0xFF455A64)),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Scaffold(
      backgroundColor: p.fundo,
      body: Column(
        children: [
          const Cabecalho(titulo: 'Comunicação por Imagens', subtitulo: 'Toque numa imagem: eu falo e mostro'),
          Expanded(
            child: GridView.count(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + MediaQuery.of(context).padding.bottom),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                for (final c in _cartoes)
                  Semantics(
                    button: true,
                    label: c.$3,
                    excludeSemantics: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _mostrar(context, c.$1, c.$3, c.$4),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: p.ac ? Colors.black : c.$4,
                            borderRadius: BorderRadius.circular(18),
                            border: p.borda,
                            boxShadow: p.sombra,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(c.$1, size: 44, color: p.ac ? Cores.amareloAC : Colors.white),
                              const SizedBox(height: 8),
                              Text(c.$2,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrar(BuildContext context, IconData icone, String frase, Color cor) {
    final s = AppScope.read(context);
    s.fala.falar(frase);
    s.registrar('recurso', 'caa');
    final ac = s.altoContraste;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ac ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: ac ? BorderSide(color: Cores.amareloAC, width: 3) : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mostre para o atendente',
                  style: TextStyle(fontSize: 14, color: ac ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 56,
                backgroundColor: ac ? Cores.amareloAC : cor,
                child: Icon(icone, size: 64, color: ac ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 18),
              Text(frase,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: ac ? Colors.white : Colors.black)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => s.fala.falar(frase),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Repetir'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fechar'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
