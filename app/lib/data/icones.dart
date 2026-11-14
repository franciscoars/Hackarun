import 'package:flutter/material.dart';

const Map<String, IconData> _iconesZona = {
  'cart': Icons.shopping_cart,
  'store': Icons.storefront,
  'bag': Icons.shopping_bag,
  'elevator': Icons.elevator,
  'wc': Icons.wc,
  'atm': Icons.local_atm,
  'support': Icons.support_agent,
  'parking': Icons.local_parking,
  'food': Icons.restaurant,
  'movie': Icons.movie,
  'baby': Icons.child_friendly,
  'toys': Icons.toys,
};

IconData iconeDe(String chave) => _iconesZona[chave] ?? Icons.place;
