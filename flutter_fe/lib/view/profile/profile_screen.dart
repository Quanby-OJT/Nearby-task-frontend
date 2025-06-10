import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:intl/intl.dart';
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
  final EscrowManagementController _escrowController =
      EscrowManagementController();
  int taskerId = 0;
  AuthenticatedUser? _user;
  bool _isLoading = true;
  final bool _isConfirmed = false;
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

  final bool _isAmountVisible = false;
  @override
  void initState() {
    super.initState();
    _fetchUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    fetchSpecialization();
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
    role = storage.read("role");
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _userController.getAuthenticatedUser(context, userId);
      setState(() {
        _user = user;
        _isLoading = false;
        taskerId = _user?.user.id ?? 0;
        _userController.firstNameController.text = _user?.user.firstName ?? '';
        _userController.middleNameController.text =
            _user?.user.middleName ?? '';
        _userController.lastNameController.text = _user?.user.lastName ?? '';
        _userController.emailController.text = _user?.user.email ?? '';
        _userController.birthdateController.text = _user?.user.birthdate ?? '';
        _userController.prefsController.text = '';
        _userController.clientAddressController.text = '';
        _userController.bioController.text = _user?.user.bio ?? '';
        _userController.specializationController.text = '';
        _userController.skillsController.text = '';
        _userController.availabilityController.text = "I am available";

        _userController.payPeriodController.text = '';
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

        _userController.wageController.text = '';

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

  /// This uploads Legal Documents, if needed.
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

  Future<void> _loadData() async {
    await _escrowController.fetchTokenBalance();
    setState(() => _isLoading = false);
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return format.format(amount);
  }

  Widget buildFilePreview(dynamic file, int index) {
    debugPrint("File: $file");

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
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
              color: Color(0xFFE23670),
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
            child: Form(
                key: updateTasker,
                child: Column(children: [
                  Center(
                      child: Column(children: [
                    GestureDetector(
                      onTap: pickProfilePicture,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!)
                            : _user?.user.imageName != null
                                ? NetworkImage(_user!.user.imageName!)
                                : null,
                        child: profileImage == null &&
                                _user?.user.imageName == null
                            ? Icon(Icons.camera_alt,
                                color: Colors.grey[800], size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${_user?.user.firstName} ${_user?.user.middleName} ${_user?.user.lastName}",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_user?.user.role == "Tasker") ...[
                      const SizedBox(height: 16),
                      Text("${_user?.tasker?.specialization}",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4A4A68),
                          )),
                      const SizedBox(height: 16),
                    ]
                  ])),
                  const SizedBox(height: 32),
                  _buildSection(
                      title: 'Personal Information',
                      description:
                          'This is where you can edit your personal information',
                      children: [
                        _buildTextField(
                          controller: _userController.emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _userController.birthdateController,
                          label: 'Birthdate',
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                            controller: _userController.bioController,
                            label: 'Bio',
                            icon: null,
                            hintText:
                                "Make it as spicy and professional as possible.",
                            maxLines: 5),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                            controller:
                                _userController.specializationController,
                            label: 'Specialization',
                            items: specialization)
                      ]),
                  const SizedBox(height: 8),
                  _buildSection(
                      title: 'Your Social Media Profiles',
                      description:
                          'Add your social media profiles to boost your credibility.',
                      children: [
                        // Facebook
                        _buildTextField(
                          controller: _userController.fbLinkController,
                          label: 'Facebook Profile URL',
                          icon: Icons.facebook,
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
                          icon: Icons.camera_alt,
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
                          icon: Icons.chat,
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
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0272B1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[600]!, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hintText,
          ),
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required List<String> items,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          )),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        onChanged: willEdit
            ? (value) {
                setState(() {
                  controller.text = value!;
                });
              }
            : null,
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          );
        }).toList(),
      )
    ]);
  }
}
