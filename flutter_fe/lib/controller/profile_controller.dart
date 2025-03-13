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
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

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
        return response["user_id"];
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
      socialMediaLinks: socialMediaeController.text,
      availability: false,
      wage: double.tryParse(wageController.text) ?? 0,
      group: false,
      phoneNumber: contactNumberController.text,
      gender: genderController.text,
      payPeriod: "Hourly",
      birthDate: DateTime.parse(birthdateController.text)
    );

    //Code to create tasker information.
    Map<String, dynamic> resultData = await ApiService.createTasker(tasker);

    if (resultData.containsKey('message')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultData['message'])),
      );
    }
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
