import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento de secretos (clave API / token del backend).
///
/// La interfaz de usuario nunca lee el valor para mostrarlo: solo consulta
/// si existe ([contains]). El valor se lee únicamente al construir el
/// cliente HTTP en el momento de la petición.
abstract interface class SecretStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<bool> contains(String key);
}

class SecureSecretStore implements SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> contains(String key) => _storage.containsKey(key: key);
}

class InMemorySecretStore implements SecretStore {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<bool> contains(String key) async => _data.containsKey(key);
}
