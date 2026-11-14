import 'dart:math';
import 'dart:ui';

/// Geometria do shopping circular (formato oval/esférico do prédio).
///
/// Todas as elipses têm a mesma proporção; `k` é o "raio" normalizado:
///   k 0.20 → borda do elevador panorâmico (centro do átrio)
///   k 0.74 → borda interna do corredor circular
///   k 0.87 → linha central do corredor (por onde a rota passa)
///   k 1.00 → fachada das lojas (portas)
///   k 1.36 → fundo das lojas
///   k 1.42 → parede externa do prédio
/// Ângulos em graus no sentido da tela: 0 = leste (direita), 90 = sul (baixo,
/// entrada principal), 180 = oeste, 270 = norte (topo).
class Geo {
  static const centro = Offset(350, 490);
  static const ax = 220.0;
  static const by = 310.0;

  static const kElevador = 0.20;
  static const kAtrio = 0.74;
  static const kCorredor = 0.87;
  static const kFachada = 1.0;
  static const kFundo = 1.36;
  static const kParede = 1.42;

  /// Passarelas que ligam o elevador ao corredor (leste, sul, oeste, norte).
  static const passarelas = [0.0, 90.0, 180.0, 270.0];

  static Offset ponto(double k, double grau) {
    final t = grau * pi / 180;
    return centro + Offset(ax * k * cos(t), by * k * sin(t));
  }

  static double kDe(Offset p) {
    final d = p - centro;
    return sqrt(pow(d.dx / ax, 2) + pow(d.dy / by, 2));
  }

  static double grauDe(Offset p) {
    final d = p - centro;
    return norm(atan2(d.dy / by, d.dx / ax) * 180 / pi);
  }

  static double norm(double g) {
    final x = g % 360;
    return x < 0 ? x + 360 : x;
  }

  /// Menor diferença angular de `de` até `para`, em (-180, 180].
  static double delta(double de, double para) {
    var d = norm(para - de);
    if (d > 180) d -= 360;
    return d;
  }

  static bool noArco(double g, double a0, double a1) => norm(g - a0) <= (a1 - a0);

  /// Pontos ao longo do corredor circular, pelo caminho mais curto.
  static List<Offset> arco(double k, double de, double para) {
    final d = delta(de, para);
    final n = max(2, (d.abs() / 4).ceil());
    return [for (var i = 0; i <= n; i++) ponto(k, de + d * i / n)];
  }

  /// Contorno de um setor do anel (uma loja/zona).
  static Path setor(double k0, double k1, double a0, double a1) {
    final path = Path();
    final n = max(4, ((a1 - a0) / 2).ceil());
    for (var i = 0; i <= n; i++) {
      final p = ponto(k1, a0 + (a1 - a0) * i / n);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    for (var i = n; i >= 0; i--) {
      final p = ponto(k0, a0 + (a1 - a0) * i / n);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Rect elipse(double k) =>
      Rect.fromCenter(center: centro, width: ax * k * 2, height: by * k * 2);

  /// Rumo de bússola (0 = Norte, 90 = Leste), do ponto `de` para `para`.
  static double rumo(Offset de, Offset para) {
    final v = para - de;
    return norm(atan2(v.dx, -v.dy) * 180 / pi);
  }

  static const _cardeais = ['Norte', 'Nordeste', 'Leste', 'Sudeste', 'Sul', 'Sudoeste', 'Oeste', 'Noroeste'];
  static const siglas = ['N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO'];

  static String cardinal(double rumo) => _cardeais[((norm(rumo) + 22.5) ~/ 45) % 8];
}
