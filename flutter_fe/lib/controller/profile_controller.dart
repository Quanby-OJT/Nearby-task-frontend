import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/document_model.dart';
import 'package:flutter_fe/model/tasker_skills.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/user_model.dart';
import '../service/api_service.dart';
import '../model/tasker_model.dart';
import '../model/auth_user.dart';

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

  // Address controllers
  final TextEditingController streetAddressController = TextEditingController();
  final TextEditingController barangayController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  final TaskerService taskerService = TaskerService();
  final ClientServices clientService = ClientServices();
  final TextEditingController accStatusController = TextEditingController();

  final GetStorage storage = GetStorage();

  Future<void> registerUser(BuildContext context) async {
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
        accStatus: 'Pending',
      );

      Map<String, dynamic> resultData = await ApiService.registerUser(user);

      Navigator.pop(context);

      if (resultData.containsKey("errors")) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            title: Text(
              "Registration Failed",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              resultData["errors"] ?? "Registration failed. Please try again.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            actions: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: Text(
                      "OK",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB71A4A),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            title: Text(
              "Registration Successful",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: Text(
              resultData["message"] ??
                  "Registration successful! Use a valid email to get your login code.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            actions: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: const Color(0xFFB71A4A),
                    ),
                    child: TextButton(
                      child: Text(
                        "OK",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WelcomePageViewMain(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          title: Text(
            "Error",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "An error occurred. Please try again later.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text(
                    "OK",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB71A4A),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      );
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

  Future<AuthenticatedUser?> getAuthenticatedUser(int userId) async {
    try {
      debugPrint(
          "ProfileController: Calling fetchAuthenticatedUser with userId: $userId");
      var result = await ApiService().fetchAuthenticatedUser(userId);
      debugPrint("ProfileController: API result: $result");
      debugPrint("ProfileController: Result keys: ${result.keys.join(', ')}");

      if (result.containsKey("data")) {
        final data = result["data"];
        debugPrint("User Data: $data");
        if (data != null && data.containsKey("client")) {
          // For clients, use the user data as-is (bio and social_media_links are already in user)
          debugPrint("ProfileController: Processing client user");

          return AuthenticatedUser(
              user: UserModel.fromJson(data["user"]),
              isClient: true,
              isTasker: false,
              client: data['client'] != null
                  ? ClientModel.fromJson(data['client'])
                  : null);
        } else if (data != null && data.containsKey("tasker")) {
          // For taskers, we no longer merge data from tasker table
          // All verification data should come from user_verify table only
          debugPrint("ProfileController: Processing tasker user");
          debugPrint(data["tasker"].toString());
          return AuthenticatedUser(
            user: UserModel.fromJson(data["user"]),
            isClient: false,
            isTasker: true,
            tasker: data['tasker'] != null
                ? TaskerModel.fromJson(data['tasker'])
                : null,
          );
        } else {
          debugPrint("ProfileController: No client or tasker data found");
          return null;
        }
      } else {
        debugPrint("ProfileController: No user data in result");
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint("ProfileController: Error in getAuthenticatedUser: $e");
      debugPrintStack(stackTrace: stackTrace);
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

  Future<List<TaskerSkills>> getRelevantTaskerSkills(
      String specialization) async {
    try {
      var response = await taskerService.getRelatedSkills(specialization);

      if (response.containsKey("data")) {
        List<TaskerSkills> skills = [];
        for (var skill in response["data"]) {
          skills.add(TaskerSkills.fromJson(skill));
        }
        return skills;
      } else if (response.containsKey('error')) {
        debugPrint(response['error']);
        return [];
      } else {
        return [];
      }
    } catch (e, st) {
      debugPrint("Error getting relevant tasker skills: $e");
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  Future<String> updateUser(List<File>? images, List<File>? documents,
      List<int>? taskerImageUrl, List<String>? taskerDocuments) async {
    try {
      String role = storage.read("role");

      if (role == "Client") {
        ClientModel client = ClientModel(
            clientId: storage.read("user_id"), bio: bioController.text);

        final updateClientResult = await clientService.updateClient(client);

        if (updateClientResult.containsKey("message")) {
          return updateClientResult["message"];
        } else if (updateClientResult.containsKey("error")) {
          debugPrint(
              "Error in updating client: ${updateClientResult["error"]}");
          return updateClientResult["error"];
        }
        return "An Error Occurred while Updating your information. Please Try Again.";
      } else if (role == "Tasker") {
        TaskerModel tasker = TaskerModel(
          taskerId: storage.read("user_id"),
          userId: storage.read("user_id"),
          bio: bioController.text,
          specialization: specializationController.text,
          skills: skillsController.text,
          availability:
              availabilityController.text == "I am available" ? true : false,
          wagePerHour: double.parse(
              wageController.text.replaceAll(RegExp(r'[^\d.]'), '')),
          payPeriod: payPeriodController.text,
          group: taskerGroupController.text == "Agency" ? true : false,
          rating: 0.0,
          taskerImagesId: taskerImageUrl ?? [],
        );

        List<File> taskerImages = [];
        List<File> taskerDocuments = [];

        if (images != null) {
          for (var image in images) {
            taskerImages.add(File(image.path));
          }
        }

        if (documents != null) {
          for (var document in documents) {
            taskerDocuments.add(File(document.path));
          }
        }

        final updateTaskerResult = await taskerService.updateTasker(
            taskerImages, taskerDocuments, tasker);

        if (updateTaskerResult.containsKey("message")) {
          return updateTaskerResult["message"];
        } else if (updateTaskerResult.containsKey("error")) {
          debugPrint(
              "Error in updating tasker: ${updateTaskerResult["error"]}");
          return updateTaskerResult["error"];
        } else {
          return "An Error Occurred while Updating your information. Please Try Again.";
        }
      }
      return "An Error Occurred while Updating your information. Please Try Again.";
    } catch (e, stackTrace) {
      debugPrint("Error updating user data: $e");
      debugPrintStack(stackTrace: stackTrace);
      return "An Error Occurred while Updating your information. Please Try Again.";
    }
  }

  void dispose() {
    //General Account Information
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    roleController.dispose();
    statusController.dispose();
    fbLinkController.dispose();
    instaLinkController.dispose();
    telegramLinkController.dispose();

    //Tasker Text
    birthdateController.dispose();
    imageController.dispose();
    companyNameController.dispose();
    taskerGroupController.dispose();
    bioController.dispose();
    specializationController.dispose();
    skillsController.dispose();
    taskerAddressController.dispose();
    availabilityController.dispose();
    wageController.dispose();
    contactNumberController.dispose();
    genderController.dispose();
    addressController.dispose();
    payPeriodController.dispose();

    // Address controllers
    streetAddressController.dispose();
    barangayController.dispose();
    cityController.dispose();
    provinceController.dispose();
    postalCodeController.dispose();
    countryController.dispose();

    accStatusController.dispose();
  }
}
