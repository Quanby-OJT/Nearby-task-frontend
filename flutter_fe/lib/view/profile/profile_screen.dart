import 'dart:io';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _userController = ProfileController();
  final GetStorage storage = GetStorage();
  AuthenticatedUser? _user;
  bool _isLoading = true;
  static String? role;
  bool willEdit = false; // Start in edit mode by default
  List<String> specialization = [];
  List<String> gender = ["Male", "Female", "Non-Binary", "I don't Want to Say"];
  List<String> availability = ['Set Your Availability', 'I am available', 'I am not available'];
  List<SpecializationModel> _specializations = [];
  List<String> payPeriods = ['Hourly', 'Daily', 'Weekly', 'Bi-Weekly', 'Monthly'];
  bool isSaving = false;
  File? profileImage;
  List<dynamic> tesdaDocuments = [];
  String saveText = "Save";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    fetchSpecialization();
  }

  Future<void> fetchSpecialization() async {
    try {
      _specializations = await JobPostService().getSpecializations();
      setState(() {
        specialization = _specializations.map((spec) => spec.specialization).toList();
        _userController.specializationController.text = _user?.tasker?.specialization ?? '';
      });
    } catch (error) {
      print('Error fetching specializations: $error');
    }
  }

  Future<void> _fetchUserData() async {
    role = storage.read("role");
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user = await _userController.getAuthenticatedUser(context, userId);
      setState(() {
        _user = user;
        _isLoading = false;
        _userController.emailController.text = _user?.user.email ?? '';
        _userController.birthdateController.text = _user?.user.birthdate ?? '';
        _userController.prefsController.text = _user?.client?.preferences ?? '';
        _userController.clientAddressController.text = _user?.client?.clientAddress ?? '';
        _userController.bioController.text = _user?.tasker?.bio ?? '';
        _userController.specializationController.text = _user?.tasker?.specialization ?? '';
        _userController.skillsController.text = _user?.tasker?.skills ?? '';
        _userController.availabilityController.text = _user?.tasker?.availability == true ? "I am available" : "I am not available";
        _userController.taskerAddressController.text = _user?.tasker?.taskerAddress ?? '';
        _userController.payPeriodController.text = _user?.tasker?.payPeriod ?? '';
        if (_user?.tasker?.taskerDocuments != null) {
          tesdaDocuments = [_user!.tasker!.taskerDocuments!]; // Store as String (URL)
        }

        if (_user?.tasker?.wage != null) {
          final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
          _userController.wageController.text = currencyFormat.format(_user!.tasker!.wage);
        } else {
          _userController.wageController.text = '';
        }
        _userController.genderController.text = _user?.user.gender ?? '';
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  //Profile Image upload
  Future<void> pickProfilePicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if(result != null &&result.files.single.path != null){
      setState(() {
        profileImage = File(result.files.single.path!);
      });
    }
  }

  /// This uploads TESDA Documents, if needed.
  ///
  Future<void> pickTESDADocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        tesdaDocuments.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  Widget buildFilePreview(dynamic file, int index) {
    if (file is File) {
      // Local file case
      String fileName = file.path.split('/').last;
      String fileExtension = fileName.split('.').last.toLowerCase();
      String fileType = fileExtension == 'pdf'
          ? 'PDF'
          : (['jpg', 'jpeg', 'png'].contains(fileExtension) ? 'Image' : 'Unknown');

      double fileSizeInKb = file.lengthSync() / 1024;
      String fileSize = fileSizeInKb < 1024
          ? '${fileSizeInKb.toStringAsFixed(2)} KB'
          : '${(fileSizeInKb / 1024).toStringAsFixed(2)} MB';

      if (file.path.endsWith('.pdf')) {
        return buildDocumentCard(fileName, fileSize, fileType);
      } else {
        return Image.file(file, width: 50, height: 50, fit: BoxFit.cover);
      }
    } else if (file is String) {
      // Remote URL case
      String fileName = file.split('/').last;
      String fileExtension = fileName.split('.').last.toLowerCase();

      if (fileExtension == 'pdf') {
        // For PDFs, display a placeholder or fetch metadata if available
        return buildDocumentCard(fileName, 'Size unavailable', 'PDF');
      } else {
        // For images, use NetworkImage
        return Image.network(file, width: 50, height: 50, fit: BoxFit.cover);
      }
    } else {
      return const Text('Unsupported file type');
    }
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

  //Main Page
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Edit Your Profile',
          style: GoogleFonts.roboto(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70, // Larger for prominence
                          backgroundColor: Colors.grey[200],
                          backgroundImage: profileImage != null
                            ? FileImage(profileImage!)
                              : const AssetImage('assets/images/image1.jpg') as ImageProvider,
                        ),
                        if (willEdit)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 28),
                            onPressed: () {
                              // Logic to change profile picture
                              pickProfilePicture();
                            },
                            padding: const EdgeInsets.all(0),
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF0272B1)),
                          ),
                      ],
                    ),
                  ),

                  // User Name (non-editable for now)
                  Text(
                    '${_user?.user.firstName ?? "User"} ${_user?.user.lastName ?? ""}',
                    style: GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (role == "Client") ...[
                          _buildSection(
                            title: "About Me",
                            children: [
                              TextFormField(
                                maxLines: 5,
                                controller: _userController.prefsController,
                                enabled: willEdit,
                                decoration: _inputDecoration(hintText: "Write about yourself"),
                              ),
                            ],
                          ),
                          _buildSection(
                            title: "My Address",
                            children: [
                              TextField(
                                controller: _userController.clientAddressController,
                                enabled: willEdit,
                                decoration: _inputDecoration(hintText: "Enter your address"),
                              ),
                            ],
                          ),
                        ],
                        if (role == "Tasker") ...[
                          _buildSection(
                            title: "Personal Details",
                            children: [
                              Text("This is how you describe yourself as a tasker. Give it your best shot to attract more clients and earn more."),
                              const SizedBox(height: 20),
                              DropdownMenu(
                                width: double.infinity,
                                enabled: willEdit,
                                controller: _userController.genderController,
                                leadingIcon: const Icon(Icons.person),
                                label: const Text("Gender"),
                                inputDecorationTheme: _dropdownDecoration(),
                                onSelected: (String? gender) {
                                  setState(() {
                                    _userController.genderController.text = gender!;
                                  });
                                },
                                dropdownMenuEntries: gender.map<DropdownMenuEntry<String>>(
                                      (String value) => DropdownMenuEntry(value: value, label: value),
                                ).toList(),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                maxLines: 5,
                                controller: _userController.bioController,
                                enabled: willEdit,
                                decoration: _inputDecoration(hintText: "Write about yourself"),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _userController.contactNumberController,
                                enabled: willEdit,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(hintText: "Enter your contact number"),
                              )
                            ],
                          ),
                          _buildSection(
                            title: "Professional Details",
                            children: [
                              Text(""),
                              DropdownMenu(
                                width: double.infinity,
                                enabled: willEdit,
                                controller: _userController.specializationController,
                                leadingIcon: const Icon(Icons.cases_outlined),
                                label: const Text("Specialization"),
                                inputDecorationTheme: _dropdownDecoration(),
                                onSelected: (String? spec) {
                                  setState(() {
                                    _userController.specializationController.text = spec!;
                                  });
                                },
                                dropdownMenuEntries: specialization.map<DropdownMenuEntry<String>>(
                                      (String value) => DropdownMenuEntry(value: value, label: value),
                                ).toList(),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                maxLines: 3,
                                controller: _userController.skillsController,
                                enabled: willEdit,
                                decoration: _inputDecoration(hintText: "List your skills"),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _userController.taskerAddressController,
                                enabled: willEdit,
                                decoration: _inputDecoration(hintText: "Enter your address"),
                              ),
                              const SizedBox(height: 20),
                              DropdownMenu(
                                width: double.infinity,
                                enabled: willEdit,
                                controller: _userController.availabilityController,
                                leadingIcon: const Icon(Icons.event_available),
                                label: const Text("Availability"),
                                inputDecorationTheme: _dropdownDecoration(),
                                onSelected: (String? spec) {
                                  setState(() {
                                    _userController.availabilityController.text = spec!;
                                  });
                                },
                                dropdownMenuEntries: availability.map<DropdownMenuEntry<String>>(
                                      (String value) => DropdownMenuEntry(value: value, label: value),
                                ).toList(),
                              ),
                              const SizedBox(height: 20),
                              //Tasker Rate and Period
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          inputFormatters: [
                                            CurrencyTextInputFormatter.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2),
                                          ],
                                          controller: _userController.wageController,
                                          enabled: willEdit,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration(hintText: "Enter your rate"),
                                        ),
                                      ),
                                      Expanded(child:
                                        DropdownMenu(
                                          width: double.infinity,
                                          enabled: willEdit,
                                          controller: _userController.payPeriodController,
                                          leadingIcon: const Icon(Icons.schedule),
                                          inputDecorationTheme: _dropdownDecoration(),
                                          onSelected: (String? period) {
                                            setState(() {
                                              _userController.payPeriodController.text = period!;
                                            });
                                          },
                                          dropdownMenuEntries: payPeriods.map<DropdownMenuEntry<String>>(
                                                (String value) => DropdownMenuEntry(value: value, label: value),
                                          ).toList(),
                                        ),



                                      ),
                                    ],
                                  ),
                                ]
                              ),

                            ],
                          ),
                          _buildSection(
                            title: "My TESDA Documents",
                            children: [
                              if (tesdaDocuments.isEmpty && !willEdit)
                                SizedBox(
                                  width: double.infinity,
                                  child: Center(
                                    child: Text(
                                      "You don't have documents uploaded yet. \n\nYou MUST upload your documents before you can accept a job.",
                                      style: GoogleFonts.openSans(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              else if (willEdit)
                                Column(
                                  children: [
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: pickTESDADocuments,
                                        child: Text('Upload Documents', style: GoogleFonts.openSans()),
                                      ),
                                    ),
                                    if (tesdaDocuments.isNotEmpty)
                                      SizedBox(
                                        height: 200,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          physics: const ClampingScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(vertical: 5),
                                          itemBuilder: (context, index) => Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Stack(
                                              alignment: Alignment.centerRight,
                                              children: [
                                                buildFilePreview(tesdaDocuments[index], index),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 50),
                                                  onPressed: () {
                                                    setState(() {
                                                      tesdaDocuments.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          itemCount: tesdaDocuments.length,
                                        ),
                                      ),
                                  ],
                                )
                              else if (tesdaDocuments.isNotEmpty)
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: tesdaDocuments.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: buildFilePreview(tesdaDocuments[index], index),
                                        );
                                      },
                                    ),
                                  ),
                            ],
                          ),
                          _buildSection(
                            title: "Social Media Links",
                            children: [
                              Text("To boost your profile to your desired clients, we want you to provide your Socials for your prospects to know you better."),
                              const SizedBox(height: 20),
                              SizedBox(width: 5,),
                              Row(
                                children: [
                                  const Icon(FontAwesomeIcons.facebook),
                                  const SizedBox(width: 10), // Add spacing
                                  Expanded(
                                    child: TextField(
                                      enabled: willEdit,
                                      decoration: _inputDecoration(hintText: 'Enter Facebook link'),
                                    )
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(FontAwesomeIcons.instagram),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      enabled: willEdit,
                                      decoration: _inputDecoration(hintText: 'Enter Instagram link'),
                                    )
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(FontAwesomeIcons.twitter),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      enabled: willEdit,
                                      decoration: _inputDecoration(hintText: 'Enter Twitter link'),
                                    )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ]
                      ]
                    )
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => willEdit = !willEdit);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(willEdit ? 'Cancel' : 'Edit Profile', style: GoogleFonts.openSans()),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: ElevatedButton.icon(
                    onPressed: (willEdit && !isSaving) ? () async {
                      setState(() {
                        isSaving = true;
                        saveText = "Please Wait.";
                      });
                      _userController.updateUser(
                        context,
                        tesdaDocuments,
                        profileImage ?? await getDefaultProfileImage(),
                      );

                       setState(() => isSaving = false);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0272B1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(saveText, style: GoogleFonts.openSans(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for sectioned layout
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.openSans(
              color: const Color(0xFF0272B1),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  // Consistent InputDecoration for text fields
  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.openSans(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF1F4FF),
      border: const OutlineInputBorder(borderSide: BorderSide.none),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0272B1), width: 2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  // Consistent InputDecorationTheme for dropdowns
  InputDecorationTheme _dropdownDecoration() {
    return const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF1F4FF),
      border: OutlineInputBorder(borderSide: BorderSide.none),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0272B1), width: 2)),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  //TESDA Document Card (must be viewable and deletable)
  Widget buildDocumentCard(String fileName, String fileSize, String fileType) {
    return Card(
      color: const Color(0xFFF1F4FF),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: SizedBox(
          width: 335,
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fileName, style: const TextStyle(fontSize: 10), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, maxLines: 2),
                    const SizedBox(height: 5,),
                    //File Details
                    Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(fileSize, style: const TextStyle(fontSize: 10)),
                      const Text(' | ', style: TextStyle(fontSize: 10)),
                      Text(fileType, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  ],
                ),
              )
            ],
          ),
        )
      )
    );
  }
}

