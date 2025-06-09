import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/document_model.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/tasker_skills.dart';
import 'package:flutter_fe/service/client_service.dart';
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
  final TextEditingController specializationController = TextEditingController();
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

  //Client Text Controller
  final TextEditingController prefsController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();
  final storage = GetStorage();

  void _showStatusModal({required BuildContext context, required bool isSuccess, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatusModal(
        isSuccess: isSuccess,
        message: message,
      ),
    );
  }

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

  Future<int> verifyEmail(BuildContext context, String token, String email) async {
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
            client: result['client'] != null ? ClientModel.fromJson(result['client']) : null
          );
        } else if (data!= null && data.containsKey("tasker")) {
          // For taskers, we no longer merge data from tasker table
          // All verification data should come from user_verify table only
          debugPrint("ProfileController: Processing tasker user");
          debugPrint(data["tasker"].toString());
          return AuthenticatedUser(
            user: UserModel.fromJson(data["user"]),
            isClient: false,
            isTasker: true,
            tasker: data['tasker'] != null ? TaskerModel.fromJson(data['tasker']) : null,
          );
        } else {
          debugPrint("ProfileController: No client or tasker data found");
          return null;
          // If neither client nor tasker specific data is present, but user data exists
          // This case might be relevant for users who haven't completed their profile as client or tasker yet.
          // debugPrint("ProfileController: Processing generic user data");
          // return AuthenticatedUser(
          //   user: UserModel.fromJson(data["user"]),
          // );
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

  Future<List<TaskerSkills>> getRelevantTaskerSkills(String specialization) async{
    try {
      var response = await taskerService.getRelatedSkills(specialization);

      if (response.containsKey("data")) {
        List<TaskerSkills> skills = [];
        for (var skill in response["data"]) {
          skills.add(TaskerSkills.fromJson(skill));
        }
        return skills;
      }else if(response.containsKey('error')){
        debugPrint(response['error']);
        return [];
      }else{
        return [];
      }
    }catch(e, st){
      debugPrint("Error getting relevant tasker skills: $e");
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  Future<String> updateUser(List<File> images, List<File> documents) async{
    try{
      String role = storage.read("role");

      if(role == "Client"){
        ClientModel client = ClientModel(
          id: storage.read("user_id"),
          preferences: bioController.text
        );

        final updateClientResult = await clientService.updateClient(client);

        if(updateClientResult.containsKey("message")){
          return updateClientResult["message"];
        }else if(updateClientResult.containsKey("error")){
          debugPrint("Error in updating client: ${updateClientResult["error"]}");
          return updateClientResult["error"];
        }
        return "An Error Occurred while Updating your information. Please Try Again.";
      }else if(role == "Tasker"){
        TaskerModel tasker = TaskerModel(
          id: storage.read("user_id"),
          bio: bioController.text,
          specialization: SpecializationModel(specialization: specializationController.text),
          skills: skillsController.text,
          availability: availabilityController.text == "I am available" ? true : false,
          wage: double.parse(wageController.text.replaceAll(RegExp(r'[^\d.]'), '')),
          payPeriod: payPeriodController.text,
          birthDate: DateTime.parse(birthdateController.text),
          group: taskerGroupController.text == "Agency" ? true : false,
          rating: 0.0
        );

        List<File> taskerImages = [];
        List<File> taskerDocuments = [];

        for(var image in images){
          taskerImages.add(File(image.path));
        }

        for(var document in documents){
          taskerDocuments.add(File(document.path));
        }

        final updateTaskerResult = await taskerService.updateTasker(taskerImages, taskerDocuments, tasker);

        if(updateTaskerResult.containsKey("message")){
          return updateTaskerResult["message"];
        }else if(updateTaskerResult.containsKey("error")){
          debugPrint("Error in updating tasker: ${updateTaskerResult["error"]}");
          return updateTaskerResult["error"];
        }else{
          return "An Error Occurred while Updating your information. Please Try Again.";
        }
      }
      return "An Error Occurred while Updating your information. Please Try Again.";
    }catch(e, stackTrace){
      debugPrint("Error updating user data: $e");
      debugPrintStack(stackTrace: stackTrace);
      return "An Error Occurred while Updating your information. Please Try Again.";
    }
  }
}
