import 'dart:ui';

import 'geometria.dart';

/// Uma zona (área) do mapa do shopping, armazenada no banco de dados.
///
/// Zonas do anel são setores entre os ângulos [ang0, ang1] (graus, ver [Geo]).
/// O elevador panorâmico fica no centro e usa o retângulo x/y/w/h.
class Zona {
  const Zona({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.andar,
    required this.cor,
    required this.icone,
    this.ang0,
    this.ang1,
    this.x = 0,
    this.y = 0,
    this.w = 0,
    this.h = 0,
    this.destino = false,
    this.ordem = 99,
    this.descricao = '',
  });

  final String id;
  final String nome;
  final String categoria;

  /// 0 = Térreo, 1 = Piso 1.
  final int andar;
  final int cor;
  final String icone;
  final double? ang0, ang1;
  final double x, y, w, h;

  /// Aparece na lista de destinos de "Rotas".
  final bool destino;
  final int ordem;
  final String descricao;

  bool get ehSetor => ang0 != null && ang1 != null;
  double get angMeio => Geo.norm((ang0! + ang1!) / 2);
  Rect get rect => Rect.fromLTWH(x, y, w, h);
  String get nomeAndar => andar == 0 ? 'Térreo' : 'Piso $andar';

  /// Onde ficam o ícone e o nome da zona no mapa.
  Offset get centroRotulo =>
      ehSetor ? Geo.ponto((Geo.kFachada + Geo.kFundo) / 2, angMeio) : rect.center;

  bool contem(Offset p) {
    if (!ehSetor) return (p - rect.center).distance <= w / 2;
    final k = Geo.kDe(p);
    return k >= Geo.kFachada && k <= Geo.kFundo && Geo.noArco(Geo.grauDe(p), ang0!, ang1!);
  }

  Map<String, Object?> toMap() => {
        'nome': nome,
        'categoria': categoria,
        'andar': andar,
        'cor': cor,
        'icone': icone,
        'ang0': ang0,
        'ang1': ang1,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'destino': destino,
        'ordem': ordem,
        'descricao': descricao,
      };

  factory Zona.fromMap(String id, Map<String, Object?> m) => Zona(
        id: id,
        nome: m['nome'] as String,
        categoria: m['categoria'] as String,
        andar: (m['andar'] as num).toInt(),
        cor: (m['cor'] as num).toInt(),
        icone: m['icone'] as String,
        ang0: (m['ang0'] as num?)?.toDouble(),
        ang1: (m['ang1'] as num?)?.toDouble(),
        x: (m['x'] as num?)?.toDouble() ?? 0,
        y: (m['y'] as num?)?.toDouble() ?? 0,
        w: (m['w'] as num?)?.toDouble() ?? 0,
        h: (m['h'] as num?)?.toDouble() ?? 0,
        destino: (m['destino'] as bool?) ?? false,
        ordem: (m['ordem'] as num?)?.toInt() ?? 99,
        descricao: (m['descricao'] as String?) ?? '',
      );
}

/// Chamado de assistência (SOS) registrado no banco.
class ChamadoSos {
  const ChamadoSos({
    required this.id,
    required this.tipo,
    required this.local,
    required this.status,
    required this.criadoEm,
  });

  final int id;
  final String tipo;
  final String local;
  final String status;
  final DateTime criadoEm;

  factory ChamadoSos.fromMap(int id, Map<String, Object?> m) => ChamadoSos(
        id: id,
        tipo: m['tipo'] as String,
        local: m['local'] as String,
        status: (m['status'] as String?) ?? 'Enviado',
        criadoEm: DateTime.parse(m['criadoEm'] as String),
      );
}

/// Evento de uso (métricas para o relatório de gestão e o mapa de calor).
class Evento {
  const Evento({
    required this.tipo,
    required this.chave,
    required this.origem,
    required this.criadoEm,
    required this.demo,
  });

  /// 'rota' (chave = id da zona) ou 'recurso' (chave = nome do recurso).
  final String tipo;
  final String chave;

  /// 'celular' ou 'totem'.
  final String origem;
  final DateTime criadoEm;

  /// true = dado de demonstração (pode ser apagado no relatório).
  final bool demo;

  factory Evento.fromMap(Map<String, Object?> m) => Evento(
        tipo: m['tipo'] as String,
        chave: m['chave'] as String,
        origem: (m['origem'] as String?) ?? 'celular',
        criadoEm: DateTime.parse(m['criadoEm'] as String),
        demo: (m['demo'] as bool?) ?? false,
      );
}
