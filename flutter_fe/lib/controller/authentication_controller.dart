import 'package:flutter/material.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/fill_up/fill_up_tasker.dart';
import 'package:flutter_fe/view/sign_in/otp_screen.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get_storage/get_storage.dart';

class AuthenticationController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  int userId;
  final storage = GetStorage();
  AuthenticationController({this.userId = 0});

  Future<void> loginAuth(BuildContext context) async {
    var response = await ApiService.authUser(
        emailController.text, passwordController.text);

    if (response.containsKey('user_id')) {
      userId = response['user_id'];
      // Store user ID temporarily until OTP verification
      storage.write('temp_user_id', userId.toString());
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(userId: userId),
        ),
      );
    } else if (response.containsKey('validation_error')) {
      String errorMessage =
          response['validation_error'] ?? "Unknown error occurred";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      // Display the error message using SnackBar
      String errorMessage = response['error'] ?? "Unknown error occurred";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> resetOTP(BuildContext context) async {
    var response = await ApiService.regenerateOTP(userId);

    if (response.containsKey('message')) {
      String messageReset = response['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageReset)),
      );
    } else {
      String errorMessage = response['error'] ?? "Unknown error occurred";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> otpAuth(BuildContext context) async {
    var response = await ApiService.authOTP(userId, otpController.text);
    debugPrint(response.toString());

    if(response.containsKey('user_id') && response.containsKey('role') && response.containsKey('session')){
      await storage.write('user_id', response['user_id']);
      await storage.write('role', response['role']); //If the user is logged in to the app, this will be the determinant if where they will be assigned.
      await storage.write('session', response['session']);
      if(response['role'] == "Client"){
        Navigator.push(context, MaterialPageRoute(builder: (context){
          return BusinessAccMain();
        }));
      }else if(response['role'] == "Tasker"){
        Navigator.push(context, MaterialPageRoute(builder: (context){
          return ServiceAccMain();
        }));
      }
    }else if(response.containsKey('validation_error')){
      String error = response['validation_error'] ?? "OTP Authentication Failed.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      String error = response['error'] ?? "OTP Authentication Failed.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    var response = await ApiService.logout(await storage.read('user_id'), storage.read('session'));

    if (response.containsKey('message')) {
      await storage.remove('user_id');
      await storage.remove('role');
      await storage.remove('session');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) => WelcomePageViewMain()), (route) => false
      );
    }else{
      String error = response['error'] ?? "Failed to Log Out the User.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}
