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
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _userController = ProfileController();
  final GetStorage storage = GetStorage();
  int taskerId = 0;
  AuthenticatedUser? _user;
  bool _isLoading = true;
  static String? role;
  bool willEdit = false; // Start in edit mode by default
  List<String> specialization = [];
  List<String> gender = ["Male", "Female", "Non-Binary", "Other"];
  List<String> availability = ['I am available', 'I am not available'];
  List<SpecializationModel> _specializations = [];
  List<String> payPeriods = [
    'Hourly',
    'Daily',
    'Weekly',
    'Bi-Weekly',
    'Monthly'
  ];
  bool isSaving = false;
  File? profileImage;
  List<dynamic> tesdaDocuments = [];
  String saveText = "Save";
  final updateTasker = GlobalKey<FormState>();

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
        specialization =
            _specializations.map((spec) => spec.specialization).toList();
        _userController.specializationController.text =
            _user?.tasker?.specialization ?? '';
      });
    } catch (error) {
      print('Error fetching specializations: $error');
    }
  }

  Future<void> _fetchUserData() async {
    role = storage.read("role");
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _userController.getAuthenticatedUser(context, userId);
      setState(() {
        _user = user;
        _isLoading = false;
        taskerId = _user?.tasker?.id ?? 0;
        _userController.emailController.text = _user?.user.email ?? '';
        _userController.birthdateController.text = _user?.user.birthdate ?? '';
        _userController.prefsController.text = _user?.client?.preferences ?? '';
        _userController.clientAddressController.text =
            _user?.client?.clientAddress ?? '';
        _userController.bioController.text = _user?.tasker?.bio ?? '';
        _userController.specializationController.text =
            _user?.tasker?.specialization ?? '';
        _userController.skillsController.text = _user?.tasker?.skills ?? '';
        _userController.availabilityController.text =
            _user?.tasker?.availability == true
                ? "I am available"
                : "I am not available";
        _userController.taskerAddressController.text = '';
        _userController.payPeriodController.text =
            _user?.tasker?.payPeriod ?? '';
        _userController.genderController.text = _user?.user.gender ?? '';
        _userController.contactNumberController.text =
            _user?.user.contact.toString() ?? '';
        _userController.fbLinkController.text =
            _user?.tasker?.socialMediaLinks?['fb'] ?? '';
        _userController.instaLinkController.text =
            _user?.tasker?.socialMediaLinks?['ig'] ?? '';
        _userController.telegramLinkController.text =
            _user?.tasker?.socialMediaLinks?['tg'] ?? '';
        if (_user?.tasker?.taskerDocuments != null) {
          debugPrint("Tasker Documents: ${_user!.tasker!.taskerDocuments}");
          tesdaDocuments = [
            _user!.tasker!.taskerDocuments!
          ]; // Store as String (URL)
        }

        if (_user?.tasker?.wage != null) {
          final currencyFormat =
              NumberFormat.currency(locale: 'en_PH', symbol: '₱');
          _userController.wageController.text =
              currencyFormat.format(_user!.tasker!.wage);
        } else {
          _userController.wageController.text = '';
        }
        _userController.genderController.text = _user?.user.gender ?? '';
        _userController.fbLinkController.text =
            _user?.tasker?.socialMediaLinks?["fb"] ?? '';
        _userController.instaLinkController.text =
            _user?.tasker?.socialMediaLinks?["ig"] ?? '';
        _userController.telegramLinkController.text =
            _user?.tasker?.socialMediaLinks?["tg"] ?? '';
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

    if (result != null && result.files.single.path != null) {
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
    debugPrint("File: " + file.toString());

    if (file is String && file.isNotEmpty) {
      Uri? fileUri = Uri.tryParse(file);
      if (fileUri != null && fileUri.hasAbsolutePath) {
        String fileExtension = file.split('.').last.toLowerCase();

        if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          // If the file is an image, display it
          return Image.network(file,
              width: double.infinity, height: 100, fit: BoxFit.cover);
        } else if (fileExtension == 'pdf') {
          // If it's a PDF, show an icon + open it in browser
          return InkWell(
            onTap: () => _openFile(file), // Open in browser
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
                            file.split('/').last,
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

    return const Text('Unsupported file type');
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Edit Your Profile',
          style: GoogleFonts.roboto(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Expanded(
        child: SingleChildScrollView(
            child: Form(
                key: updateTasker,
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
                              backgroundImage: NetworkImage(
                                _isLoading
                                    ? '/assets/images/default-profile.jpg'
                                    : '${_user?.user.image}',
                              ),
                              // backgroundImage: profileImage != null
                              //   ? FileImage(profileImage!)
                              //     : const AssetImage('assets/images/default-profile.jpg') as ImageProvider,
                            ),
                            profileImage != null
                                ? CircleAvatar(
                                    radius: 70,
                                    backgroundImage: FileImage(profileImage!))
                                : CircleAvatar(
                                    radius: 70,
                                    backgroundImage:
                                        NetworkImage('${_user?.user.image}'),
                                  ),
                            if (willEdit)
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white, size: 28),
                                onPressed: () {
                                  // Logic to change profile picture
                                  pickProfilePicture();
                                },
                                padding: const EdgeInsets.all(0),
                                style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF0272B1)),
                              ),
                          ],
                        ),
                      ),

                      // User Name (non-editable for now)
                      Text(
                        '${_user?.user.firstName ?? "User"} ${_user?.user.lastName ?? ""}',
                        style: GoogleFonts.openSans(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Form Fields
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (role == "Client") ...[
                              _buildSection(
                                title: "About Me",
                                children: [
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your desired preferences";
                                      }

                                      return null;
                                    },
                                    maxLines: 5,
                                    controller: _userController.prefsController,
                                    enabled: willEdit,
                                    decoration: _inputDecoration(
                                        hintText: "Write about yourself"),
                                  ),
                                ],
                              ),
                              _buildSection(
                                title: "My Address",
                                children: [
                                  TextFormField(
                                    controller:
                                        _userController.clientAddressController,
                                    enabled: willEdit,
                                    decoration: _inputDecoration(
                                        hintText: "Enter your address"),
                                  ),
                                ],
                              ),
                            ],
                            if (role == "Tasker") ...[
                              _buildSection(
                                title: "Personal Details",
                                children: [
                                  Text(
                                      "This is how you describe yourself as a tasker. Give it your best shot to attract more clients and earn more."),
                                  const SizedBox(height: 20),
                                  DropdownMenu(
                                    width: double.infinity,
                                    enabled: willEdit,
                                    controller:
                                        _userController.genderController,
                                    leadingIcon: const Icon(Icons.person),
                                    label: const Text("Gender"),
                                    inputDecorationTheme: _dropdownDecoration(),
                                    onSelected: (String? gender) {
                                      setState(() {
                                        _userController.genderController.text =
                                            gender!;
                                      });
                                    },
                                    dropdownMenuEntries: gender
                                        .map<DropdownMenuEntry<String>>(
                                          (String value) => DropdownMenuEntry(
                                              value: value, label: value),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your Information.";
                                      }

                                      return null;
                                    },
                                    maxLines: 5,
                                    controller: _userController.bioController,
                                    enabled: willEdit,
                                    decoration: _inputDecoration(
                                        hintText: "Write about yourself"),
                                  ),
                                  const SizedBox(height: 20),
                                  //Tasker's COntact Number
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your contact number";
                                      }

                                      return null;
                                    },
                                    controller:
                                        _userController.contactNumberController,
                                    enabled: willEdit,
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDecoration(
                                        hintText: "Enter your contact number"),
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
                                    controller: _userController
                                        .specializationController,
                                    label: const Text("Specialization"),
                                    inputDecorationTheme: _dropdownDecoration(),
                                    onSelected: (String? spec) {
                                      setState(() {
                                        _userController.specializationController
                                            .text = spec!;
                                      });
                                    },
                                    dropdownMenuEntries: specialization
                                        .map<DropdownMenuEntry<String>>(
                                          (String value) => DropdownMenuEntry(
                                              value: value, label: value),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your skills";
                                      }
                                      return null;
                                    },
                                    maxLines: 3,
                                    controller:
                                        _userController.skillsController,
                                    enabled: willEdit,
                                    decoration: _inputDecoration(
                                        hintText: "List your skills"),
                                  ),
                                  const SizedBox(height: 20),
                                  //Tasker Address
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your address.";
                                      }
                                      return null;
                                    },
                                    controller:
                                        _userController.taskerAddressController,
                                    enabled: willEdit,
                                    decoration: _inputDecoration(
                                        hintText: "Enter your address"),
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownMenu(
                                    width: double.infinity,
                                    enabled: willEdit,
                                    controller:
                                        _userController.availabilityController,
                                    leadingIcon:
                                        const Icon(Icons.event_available),
                                    label: const Text("Availability"),
                                    inputDecorationTheme: _dropdownDecoration(),
                                    onSelected: (String? spec) {
                                      setState(() {
                                        _userController.availabilityController
                                            .text = spec!;
                                      });
                                    },
                                    dropdownMenuEntries: availability
                                        .map<DropdownMenuEntry<String>>(
                                          (String value) => DropdownMenuEntry(
                                              value: value, label: value),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  //Tasker Rate and Period
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return "Please enter your rate";
                                                  }
                                                  return null;
                                                },
                                                inputFormatters: [
                                                  CurrencyTextInputFormatter
                                                      .currency(
                                                          locale: 'en_PH',
                                                          symbol: '₱',
                                                          decimalDigits: 2),
                                                ],
                                                controller: _userController
                                                    .wageController,
                                                enabled: willEdit,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: _inputDecoration(
                                                    hintText:
                                                        "Enter your rate"),
                                              ),
                                            ),
                                            Expanded(
                                              child: DropdownMenu(
                                                width: double.infinity,
                                                enabled: willEdit,
                                                controller: _userController
                                                    .payPeriodController,
                                                leadingIcon:
                                                    const Icon(Icons.schedule),
                                                inputDecorationTheme:
                                                    _dropdownDecoration(),
                                                onSelected: (String? period) {
                                                  setState(() {
                                                    _userController
                                                        .payPeriodController
                                                        .text = period!;
                                                  });
                                                },
                                                dropdownMenuEntries: payPeriods
                                                    .map<
                                                        DropdownMenuEntry<
                                                            String>>(
                                                      (String value) =>
                                                          DropdownMenuEntry(
                                                              value: value,
                                                              label: value),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ]),
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
                                            child: Text('Upload Documents',
                                                style: GoogleFonts.openSans()),
                                          ),
                                        ),
                                        if (tesdaDocuments.isNotEmpty)
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxHeight: 130),
                                            child: SizedBox(
                                              height: double.infinity,
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5),
                                                itemBuilder: (context, index) =>
                                                    Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 3),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      buildFilePreview(
                                                          tesdaDocuments[index],
                                                          index),
                                                    ],
                                                  ),
                                                ),
                                                itemCount:
                                                    tesdaDocuments.length,
                                              ),
                                            ),
                                          )
                                      ],
                                    )
                                  else if (tesdaDocuments.isNotEmpty)
                                    SizedBox(
                                      height: 80,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: tesdaDocuments.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10),
                                            child: buildFilePreview(
                                                tesdaDocuments[index], index),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            ...[
                              _buildSection(
                                title: "Social Media Links",
                                children: [
                                  Text(
                                      "To boost your profile to your desired clients (taskers), we want you to provide your Socials for your prospects to know you better."),
                                  const SizedBox(height: 20),
                                  SizedBox(width: 5),
                                  //Facebook Link
                                  Row(
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.facebook,
                                        color: Colors.blueAccent,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: TextFormField(
                                        controller:
                                            _userController.fbLinkController,
                                        enabled: willEdit,
                                        decoration: _inputDecoration(
                                            hintText: 'Enter Facebook link'),
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  //Instagram Link
                                  Row(
                                    children: [
                                      FaIcon(FontAwesomeIcons.instagram,
                                          color: Colors.pinkAccent),
                                      //color: GradientRotation(radians),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: TextFormField(
                                        controller:
                                            _userController.instaLinkController,
                                        enabled: willEdit,
                                        decoration: _inputDecoration(
                                            hintText: 'Enter Instagram link'),
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      FaIcon(FontAwesomeIcons.telegram,
                                          color: Colors.lightBlueAccent),
                                      //color: GradientRotation(radians),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: TextFormField(
                                        controller: _userController
                                            .telegramLinkController,
                                        enabled: willEdit,
                                        decoration: _inputDecoration(
                                            hintText: 'Enter Telegram link'),
                                      )),
                                    ],
                                  ),
                                  SizedBox(height: 100),
                                ],
                              )
                            ]
                          ])
                    ]))),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildActionButtons()),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      SizedBox(
        width: 120,
        child: ElevatedButton(
          onPressed: () {
            setState(() => willEdit = !willEdit);
            _fetchUserData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(willEdit ? 'Cancel' : 'Edit Profile',
              style: GoogleFonts.openSans()),
        ),
      ),
      SizedBox(
        width: 160,
        child: ElevatedButton.icon(
          onPressed: (willEdit && !isSaving)
              ? () async {
                  setState(() {
                    isSaving = true;
                    saveText = "Please Wait.";
                  });

                  if (updateTasker.currentState!.validate()) {
                    await _userController.updateUser(
                        context,
                        taskerId,
                        tesdaDocuments,
                        profileImage ?? await getDefaultProfileImage());
                  }
                  setState(() {
                    isSaving = false;
                    saveText = "Save";
                    willEdit = false;
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0272B1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          icon: Icon(isSaving ? Icons.hourglass_empty : Icons.save,
              color: Colors.white),
          label:
              Text(saveText, style: GoogleFonts.openSans(color: Colors.white)),
        ),
      )
    ];
  }

  // Helper method for sectioned layout
  Widget _buildSection(
      {required String title, required List<Widget> children}) {
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
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0272B1), width: 2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  // Consistent InputDecorationTheme for dropdowns
  InputDecorationTheme _dropdownDecoration() {
    return const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF1F4FF),
      border: OutlineInputBorder(borderSide: BorderSide.none),
      enabledBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0272B1), width: 2)),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  //TESDA Document Card (must be viewable and deletable)
  Widget buildDocumentCard(String fileName, String fileSize, String fileType) {
    return Card(
        color: const Color(0xFFF1F4FF),
        elevation: 2,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            child: SizedBox(
              width: 335,
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child:
                        Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(fileName,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2),
                        const SizedBox(height: 5),
                        //File Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(fileSize,
                                style: const TextStyle(fontSize: 10)),
                            const Text(' | ', style: TextStyle(fontSize: 10)),
                            Text(fileType,
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )));
  }
}
