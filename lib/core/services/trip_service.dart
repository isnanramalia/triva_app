import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TripService {
  final String baseUrl = 'http://10.0.2.2:8000/api'; // Sesuaikan IP

  // Fungsi Create Trip Lengkap (Header + Member)
  Future<bool> createTripWithMembers({
    required String name,
    required String emoji, // ✅ Field baru sesuai DB refactor
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> members,
  }) async {
    
    // 1. Ambil Token
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      // 2. CREATE TRIP HEADER
      final tripResponse = await http.post(
        Uri.parse('$baseUrl/trips'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "name": name,
          "emoji": emoji, // ✅ Kirim emoji ke backend
          "description": "Trip created via App",
          "currency_code": "IDR",
          "start_date": startDate,
          "end_date": endDate,
        }),
      );

      if (tripResponse.statusCode != 201) {
        print("Gagal buat trip: ${tripResponse.body}");
        return false;
      }

      final tripData = jsonDecode(tripResponse.body)['data']; // Sesuaikan struktur response
      final int tripId = tripData['id'];

      // 3. ADD MEMBERS (Looping)
      // Filter: Jangan add diri sendiri, karena creator otomatis jadi admin
      final membersToAdd = members.where((m) => m['isCurrentUser'] != true).toList();

      for (var member in membersToAdd) {
        // Tentukan body request berdasarkan tipe member (User vs Guest)
        Map<String, dynamic> memberBody;
        
        // Logika sederhana: Kalau punya field 'email' berarti User, kalau tidak berarti Guest
        // (Pastikan UI create_trip_sheet kamu mengirim struktur data yang konsisten)
        if (member.containsKey('email') && member['email'] != null && member['email'].toString().isNotEmpty) {
          memberBody = {
            "type": "user",
            "email": member['email'],
            "role": "member"
          };
        } else {
          memberBody = {
            "type": "guest",
            "guest_name": member['name'],
            "guest_contact": null, // ✅ Nullable sesuai DB refactor
            "role": "member"
          };
        }

        await http.post(
          Uri.parse('$baseUrl/trips/$tripId/members'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(memberBody),
        );
      }

      return true;

    } catch (e) {
      print("Error creating trip: $e");
      return false;
    }
  }
}