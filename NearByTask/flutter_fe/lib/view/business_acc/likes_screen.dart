import 'package:flutter/material.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/like_service.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  List<UserModel> _likedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedUsers();
  }

  Future<void> _fetchLikedUsers() async {
    try {
      List<UserModel> likedUsers = await LikeService.fetchLikedUsers(
          'currentUserId'); // Replace 'currentUserId' with the actual current user ID
      setState(() {
        _likedUsers = likedUsers;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching liked users: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
            child: Text(
          'Available Services',
          style:
              TextStyle(color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
        )),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _likedUsers.length,
              itemBuilder: (context, index) {
                final user = _likedUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.image),
                  ),
                  title: Text(user.firstName,
                      style: TextStyle(color: Colors.black)),
                );
              },
            ),
    );
  }
}
