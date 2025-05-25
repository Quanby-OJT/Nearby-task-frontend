import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_fe/config/url_strategy.dart';

class LikeService {
  static final String url = apiUrl ?? "https://192.168.1.10:5000/connect";

  static Future<void> addLike(int userId, bool like, String likedBy) async {
    final String token = await AuthService.getSessionToken();
    final response = await http.post(
      Uri.parse("$url/likeJob"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "Authentication": "Bearer $token"
      },
      body: jsonEncode(<String, dynamic>{
        'user_id': userId,
        'like': like,
        'likedBy': likedBy,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add like');
    }
  }

  static Future<List<UserModel>> fetchLikedUsers(String likedBy) async {
    final response = await http.get(
      Uri.parse('$url/likes?likedBy=$likedBy'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => UserModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load liked users');
    }
  }
}
