import 'dart:io';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/view/profile/payment_processing.dart';
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

  bool _isAmountVisible = false;
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

        _userController.streetAddressController.text =
            _user?.tasker?.address?['street_address'] ?? '';
        _userController.barangayController.text =
            _user?.tasker?.address?['barangay'] ?? '';
        _userController.cityController.text =
            _user?.tasker?.address?['city'] ?? '';
        _userController.provinceController.text =
            _user?.tasker?.address?['province'] ?? '';
        _userController.postalCodeController.text =
            _user?.tasker?.address?['postal_code'] ?? '';
        _userController.countryController.text =
            _user?.tasker?.address?['country'] ?? '';
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
        centerTitle: true,
        title: Text(
          'Your Profile Information',
          style: GoogleFonts.poppins(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Form(
            key: updateTasker,
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        "${_user?.user.firstName} ${_user?.user.middleName} ${_user?.user.lastName}",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 3,
                    child: SizedBox(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    _isAmountVisible ? NumberFormat.currency(locale: 'en_PH', symbol: 'PHP ').format(_escrowController.tokenCredits.value) : "PHP ***********",
                                    style: GoogleFonts.poppins(
                                        fontSize: 30,
                                        fontWeight:
                                        FontWeight.bold,
                                        color:
                                        Color(0xFF3C28CC))),
                                IconButton(
                                    icon: Icon(
                                        _isAmountVisible
                                            ? FontAwesomeIcons.eye
                                            : FontAwesomeIcons
                                            .eyeSlash,
                                        color: Color(0xFF3C28CC)),
                                    onPressed: () => setState(
                                          () {
                                        _isAmountVisible =
                                        !_isAmountVisible;
                                      },
                                    ))
                              ],
                            ),
                            Text("Current Balance",
                                style: GoogleFonts.poppins()),
                            const SizedBox(height: 15),
                            //User Wallet
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 20.0,
                                        vertical: 15.0),
                                    backgroundColor:
                                    Color(0xFF0272B1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            10.0))),
                                onPressed: () =>
                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => PaymentProcessingPage()
                                    )
                                    ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (role == "Tasker") ...[
                                      const Icon(
                                          FontAwesomeIcons
                                              .moneyBillTransfer,
                                          size: 14,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                          "Withdraw Amount",
                                          style:
                                          GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors
                                                  .white,
                                              fontWeight:
                                              FontWeight
                                                  .w600))
                                    ],
                                    if(role == "Client")...[
                                      const Icon(FontAwesomeIcons.piggyBank, size: 14, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text("Deposit Amount", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600))
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      )
                    )
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your social media profiles to enhance your verification',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

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
              ]
            )
          )
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: Icon(icon, color: Colors.grey[600]),
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
}