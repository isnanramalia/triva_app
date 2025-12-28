import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl; 

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Asumsi response backend: { "status": "success", "data": { "token": "...", "user": {...} } }
        // Sesuaikan parsing ini dengan response Postman kamu yang sebenarnya
        String token = data['data']['token']; 
        
        // Simpan token ke HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        
        // Opsional: Simpan data user juga biar bisa ditampilkan di profile
        await prefs.setString('user_data', jsonEncode(data['data']['user']));

        return true;
      } else {
        print('Login gagal: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error login: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data
  }
}