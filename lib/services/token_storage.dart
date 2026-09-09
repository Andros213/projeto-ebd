import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }
}
