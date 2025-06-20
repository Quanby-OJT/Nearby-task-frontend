import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/tasker_controller.dart';
import 'package:flutter_fe/model/images_model.dart';
import 'package:flutter_fe/model/tasker_skills.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dotted_border/dotted_border.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _userController = ProfileController();
  final GetStorage storage = GetStorage();
  final TaskerController taskerController = TaskerController();
  AuthenticatedUser? _user;
  bool _isLoading = true;
  bool willEdit = false;
  bool isGroup = false;
  File? profileImage;
  List<String> specialization = [];
  List<String> gender = ["Male", "Female", "Non-Binary", "Other"];
  bool _isAvailable = true; // true for available, false for not available
  List<SpecializationModel> _specializations = [];
  List<int> existingTaskerImages = [];
  List<ImagesModel> taskerImages = [];
  List<String> payPeriods = [
    'Hourly',
    'Daily',
    'Weekly',
    'Bi-Weekly',
    'Monthly'
  ];
  bool isSaving = false;
  List<File> taskerProfileImages = [];
  List<File> tesdaDocuments = [];
  List<int> taskerImageIds = [];
  String saveText = "Save";
  List<String> _selectedSkills = [];
  final updateTasker = GlobalKey<FormState>();
  String?
      _userProfileImageUrl; // Store profile image from client_images or tasker_images

  @override
  void initState() {
    super.initState();
    loadAllDataAtOnce();
  }

  void loadAllDataAtOnce() async {
    setState(() {
      _isLoading = true;
    });
    final role = storage.read('role');
    await Future.wait([
      _fetchUserData(),
      if (role == "Tasker") fetchSpecialization(),
      if (role == "Tasker") getAllTaskerImages(),
      _fetchUserProfileImage(), // Fetch profile image from appropriate table
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  Future<void> fetchSpecialization() async {
    try {
      _specializations = await JobPostService().getSpecializations();
      setState(() {
        specialization =
            _specializations.map((spec) => spec.specialization).toList();
        _userController.specializationController.text = _user?.user.bio ?? '';
      });
    } catch (error) {
      print('Error fetching specializations: $error');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _userController.getAuthenticatedUser(context, userId);
      String role = storage.read('role');

      debugPrint("Current User: ${user?.client?.bio}");
      setState(() {
        _user = user;
        _userController.emailController.text = _user?.user.email ?? '';
        _userController.birthdateController.text = _user?.user.birthdate ?? '';
        _userController.bioController.text = role == "Tasker"
            ? _user?.tasker?.bio ?? ''
            : _user?.client?.bio ?? '';
        _userController.specializationController.text =
            _user?.tasker?.specialization ?? '';
        _userController.skillsController.text = _user?.tasker?.skills ?? '';
        _isAvailable = _user?.tasker?.availability ?? false;
        _userController.availabilityController.text =
            _isAvailable ? "I am available" : "Not available";

        _userController.payPeriodController.text =
            _user?.tasker?.payPeriod ?? '';
        // Pre-fill selected skills if user already has skills
        if (_user?.tasker?.skills != null &&
            _user!.tasker!.skills!.isNotEmpty) {
          _selectedSkills =
              _user!.tasker!.skills!.split(',').map((s) => s.trim()).toList();
        }
        _userController.genderController.text = _user?.user.gender ?? '';
        _userController.contactNumberController.text =
            _user?.user.contact.toString() ?? '';
        _userController.fbLinkController.text =
            _user?.user.socialMediaLinks?['fb'] ?? '';
        _userController.instaLinkController.text =
            _user?.user.socialMediaLinks?['ig'] ?? '';
        _userController.telegramLinkController.text =
            _user?.user.socialMediaLinks?['tg'] ?? '';
        tesdaDocuments = [];
        //taskerImageIds = _user?.tasker?.taskerImages ?? [];

        final currencyFormatter =
            NumberFormat.currency(locale: 'en_PH', symbol: '₱');
        _userController.wageController.text = _user?.tasker?.wage != null
            ? currencyFormatter.format(_user!.tasker!.wage)
            : '';

        _userController.genderController.text = _user?.user.gender ?? '';
        _userController.fbLinkController.text =
            _user?.user.socialMediaLinks?["fb"] ?? '';
        _userController.instaLinkController.text =
            _user?.user.socialMediaLinks?["ig"] ?? '';
        _userController.telegramLinkController.text =
            _user?.user.socialMediaLinks?["tg"] ?? '';

        _userController.streetAddressController.text = '';
        _userController.barangayController.text = '';
        _userController.cityController.text = '';
        _userController.provinceController.text = '';
        _userController.postalCodeController.text = '';
        _userController.countryController.text = '';
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching user data: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> getAllTaskerImages() async {
    int userId = storage.read("user_id");

    final taskerImages = await taskerController.getAllTaskerImages(userId);
    List<String> imageUrls =
        taskerImages?.map((image) => image.image_url).toList() ?? [];
    List<int?> imageUrlIds =
        taskerImages?.map((image) => image.id).toList() ?? [];
    debugPrint("All Images: $imageUrls");
    debugPrint("All Image Ids: $imageUrlIds");

    setState(() {
      this.taskerImages = taskerImages ?? [];
    });
  }

  Future<void> _fetchUserProfileImage() async {
    try {
      final userId = storage.read('user_id');
      final role = storage.read('role');

      if (userId != null) {
        debugPrint("Fetching profile image for user ID: $userId, role: $role");

        Map<String, dynamic> result;

        if (role?.toLowerCase() == 'tasker') {
          final taskerService = TaskerService();
          result =
              await taskerService.getTaskerImages(int.parse(userId.toString()));
        } else if (role?.toLowerCase() == 'client') {
          final clientService = ClientServices();
          result =
              await clientService.getClientImages(int.parse(userId.toString()));
        } else {
          debugPrint('Unknown user role for fetching profile image: $role');
          return;
        }

        debugPrint("Profile image fetch result: $result");

        if (result.containsKey('images') && result['images'] is List) {
          final List<dynamic> images = result['images'];
          if (images.isNotEmpty) {
            final firstImage = images.first;
            if (firstImage is Map && firstImage['image_link'] != null) {
              setState(() {
                _userProfileImageUrl = firstImage['image_link'];
              });
              debugPrint('✅ Found user profile image: $_userProfileImageUrl');
            }
          } else {
            debugPrint('No profile images found for user');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile image: $e');
    }
  }

  ImageProvider<Object>? _getProfileImageProvider() {
    // Priority 1: Newly uploaded images (for editing)
    if (taskerProfileImages.isNotEmpty) {
      return FileImage(taskerProfileImages.first);
    }
    // Priority 2: Profile image from client_images/tasker_images table
    else if (_userProfileImageUrl != null && _userProfileImageUrl!.isNotEmpty) {
      return NetworkImage(_userProfileImageUrl!);
    }
    // Priority 3: Default user image from user table
    else if (_user?.user.imageName != null &&
        _user!.user.imageName!.isNotEmpty) {
      return NetworkImage(_user!.user.imageName!);
    }
    // Fallback: Default asset image
    else {
      return const AssetImage('assets/images/default-profile.jpg');
    }
  }

  Future<void> updateUser() async {
    try {
      setState(() {
        isSaving = true;
      });
      List<int> taskerImgIds =
          taskerImages.map((imgIds) => imgIds.id ?? 0).toList();
      debugPrint("Updated Image Ids: $taskerImgIds");
      String updateResult = await _userController.updateUser(
          taskerProfileImages, tesdaDocuments, profileImage, taskerImgIds);
      debugPrint("Result of Update Tasker Result: $updateResult");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updateResult),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint("Error updating user: $error");
      debugPrint("Stack Trace: $stackTrace");
    } finally {
      setState(() {
        isSaving = false;
        willEdit = false;
        taskerImages = [];
        tesdaDocuments = [];
        taskerProfileImages = [];
      });
      loadAllDataAtOnce();
    }
  }

  //Tasker Images Upload
  Future<void> pickTaskerPicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      if (result.files.length > 9) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only upload up to 9 images.',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      setState(() {
        for (var file in result.files) {
          if (file.path != null && taskerProfileImages.length < 9) {
            // Ensure not to exceed 9 images
            taskerProfileImages.add(File(file.path!));
          }
        }
      });
    }
  }

  //Profile Image Upload
  Future<void> pickProfilePicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        profileImage = File(result.files.first.path!);
      });
    }
  }

  Future<void> pickTESDADocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        tesdaDocuments.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  Widget buildFilePreview(File file, int index) {
    debugPrint("File: ${file.path}");

    if (file.path.isNotEmpty) {
      Uri? fileUri = Uri.tryParse(file.path);
      if (fileUri != null && fileUri.hasAbsolutePath) {
        String fileExtension = file.path.split('.').last.toLowerCase();
        debugPrint("File Extension: $fileExtension");

        if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          // If the file is an image, display it
          return Image.file(file,
              width: double.infinity, height: 100, fit: BoxFit.cover);
        } else if (fileExtension == 'pdf') {
          // If it's a PDF, show an icon + open it in browser
          return InkWell(
            onTap: () => _openFile(file.toString()), // Open in browser
            child: Card(
              color: Colors.white,
              elevation: 3,
              child: Flexible(
                  fit: FlexFit.loose,
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // FIX: Prevent Row from expanding infinitely
                    children: [
                      const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.picture_as_pdf,
                              color: Colors.red, size: 40)),
                      Flexible(
                        // FIX: Allow text to wrap instead of forcing width expansion
                        fit: FlexFit.loose,
                        child: Padding(
                          padding: const EdgeInsets.only(right: (10)),
                          child: Text(
                            file.path.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (willEdit) ...[
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 50),
                          onPressed: () {
                            setState(() {
                              tesdaDocuments.removeAt(index);
                            });
                          },
                        ),
                      ]
                    ],
                  )),
            ),
          );
        }
      }
    }

    return Text('Unsupported file type',
        style: GoogleFonts.poppins(color: Colors.red));
  }

  Future<File> getDefaultProfileImage() async {
    // Load the asset as bytes
    final byteData = await rootBundle.load('assets/images/default-profile.jpg');
    final bytes = byteData.buffer.asUint8List();

    // Write the bytes to a temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/default-profile.jpg');
    await tempFile.writeAsBytes(bytes);

    return tempFile;
  }

  void openDocument(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not open document: $url');
    }
  }

  void _openFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  //Main Page
  @override
  Widget build(BuildContext context) {
    //if (_isLoading) return const Scaffold(body: Center(child: CustomLoading()));

    String role = storage.read("role");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Your Profile",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE23670),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  willEdit = !willEdit;
                });
              },
              icon: Icon(
                FontAwesomeIcons.penToSquare,
                color: Color(0xFFE23670),
              )),
          IconButton(
              onPressed: willEdit
                  ? () {
                      if (updateTasker.currentState!.validate()) {
                        updateUser();
                      }
                    }
                  : null,
              icon: Icon(
                FontAwesomeIcons.floppyDisk,
                color: willEdit ? Color(0xFFE23670) : Color(0XFF9696A5),
              ))
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SingleChildScrollView(
            child: Form(
                key: updateTasker,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(children: [
                  GestureDetector(
                    onTap: willEdit ? pickProfilePicture : null,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _getProfileImageProvider(),
                      child: willEdit
                          ? Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFFE23670),
                                  size: 20,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                      "${_user?.user.firstName} ${_user?.user.middleName?.isNotEmpty == true ? "${_user!.user.middleName?[0]}." : ""} ${_user?.user.lastName}",
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFE23670),
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(_user?.user.email ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  if (role == "Tasker")
                    _buildSection(
                        title: "Media",
                        description: "Add up to 9 of your best pictures.",
                        children: [
                          SizedBox(height: 16),
                          Center(
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              children: List.generate(9, (index) {
                                Widget imageWidget;

                                // 1. Prioritize displaying uploaded images
                                if (index < taskerProfileImages.length) {
                                  imageWidget = ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      taskerProfileImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                // 2. Fill remaining with tasker images if not empty
                                else if (index - taskerProfileImages.length <
                                    taskerImages.length) {
                                  imageWidget = ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      //taskerImages.[index - profileImages.length],
                                      taskerImages.isNotEmpty
                                          ? taskerImages[index -
                                                  taskerProfileImages.length]
                                              .image_url
                                          : '',
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } else {
                                  imageWidget = Center(
                                      child: SizedBox(
                                          height: 200,
                                          width: 100)); // Empty cell
                                }
                                // 1. Prioritize displaying uploaded images
                                if (index < taskerProfileImages.length) {
                                  imageWidget = ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      taskerProfileImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                // 2. Fill remaining with tasker images if not empty
                                else if (index - taskerProfileImages.length <
                                    taskerImages.length) {
                                  imageWidget = ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      //taskerImages.[index - profileImages.length],
                                      taskerImages.isNotEmpty
                                          ? taskerImages[index -
                                                  taskerProfileImages.length]
                                              .image_url
                                          : '',
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } else {
                                  imageWidget = Center(
                                      child: SizedBox(
                                          height: 200,
                                          width: 100)); // Empty cell
                                }

                                return AspectRatio(
                                  aspectRatio: 3 / 4,
                                  child: GestureDetector(
                                    onTap: willEdit ? pickTaskerPicture : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Display dotted border always
                                          DottedBorder(
                                            borderType: BorderType.RRect,
                                            radius: Radius.circular(10),
                                            dashPattern: [10, 5],
                                            color: Colors.grey[500]!,
                                            strokeWidth: 1,
                                            padding: EdgeInsets.zero,
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: imageWidget,
                                            ),
                                          ),

                                          // Delete icon for profileImages
                                          if (willEdit &&
                                              index <
                                                  taskerProfileImages.length)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                icon: Icon(Icons.remove_circle,
                                                    color: Colors.red,
                                                    size: 20),
                                                onPressed: () {
                                                  setState(() {
                                                    taskerProfileImages
                                                        .removeAt(index);
                                                  });
                                                },
                                              ),
                                            )

                                          // Delete icon for taskerImages
                                          else if (willEdit &&
                                              index -
                                                      taskerProfileImages
                                                          .length <
                                                  taskerImages
                                                      .length) //&& taskerImages[index - profileImages.length].isNotEmpty)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                icon: Icon(Icons.remove_circle,
                                                    color: Colors.red,
                                                    size: 20),
                                                onPressed: () {
                                                  setState(() {
                                                    taskerImages.removeAt(
                                                        index -
                                                            taskerProfileImages
                                                                .length);
                                                  });
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ]),
                  _buildSection(
                      title: 'Your QTask Profile',
                      description:
                          'This is where you describe yourself to your potential clients/taskers.',
                      children: [
                        const SizedBox(height: 16),
                        _buildTextField(
                            controller: _userController.bioController,
                            label: 'Bio',
                            icon: null,
                            hintText:
                                "Make it as spicy as possible, but remain professional in your work.",
                            maxLines: 5,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 100) {
                                  return 'Your Information must be at least 100 characters long.';
                                }
                              }
                              return null;
                            }),
                        const SizedBox(height: 16),
                        if (role == "Tasker") ...[
                          _buildDropdownField(
                              controller:
                                  _userController.specializationController,
                              label: 'Specialization',
                              items: specialization,
                              onChanged: (value) {
                                setState(() {
                                  _userController.skillsController.text =
                                      ''; // Clear skills
                                  _selectedSkills
                                      .clear(); // Clear selected skills list
                                });
                              },
                              hintText: 'Select your specialization',
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a specialization';
                                }
                                return null;
                              }),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: willEdit &&
                                    _userController.specializationController
                                        .text.isNotEmpty
                                ? () {
                                    _showRelevantSkillsBottomSheet(context);
                                  }
                                : null,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                  controller: _userController.skillsController,
                                  label: 'Relevant Skills',
                                  icon: null,
                                  hintText:
                                      "Please Select all of your relevant skills.",
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      // Check if _user.tasker.skills is null or empty before validating _selectedSkills
                                      if ((_user?.tasker?.skills == null ||
                                              _user!.tasker!.skills!.isEmpty) &&
                                          _selectedSkills.isEmpty) {
                                        return 'Please select at least one skill';
                                      }
                                      return null;
                                    }
                                    return null;
                                  }),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Flexible(
                              flex: 2, // Occupy 3/4 of the row
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                // Add some spacing
                                child: _buildTextField(
                                    controller: _userController.wageController,
                                    label: 'Your Wage',
                                    icon: null,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      CurrencyInputFormatter(),
                                    ],
                                    hintText: '₱ 0.00',
                                    validator: (value) {
                                      // Remove ₱ from value before parsing
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          value != '₱0.00') {
                                        // Also check if the value is not just the default "₱0.00"
                                        // before trying to parse.
                                        if (double.tryParse(value.replaceAll(
                                                RegExp(r'[^0-9.]'), '')) ==
                                            0) {
                                          return 'Please input your desired wage.';
                                        }
                                        return null;
                                      }
                                      return null;
                                    }),
                              ),
                            ),
                            Flexible(
                                flex: 1, // Occupy 1/4 of the row
                                child: _buildDropdownField(
                                    controller:
                                        _userController.payPeriodController,
                                    label: "",
                                    items: payPeriods,
                                    hintText: "Per",
                                    validator: (String? value) {
                                      if (value == null) {
                                        return 'Please select a pay period';
                                      }

                                      return null;
                                    })),
                          ]),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Are you available?",
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text("Category",
                                    textAlign: TextAlign.start,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    )),
                              )
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: buildButtonWithIcon(
                                    onPressed: _toggleAvailability,
                                    label: _isAvailable
                                        ? 'I am available'
                                        : 'Not available',
                                    color: _isAvailable
                                        ? Color(0XFF4DBF66)
                                        : Color(0XFFD43D4D),
                                    icon: _isAvailable
                                        ? FontAwesomeIcons.check
                                        : FontAwesomeIcons.xmark),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: buildButtonWithIcon(
                                      onPressed: _toggleGroupTasker,
                                      label: isGroup ? 'Agency' : 'Individual',
                                      color: isGroup
                                          ? Color(0XFF3C28CC)
                                          : Color(0XFFE23670),
                                      icon: isGroup
                                          ? FontAwesomeIcons.building
                                          : FontAwesomeIcons.userGear))
                            ],
                          ),
                        ]
                      ]),
                  const SizedBox(height: 8),
                  if (role == "Tasker")
                    _buildSection(
                        title:
                            "Your TESDA Documents and Other Credentials (Optional)",
                        description:
                            "To further boost your credibility, you can upload your TESDA certifications (or any other certifications) to boost your credibility.",
                        children: [
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: willEdit ? pickTESDADocuments : null,
                            child: DottedBorder(
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(12),
                              padding: const EdgeInsets.all(6),
                              dashPattern: const [8, 4],
                              strokeWidth: 2,
                              color: Colors.grey.shade400,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.cloudArrowUp,
                                      size: 40,
                                      color: Color(0xFFE23670),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Tap to upload documents",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Supports: PDF, JPG, PNG",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (tesdaDocuments.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tesdaDocuments.length,
                              itemBuilder: (context, index) {
                                final file = tesdaDocuments[index];
                                // Assuming buildFilePreview can handle File objects directly now
                                // or you have a way to get the file name.
                                // If file is a String (URL), that's handled by buildFilePreview.
                                // If file is a File object, we might need to adjust buildFilePreview
                                // or extract the path/name here.
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: buildFilePreview(file, index),
                                );
                              },
                            ),
                        ]),
                  const SizedBox(height: 8),
                  _buildSection(
                      title: 'Your Social Media Profiles (Optional)',
                      description:
                          'You can add your social media profiles here to help your potential loyal customers find you.',
                      children: [
                        // Facebook
                        _buildTextField(
                          controller: _userController.fbLinkController,
                          label: 'Facebook Profile URL',
                          icon: FontAwesomeIcons.facebook,
                          keyboardType: TextInputType.url,
                          hintText: 'https://facebook.com/yourusername',
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!value.contains('facebook.com')) {
                                return 'Please enter a valid Facebook URL';
                              }
                            }
                            return null; // Optional field
                          },
                        ),
                        const SizedBox(height: 16),

                        // Instagram
                        _buildTextField(
                          controller: _userController.instaLinkController,
                          label: 'Instagram Profile URL',
                          icon: FontAwesomeIcons.instagram,
                          keyboardType: TextInputType.url,
                          hintText: 'https://instagram.com/yourusername',
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!value.contains('instagram.com')) {
                                return 'Please enter a valid Instagram URL';
                              }
                            }
                            return null; // Optional field
                          },
                        ),
                        const SizedBox(height: 16),
                        // Twitter
                        _buildTextField(
                          controller: _userController.telegramLinkController,
                          label: 'Twitter Profile URL',
                          icon: FontAwesomeIcons.twitter,
                          keyboardType: TextInputType.url,
                          hintText: 'https://twitter.com/yourusername',
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!value.contains('twitter.com') &&
                                  !value.contains('x.com')) {
                                return 'Please enter a valid Twitter/X URL';
                              }
                            }
                            return null; // Optional field
                          },
                        ),
                        const SizedBox(height: 24),
                      ])
                ]))),
      ),
    );
  }

  void _toggleAvailability() {
    setState(() {
      _isAvailable = !_isAvailable;
      _userController.availabilityController.text =
          _isAvailable ? "I am available" : "I am not available";
    });
  }

  void _toggleGroupTasker() {
    setState(() {
      isGroup = !isGroup;
      _userController.taskerGroupController.text =
          isGroup ? "Agency" : "Individual";
    });
  }

  Widget buildButtonWithIcon({
    required VoidCallback onPressed,
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return ElevatedButton.icon(
      onPressed: willEdit ? onPressed : null,
      icon: icon != null
          ? Icon(icon, color: willEdit ? Colors.white : Colors.grey[400])
          : const SizedBox.shrink(), // Empty space if no icon
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: willEdit ? Colors.white : Colors.grey[400],
          fontSize: 14,
        ),
        textAlign: TextAlign.center, // Center text
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  // Helper method for sectioned layout
  Widget _buildSection(
      {required String title,
      required String description,
      required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFFE23670),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: const Color(0xFF4A4A68),
              fontSize: 16,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showRelevantSkillsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return RelevantSkillsBottomSheet(
          initialSelectedSkills: List.from(_selectedSkills), // Pass a copy
          onSkillsSaved: (updatedSkills) {
            setState(() {
              _selectedSkills = updatedSkills;
              _userController.skillsController.text =
                  _selectedSkills.join(', ');
            });
          },
          selectedSpecialization: _userController.specializationController.text,
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: willEdit,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon:
                icon != null ? Icon(icon, color: Colors.grey[600]) : null,
            enabledBorder: willEdit
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  )
                : InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFE23670), width: 2),
                  )
                : InputBorder.none,
            errorBorder: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                  )
                : InputBorder.none,
            focusedErrorBorder: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red[600]!, width: 2),
                  )
                : InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hintText,
            border: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                : InputBorder.none,
          ),
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    void Function(String?)? onChanged,
    required String hintText,
    required String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          )),
      const SizedBox(height: 8),
      Container(
        decoration: willEdit
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
                color: Colors.grey[100],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[100]!),
                color: Colors.grey[100],
              ),
        child: DropdownButtonFormField<String>(
          hint: Text(hintText),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            enabledBorder: willEdit
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  )
                : InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFE23670), width: 2),
                  )
                : InputBorder.none,
            errorBorder: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                  )
                : InputBorder.none,
            focusedErrorBorder: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red[600]!, width: 2),
                  )
                : InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: willEdit
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                : InputBorder.none,
          ),
          value: controller.text.isNotEmpty ? controller.text : null,
          onChanged: willEdit
              ? (value) {
                  setState(() {
                    controller.text = value!;
                    if (onChanged != null) {
                      onChanged(value);
                    }
                  });
                }
              : null,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style:
                      GoogleFonts.montserrat(fontSize: 14, color: Colors.black),
                ));
          }).toList(),
          isExpanded: true,
          // Make the dropdown take the full width
          style: GoogleFonts.montserrat(fontSize: 14),
          validator: validator,
        ),
      ),
    ]);
  }
}

class RelevantSkillsBottomSheet extends StatefulWidget {
  final List<String> initialSelectedSkills;
  final Function(List<String>) onSkillsSaved;
  final String selectedSpecialization;

  const RelevantSkillsBottomSheet(
      {super.key,
      required this.initialSelectedSkills,
      required this.onSkillsSaved,
      required this.selectedSpecialization});

  @override
  State<RelevantSkillsBottomSheet> createState() =>
      _RelevantSkillsBottomSheetState();
}

class _RelevantSkillsBottomSheetState extends State<RelevantSkillsBottomSheet> {
  late List<String> _tempSelectedSkills;
  List<TaskerSkills> _allSkills = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tempSelectedSkills = List.from(widget.initialSelectedSkills);
    getAllRelevantSkills();
  }

  void getAllRelevantSkills() async {
    setState(() {
      isLoading = true;
    });

    final fetchedTaskerSKills = await ProfileController()
        .getRelevantTaskerSkills(widget.selectedSpecialization);

    setState(() {
      _allSkills = fetchedTaskerSKills;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return FractionallySizedBox(heightFactor: 0.5, child: CustomLoading());
    }

    return FractionallySizedBox(
      heightFactor: 0.5, // Occupy half of the screen height
      child: Padding(
        padding: MediaQuery.of(context).viewInsets, // Adjust for keyboard
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Select Relevant Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  )),
              const SizedBox(height: 10),
              if (_allSkills.isEmpty) ...[
                Center(
                    child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    const Icon(FontAwesomeIcons.gears,
                        color: Colors.grey, size: 50),
                    const SizedBox(height: 10),
                    const Text(
                        "No relevant skills found. Please Close this and try again.")
                  ],
                ))
              ] else ...[
                Expanded(
                  child: ListView(
                    children: _allSkills.map((skill) {
                      return CheckboxListTile(
                        title: Text(skill.relevantSkills),
                        value:
                            _tempSelectedSkills.contains(skill.relevantSkills),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _tempSelectedSkills.add(skill.relevantSkills);
                            } else {
                              _tempSelectedSkills.remove(skill.relevantSkills);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                ElevatedButton(
                  child: const Text('Save Skills'),
                  onPressed: () {
                    widget.onSkillsSaved(_tempSelectedSkills);
                    Navigator.pop(context); // Close the bottom sheet
                  },
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(newText);
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    String formattedText = formatter.format(value / 100);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
