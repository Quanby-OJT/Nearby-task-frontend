import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:get_storage/get_storage.dart';
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
  final TextEditingController confirmPasswordController =TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController taskerGroupController = TextEditingController();
  // Fetched user inputs End

  //Tasker Text Controller
  final TextEditingController bioController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController taskerAddressController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController wageController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController payPeriodController = TextEditingController();

  //Client Text Controller
  final TextEditingController prefsController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();
  final storage = GetStorage();



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
        emailController.text.isEmpty ||
      passwordController.text.isEmpty) {
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

    Map<String, dynamic> resultData = await ApiService.registerUser(user);
    if (resultData.containsKey("message")) {
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

  Future<int> verifyEmail(BuildContext context, String token, String email) async {
    try {
      final response = await ApiService.verifyEmail(token, email);
      if (response.containsKey("message")) {
        await storage.write("session", response["token"]);
        await storage.write("user_id", response["user_id"]);
        return response["user_id"];
      }
      return 0;
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed. Please Try Again.')),
      );
      return 0;
    }
  }


  Future<void> createTasker(BuildContext context, String specialization, String gender, String image, String tesdaFile, File documentFile, File profileImage) async {
     if (birthdateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your birthdate')),
      );
      return;
    }
    DateTime birthDate = DateTime.parse(birthdateController.text);
    DateTime eighteenYearsAgo = DateTime.now().subtract(Duration(days: 18 * 365));
    if (birthDate.isAfter(eighteenYearsAgo)) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be at least 18 years old to register')),
      );
      return;
    }

    TaskerModel tasker = TaskerModel(
      bio: bioController.text,
      specialization: specialization,
      skills: skillsController.text,
      taskerAddress: taskerAddressController.text,
      taskerDocuments: tesdaFile,
      socialMediaLinks: socialMediaController.text,
      availability: false,
      wage: double.tryParse(wageController.text) ?? 0,
      group: false,
      phoneNumber: contactNumberController.text,
      gender: gender,
      payPeriod: "Hourly",
      birthDate: DateTime.parse(birthdateController.text)
    );

    //Code to create tasker information.
    Map<String, dynamic> resultData = await ApiService.createTasker(tasker, documentFile, profileImage);

    if (resultData.containsKey('message')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultData['message'])),
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultData['error'])),
      );
    }
  }

  Future<AuthenticatedUser?> getAuthenticatedUser(BuildContext context, String userId) async {
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
