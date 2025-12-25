import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TripService {
  // ⚠️ GANTI DENGAN IP LAPTOP KAMU SAAT INI (Cek ipconfig)
  final String baseUrl = 'http://192.168.1.10:8000/api';

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    try {
      // Build URL dengan query parameter
      final uri = Uri.parse(
        '$baseUrl/users',
      ).replace(queryParameters: {if (query.isNotEmpty) 'search': query});

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> users = data['data'];

        // Mapping biar sesuai format UI
        return users
            .map(
              (u) => {
                'name': u['name'],
                'email': u['email'], // Simpan email untuk keperluan invite
                'username':
                    u['email'], // Sementara tampilkan email sbg username
                'isCurrentUser': false,
                'isGuest': false,
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      print("🔥 Error Search Users: $e");
      return [];
    }
  }

  // Fungsi Create Trip
  Future<bool> createTripWithMembers({
    required String name,
    required String? coverUrl,
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> members,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      print("🚀 Creating Trip: $name to $baseUrl");

      // 1. CREATE TRIP
      final tripResponse = await http
          .post(
            Uri.parse('$baseUrl/trips'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "name": name,
              "cover_url": coverUrl,
              "description": "Trip to $name",
              "currency_code": "IDR",
              "start_date": startDate,
              "end_date": endDate,
            }),
          )
          .timeout(const Duration(seconds: 15)); // Timeout 15 detik

      if (tripResponse.statusCode != 201) {
        print("❌ Gagal Create Trip: ${tripResponse.body}");
        return false;
      }

      final tripData = jsonDecode(tripResponse.body)['data'];
      final int tripId = tripData['id'];

      // 2. ADD MEMBERS
      final membersToAdd = members
          .where((m) => m['isCurrentUser'] != true)
          .toList();

      for (var member in membersToAdd) {
        Map<String, dynamic> memberBody = {
          "role": "member",
          "type": (member['email'] != null) ? "user" : "guest",
        };

        if (memberBody["type"] == "user") {
          memberBody["email"] = member['email'];
        } else {
          memberBody["guest_name"] = member['name'];
          // ✅ PERBAIKAN: Masukkan contact WA ke body request
          memberBody["guest_contact"] = member['contact'];
        }

        // Panggil API Add Member
        await http.post(
          Uri.parse('$baseUrl/trips/$tripId/members'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(memberBody),
        );
      }

      print("✅ Trip Created Successfully!");
      return true;
    } catch (e) {
      print("🔥 Error Service: $e");
      return false;
    }
  }

  // Fungsi Get Trips (FIXED)
  Future<List<Map<String, dynamic>>> getTrips({int page = 1}) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    try {
      print("📡 Fetching Trips Page: $page");

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/trips?page=$page&per_page=10',
            ), // Tambah per_page biar pasti
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Pastikan ambil dari data -> data (Laravel Default Pagination)
        List<dynamic> tripsList = data['data']['data'];
        return tripsList.map((trip) => trip as Map<String, dynamic>).toList();
      } else {
        print("❌ Gagal Fetch: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🔥 Error Fetch: $e");
      rethrow; // Lempar error agar UI tahu
    }
  }

  Future<Map<String, dynamic>?> getTripDetail(int id) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/trips/$id'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Mengembalikan object trip lengkap
      } else {
        print("❌ Gagal Get Detail: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔥 Error Get Detail: $e");
      return null;
    }
  }

  // ✅ BARU: Add Single Member to Existing Trip
  Future<bool> addMemberToTrip(int tripId, Map<String, dynamic> member) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      Map<String, dynamic> body = {
        "role": "member",
        "type": (member['email'] != null) ? "user" : "guest",
      };

      if (body["type"] == "user") {
        body["email"] = member['email'];
      } else {
        body["guest_name"] = member['name'];
        body["guest_contact"] = member['contact']; // Wajib untuk guest
      }

      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("❌ Gagal Add Member: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🔥 Error Add Member Service: $e");
      return false;
    }
  }

  // ✅ BARU: Create Transaction (Manual)
  Future<bool> createTransaction(int tripId, Map<String, dynamic> data) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("❌ Gagal Create Transaction: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🔥 Error Create Transaction Service: $e");
      return false;
    }
  }

  // ✅ BARU: Ambil Saran Pembayaran (Siapa hutang siapa)
  Future<List<dynamic>> getSettlementSuggestions(int tripId) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/$tripId/settlements/suggest'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("🔥 Error Get Settlements: $e");
      return [];
    }
  }

  // ✅ BARU: Bayar Hutang (Set as Paid)
  Future<bool> createSettlement(
    int tripId,
    int fromMemberId,
    int toMemberId,
    double amount,
  ) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/settlements'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'from_member_id': fromMemberId,
          'to_member_id': toMemberId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("❌ Gagal Settlement: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🔥 Error Create Settlement: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMyBalances(int tripId) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/$tripId/my-balances'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      print("🔥 Error Get MyBalances: $e");
      return [];
    }
  }

  // ✅ BARU: Get Trip Summary (Overview & Settlement Plan)
  Future<Map<String, dynamic>?> getSummary(int tripId) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/$tripId/summary'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print("🔥 Error Get Summary: $e");
      return null;
    }
  }
}
