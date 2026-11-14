import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// `?totem` no endereço (ou --dart-define=TOTEM=true) abre o modo Totem.
final bool modoTotem =
    Uri.base.queryParameters.containsKey('totem') || const bool.fromEnvironment('TOTEM');

/// `?destino=praca` abre direto a rota (usado pelo QR Code do totem).
final String? destinoInicial = Uri.base.queryParameters['destino'];

/// Endereço que o QR Code do totem aponta (IP do PC na rede local).
String get urlPublica {
  const lan = String.fromEnvironment('LAN_URL');
  if (lan.isNotEmpty) return lan;
  if (kIsWeb) return Uri.base.origin;
  return 'http://localhost:8090';
}

final navegadorKey = GlobalKey<NavigatorState>();

/// Destino da rota aberta agora (o QR do totem acompanha).
final rotaAtual = ValueNotifier<String?>(null);
