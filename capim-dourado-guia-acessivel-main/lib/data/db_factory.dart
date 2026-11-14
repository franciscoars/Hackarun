// Seleciona a implementação do banco conforme a plataforma:
// Web (QR Code no celular) -> IndexedDB · Android/Desktop -> arquivo local.
export 'db_factory_io.dart' if (dart.library.js_interop) 'db_factory_web.dart';
