import 'package:sembast_web/sembast_web.dart';

Future<Database> abrirBanco(String nome) => databaseFactoryWeb.openDatabase(nome);
