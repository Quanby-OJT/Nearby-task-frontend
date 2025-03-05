import 'dart:io';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';

class SignUpTaskerAcc extends StatefulWidget {
  final String role;
  const SignUpTaskerAcc({super.key, required this.role});

  @override
  State<SignUpTaskerAcc> createState() => _SignUpTaskerAccState();
}

class _SignUpTaskerAccState extends State<SignUpTaskerAcc> {

  final ProfileController _controller = ProfileController();

  @override
  void initState(){
    super.initState();
    _controller.roleController.text = widget.role;
  }
  // File? _selectedImage; // Store the selected image bytes
  // String? _imageName; // Store the selected image name
  //
  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(
  //     source:
  //         ImageSource.gallery, // Change to ImageSource.camera for camera input
  //   );

    // if (pickedFile != null) {
    //   setState(() {
    //     _selectedImage = File(pickedFile.path); // Store the selected file
    //     _imageName = pickedFile.name; // Store file name
    //     _controller.setImage(
    //         _selectedImage!, _imageName!); // Pass image to controller
    //   });
    // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/images/icons8-worker-100-colored.png', // Replace with your actual logo path
              height: 150,
              width: 150,
            ),
            SizedBox(height: 20), // Spa
            Text(
              'Create a New Tasker Account',
              style: TextStyle(
                  color: const Color(0xFF0272B1),
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 20, right: 20),
              child: Text(
                textAlign: TextAlign.center,
                "With ONE SWIPE, You can Find a New Task in a Matter of Seconds.",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
              ),
            ),
            SizedBox(
              height: 450,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme:
                    ColorScheme.light(primary: Color(0xFF0272B1)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                      child: TextFormField(
                        controller: _controller.firstNameController,
                        cursorColor: Color(0xFF0272B1),
                        validator: (value) =>
                        value!.isEmpty ? "Please Input Your First Name" : null,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F4FF),
                            hintText: 'First Name',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: Color(0xFF0272B1), width: 2))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                      child: Row(
                        children: [
                          // Middle Name Field
                          Expanded(
                            child: TextFormField(
                              controller: _controller.middleNameController, // Make sure this controller exists
                              cursorColor: Color(0xFF0272B1),
                              validator: (value) =>
                              value!.isEmpty ? "Please Input Your Middle Name" : null,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color(0xFFF1F4FF),
                                hintText: 'Middle Name',
                                hintStyle: TextStyle(color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.transparent, width: 0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Color(0xFF0272B1), width: 2),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10), // Spacing between the fields
                          // Last Name Field
                          Expanded(
                            child: TextFormField(
                              controller: _controller.lastNameController,
                              cursorColor: Color(0xFF0272B1),
                              validator: (value) =>
                              value!.isEmpty ? "Please Input Your Last Name" : null,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color(0xFFF1F4FF),
                                hintText: 'Last Name',
                                hintStyle: TextStyle(color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.transparent, width: 0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Color(0xFF0272B1), width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                      child: TextFormField(
                        controller: _controller.emailController,
                        cursorColor: Color(0xFF0272B1),
                        validator: (value) =>
                            value!.isEmpty ? "Please Input Your Valid Email" : null,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F4FF),
                            hintText: 'Your Valid Email',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.transparent, width: 0),
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: Color(0xFF0272B1), width: 2))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                      child: TextFormField(
                        obscureText: true,
                        cursorColor: Color(0xFF0272B1),
                        validator: (value) =>
                            value!.isEmpty ? "Your Password Must had at least 6 characters long" : null,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F4FF),
                            hintText: 'Your Password',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.transparent, width: 0),
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: Color(0xFF0272B1), width: 2))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                      child: TextFormField(
                        obscureText: true,
                        cursorColor: Color(0xFF0272B1),
                        validator: (value) =>
                            value!.isEmpty ? "Please Confirm Your Password" : null,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F4FF),
                            hintText: 'Confirmed Password',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.transparent, width: 0),
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: Color(0xFF0272B1), width: 2))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0272B1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _controller.registerUser(context);
                        },
                        child: Text(
                          'Create a New Tasker Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                    ),
                  )]),
                )
              ),
              TextButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SignIn();
                    }));
                  },
                  child: Text(
                    textAlign: TextAlign.right,
                    'Already have an account?',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )
              ),
          ],
        ),
      )
    );
  }
}
