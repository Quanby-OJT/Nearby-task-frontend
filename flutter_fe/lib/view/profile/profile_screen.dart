import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/model/specialization.dart';

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
  bool willEdit = true; // Start in edit mode by default
  String selectedSpecialization = "";
  String selectedAvailability = "";
  String selectedGender = "";
  List<String> specialization = [];
  List<String> gender = ["Male", "Female", "Non-Binary", "I don't Want to Say"];
  List<String> availability = ['Set Your Availability', 'I am available', 'I am not available'];
  List<SpecializationModel> _specializations = [];

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
        _userController.wageController.text = _user?.tasker?.wage.toString() ?? '';
        _userController.genderController.text = _user?.user.gender ?? '';
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

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
                          backgroundImage: const AssetImage('assets/images/image1.jpg'),
                        ),
                        if (willEdit)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 28),
                            onPressed: () {
                              // Logic to change profile picture
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
                              DropdownMenu(
                                width: double.infinity,
                                enabled: willEdit,
                                controller: _userController.genderController,
                                leadingIcon: const Icon(Icons.person),
                                label: const Text("Gender"),
                                inputDecorationTheme: _dropdownDecoration(),
                                onSelected: (String? gender) {
                                  setState(() {
                                    selectedGender = gender ?? "I don't Want to Say";
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
                            ],
                          ),
                          _buildSection(
                            title: "Professional Details",
                            children: [
                              DropdownMenu(
                                width: double.infinity,
                                enabled: willEdit,
                                controller: _userController.specializationController,
                                leadingIcon: const Icon(Icons.cases_outlined),
                                label: const Text("Specialization"),
                                inputDecorationTheme: _dropdownDecoration(),
                                onSelected: (String? spec) {
                                  setState(() {
                                    selectedSpecialization = spec ?? "";
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
                                    selectedAvailability = spec ?? "Set Your Availability";
                                    _userController.availabilityController.text = spec!;
                                  });
                                },
                                dropdownMenuEntries: availability.map<DropdownMenuEntry<String>>(
                                      (String value) => DropdownMenuEntry(value: value, label: value),
                                ).toList(),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                inputFormatters: [
                                  CurrencyTextInputFormatter.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2),
                                ],
                                controller: _userController.wageController,
                                enabled: willEdit,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(hintText: "Enter your rate"),
                              ),
                            ],
                          ),
                          _buildSection(
                            title: "My TESDA Documents",
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 200,
                                child: Placeholder(
                                  child: Center(child: Text("Tap to upload", style: GoogleFonts.openSans())),
                                ),
                              ),
                            ],
                          ),
                          _buildSection(
                            title: "Social Media Links",
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(onPressed: () {}, icon: const Icon(Icons.facebook)),
                                  IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt)),
                                  IconButton(onPressed: () {}, icon: const Icon(Icons.cases_outlined)),
                                  IconButton(onPressed: () {}, icon: const Icon(Icons.tiktok)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
                    onPressed: willEdit ? () {
                      // Call updateUser logic here
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0272B1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text('Save', style: GoogleFonts.openSans(color: Colors.white)),
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
}