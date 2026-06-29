// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/helper/file_compress.dart';
import '../models/user_model.dart';
import 'package:mobile/services/chat/chat_socket_service.dart';

class AuthService {
  final String baseUrl =
      "https://frettiest-ariella-unnationally.ngrok-free.dev/api/v1";
  final _storage = const FlutterSecureStorage();

  // Biến lưu user hiện tại để dùng toàn app
  static UserModel? currentUser;

  // login
  Future<bool> login(String phoneNumber, String password) async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        print(
          "=== DEBUG LOGIN (Attempt ${retryCount + 1}/${maxRetries + 1}) ===",
        );
        print("Endpoint: $baseUrl/auth/login");
        print("Phone: $phoneNumber");

        final uri = Uri.parse('$baseUrl/auth/login');

        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'ngrok-skip-browser-warning': 'true',
                'User-Agent': 'BetterUS-Mobile-App',
              },
              body: jsonEncode({
                'phoneNumber': phoneNumber,
                'password': password,
              }),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Kết nối đến server quá lâu. Vui lòng thử lại');
              },
            );

        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);

          if (data['accessToken'] == null) {
            throw Exception('Không nhận được token từ server');
          }

          await _storage.write(key: 'token', value: data['accessToken']);
          print("✅ Token đã lưu");

          // ĐỢI lấy xong data user rồi mới báo thành công
          UserModel? loadedUser = await getMe();

          if (loadedUser == null) {
            throw Exception('Không thể lấy thông tin người dùng');
          }

          print("✅ Login thành công: ${loadedUser.profile?.fullName}");
          return true;
        } else {
          // lay loi tu backend
          try {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['message'] ?? 'Đăng nhập thất bại';
            throw Exception(errorMessage);
          } catch (e) {
            throw Exception(
              'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin',
            );
          }
        }
      } on SocketException catch (e) {
        // Lỗi kết nối - retry nếu còn lượt
        print("⚠️ Connection error (attempt ${retryCount + 1}): $e");

        if (retryCount < maxRetries) {
          retryCount++;
          print("🔄 Retrying in 2 seconds...");
          await Future.delayed(const Duration(seconds: 2));
          continue; // Thử lại
        } else {
          // Hết lượt retry
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra:\n'
            '1. Kết nối internet\n'
            '2. Backend server đang chạy\n'
            '3. Ngrok URL còn hoạt động',
          );
        }
      } on TimeoutException {
        if (retryCount < maxRetries) {
          retryCount++;
          print("🔄 Timeout, retrying in 2 seconds...");
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          throw Exception('Kết nối đến server quá lâu. Vui lòng thử lại');
        }
      } catch (e) {
        print("❌ Login error: $e");
        rethrow; // Ném lại exception để login.dart bắt được
      }
    }

    // Không bao giờ đến đây nhưng Dart yêu cầu return
    throw Exception('Đăng nhập thất bại');
  }

  Future<UserModel?> getMe() async {
    try {
      String? token = await _storage.read(key: 'token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // xac thuc hs256
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        currentUser = UserModel.fromJson(userData);
        return currentUser;
      }
      return null;
    } catch (e) {
      print("Lỗi API getMe: $e"); //console 
      return null;
    }
  }

  Future<void> logout() async {
    // Ngắt kết nối socket trước khi xóa token
    // Tránh việc Singleton ChatSocketService giữ lại token cũ
    ChatSocketService().disconnect();
    await _storage.delete(key: 'token');
    currentUser = null;
  }

  Future<String?> getRole() async {
    if (currentUser == null) {
      await getMe();
    }
    return currentUser?.role;
  }

  Future<String?> getToken() async {
    try {
      // Đọc giá trị với key là 'token' từ bộ nhớ bảo mật
      String? token = await _storage.read(key: 'token');

      // Debug để kiểm tra xem đã lấy được token chưa (nên xóa khi release)
      print(
        "DEBUG: Lấy Token thành công: ${token != null ? 'Đã có' : 'Trống'}",
      );

      return token;
    } catch (e) {
      print("DEBUG: Lỗi khi đọc Token từ storage: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(
          response.body,
        ); 
      }
      print("Lỗi Register: ${response.body}");
      return null;
    } catch (e) {
      print("Lỗi kết nối: $e");
      return null;
    }
  }

  Future<bool> createBeneficiaryProfile({
    required String token,
    required String fullName,
    required String vulnerabilityType,
    String? situationDescription,
    String? guardianName,
    String? guardianPhone,
    String? guardianRelation,
    required File avatarUrl,
    required File cccdFront,
    required File cccdBack,
    List<File>? proofFiles,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/auth/profile/ncgd'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['fullName'] = fullName;
      request.fields['vulnerabilityType'] = vulnerabilityType;

      if (situationDescription != null && situationDescription.isNotEmpty) {
        request.fields['situationDescription'] = situationDescription;
      }
      if (guardianName != null && guardianName.isNotEmpty) {
        request.fields['guardianName'] = guardianName;
      }
      if (guardianPhone != null && guardianPhone.isNotEmpty) {
        request.fields['guardianPhone'] = guardianPhone;
      }
      if (guardianRelation != null && guardianRelation.isNotEmpty) {
        request.fields['guardianRelation'] = guardianRelation;
      }

      // 2. Nén và thêm các File bắt buộc
      // Việc nén giúp tránh lỗi "File size too large" từ Cloudinary
      final File compressedAvatar = await compressFile(avatarUrl);
      final File compressedFront = await compressFile(cccdFront);
      final File compressedBack = await compressFile(cccdBack);

      request.files.add(
        await http.MultipartFile.fromPath('avatarUrl', compressedAvatar.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('cccdFront', compressedFront.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('cccdBack', compressedBack.path),
      );

      // 3. Nén và thêm danh sách File minh chứng (Array)
      if (proofFiles != null && proofFiles.isNotEmpty) {
        for (var file in proofFiles) {
          final File compressedProof = await compressFile(file);
          request.files.add(
            await http.MultipartFile.fromPath(
              'proofFiles',
              compressedProof.path,
            ),
          );
        }
      }
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Lỗi từ Server (${response.statusCode}): $respStr");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối API: $e");
      return false;
    }
  }

  Future<bool> updateVolunteerProfile({
    required String token,
    required String fullName,
    required String bio,
    required int experienceYears,
    List<String>? skills,
    List<String>? preferredDistricts,
    File? avatar,
    File? cccdFront,
    File? cccdBack,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/users/profile/volunteer'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // QUAN TRỌNG: Chỉ gửi field nếu có giá trị
      request.fields['fullName'] = fullName;

      // Bio - chỉ gửi nếu không empty
      if (bio.isNotEmpty) {
        request.fields['bio'] = bio;
      }

      request.fields['experienceYears'] = experienceYears.toString();

      // FIXED: Gửi skills dưới dạng comma-separated string
      // Backend Transform decorator sẽ parse "LOGISTICS,TEACHING" thành array
      if (skills != null && skills.isNotEmpty) {
        request.fields['skills'] = skills.join(',');
        print("DEBUG: Skills sent: ${skills.join(',')}");
      }

      // FIXED: Gửi preferredDistricts dưới dạng comma-separated string
      if (preferredDistricts != null && preferredDistricts.isNotEmpty) {
        request.fields['preferredDistricts'] = preferredDistricts.join(',');
        print("DEBUG: Districts sent: ${preferredDistricts.join(',')}");
      }

      if (avatar != null) {
        final compressed = await compressFile(avatar);
        request.files.add(
          await http.MultipartFile.fromPath('avatarUrl', compressed.path),
        );
        print("DEBUG: Avatar attached");
      }
      if (cccdFront != null) {
        final compressed = await compressFile(cccdFront);
        request.files.add(
          await http.MultipartFile.fromPath('cccdFront', compressed.path),
        );
        print("DEBUG: CCCD Front attached");
      }
      if (cccdBack != null) {
        final compressed = await compressFile(cccdBack);
        request.files.add(
          await http.MultipartFile.fromPath('cccdBack', compressed.path),
        );
        print("DEBUG: CCCD Back attached");
      }

      print("=== DEBUG VOLUNTEER UPDATE ===");
      print("Endpoint: $baseUrl/users/profile/volunteer");
      print("Fields: ${request.fields}");
      print("Files count: ${request.files.length}");

      var response = await request.send();

      if (response.statusCode == 200) {
        print("✅ Volunteer Update Success");
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("❌ Volunteer Update FAILED (${response.statusCode})");
        print("Response: $respStr");
        return false;
      }
    } catch (e) {
      print("❌ Exception in updateVolunteerProfile: $e");
      return false;
    }
  }

  Future<bool> createVolunteerProfile({
    required String token,
    required String fullName,
    required int experienceYears,

    String? bio,

    required File avatarUrl,
    required File cccdFront,
    required File cccdBack,
  }) async {
    try {
      // 1. Khởi tạo request PUT với đường dẫn chính xác cho TNV
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/auth/profile/tnv'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['fullName'] = fullName;
      request.fields['experienceYears'] = experienceYears.toString();

      if (bio != null && bio.isNotEmpty) {
        request.fields['bio'] = bio;
      }

      final File compressedAvatar = await compressFile(avatarUrl);
      final File compressedFront = await compressFile(cccdFront);
      final File compressedBack = await compressFile(cccdBack);

      request.files.add(
        await http.MultipartFile.fromPath('avatarUrl', compressedAvatar.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('cccdFront', compressedFront.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('cccdBack', compressedBack.path),
      );

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Lỗi từ Server TNV (${response.statusCode}): $respStr");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối API TNV: $e");
      return false;
    }
  }

  Future<bool> updateBeneficiaryProfile({
    required String token,
    String? fullName,
    String? vulnerabilityType,
    String? situationDescription,
    String? healthCondition,
    String? guardianName,
    String? guardianPhone,
    String? guardianRelation,
    File? avatar,
    File? cccdFront,
    File? cccdBack,
    List<File>? proofFiles,
    List<String>? keepingProofFiles,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/users/profile/benificiary'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Text fields
      if (fullName != null && fullName.isNotEmpty) {
        request.fields['fullName'] = fullName;
      }
      if (vulnerabilityType != null && vulnerabilityType.isNotEmpty) {
        request.fields['vulnerabilityType'] = vulnerabilityType;
      }
      if (situationDescription != null && situationDescription.isNotEmpty) {
        request.fields['situationDescription'] = situationDescription;
      }
      if (healthCondition != null && healthCondition.isNotEmpty) {
        request.fields['healthCondition'] = healthCondition;
      }
      if (guardianName != null && guardianName.isNotEmpty) {
        request.fields['guardianName'] = guardianName;
      }
      if (guardianPhone != null && guardianPhone.isNotEmpty) {
        request.fields['guardianPhone'] = guardianPhone;
      }
      if (guardianRelation != null && guardianRelation.isNotEmpty) {
        request.fields['guardianRelation'] = guardianRelation;
      }

      // keepingProofFiles (array of URLs)
      if (keepingProofFiles != null && keepingProofFiles.isNotEmpty) {
        for (var url in keepingProofFiles) {
          request.fields['keepingProofFiles[]'] = url;
        }
      }

      // File uploads
      if (avatar != null) {
        final compressed = await compressFile(avatar);
        request.files.add(
          await http.MultipartFile.fromPath('avatarUrl', compressed.path),
        );
      }
      if (cccdFront != null) {
        final compressed = await compressFile(cccdFront);
        request.files.add(
          await http.MultipartFile.fromPath('cccdFront', compressed.path),
        );
      }
      if (cccdBack != null) {
        final compressed = await compressFile(cccdBack);
        request.files.add(
          await http.MultipartFile.fromPath('cccdBack', compressed.path),
        );
      }
      if (proofFiles != null && proofFiles.isNotEmpty) {
        for (var file in proofFiles) {
          final compressed = await compressFile(file);
          request.files.add(
            await http.MultipartFile.fromPath('proofFiles', compressed.path),
          );
        }
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Lỗi từ Server NCGD (${response.statusCode}): $respStr");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối API NCGD: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      String? token = await getToken(); // Sử dụng hàm getToken có sẵn của bạn
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        // Cập nhật lại biến static currentUser để đồng bộ toàn app
        currentUser = UserModel.fromJson(userData);

        return userData; // Trả về Map để bạn dễ truy cập sâu vào các trường
      } else {
        print("Lỗi lấy Profile: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Lỗi API getMyProfile: $e");
      return null;
    }
  }
}
