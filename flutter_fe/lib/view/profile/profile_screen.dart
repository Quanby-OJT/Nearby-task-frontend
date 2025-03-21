import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'dart:ffi';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _userController = ProfileController();
  final AuthenticationController _authController = AuthenticationController();
  final GetStorage storage = GetStorage();
  AuthenticatedUser? _user;
  bool _isLoading = true;
  static String? role;
  bool willEdit = false;
  String? selectedSpecialization;
  String? selectedAvailability;
  List<String> specialization = [];
  List<SpecializationModel> _specializations = [];
  List<String> availability = ['Set Your Availability', 'I am available', 'I am not Available'];
  bool submitting = false;

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

  Future<void> updateUser() async {
    bool isUpdated = false;
  }

  Future<void> _fetchUserData() async {
    role = storage.read("role");
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _userController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
      setState(() {
        _user = user;
        _isLoading = false;
        // General Information
        _userController.emailController.text = _user?.user.email ?? '';
        _userController.birthdateController.text = _user?.user.birthdate ?? '';

        // Client Information
        _userController.prefsController.text = _user?.client?.preferences ?? '';
        _userController.clientAddressController.text = _user?.client?.clientAddress ?? '';

        //Tasker Information
        _userController.bioController.text = _user?.tasker?.bio ?? '';
        _userController.specializationController.text = _user?.tasker?.specialization ?? '';
        _userController.skillsController.text = _user?.tasker?.skills ?? '';
        _userController.availabilityController.text = _user?.tasker?.availability == true ? "I am available" : "I am not available";
        _userController.taskerAddressController.text = _user?.tasker?.taskerAddress ?? '';
        _userController.wageController.text = _user?.tasker?.wage.toString() ?? '';
        _userController.payPeriodController.text = _user?.tasker?.payPeriod ?? '';
        _userController.birthdateController.text = _user?.tasker?.birthDate.toString() ?? '';
        _userController.contactNumberController.text = _user?.tasker?.phoneNumber ?? '';
        _userController.genderController.text = _user?.tasker?.gender ?? '';
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Edit Your Profile',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment(0, -0.85),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        AssetImage('assets/images/image1.jpg'),
                  ),
                ),

                //This is only temporary, as functionalities will be prioritized first.
                Padding(
                  padding: const EdgeInsets.only(
                      left: 40, right: 40, top: 20, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Edit and update buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0, bottom: 10.0),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 125,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    willEdit = !willEdit;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color(0xFF0272B1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              10)),
                                ),
                                child: Text(
                                  willEdit
                                      ? 'Cancel'
                                      : 'Edit Profile',
                                  style: GoogleFonts.openSans(
                                      fontSize: 14,
                                      color: Colors.white),
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 50,
                              width: 200,
                              child: ElevatedButton.icon(
                                onPressed: () {

                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color(0xFF0272B1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              10)),
                                ),

                                icon: Icon(Icons.save_as,
                                    color: Colors.white),
                                label: Text(
                                  'Update Information',
                                  style: GoogleFonts.openSans(
                                      fontSize: 14,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //Form to be displayed will be determined by the role of the user
                      if (role == "Client") ...[
                        Text(
                          'About me',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                            fontSize: 14,
                          ),
                        ),
                        TextFormField(
                          maxLines: 5,
                          controller:
                              _userController.prefsController,
                          enabled: willEdit,
                          cursorColor: Color(0xFF0272B1),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F4FF),
                            hintText: 'Write about yourself',
                            hintStyle:
                                TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none),
                          ),
                        ),
                        Text(
                          'My Address',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                            fontSize: 14,
                          ),
                        ),
                        TextField(
                          controller: _userController
                              .clientAddressController,
                          enabled: willEdit,
                          cursorColor: Color(0xFF0272B1),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F4FF),
                            hintText:
                                'Enter your address', // Corrected hint text for clarity
                            hintStyle:
                                TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                      // Fields for "Tasker" role
                      if (role == "Tasker") ...[
                        // General Tasker Information

                        //About Tasker
                        Text(
                          'About me',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                            fontSize: 14,
                          ),
                        ),
                        TextFormField(
                          maxLines: 5,
                          controller:
                          _userController.bioController,
                          enabled: willEdit,
                          cursorColor: Color(0xFF0272B1),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F4FF),
                            hintText: 'Write about yourself',
                            hintStyle:
                            TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none),
                          ),
                        ),

                        //Specialization
                        Text(
                          'My Specialization',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                            fontSize: 14,
                          ),
                        ),
                        DropdownMenu(
                          width: 400,
                          enabled: willEdit,
                          controller: _userController.specializationController,
                          enableFilter: true,
                          leadingIcon: const Icon(Icons.cases_outlined),
                          label: const Text('Select Specialization'),
                          inputDecorationTheme: const InputDecorationTheme(
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                          ),
                          onSelected: (String? spec) {
                            setState(() {
                              selectedSpecialization = spec;
                              _userController.specializationController.text = spec!;
                              debugPrint(_userController.specializationController.text);
                            });
                          },
                          dropdownMenuEntries: specialization.map<DropdownMenuEntry<String>>((String value) {
                            return DropdownMenuEntry<String>(value: value, label: value);
                          }).toList(),
                        ),


                        //Skills (displayed as badge)
                        Text(
                          'My Skills',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                            fontSize: 14,
                          )
                        ),
                        TextFormField(
                          maxLines: 5,
                          controller: _userController.skillsController,
                          enabled: willEdit,
                          cursorColor: Color(0xFF0272B1),
                        ),

                        //Tasker Address
                        Text(
                          'My Address',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                            fontSize: 14,
                          )
                        ),
                        TextField(
                          controller: _userController.taskerAddressController,
                          enabled: willEdit,
                          cursorColor: Color(0xFF0272B1),
                        ),

                        //Availability
                        Text(
                          'Are you Available?',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                          )
                        ),
                        DropdownMenu(
                          enabled: willEdit,
                          width: 400,
                          controller: _userController.availabilityController,
                          enableFilter: true,
                          label: const Text("Set Your Availability"),
                          leadingIcon: const Icon(Icons.event_available),
                          inputDecorationTheme: const InputDecorationTheme(
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                          ),
                          onSelected: (String? spec) {
                            setState(() {
                              selectedAvailability = spec;
                              _userController.availabilityController.text = spec!;
                              debugPrint(_userController.availabilityController.text);
                            });
                          },
                          dropdownMenuEntries: availability.map<DropdownMenuEntry<String>>((String value) {
                            return DropdownMenuEntry<String>(value: value, label: value);
                          }).toList(),
                        ),
                        //Tasker Wage
                        Text(
                            'My Current Rate',
                            style: GoogleFonts.openSans(
                              color: Color(0xFF0272B1),
                            )
                        ),
                        TextField(
                          inputFormatters: [
                            CurrencyTextInputFormatter.currency(
                              locale: 'en_PH',
                              symbol: '₱',
                              decimalDigits: 2,
                            )
                          ],
                          controller: _userController.wageController,
                          enabled: willEdit,
                          cursorColor: Color(0xFF0272B1),
                          keyboardType: TextInputType.number,
                        ),

                        //TESDA Documents Link. Will be displayed as a document.
                        Text(
                            'My TESDA Documents',
                            style: GoogleFonts.openSans(
                              color: Color(0xFF0272B1),
                            )
                        ),
                        Center(
                          child: SizedBox(
                              width: 300,
                              height: 400,
                              child: Placeholder() //To display the PDF File and this will act as a button if the user decides to replace a new file.
                          ),
                        ),
                        //Social Media Links
                        Text(
                          'My Social Media Links',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                          )
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.facebook),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.camera_alt),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.cases_outlined),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.tiktok),
                            )
                          ]
                        )
                      ],
                    ]
                  )
                )
              ]
            )
          )
        )
      )
        // body: SingleChildScrollView(
        //   child: Column(
        //     children: [
        //       Container(
        //         decoration: BoxDecoration(
        //           color: Colors.white,
        //           borderRadius: BorderRadius.only(
        //             topLeft: Radius.circular(0),
        //             topRight: Radius.circular(0),
        //           ),
        //         ),
        //         child: Padding(
        //           padding: const EdgeInsets.only(top: 20.0, bottom: 0),
        //           child: SingleChildScrollView(
        //             scrollDirection: Axis.vertical,
        //             child: Column(
        //               mainAxisAlignment: MainAxisAlignment.start,
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 //SizedBox(height: 20),
        //                 Container(
        //                   alignment: Alignment(0, -0.85),
        //                   child: CircleAvatar(
        //                     radius: 60,
        //                     backgroundColor: Colors.white,
        //                     backgroundImage:
        //                         AssetImage('assets/images/image1.jpg'),
        //                   ),
        //                 ),
        //                 Padding(
        //                   padding:
        //                       const EdgeInsets.only(left: 40, right: 40, top: 10),
        //                   child: Column(
        //                     spacing: 10,
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     children: [
        //                       Text('Name',
        //                           style: GoogleFonts.openSans(
        //                               color: Color(0xFF0272B1), fontSize: 14)),
        //                       TextField(
        //                         controller: _userController.firstNameController,
        //                         enabled: true,
        //                         cursorColor: Color(0xFF0272B1),
        //                         decoration: InputDecoration(
        //                             filled: true,
        //                             fillColor: Color(0xFFF1F4FF),
        //                             hintText:
        //                                 'John Michael Doe', // Example with middle name
        //                             hintStyle: TextStyle(color: Colors.grey),
        //                             disabledBorder: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 2)),
        //                             enabledBorder: OutlineInputBorder(
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 0),
        //                                 borderRadius: BorderRadius.circular(10)),
        //                             border: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Color(0xFF0272B1), width: 2))),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 Padding(
        //                   padding:
        //                       const EdgeInsets.only(left: 40, right: 40, top: 10),
        //                   child: Column(
        //                     spacing: 10,
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     children: [
        //                       Text('Preferences',
        //                           style: GoogleFonts.openSans(
        //                               color: Color(0xFF0272B1), fontSize: 14)),
        //                       TextField(
        //                         controller: _userController.prefsController,
        //                         enabled: true,
        //                         cursorColor: Color(0xFF0272B1),
        //                         decoration: InputDecoration(
        //                             filled: true,
        //                             fillColor: Color(0xFFF1F4FF),
        //                             hintText: 'Electrician',
        //                             hintStyle: TextStyle(color: Colors.grey),
        //                             disabledBorder: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 2)),
        //                             enabledBorder: OutlineInputBorder(
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 0),
        //                                 borderRadius: BorderRadius.circular(10)),
        //                             border: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Color(0xFF0272B1), width: 2))),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 Padding(
        //                   padding:
        //                       const EdgeInsets.only(left: 40, right: 40, top: 10),
        //                   child: Column(
        //                     spacing: 10,
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     children: [
        //                       Text('Contact Number',
        //                           style: GoogleFonts.openSans(
        //                               color: Color(0xFF0272B1), fontSize: 14)),
        //                       TextField(
        //                         enabled: true,
        //                         cursorColor: Color(0xFF0272B1),
        //                         decoration: InputDecoration(
        //                             filled: true,
        //                             fillColor: Color(0xFFF1F4FF),
        //                             hintText: '099991345262',
        //                             hintStyle: TextStyle(color: Colors.grey),
        //                             disabledBorder: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 2)),
        //                             enabledBorder: OutlineInputBorder(
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 0),
        //                                 borderRadius: BorderRadius.circular(10)),
        //                             border: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Color(0xFF0272B1), width: 2))),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 Padding(
        //                   padding:
        //                       const EdgeInsets.only(left: 40, right: 40, top: 10),
        //                   child: Column(
        //                     spacing: 10,
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     children: [
        //                       Text('Email',
        //                           style: GoogleFonts.openSans(
        //                               color: Color(0xFF0272B1), fontSize: 14)),
        //                       TextField(
        //                         controller: _userController.emailController,
        //                         enabled: true,
        //                         cursorColor: Color(0xFF0272B1),
        //                         decoration: InputDecoration(
        //                             filled: true,
        //                             fillColor: Color(0xFFF1F4FF),
        //                             hintText: 'test@gmail.com',
        //                             hintStyle: TextStyle(color: Colors.grey),
        //                             disabledBorder: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 2)),
        //                             enabledBorder: OutlineInputBorder(
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 0),
        //                                 borderRadius: BorderRadius.circular(10)),
        //                             border: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Color(0xFF0272B1), width: 2))),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 Padding(
        //                   padding:
        //                       const EdgeInsets.only(left: 40, right: 40, top: 10),
        //                   child: Column(
        //                     spacing: 10,
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     children: [
        //                       Text('Address',
        //                           style: GoogleFonts.openSans(
        //                               color: Color(0xFF0272B1), fontSize: 14)),
        //                       TextField(
        //                         controller:
        //                             _userController.clientAddressController,
        //                         enabled: true,
        //                         cursorColor: Color(0xFF0272B1),
        //                         decoration: InputDecoration(
        //                             filled: true,
        //                             fillColor: Color(0xFFF1F4FF),
        //                             hintText: 'Legazpi, Albay',
        //                             hintStyle: TextStyle(color: Colors.grey),
        //                             disabledBorder: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 2)),
        //                             enabledBorder: OutlineInputBorder(
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 0),
        //                                 borderRadius: BorderRadius.circular(10)),
        //                             border: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Color(0xFF0272B1), width: 2))),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 Padding(
        //                   padding:
        //                       const EdgeInsets.only(left: 40, right: 40, top: 10),
        //                   child: Column(
        //                     spacing: 10,
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     children: [
        //                       Text('Date of Birth',
        //                           style: GoogleFonts.openSans(
        //                               color: Color(0xFF0272B1), fontSize: 14)),
        //                       TextField(
        //                         controller: _userController.birthdateController,
        //                         enabled: true,
        //                         cursorColor: Color(0xFF0272B1),
        //                         decoration: InputDecoration(
        //                             filled: true,
        //                             fillColor: Color(0xFFF1F4FF),
        //                             hintText: '09/02/2000',
        //                             hintStyle: TextStyle(color: Colors.grey),
        //                             disabledBorder: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 2)),
        //                             enabledBorder: OutlineInputBorder(
        //                                 borderSide: BorderSide(
        //                                     color: Colors.transparent, width: 0),
        //                                 borderRadius: BorderRadius.circular(10)),
        //                             border: OutlineInputBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 borderSide: BorderSide(
        //                                     color: Color(0xFF0272B1), width: 2))),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 // Padding(
        //                 //   padding: const EdgeInsets.only(top: 30.0),
        //                 //   child: Container(
        //                 //       height: 50,
        //                 //       width: double.infinity,
        //                 //       padding: EdgeInsets.symmetric(horizontal: 40),
        //                 //       child: ElevatedButton.icon(
        //                 //         onPressed: () {
        //                 //           _authController.logout(context);
        //                 //         },
        //                 //         style: ElevatedButton.styleFrom(
        //                 //             backgroundColor: Color(0xFF0272B1),
        //                 //             shape: RoundedRectangleBorder(
        //                 //                 borderRadius: BorderRadius.circular(10))),
        //                 //         icon: Icon(Icons.logout, color: Colors.white),
        //                 //         label: Text('Logout',
        //                 //             style: TextStyle(color: Colors.white)),
        //                 //       )),
        //                 // ),
        //               ],
        //             ),
        //           ),
        //         ),
        //       )
        //     ],
        //   ),
        // ),
    );
  }
}
