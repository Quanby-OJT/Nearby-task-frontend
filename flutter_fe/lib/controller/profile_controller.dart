import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_model.dart';
import '../model/user_model.dart';
import '../service/api_service.dart';
import '../model/tasker_model.dart';
import '../model/auth_user.dart';

class ProfileController {
  // Fetched user inputs Start
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



  // Byte for the image start
  // void setImage(File image, String name) {
  //   imageData = image;
  //   imageName = name;
  // }
  // Byte for the image end
  Future<void> registerUser(BuildContext context) async {
    if (passwordController.text.isEmpty ||
        firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }
// Validation if password not matched end

// Store the inputs Start
    UserModel user = UserModel(
        firstName: firstNameController.text,
        middleName: middleNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        password: passwordController.text,
        role: roleController.text,
        accStatus: 'Pending');
    bool success = await ApiService.registerUser(user);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultData["message"] ?? "Registration Successful! Please Check your Email to confirm your email."
          )
        ),
      );
    } else if (resultData.containsKey("errors")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            resultData["errors"] ?? "Please Check Your inputs and try again"
          )
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          resultData["error"] ?? "Registration Failed!")
        ),
      );
    }
  }

// In your ProfileController class (assuming this is where verifyEmail is defined)
// Update verifyEmail to return userId
  Future<int> verifyEmail(BuildContext context, String token, String email) async {
    try {
      // Your existing verification logic
      // Assuming this returns a response with userId after successful verification
      //debugPrint("Token : ${token}" + "Email: ${email}");
      final response = await ApiService.verifyEmail(token, email); // Modify this based on your actual implementation
      if (response.containsKey("message")) { // Adjust this condition based on your API response
        return response["user_id"]; // Return the userId from your API response
      }
      return 0;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
      return 0;
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
      BuildContext context, String userId) async {
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
