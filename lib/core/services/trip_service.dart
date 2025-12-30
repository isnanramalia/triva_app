import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'dart:io';
import '../config/api_config.dart';

class TripService {
  final String baseUrl = ApiConfig.baseUrl;

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

  Future<int?> createTripWithMembers({
    required String name,
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> members,
    File? coverFile,
    String? coverUrl,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/trips'));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;

      request.fields['members'] = jsonEncode(members);

      if (coverFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('cover_image', coverFile.path),
        );
      } else if (coverUrl != null) {
        request.fields['cover_url'] = coverUrl;
      }

      print("📤 Sending Trip Request: ${request.fields}");
      if (coverFile != null) print("📤 With File: ${coverFile.path}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']['id']; // Kembalikan ID Trip baru
      } else {
        print("Create Trip Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error creating trip: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTrips({int page = 1}) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    try {
      print("📡 Fetching Trips Page: $page");

      final response = await http
          .get(
            Uri.parse('$baseUrl/trips?page=$page&per_page=10'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> tripsList = data['data']['data'];

        if (tripsList.isNotEmpty) {
          print("📦 SAMPLE TRIP DATA: ${tripsList.first}");
        }

        return tripsList.map((trip) => trip as Map<String, dynamic>).toList();
      } else {
        print("❌ Gagal Fetch: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🔥 Error Fetch: $e");
      rethrow;
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

  // Tambahkan function ini di dalam class TripService
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
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'from_member_id': fromMemberId,
          'to_member_id': toMemberId,
          'amount': amount,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error creating settlement: $e");
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

  // ✅ Get Share Link
  Future<String?> getShareLink(int tripId) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/share'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      }
      return null;
    } catch (e) {
      print("🔥 Error Get Share Link: $e");
      return null;
    }
  }

  Future<bool> updateTripCover(int tripId, File imageFile) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/trips/$tripId/cover'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Attach file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Upload Failed: $respStr");
        return false;
      }
    } catch (e) {
      print("Error uploading cover: $e");
      return false;
    }
  }

  Future<bool> renameTrip(int tripId, String newName) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/$tripId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': newName}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error renaming trip: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getTransactionDetail(
    int tripId,
    int transactionId,
  ) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/$tripId/transactions/$transactionId'),
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
      print("Error fetching transaction detail: $e");
      return null;
    }
  }

  // ✅ BARU: Update Transaction
  Future<bool> updateTransaction(
    int tripId,
    int transactionId,
    Map<String, dynamic> data,
  ) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        // Gunakan PUT untuk update
        Uri.parse('$baseUrl/trips/$tripId/transactions/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("❌ Gagal Update Transaction: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🔥 Error Update Transaction Service: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> joinTrip(String token) async {
    final tokenAuth = await AuthService().getToken();
    if (tokenAuth == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/join'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $tokenAuth',
        },
        body: jsonEncode({'token': token}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to join trip');
      }
    } catch (e) {
      print("Error joining trip: $e");
      throw e;
    }
  }

  // ==========================================
  // AI & SMART SCAN FEATURES
  // ==========================================

  /// 1. Mengirim Gambar/Teks ke Backend -> diteruskan ke n8n
  Future<Map<String, dynamic>> prepareAi({
    required int tripId,
    File? image,
    String? query,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception("User not logged in");

    try {
      final uri = Uri.parse('$baseUrl/trips/$tripId/transactions/prepare-ai');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // LOGIC GAMBAR OPSIONAL (Sudah Benar)
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      // LOGIC TEKS OPSIONAL (Sudah Benar)
      if (query != null && query.isNotEmpty) {
        request.fields['query'] = query;
      }

      print("🚀 Sending AI Request: Image=${image != null}, Query=$query");

      // --- PERBAIKAN: TAMBAHKAN TIMEOUT 60 DETIK ---
      // AI butuh waktu mikir, jangan sampai putus duluan
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception(
            "Koneksi timeout. AI butuh waktu lebih lama dari biasanya.",
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print("🤖 AI Response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Coba parse error message dari backend
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? "AI Processing Failed");
        } catch (_) {
          // Kalau response bukan JSON (misal HTML error 500)
          throw Exception(
            "Server Error (${response.statusCode}): ${response.body}",
          );
        }
      }
    } catch (e) {
      print("🔥 Error prepareAi: $e");
      // UI akan membaca 'status': 'error' ini
      return {
        'status': 'error',
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// 2. Menyimpan Transaksi Final (Save AI)
  Future<bool> saveAiTransaction(
    int tripId,
    Map<String, dynamic> payload,
  ) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/transactions/save-ai'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print("💾 Save AI Response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Opsional: Print error detail buat debugging
        print("❌ Gagal Save AI: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🔥 Error saveAiTransaction: $e");
      return false;
    }
  }
}
