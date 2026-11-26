import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gerenciamento de armazenamento seguro de credenciais
/// Conforme AGENTS.md e RNF01:
/// - O JWT DEVE ser salvo exclusivamente em flutter_secure_storage (nunca em shared_preferences).
/// - Proibido logar token, CPF ou documentos no console.
class AppStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _keyJwt = 'triasus_jwt_token';
  static const String _keyUserData = 'triasus_user_json';
  static const String _keyFontScale = 'triasus_font_scale';

  /// Salva o token JWT de autenticação
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyJwt, value: token);
  }

  /// Recupera o token JWT salvo
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyJwt);
  }

  /// Salva dados resumidos do perfil do cidadão logado (JSON string)
  static Future<void> saveUserData(String json) async {
    await _storage.write(key: _keyUserData, value: json);
  }

  /// Recupera dados salvos do perfil
  static Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  /// Salva a escala de fonte preferida
  static Future<void> saveFontScale(double scale) async {
    await _storage.write(key: _keyFontScale, value: scale.toString());
  }

  /// Recupera a escala de fonte preferida
  static Future<double> getFontScale() async {
    final value = await _storage.read(key: _keyFontScale);
    if (value != null) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 1.0;
  }

  /// Remove todas as credenciais (logout seguro)
  static Future<void> clearAuth() async {
    await _storage.delete(key: _keyJwt);
    await _storage.delete(key: _keyUserData);
  }
}
