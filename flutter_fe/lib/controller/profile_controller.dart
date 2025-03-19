import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import '../model/user_model.dart';
import '../service/api_service.dart';
import '../model/tasker_model.dart';
import '../model/auth_user.dart';

class ProfileController {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  // Fetched user inputs End

  //Tasker Text Controller
  final TextEditingController bioController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController taskerAddressController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController wageController = TextEditingController();
  final TextEditingController tesdaController = TextEditingController();
  final TextEditingController socialMediaeController = TextEditingController();

  //Client Text Controller
  final TextEditingController prefsController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();

  //Client Text Controller

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email";
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a password";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters long";
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one uppercase letter";
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number";
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }
    if (value != passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "Please enter your $fieldName";
    }
    if (value.length < 2) {
      return "$fieldName must be at least 2 characters long";
    }
    return null;
  }

  Future<void> registerUser(BuildContext context) async {
    // Validate all fields
    String? emailError = validateEmail(emailController.text);
    String? passwordError = validatePassword(passwordController.text);
    String? confirmPasswordError =
        validateConfirmPassword(confirmPasswordController.text);
    String? firstNameError =
        validateName(firstNameController.text, "first name");
    String? lastNameError = validateName(lastNameController.text, "last name");

    // Check if there are any validation errors
    if (emailError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        firstNameError != null ||
        lastNameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError ??
              passwordError ??
              confirmPasswordError ??
              firstNameError ??
              lastNameError ??
              "Please fix the errors in the form"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      UserModel user = UserModel(
          firstName: firstNameController.text,
          middleName: middleNameController.text,
          lastName: lastNameController.text,
          email: emailController.text,
          password: passwordController.text,
          role: roleController.text,
          accStatus: 'Pending');

      Map<String, dynamic> resultData = await ApiService.registerUser(user);

      // Hide loading indicator
      Navigator.pop(context);

      if (resultData.containsKey("errors")) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text("Registration Failed"),
                  content: Text(resultData["errors"] ??
                      "Registration failed. Please try again."),
                  actions: [
                    TextButton(
                      child: Text("OK"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ));
      } else {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text("Registration Successful"),
                  content: Text(resultData["message"] ??
                      "Registration successful! Please check your email to verify your account."),
                  actions: [
                    TextButton(
                      child: Text("OK"),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WelcomePageViewMain())),
                    ),
                  ],
                ));
      }
    } catch (e) {
      Navigator.pop(context);

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("Error"),
                content: Text("An error occurred. Please try again later."),
                actions: [
                  TextButton(
                    child: Text("OK"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ));
    }
  }

  Future<int> verifyEmail(
      BuildContext context, String token, String email) async {
    try {
      final response = await ApiService.verifyEmail(token, email);

      if (response.containsKey("message")) {
        // Return the user_id for navigation
        return response["user_id"] as int;
      } else {
        throw Exception(response["error"] ?? "Verification failed");
      }
    } catch (e) {
      throw Exception("Failed to verify email: ${e.toString()}");
    }
  }

  Future<void> createTasker(BuildContext context) async {
    TaskerModel tasker = TaskerModel(
        bio: bioController.text,
        specialization: specializationController.text,
        skills: skillsController.text,
        taskerAddress: taskerAddressController.text,
        taskerDocuments: tesdaController.text,
        socialMediaLinks: socialMediaeController.text);

    //Code to create tasker information.
  }

  Future<AuthenticatedUser?> getAuthenticatedUser(
      BuildContext context, int userId) async {
    try {
      var result = await ApiService.fetchAuthenticatedUser(userId);
      debugPrint("Data: $result");

      if (result.containsKey("user")) {
        UserModel user = result["user"] as UserModel;

        if (result.containsKey("client")) {
          ClientModel client = result["client"] as ClientModel;
          return AuthenticatedUser(user: user, client: client);
        } else if (result.containsKey("tasker")) {
          TaskerModel tasker = result["tasker"] as TaskerModel;
          debugPrint("Retrieved Data: " + tasker.toString());
          return AuthenticatedUser(user: user, tasker: tasker);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["error"] ?? "Unknown error occurred.")),
      );
      return null;
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      return null;
    }
  }
}
