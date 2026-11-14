import 'dart:math';

import 'package:sembast/sembast.dart';

import 'db_factory.dart';
import 'models.dart';
import 'seed.dart';

/// Banco de dados local (Sembast — NoSQL).
///
/// Coleções:
///  - `zonas`         → áreas do mapa (2 pavimentos)
///  - `chamados_sos`  → chamados de assistência enviados pelo usuário
///  - `eventos`       → métricas de uso (relatório de gestão e mapa de calor)
///  - `preferencias`  → alto contraste, guia por voz, versão dos dados
class ShoppingDatabase {
  ShoppingDatabase._(this._db);

  final Database _db;

  static final _zonas = stringMapStoreFactory.store('zonas');
  static final _sos = intMapStoreFactory.store('chamados_sos');
  static final _eventos = intMapStoreFactory.store('eventos');
  static final _prefs = StoreRef<String, Object?>('preferencias');

  /// Aumente quando mudar `seed.dart` para regravar o mapa.
  static const _versaoDados = 2;

  static Future<ShoppingDatabase> abrir() async {
    final db = ShoppingDatabase._(await abrirBanco('capim_dourado.db'));
    await db._popularSeNecessario();
    await db._criarDemonstracaoSeNecessario();
    return db;
  }

  Future<void> _popularSeNecessario() async {
    final versao = await _prefs.record('versao_dados').get(_db);
    if (versao == _versaoDados) return;
    await _db.transaction((txn) async {
      await _zonas.delete(txn);
      for (final z in zonasIniciais) {
        await _zonas.record(z.id).put(txn, z.toMap());
      }
      await _prefs.record('versao_dados').put(txn, _versaoDados);
    });
  }

  // ── Zonas ──
  Future<List<Zona>> zonas() async {
    final registros = await _zonas.find(_db);
    return registros.map((r) => Zona.fromMap(r.key, r.value)).toList();
  }

  // ── Preferências ──
  Future<Map<String, Object?>> preferencias() async {
    final registros = await _prefs.find(_db);
    return {for (final r in registros) r.key: r.value};
  }

  Future<void> salvarPreferencia(String chave, Object valor) =>
      _prefs.record(chave).put(_db, valor);

  // ── Chamados SOS ──
  Future<int> registrarChamado({required String tipo, required String local}) {
    return _sos.add(_db, {
      'tipo': tipo,
      'local': local,
      'status': 'Enviado',
      'criadoEm': DateTime.now().toIso8601String(),
    });
  }

  Future<void> atualizarStatus(int id, String status) =>
      _sos.record(id).update(_db, {'status': status});

  Future<List<ChamadoSos>> chamadosRecentes({int limite = 5}) async {
    final registros = await _sos.find(
      _db,
      finder: Finder(sortOrders: [SortOrder(Field.key, false)], limit: limite),
    );
    return registros.map((r) => ChamadoSos.fromMap(r.key, r.value)).toList();
  }

  // ── Métricas de uso ──
  Future<void> registrarEvento({required String tipo, required String chave, required String origem}) {
    return _eventos.add(_db, {
      'tipo': tipo,
      'chave': chave,
      'origem': origem,
      'criadoEm': DateTime.now().toIso8601String(),
      'demo': false,
    });
  }

  Future<List<Evento>> eventos() async {
    final registros = await _eventos.find(_db);
    return registros.map((r) => Evento.fromMap(r.value)).toList();
  }

  Future<void> apagarDemonstracao() async {
    await _eventos.delete(_db, finder: Finder(filter: Filter.equals('demo', true)));
    await _prefs.record('demo_apagada').put(_db, true);
  }

  /// Gera 7 dias de uso fictício para a apresentação do relatório.
  /// Fica marcado como demonstração e pode ser apagado pelo relatório.
  Future<void> _criarDemonstracaoSeNecessario() async {
    final jaCriada = await _prefs.record('demo_criada').get(_db);
    if (jaCriada == true) return;

    final rnd = Random(18);
    const destinos = {'praca': 34, 'banh0': 22, 'cinema': 16, 'sac': 9, 'estac': 8, 'kids': 6, 'fralda': 5, 'caixas': 5, 'hiper': 4, 'ancora': 3};
    const recursos = {'rotas': 30, 'guiaVoz': 14, 'altoContraste': 8, 'mapa': 10, 'sos': 4, 'caa': 3, 'voz': 5};
    // Fluxo do shopping: pico no almoço e no fim da tarde.
    const pesoHora = {10: 2, 11: 4, 12: 9, 13: 9, 14: 5, 15: 4, 16: 5, 17: 7, 18: 9, 19: 10, 20: 8, 21: 4};

    T sortear<T>(Map<T, int> pesos) {
      final total = pesos.values.reduce((a, b) => a + b);
      var r = rnd.nextInt(total);
      for (final e in pesos.entries) {
        if (r < e.value) return e.key;
        r -= e.value;
      }
      return pesos.keys.first;
    }

    final agora = DateTime.now();
    await _db.transaction((txn) async {
      for (var i = 0; i < 420; i++) {
        final dia = agora.subtract(Duration(days: rnd.nextInt(7)));
        final hora = sortear(pesoHora);
        final quando = DateTime(dia.year, dia.month, dia.day, hora, rnd.nextInt(60));
        final ehRota = rnd.nextDouble() < 0.55;
        await _eventos.add(txn, {
          'tipo': ehRota ? 'rota' : 'recurso',
          'chave': ehRota ? sortear(destinos) : sortear(recursos),
          'origem': rnd.nextDouble() < 0.6 ? 'totem' : 'celular',
          'criadoEm': quando.toIso8601String(),
          'demo': true,
        });
      }
      await _prefs.record('demo_criada').put(txn, true);
    });
  }
}
