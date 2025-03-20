import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/controller/profile_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
        _userController.clientAddressController.text =
            _user?.client?.clientAddress ?? '';
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
                      left: 40, right: 40, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Edit and update buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            //Form to be displayed will be determined by the role of the user

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
                                  //Update Client Information
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color(0xFF0272B1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              10)),
                                ),
                                icon: Icon(Icons.logout,
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
                      if (role == "Client") ...[
                        Text(
                          'About me',
                          style: GoogleFonts.openSans(
                            color: Color(0xFF0272B1),
                            fontSize: 14,
                          ),
                        ),
                        TextFormField(
                          maxLines: 2,
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
                        // Example fields for Tasker (customize as needed)
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
