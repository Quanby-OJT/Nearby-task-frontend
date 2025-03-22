import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get_storage/get_storage.dart';
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
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController taskerGroupController = TextEditingController();
  // Fetched user inputs End

  //Tasker Text Controller
  final TextEditingController bioController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController taskerAddressController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController wageController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController payPeriodController = TextEditingController();
  final TextEditingController accStatusController = TextEditingController();

  //Client Text Controller
  final TextEditingController prefsController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();
  final storage = GetStorage();

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

  String? validateLastName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "Please enter your $fieldName";
    }
    if (value.length < 2) {
      return "$fieldName must be at least 2 characters long";
    }
    return null;
  }

  String? validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your contact number";
    }

    if (value[0] != '0' && value[1] != '9') {
      return "Contact number must start with 09";
    }
    if (value.length != 11) {
      return "Contact number must be 11 digits";
    }
    return null;
  }

  String? validateBirthdate(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your birthdate";
    }
    DateTime birthDate = DateTime.parse(value);
    if (birthDate.isAfter(DateTime.now())) {
      return "Birthdate cannot be in the future";
    }
    return null;
  }

  String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return "Please select your gender";
    }
    return null;
  }

  Future<void> updateUserData(BuildContext context, userId) async {
    print('Updating user data');

    // Validate all fields
    String? emailError = validateEmail(emailController.text);
    String? firstNameError =
        validateName(firstNameController.text, "first name");
    String? lastNameError = validateName(lastNameController.text, "last name");
    String? contactError = validateContactNumber(contactNumberController.text);
    String? genderError = validateGender(genderController.text);
    String? birthdateError = validateBirthdate(birthdateController.text);

    // Check if there are any validation errors
    if (emailError != null ||
        firstNameError != null ||
        lastNameError != null ||
        contactError != null ||
        genderError != null ||
        birthdateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError ??
              firstNameError ??
              lastNameError ??
              contactError ??
              genderError ??
              birthdateError ??
              "Please fix the errors in the form"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      UserModel user = UserModel(
        id: userId,
        firstName: firstNameController.text,
        middleName: middleNameController.text.isNotEmpty
            ? middleNameController.text
            : null,
        lastName: lastNameController.text,
        email: emailController.text,
        role: roleController.text,
        birthdate: birthdateController.text,
        contact: contactNumberController.text,
        gender: genderController.text,
      );

      print('User data from updateUserData: ${user.toString()}');

      Map<String, dynamic> resultData = await ApiService.updateUser(user);

      if (resultData.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultData["errors"] ??
                "Failed to update user. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating user: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateUserWithImage(
      BuildContext context, userId, File profileImage) async {
    try {
      // Validate fields
      String? emailError = validateEmail(emailController.text);
      String? firstNameError =
          validateName(firstNameController.text, "first name");
      String? lastNameError =
          validateName(lastNameController.text, "last name");

      // Check if there are any validation errors
      if (emailError != null ||
          firstNameError != null ||
          lastNameError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailError ??
                firstNameError ??
                lastNameError ??
                "Please fix the errors in the form"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create user model
      UserModel user = UserModel(
          id: userId,
          firstName: firstNameController.text,
          middleName: middleNameController.text,
          lastName: lastNameController.text,
          email: emailController.text,
          role: roleController.text,
          accStatus: accStatusController.text,
          birthdate: birthdateController.text,
          contact: contactNumberController.text,
          gender: genderController.text);

      // Call API service to update user with image
      Map<String, dynamic> resultData =
          await ApiService.updateUserWithProfileImage(user, profileImage);

      if (resultData.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultData["errors"] ??
                "Failed to update user with profile image. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User profile updated successfully with new image"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Error updating user with profile image: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateUserWithID(
      BuildContext context, userId, File idImage) async {
    try {
      // Validate fields
      String? emailError = validateEmail(emailController.text);
      String? firstNameError =
          validateName(firstNameController.text, "first name");
      String? lastNameError =
          validateName(lastNameController.text, "last name");

      // Check if there are any validation errors
      if (emailError != null ||
          firstNameError != null ||
          lastNameError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailError ??
                firstNameError ??
                lastNameError ??
                "Please fix the errors in the form"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create user model
      UserModel user = UserModel(
          id: userId,
          firstName: firstNameController.text,
          middleName: middleNameController.text,
          lastName: lastNameController.text,
          email: emailController.text,
          role: roleController.text,
          accStatus: accStatusController.text,
          birthdate: birthdateController.text,
          contact: contactNumberController.text,
          gender: genderController.text);

      // Call API service to update user with ID image
      Map<String, dynamic> resultData =
          await ApiService.updateUserWithIDImage(user, idImage);

      if (resultData.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultData["errors"] ??
                "Failed to update user with ID image. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("User profile updated successfully with new ID image"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating user with ID image: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateUserWithBothImages(
      BuildContext context, int userId, File profileImage, File idImage) async {
    try {
      // Validate fields
      String? emailError = validateEmail(emailController.text);
      String? firstNameError =
          validateName(firstNameController.text, "first name");
      String? lastNameError =
          validateName(lastNameController.text, "last name");
      String? contactError =
          validateContactNumber(contactNumberController.text);
      String? genderError = validateGender(genderController.text);
      String? birthdateError = validateBirthdate(birthdateController.text);

      // Check if there are any validation errors
      if (emailError != null ||
          firstNameError != null ||
          lastNameError != null ||
          contactError != null ||
          genderError != null ||
          birthdateError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailError ??
                firstNameError ??
                lastNameError ??
                contactError ??
                genderError ??
                birthdateError ??
                "Please fix the errors in the form"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create user model
      UserModel user = UserModel(
        id: userId,
        firstName: firstNameController.text,
        middleName: middleNameController.text.isNotEmpty
            ? middleNameController.text
            : null,
        lastName: lastNameController.text,
        email: emailController.text,
        role: roleController.text,
        birthdate: birthdateController.text,
        contact: contactNumberController.text,
        gender: genderController.text,
      );

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Call API service to update user with both images
      Map<String, dynamic> resultData =
          await ApiService.updateUserWithBothImages(
              user, profileImage, idImage);

      // Close loading indicator
      Navigator.pop(context);

      if (resultData.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultData["errors"] ??
                "Failed to update user with images. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultData["message"] ?? "User updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating user with images: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> createTasker(
      BuildContext context,
      String specialization,
      String gender,
      String image,
      String tesdaFile,
      File documentFile,
      File profileImage) async {
    if (birthdateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your birthdate')),
      );
      return;
    }
    DateTime birthDate = DateTime.parse(birthdateController.text);
    DateTime eighteenYearsAgo =
        DateTime.now().subtract(Duration(days: 18 * 365));
    if (birthDate.isAfter(eighteenYearsAgo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('You must be at least 18 years old to register')),
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
        birthDate: DateTime.parse(birthdateController.text));

    //Code to create tasker information.
    Map<String, dynamic> resultData =
        await ApiService.createTasker(tasker, documentFile, profileImage);

    if (resultData.containsKey('message')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultData['message'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultData['error'])),
      );
    }
  }

  Future<AuthenticatedUser?> getAuthenticatedUser(
      BuildContext context, int userId) async {
    try {
      var result = await ApiService.fetchAuthenticatedUser(userId);
      debugPrint("Data fetch from profile controller: $result");

      if (result.containsKey("user")) {
        UserModel user = result["user"] as UserModel;
        debugPrint("Retrieved Data: $user");

        if (result.containsKey("client")) {
          ClientModel client = result["client"] as ClientModel;
          debugPrint("Retrieved Data: $client");
          return AuthenticatedUser(user: user, client: client);
        } else if (result.containsKey("tasker")) {
          TaskerModel tasker = result["tasker"] as TaskerModel;

          debugPrint("Retrieved Data: $tasker");

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
