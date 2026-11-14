import 'models.dart';

/// Dados iniciais do mapa (MVP: só locais fixos — zonas principais,
/// banheiros, elevador, praça). Gravados no banco na primeira execução.
///
/// O prédio é circular: as zonas são setores do anel em volta do corredor.
/// Ângulos (graus): 0 = leste, 90 = sul (entrada), 180 = oeste, 270 = norte.
const _elevador = (x: 305.0, y: 445.0, w: 90.0, h: 90.0);

final List<Zona> zonasIniciais = [
  // ───────────── TÉRREO (andar 0) — entrada principal em 75°..105° ─────────────
  const Zona(id: 'estac', nome: 'Estacionamento', categoria: 'Acesso', andar: 0,
      ang0: 105, ang1: 150, cor: 0xFF9E9E9E, icone: 'parking',
      destino: true, ordem: 8, descricao: 'Acesso ao estacionamento e vagas PcD.'),
  const Zona(id: 'banh0', nome: 'Banheiros', categoria: 'Banheiros', andar: 0,
      ang0: 150, ang1: 185, cor: 0xFF4FC3F7, icone: 'wc',
      destino: true, ordem: 3, descricao: 'Banheiros acessíveis com barras de apoio.'),
  const Zona(id: 'caixas', nome: 'Caixas e Farmácia', categoria: 'Serviços', andar: 0,
      ang0: 185, ang1: 225, cor: 0xFF66BB6A, icone: 'atm',
      destino: true, ordem: 7, descricao: 'Caixas eletrônicos e farmácia.'),
  const Zona(id: 'hiper', nome: 'Hipermercado', categoria: 'Compras', andar: 0,
      ang0: 225, ang1: 285, cor: 0xFF8BC34A, icone: 'cart',
      destino: true, ordem: 9, descricao: 'Supermercado com carrinhos adaptados.'),
  const Zona(id: 'ancora', nome: 'Loja de Departamento', categoria: 'Compras', andar: 0,
      ang0: 285, ang1: 345, cor: 0xFFBA68C8, icone: 'bag', destino: true, ordem: 10),
  const Zona(id: 'lojasL', nome: 'Lojas', categoria: 'Lojas', andar: 0,
      ang0: 345, ang1: 380, cor: 0xFFFFB74D, icone: 'store'),
  const Zona(id: 'sac', nome: 'SAC · Atendimento', categoria: 'Serviços', andar: 0,
      ang0: 20, ang1: 50, cor: 0xFFE57373, icone: 'support',
      destino: true, ordem: 6, descricao: 'Atendimento ao cliente, achados e perdidos.'),
  const Zona(id: 'lojasO', nome: 'Lojas', categoria: 'Lojas', andar: 0,
      ang0: 50, ang1: 75, cor: 0xFFFFB74D, icone: 'store'),
  Zona(id: 'elev0', nome: 'Elevador panorâmico', categoria: 'Acesso', andar: 0,
      x: _elevador.x, y: _elevador.y, w: _elevador.w, h: _elevador.h,
      cor: 0xFF90A4AE, icone: 'elevator'),

  // ───────────── PISO 1 (andar 1) ─────────────
  const Zona(id: 'lojasD', nome: 'Lojas', categoria: 'Lojas', andar: 1,
      ang0: 75, ang1: 125, cor: 0xFFFFB74D, icone: 'store'),
  const Zona(id: 'fralda', nome: 'Fraldário', categoria: 'Família', andar: 1,
      ang0: 125, ang1: 160, cor: 0xFFF48FB1, icone: 'baby', destino: true, ordem: 4),
  const Zona(id: 'banh1', nome: 'Banheiros', categoria: 'Banheiros', andar: 1,
      ang0: 160, ang1: 200, cor: 0xFF4FC3F7, icone: 'wc'),
  const Zona(id: 'praca', nome: 'Praça de Alimentação', categoria: 'Alimentação', andar: 1,
      ang0: 200, ang1: 290, cor: 0xFFFF8A65, icone: 'food',
      destino: true, ordem: 1, descricao: 'Restaurantes e lanchonetes.'),
  const Zona(id: 'cinema', nome: 'Cinema', categoria: 'Lazer', andar: 1,
      ang0: 290, ang1: 350, cor: 0xFF7E57C2, icone: 'movie',
      destino: true, ordem: 2, descricao: 'Salas com assentos reservados para PcD.'),
  const Zona(id: 'lojasC', nome: 'Lojas', categoria: 'Lojas', andar: 1,
      ang0: 350, ang1: 400, cor: 0xFFFFB74D, icone: 'store'),
  const Zona(id: 'kids', nome: 'Espaço Kids', categoria: 'Família', andar: 1,
      ang0: 40, ang1: 75, cor: 0xFFFFD54F, icone: 'toys', destino: true, ordem: 5),
  Zona(id: 'elev1', nome: 'Elevador panorâmico', categoria: 'Acesso', andar: 1,
      x: _elevador.x, y: _elevador.y, w: _elevador.w, h: _elevador.h,
      cor: 0xFF90A4AE, icone: 'elevator'),
];
