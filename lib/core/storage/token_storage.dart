import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  static const _key = 'auth_token';

  final SharedPreferences _prefs;

  Future<String?> readToken() async => _prefs.getString(_key);

  Future<void> saveToken(String token) async {
    await _prefs.setString(_key, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_key);
  }
}
