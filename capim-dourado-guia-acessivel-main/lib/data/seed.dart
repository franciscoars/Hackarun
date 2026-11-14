import 'models.dart';

/// Dados iniciais gravados no banco na primeira execução.
///
/// Sistema de coordenadas do mapa: 700 (largura) x 1000 (altura), em retrato.
/// Corredor central vertical em x = 305..395. Entrada principal embaixo.
/// Coluna esquerda: x 50..300 · Coluna direita: x 400..650.
const List<Zona> zonasIniciais = [
  // ───────────── TÉRREO (andar 0) ─────────────
  Zona(id: 'hiper', nome: 'Hipermercado', categoria: 'Compras', andar: 0,
      x: 50, y: 60, w: 250, h: 270, cor: 0xFF8BC34A, icone: 'cart',
      destino: true, ordem: 9, descricao: 'Supermercado com carrinhos adaptados.'),
  Zona(id: 'caixas', nome: 'Caixas e Farmácia', categoria: 'Serviços', andar: 0,
      x: 50, y: 350, w: 250, h: 170, cor: 0xFF66BB6A, icone: 'atm',
      destino: true, ordem: 7, descricao: 'Caixas eletrônicos e farmácia.'),
  Zona(id: 'banh0', nome: 'Banheiros', categoria: 'Banheiros', andar: 0,
      x: 50, y: 540, w: 250, h: 150, cor: 0xFF4FC3F7, icone: 'wc',
      destino: true, ordem: 3, descricao: 'Banheiros acessíveis com barras de apoio.'),
  Zona(id: 'lojasO', nome: 'Lojas', categoria: 'Lojas', andar: 0,
      x: 50, y: 710, w: 250, h: 160, cor: 0xFFFFB74D, icone: 'store'),
  Zona(id: 'ancora', nome: 'Loja de Departamento', categoria: 'Compras', andar: 0,
      x: 400, y: 60, w: 250, h: 240, cor: 0xFFBA68C8, icone: 'bag',
      destino: true, ordem: 10),
  Zona(id: 'lojasL', nome: 'Lojas', categoria: 'Lojas', andar: 0,
      x: 400, y: 320, w: 250, h: 110, cor: 0xFFFFB74D, icone: 'store'),
  Zona(id: 'elev0', nome: 'Elevadores e Escadas', categoria: 'Acesso', andar: 0,
      x: 400, y: 450, w: 250, h: 80, cor: 0xFF90A4AE, icone: 'elevator'),
  Zona(id: 'sac', nome: 'SAC · Atendimento', categoria: 'Serviços', andar: 0,
      x: 400, y: 550, w: 250, h: 140, cor: 0xFFE57373, icone: 'support',
      destino: true, ordem: 6, descricao: 'Atendimento ao cliente, achados e perdidos.'),
  Zona(id: 'estac', nome: 'Estacionamento', categoria: 'Acesso', andar: 0,
      x: 400, y: 710, w: 250, h: 160, cor: 0xFF9E9E9E, icone: 'parking',
      destino: true, ordem: 8, descricao: 'Acesso ao estacionamento e vagas PcD.'),

  // ───────────── PISO 1 (andar 1) ─────────────
  Zona(id: 'praca', nome: 'Praça de Alimentação', categoria: 'Alimentação', andar: 1,
      x: 50, y: 60, w: 250, h: 370, cor: 0xFFFF8A65, icone: 'food',
      destino: true, ordem: 1, descricao: 'Restaurantes e lanchonetes.'),
  Zona(id: 'banh1', nome: 'Banheiros', categoria: 'Banheiros', andar: 1,
      x: 50, y: 450, w: 250, h: 110, cor: 0xFF4FC3F7, icone: 'wc'),
  Zona(id: 'fralda', nome: 'Fraldário', categoria: 'Família', andar: 1,
      x: 50, y: 580, w: 250, h: 130, cor: 0xFFF48FB1, icone: 'baby',
      destino: true, ordem: 4),
  Zona(id: 'kids', nome: 'Espaço Kids', categoria: 'Família', andar: 1,
      x: 50, y: 730, w: 250, h: 140, cor: 0xFFFFD54F, icone: 'toys',
      destino: true, ordem: 5),
  Zona(id: 'cinema', nome: 'Cinema', categoria: 'Lazer', andar: 1,
      x: 400, y: 60, w: 250, h: 240, cor: 0xFF7E57C2, icone: 'movie',
      destino: true, ordem: 2, descricao: 'Salas com assentos reservados para PcD.'),
  Zona(id: 'lojasC', nome: 'Lojas', categoria: 'Lojas', andar: 1,
      x: 400, y: 320, w: 250, h: 110, cor: 0xFFFFB74D, icone: 'store'),
  Zona(id: 'elev1', nome: 'Elevadores e Escadas', categoria: 'Acesso', andar: 1,
      x: 400, y: 450, w: 250, h: 80, cor: 0xFF90A4AE, icone: 'elevator'),
  Zona(id: 'lojasD', nome: 'Lojas', categoria: 'Lojas', andar: 1,
      x: 400, y: 550, w: 250, h: 320, cor: 0xFFFFB74D, icone: 'store'),
];
