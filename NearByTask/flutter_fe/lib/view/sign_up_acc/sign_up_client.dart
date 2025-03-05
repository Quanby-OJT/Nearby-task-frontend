import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';

class SignUpClientAcc extends StatefulWidget {
  final String role;
  const SignUpClientAcc({super.key, required this.role});

  @override
  State<SignUpClientAcc> createState() => _SignUpClientAccState();
}

class _SignUpClientAccState extends State<SignUpClientAcc> {
  //int currentStep = 0;

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
                'assets/images/icons8-checklist-100-colored.png', // Replace with your actual logo path
                height: 150,
                width: 150,
              ),
              SizedBox(height: 20), // Spa
              Text(
                'Create a New Client Account',
                style: TextStyle(
                    color: const Color(0xFF0272B1),
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                child: Text(
                  textAlign: TextAlign.center,
                  "With ONE SWIPE, You can Find a New Tasker in a MATTER OF SECONDS.",
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
                              value!.isEmpty ? "Passwords do not match" : null,
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
                            padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0272B1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 30),
                              ),
                              onPressed: () {
                                _controller.registerUser(context);
                              },
                              child: Text(
                                  'Create New Client Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white
                                ),
                              ),
                            ),
                          )]),
                  )
              ),
              TextButton(
                  onPressed: () {
                    // Navigator.push(context,
                    //     MaterialPageRoute(builder: (context) {
                    //       return SignIn();
                    //     }));
                  },
                  child: Text(
                    textAlign: TextAlign.right,
                    'Already have an account',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )),
            ],
          ),
        ));
  }

  // List<Step> getSteps() => [
  //       Step(
  //           state: currentStep > 0 ? StepState.complete : StepState.indexed,
  //           isActive: currentStep >= 0,
  //           title: Text('Basic Information'),
  //           content: Column(
  //             children: [
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.firstNameController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       value!.isEmpty ? "First name is required" : null,
  //                   decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Color(0xFFF1F4FF),
  //                       hintText: 'First Name',
  //                       hintStyle: TextStyle(color: Colors.grey),
  //                       enabledBorder: OutlineInputBorder(
  //                           borderSide:
  //                               BorderSide(color: Colors.transparent, width: 0),
  //                           borderRadius: BorderRadius.circular(10)),
  //                       focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                           borderSide: BorderSide(
  //                               color: Color(0xFF0272B1), width: 2))),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.lastNameController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       value!.isEmpty ? "Last name is required" : null,
  //                   decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Color(0xFFF1F4FF),
  //                       hintText: 'Last Name',
  //                       hintStyle: TextStyle(color: Colors.grey),
  //                       enabledBorder: OutlineInputBorder(
  //                           borderSide:
  //                               BorderSide(color: Colors.transparent, width: 0),
  //                           borderRadius: BorderRadius.circular(10)),
  //                       focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                           borderSide: BorderSide(
  //                               color: Color(0xFF0272B1), width: 2))),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       value!.isEmpty ? "Contact is required" : null,
  //                   decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Color(0xFFF1F4FF),
  //                       hintText: 'Contact number',
  //                       hintStyle: TextStyle(color: Colors.grey),
  //                       enabledBorder: OutlineInputBorder(
  //                           borderSide:
  //                               BorderSide(color: Colors.transparent, width: 0),
  //                           borderRadius: BorderRadius.circular(10)),
  //                       focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                           borderSide: BorderSide(
  //                               color: Color(0xFF0272B1), width: 2))),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       value!.isEmpty ? "Address is required" : null,
  //                   decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Color(0xFFF1F4FF),
  //                       hintText: 'Address',
  //                       hintStyle: TextStyle(color: Colors.grey),
  //                       enabledBorder: OutlineInputBorder(
  //                           borderSide:
  //                               BorderSide(color: Colors.transparent, width: 0),
  //                           borderRadius: BorderRadius.circular(10)),
  //                       focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                           borderSide: BorderSide(
  //                               color: Color(0xFF0272B1), width: 2))),
  //                 ),
  //               ),
  //             ],
  //           )),
  //       Step(
  //           state: currentStep > 1 ? StepState.complete : StepState.indexed,
  //           isActive: currentStep >= 1,
  //           title: Text('Authentication'),
  //           content: Column(
  //             children: [
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.emailController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       value!.isEmpty ? "Email is required" : null,
  //                   decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Color(0xFFF1F4FF),
  //                       hintText: 'Enter email',
  //                       hintStyle: TextStyle(color: Colors.grey),
  //                       enabledBorder: OutlineInputBorder(
  //                           borderSide:
  //                               BorderSide(color: Colors.transparent, width: 0),
  //                           borderRadius: BorderRadius.circular(10)),
  //                       focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                           borderSide: BorderSide(
  //                               color: Color(0xFF0272B1), width: 2))),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.passwordController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       value!.isEmpty ? "Password is required" : null,
  //                   decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Color(0xFFF1F4FF),
  //                       hintText: 'Enter password',
  //                       hintStyle: TextStyle(color: Colors.grey),
  //                       enabledBorder: OutlineInputBorder(
  //                           borderSide:
  //                               BorderSide(color: Colors.transparent, width: 0),
  //                           borderRadius: BorderRadius.circular(10)),
  //                       focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                           borderSide: BorderSide(
  //                               color: Color(0xFF0272B1), width: 2))),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.confirmPasswordController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       value!.isEmpty ? "Password is required" : null,
  //                   decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Color(0xFFF1F4FF),
  //                       hintText: 'Confirm password',
  //                       hintStyle: TextStyle(color: Colors.grey),
  //                       enabledBorder: OutlineInputBorder(
  //                           borderSide:
  //                               BorderSide(color: Colors.transparent, width: 0),
  //                           borderRadius: BorderRadius.circular(10)),
  //                       focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                           borderSide: BorderSide(
  //                               color: Color(0xFF0272B1), width: 2))),
  //                 ),
  //               )
  //             ],
  //           )),
  //       Step(
  //           isActive: currentStep >= 2,
  //           title: Text('Certificates'),
  //           content: Column(
  //             children: [
  //               ElevatedButton(
  //                 onPressed: _pickImage,
  //                 child: Text("Pick Image"),
  //               ),
  //               // Image Picker Button End
  //
  //               // Show Selected Image Start (if any if not yung icon makikita base sa baba)
  //               _selectedImage != null
  //                   ? Column(
  //                       children: [
  //                         // Text("Selected Image: $_imageName"),
  //                         Image.file(
  //                           _selectedImage!,
  //                           height: 200,
  //                           width: 200,
  //                         ), // Show image
  //                       ],
  //                     )
  //                   : Text("No Image Selected"),
  //             ],
  //           )),
  //     ];
}
