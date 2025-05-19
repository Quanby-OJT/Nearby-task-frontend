import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/document_model.dart';
import 'package:flutter_fe/service/profile_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/user_model.dart';
import '../service/api_service.dart';
import '../model/tasker_model.dart';
import '../model/auth_user.dart';
import '../view/custom_loading/statusModal.dart';

class ProfileController {
  //General Account Information
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController fbLinkController = TextEditingController();
  final TextEditingController instaLinkController = TextEditingController();
  final TextEditingController telegramLinkController = TextEditingController();

  // Fetched user inputs End

  //Tasker Text
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController taskerGroupController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController taskerAddressController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController wageController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController payPeriodController = TextEditingController();
  final TextEditingController specializationIdController =
      TextEditingController();

  // Address controllers
  final TextEditingController streetAddressController = TextEditingController();
  final TextEditingController barangayController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  final TaskerService taskerService = TaskerService();
  final TextEditingController accStatusController = TextEditingController();

  //Client Text Controller
  final TextEditingController prefsController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();
  final storage = GetStorage();

  void _showStatusModal({
    required BuildContext context,
    required bool isSuccess,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatusModal(
        isSuccess: isSuccess,
        message: message,
      ),
    );
  }

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
    if (value.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one uppercase letter";
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return "Password must contain at least one lowercase letter";
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number";
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return "Password must contain at least one special character";
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

  String? validateSpecialization(String? value) {
    if (value == null || value.isEmpty) {
      return "Please select your specialization";
    }
    return null;
  }

  String? validateWage(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your wage";
    }
    return null;
  }

  String? validatePaySchedule(String? value) {
    if (value == null || value.isEmpty) {
      return "Please select your pay schedule";
    }
    return null;
  }

  String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your bio";
    }
    return null;
  }

  String? validateSkills(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your skills";
    }
    return null;
  }

  String? validateRole(String? value) {
    if (value == null || value.isEmpty) {
      return "Please select your role";
    }
    return null;
  }

  String? validateSpecializationId(String? value) {
    if (value == null || value.isEmpty) {
      return "Please select your id";
    }
    return null;
  }

// Client field
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
    String? roleError = validateRole(roleController.text);

    // Check if there are any validation errors
    if (emailError != null ||
        firstNameError != null ||
        lastNameError != null ||
        contactError != null ||
        genderError != null ||
        birthdateError != null ||
        roleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError ??
              firstNameError ??
              lastNameError ??
              contactError ??
              genderError ??
              birthdateError ??
              roleError ??
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

      print('User data from updateUserData: ${user.toString()}');

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
    String? emailError = validateEmail(emailController.text);
    String? passwordError = validatePassword(passwordController.text);
    String? confirmPasswordError =
        validateConfirmPassword(confirmPasswordController.text);
    String? firstNameError =
        validateName(firstNameController.text, "first name");
    String? lastNameError = validateName(lastNameController.text, "last name");

    if (emailError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        firstNameError != null ||
        lastNameError != null) {
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: emailError ??
            passwordError ??
            confirmPasswordError ??
            firstNameError ??
            lastNameError ??
            "Please fix the errors in the form",
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CustomLoading(),
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

      Navigator.pop(context);

      if (resultData.containsKey("errors")) {
        showDialog(
            context: context,
            builder: (context) => StatusModal(
                  title: "Registration Failed",
                  isSuccess: false,
                  message: resultData["errors"] ??
                      "Registration failed. Please try again.",
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
                      "Registration successful! Use a valid email to get your login code."),
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
        return response["user_id"] as int;
      } else {
        throw Exception(response["error"] ?? "Verification failed");
      }
    } catch (e) {
      throw Exception("Failed to verify email: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> updateTaskerNoImages(
      BuildContext context, UserModel user) async {
    try {
      // Validate fields
      String? contactError =
          validateContactNumber(contactNumberController.text);
      String? genderError = validateGender(genderController.text);
      String? birthdateError = validateBirthdate(birthdateController.text);
      String? specializationError =
          validateSpecialization(specializationController.text);
      String? wageError = validateWage(wageController.text);
      String? payScheduleError = validatePaySchedule(payPeriodController.text);
      String? bioError = validateBio(bioController.text);
      String? skillsError = validateSkills(skillsController.text);
      String? roleError = validateRole(roleController.text);
      String? specializationIdError =
          validateSpecializationId(specializationIdController.text);

      // Check if there are any validation errors
      if (contactError != null ||
          genderError != null ||
          birthdateError != null ||
          specializationError != null ||
          wageError != null ||
          payScheduleError != null ||
          bioError != null ||
          skillsError != null ||
          roleError != null ||
          specializationIdError != null) {
        return {
          "errors": contactError ??
              genderError ??
              birthdateError ??
              specializationError ??
              wageError ??
              payScheduleError ??
              roleError ??
              bioError ??
              skillsError ??
              specializationIdError ??
              "Please fix the errors in the form"
        };
      }

      Map<String, dynamic> result =
          await ApiService.updateTaskerProfileNoImages(
        user.id ?? 0, // Use 0 as fallback if id is null
        {
          "first_name": user.firstName,
          "middle_name": user.middleName ?? '',
          "last_name": user.lastName,
          "email": user.email,
          "user_role": user.role,
          "contact": user.contact ?? '',
          "gender": user.gender ?? '',
          "birthdate": user.birthdate ?? '',
          "specialization": specializationIdController.text,
          "bio": bioController.text,
          "skills": skillsController.text,
          "wage_per_hour": wageController.text,
          "pay_period": payPeriodController.text,
        },
      );

      return result;
    } catch (e) {
      return {"errors": "Error updating profile: $e"};
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
          //Client
          ClientModel client = result["client"] as ClientModel;
          debugPrint("User is a client and has client data: $client");
          return AuthenticatedUser(user: user, client: client);
        } else if (result.containsKey("tasker")) {
          TaskerModel tasker = result["tasker"] as TaskerModel;
          //Tasker
          debugPrint("User is a tasker and has tasker data: $tasker $user");

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

  // Fetching document link from database
  Future<DocumentInfo?> getDocumentLink(int documentId) async {
    final response = await taskerService.getDocumentLink(documentId);
    if (response.containsKey("data")) {
      return DocumentInfo.fromMap(response["data"] as Map<String, dynamic>);
    }
    return null;
  }

  // this is for tasker with only Profile image
  Future<Map<String, dynamic>> updateTaskerWithOnlyProfileImage2nd(
      BuildContext context, UserModel user, File image) async {
    try {
      // Validate fields
      String? contactError =
          validateContactNumber(contactNumberController.text);
      String? genderError = validateGender(genderController.text);
      String? birthdateError = validateBirthdate(birthdateController.text);
      String? specializationError =
          validateSpecialization(specializationController.text);
      String? wageError = validateWage(wageController.text);
      String? payScheduleError = validatePaySchedule(payPeriodController.text);
      String? bioError = validateBio(bioController.text);
      String? skillsError = validateSkills(skillsController.text);
      String? roleError = validateRole(roleController.text);
      String? specializationIdError =
          validateSpecializationId(specializationIdController.text);

      // Check if there are any validation errors
      if (contactError != null ||
          genderError != null ||
          birthdateError != null ||
          specializationError != null ||
          wageError != null ||
          payScheduleError != null ||
          bioError != null ||
          skillsError != null ||
          roleError != null ||
          specializationIdError != null) {
        return {
          "errors": contactError ??
              genderError ??
              birthdateError ??
              specializationError ??
              wageError ??
              payScheduleError ??
              roleError ??
              bioError ??
              skillsError ??
              specializationIdError ??
              "Please fix the errors in the form"
        };
      }

      // Call API service to update user without images
      Map<String, dynamic> result =
          await ApiService.updateTaskerProfileWithImageTobackend(
        user.id ?? 0, image, // Use 0 as fallback if id is null
        {
          "first_name": user.firstName,
          "middle_name": user.middleName ?? '',
          "last_name": user.lastName,
          "email": user.email,
          "user_role": user.role,
          "contact": user.contact ?? '',
          "gender": user.gender ?? '',
          "birthdate": user.birthdate ?? '',
          "specialization": specializationIdController.text,
          "bio": bioController.text,
          "skills": skillsController.text,
          "wage_per_hour": wageController.text,
          "pay_period": payPeriodController.text,
        },
      );

      return result;
    } catch (e) {
      return {"errors": "Error updating profile: $e"};
    }
  }

  // this is for tasker with only PDF
  Future<Map<String, dynamic>> updateTaskerOnlyPdf(
      BuildContext context, UserModel user, File file) async {
    try {
      // Validate fields
      String? contactError =
          validateContactNumber(contactNumberController.text);
      String? genderError = validateGender(genderController.text);
      String? birthdateError = validateBirthdate(birthdateController.text);
      String? specializationError =
          validateSpecialization(specializationController.text);
      String? wageError = validateWage(wageController.text);
      String? payScheduleError = validatePaySchedule(payPeriodController.text);
      String? bioError = validateBio(bioController.text);
      String? skillsError = validateSkills(skillsController.text);
      String? roleError = validateRole(roleController.text);
      String? specializationIdError =
          validateSpecializationId(specializationIdController.text);

      // Check if there are any validation errors
      if (contactError != null ||
          genderError != null ||
          birthdateError != null ||
          specializationError != null ||
          wageError != null ||
          payScheduleError != null ||
          bioError != null ||
          skillsError != null ||
          roleError != null ||
          specializationIdError != null) {
        return {
          "errors": contactError ??
              genderError ??
              birthdateError ??
              specializationError ??
              wageError ??
              payScheduleError ??
              roleError ??
              bioError ??
              skillsError ??
              specializationIdError ??
              "Please fix the errors in the form"
        };
      }

      // Call API service to update user without images
      Map<String, dynamic> result = await ApiService.updateTaskerProfileWithPdf(
        user.id ?? 0, file, // Use 0 as fallback if id is null
        {
          "first_name": user.firstName,
          "middle_name": user.middleName ?? '',
          "last_name": user.lastName,
          "email": user.email,
          "user_role": user.role,
          "contact": user.contact ?? '',
          "gender": user.gender ?? '',
          "birthdate": user.birthdate ?? '',
          "specialization": specializationIdController.text,
          "bio": bioController.text,
          "skills": skillsController.text,
          "wage_per_hour": wageController.text,
          "pay_period": payPeriodController.text,
        },
      );

      return result;
    } catch (e) {
      return {"errors": "Error updating profile: $e"};
    }
  }

  // this is for tasker with profile and PDF
  Future<Map<String, dynamic>> updateTaskerWithFiles(
      BuildContext context, int userId, File file, File image) async {
    try {
      // Validate fields
      String? contactError =
          validateContactNumber(contactNumberController.text);
      String? genderError = validateGender(genderController.text);
      String? birthdateError = validateBirthdate(birthdateController.text);
      String? specializationError =
          validateSpecialization(specializationController.text);
      String? wageError = validateWage(wageController.text);
      String? payScheduleError = validatePaySchedule(payPeriodController.text);
      String? bioError = validateBio(bioController.text);
      String? skillsError = validateSkills(skillsController.text);
      String? roleError = validateRole(roleController.text);
      String? specializationIdError =
          validateSpecializationId(specializationController.text);

      // Check if there are any validation errors
      if (contactError != null ||
          genderError != null ||
          birthdateError != null ||
          specializationError != null ||
          wageError != null ||
          payScheduleError != null ||
          bioError != null ||
          skillsError != null ||
          roleError != null ||
          specializationIdError != null) {
        return {
          "errors": contactError ??
              genderError ??
              birthdateError ??
              specializationError ??
              wageError ??
              payScheduleError ??
              roleError ??
              bioError ??
              skillsError ??
              specializationIdError ??
              "Please fix the errors in the form"
        };
      }

      UserModel user = UserModel(
        id: userId,
        firstName: firstNameController.text,
        middleName: middleNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        role: roleController.text,
        birthdate: birthdateController.text,
        contact: contactNumberController.text,
        gender: genderController.text,
        image: imageController.text,
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

      // Call API service to update user without images
      Map<String, dynamic> result =
          await ApiService.updateTaskerProfileWithFiles(
        userId, file, image, // Use 0 as fallback if id is null
        {
          "first_name": user.firstName,
          "middle_name": user.middleName ?? '',
          "last_name": user.lastName,
          "email": user.email,
          "user_role": user.role,
          "contact": user.contact ?? '',
          "gender": user.gender ?? '',
          "birthdate": user.birthdate ?? '',
          "specialization": specializationController.text,
          "bio": bioController.text,
          "skills": skillsController.text,
          "wage_per_hour": wageController.text,
          "pay_period": payPeriodController.text,
        },
      );

      return result;
    } catch (e) {
      return {"errors": "Error updating profile: $e"};
    }
  }

  // This is a tasker with pdf and profile
  Future<void> updateTaskerWithOnlyProfileImage1st(
      BuildContext context, int userId, File image) async {
    try {
      // Create user model with current data
      UserModel user = UserModel(
        id: userId,
        firstName: firstNameController.text,
        middleName: middleNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        role: roleController.text,
        birthdate: birthdateController.text,
        contact: contactNumberController.text,
        gender: genderController.text,
        image: imageController.text,
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

      // Call API service to update tasker profile without images
      Map<String, dynamic> result =
          await updateTaskerWithOnlyProfileImage2nd(context, user, image);

      // Close loading indicator
      Navigator.pop(context);

      if (result.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["errors"] ??
                "Failed to update profile. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home page or refresh the current page
        Navigator.pop(context);
      }
    } catch (e) {}
  }

  // This is for tasker with only PDf file
  Future<void> updateTaskerWithOnlyPdfFile(
      BuildContext context, int userId, File file) async {
    try {
      // Create user model with current data
      UserModel user = UserModel(
        id: userId,
        firstName: firstNameController.text,
        middleName: middleNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        role: roleController.text,
        birthdate: birthdateController.text,
        contact: contactNumberController.text,
        gender: genderController.text,
        image: imageController.text,
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

      // Call API service to update tasker profile without images
      Map<String, dynamic> result =
          await updateTaskerOnlyPdf(context, user, file);

      // Close loading indicator
      Navigator.pop(context);

      if (result.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["errors"] ??
                "Failed to update profile. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home page or refresh the current page
        Navigator.pop(context);
      }
    } catch (e) {}
  }

  Future<void> updateTaskerInfo(
      BuildContext context, int userId, File? file, File? image) async {
    // Create user model with current data

    try {
      // Create user model with current data
      UserModel user = UserModel(
        firstName: firstNameController.text.trim(),
        middleName: middleNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        role: roleController.text.trim(),
        birthdate: birthdateController.text.trim(),
        contact: contactNumberController.text.trim(),
        gender: genderController.text.trim(),
      );

      TaskerModel tasker = TaskerModel(
          id: userId,
          bio: bioController.text.trim(),
          specialization: specializationIdController.text.trim(),
          skills: skillsController.text.trim(),
          availability: availabilityController.text.trim() == 'true',
          wage: double.tryParse(wageController.text.trim()) ?? 0.0,
          payPeriod: payPeriodController.text.trim(),
          group: taskerGroupController.text.trim() == 'true',
          birthDate: DateTime.parse(birthdateController.text),
          user: user,
          rating: 0);

      AddressModel address = AddressModel(
        id: userId.toString(),
        streetAddress: streetAddressController.text.trim(),
        barangay: barangayController.text.trim(),
        city: cityController.text.trim(),
        province: provinceController.text.trim(),
        postalCode: postalCodeController.text.trim(),
        country: countryController.text.trim(),
      );

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      Map<String, dynamic> result = await taskerService
          .updateTaskerInfoWithFiles(tasker, address, file, image);

      // Close loading dialog
      Navigator.pop(context);

      if (result.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["errors"]),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"]),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Navigate back or refresh
        Navigator.pop(context);
      }
    } catch (e) {
      // Ensure loading dialog is closed in case of exception
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // This is for tasker without profile and PDF
  Future<void> updateTaskerWithoutFile(BuildContext context, int userId) async {
    try {
      // Create user model with current data
      UserModel user = UserModel(
        id: userId,
        firstName: firstNameController.text,
        middleName: middleNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        role: roleController.text,
        birthdate: birthdateController.text,
        contact: contactNumberController.text,
        gender: genderController.text,
        image: imageController.text,
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

      // Call API service to update tasker profile without images
      Map<String, dynamic> result = await updateTaskerNoImages(context, user);

      // Close loading indicator
      Navigator.pop(context);

      if (result.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["errors"] ??
                "Failed to update profile. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home page or refresh the current page
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateUser(
    BuildContext context,
    int taskerId,
    List<dynamic> documentFile,
    File profileImage,
  ) async {
    // Check if the widget is still mounted before proceeding
    if (!context.mounted) return;

    String role = await storage.read('role');
    debugPrint("TESDA File: $documentFile");
    debugPrint("Profile Image: $profileImage");

    UserModel user = UserModel(
      firstName: '',
      middleName: '',
      lastName: '',
      email: '',
      role: role,
      accStatus: '',
      gender: genderController.text,
    );

    Map<String, String> socials = {
      "fb": fbLinkController.text,
      "ig": instaLinkController.text,
      "tg": telegramLinkController.text,
    };

    if (role == 'Client') {
      ClientModel client = ClientModel(
        preferences: prefsController.text,
        clientAddress: clientAddressController.text,
      );

      Map<String, dynamic> resultData =
          await ProfileService.updateClient(client, user, profileImage);

      // Check if widget is still mounted before showing SnackBar
      if (!context.mounted) return;

      if (resultData.containsKey("message")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultData['message'])),
        );
      } else if (resultData.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultData['errors'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultData['error'])),
        );
      }
    } else if (role == 'Tasker') {
      String cleanedWage = wageController.text
          .replaceAll('₱', '') // Remove currency symbol
          .replaceAll(',', ''); // Remove thousands separator

      Map<String, String> address = {
        "street_address": streetAddressController.text,
        "barangay": barangayController.text,
        "city": cityController.text,
        "province": provinceController.text,
        "postal_code": postalCodeController.text,
        "country": countryController.text,
      };

      TaskerModel tasker = TaskerModel(
          id: taskerId,
          bio: bioController.text,
          group: false,
          specialization: specializationController.text,
          skills: skillsController.text,
          address: address,
          taskerDocuments: documentFile.toString(),
          availability:
              availabilityController.text == "I am available" ? true : false,
          socialMediaLinks: socials,
          wage: double.parse(cleanedWage),
          payPeriod: payPeriodController.text,
          birthDate: DateTime.parse(birthdateController.text),
          user: null,
          rating: 0);

      Map<String, dynamic> resultData = await ProfileService.updateTasker(
          tasker, user, documentFile, profileImage);

      if (!context.mounted) return;

      if (resultData.containsKey("message")) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: Text(
              resultData['message'],
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: Text("Dismiss"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: Text(
              resultData['error'] ??
                  "An Error Occurred while Updating Your Profile Information. Please Try Again.",
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: Text("Dismiss"),
              ),
            ],
          ),
        );
      }
    }
  }
}
