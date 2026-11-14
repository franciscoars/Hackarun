import 'package:sembast/sembast.dart';

import 'db_factory.dart';
import 'models.dart';
import 'seed.dart';

/// Banco de dados local (Sembast — NoSQL).
///
/// Coleções:
///  - `zonas`         → áreas do mapa (2 pavimentos)
///  - `chamados_sos`  → chamados de assistência enviados pelo usuário
///  - `preferencias`  → alto contraste, guia por voz, versão dos dados
class ShoppingDatabase {
  ShoppingDatabase._(this._db);

  final Database _db;

  static final _zonas = stringMapStoreFactory.store('zonas');
  static final _sos = intMapStoreFactory.store('chamados_sos');
  static final _prefs = StoreRef<String, Object?>('preferencias');

  /// Aumente quando mudar `seed.dart` para regravar o mapa.
  static const _versaoDados = 1;

  static Future<ShoppingDatabase> abrir() async {
    final db = ShoppingDatabase._(await abrirBanco('capim_dourado.db'));
    await db._popularSeNecessario();
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
}
