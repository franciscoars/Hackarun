import 'dart:ui';

/// Uma zona (área) do mapa do shopping, armazenada no banco de dados.
class Zona {
  const Zona({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.andar,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.cor,
    required this.icone,
    this.destino = false,
    this.ordem = 99,
    this.descricao = '',
  });

  final String id;
  final String nome;
  final String categoria;

  /// 0 = Térreo, 1 = Piso 1.
  final int andar;

  /// Retângulo no sistema de coordenadas do mapa (700 x 1000).
  final double x, y, w, h;
  final int cor;
  final String icone;

  /// Aparece na lista de destinos de "Rotas".
  final bool destino;
  final int ordem;
  final String descricao;

  Rect get rect => Rect.fromLTWH(x, y, w, h);
  String get nomeAndar => andar == 0 ? 'Térreo' : 'Piso $andar';

  Map<String, Object?> toMap() => {
        'nome': nome,
        'categoria': categoria,
        'andar': andar,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'cor': cor,
        'icone': icone,
        'destino': destino,
        'ordem': ordem,
        'descricao': descricao,
      };

  factory Zona.fromMap(String id, Map<String, Object?> m) => Zona(
        id: id,
        nome: m['nome'] as String,
        categoria: m['categoria'] as String,
        andar: (m['andar'] as num).toInt(),
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        w: (m['w'] as num).toDouble(),
        h: (m['h'] as num).toDouble(),
        cor: (m['cor'] as num).toInt(),
        icone: m['icone'] as String,
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
