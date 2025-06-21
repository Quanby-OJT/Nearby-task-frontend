import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/view/service_acc/task_information.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_fe/controller/task_controller.dart';

import 'package:flutter_fe/view/task/task_disputed.dart';

import 'package:flutter_fe/model/task_model.dart';

class DisputeBottomSheet extends StatefulWidget{
  final TaskModel taskInformation;
  final ClientRequestModel requestInformation;
  const DisputeBottomSheet({
    super.key,
    required this.taskInformation,
    required this.requestInformation
  });

  @override
  State<DisputeBottomSheet> createState() => _DisputeBottomSheetState();
}

class _DisputeBottomSheetState extends State<DisputeBottomSheet>{
  Key formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  final TaskController taskController = TaskController();

  final TextEditingController _disputeTypeController = TextEditingController();
  final TextEditingController _disputeDetailsController =
  TextEditingController();
  final List<File> _imageEvidence = [];
  final ImagePicker _picker = ImagePicker();
  bool IsWeb = false;

  @override
  void dispose(){
    _feedbackController.dispose();
    _reportController.dispose();
    _disputeTypeController.dispose();
    _disputeDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imageEvidence.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can upload a maximum of 5 images.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 100,
        maxWidth: 1000,
        maxHeight: 1000,
      );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var pickedFile in pickedFiles) {
          if (_imageEvidence.length < 5) {
            _imageEvidence.add(File(pickedFile.path));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can upload a maximum of 5 images. Some images were not added.'),
                backgroundColor: Colors.orange,
              ),
            );
            break;
          }
        }
      });
    }
  }


  @override
  Widget build(BuildContext context){
    Color color = Color(0xFFB71A4A);

    return Form(
        key: GlobalKey<FormState>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'File a Dispute',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Reason for Dispute',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _disputeTypeController.text.isEmpty
                      ? '--Select Reason of Dispute--'
                      : _disputeTypeController.text,
                  items: <String>[
                    '--Select Reason of Dispute--',
                    'Poor Quality of Work',
                    'Breach of Contract',
                    'Task Still Not Completed',
                    'Tasker Did Not Finish what\'s Required',
                    'Others (Provide Details)'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _disputeTypeController.text = newValue ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Details of the Dispute',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _disputeDetailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Provide Details About the Dispute',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  'Provide some Evidence',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: (_imageEvidence.length < 5) ? Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageEvidence.isNotEmpty
                        ? SizedBox(
                      width: 300.0,
                      height: 240,
                      child: GridView.builder(
                        itemCount: _imageEvidence.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return Stack(
                            children: [
                              Center(
                                child: IsWeb
                                    ? Image.network(_imageEvidence[index].path)
                                    : Image.file(_imageEvidence[index]),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _imageEvidence.removeAt(index);
                                  }),
                                  child: Icon(Icons.remove_circle, color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                        : const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.fileImage,
                              size: 40, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Upload Photos (Screenshots, Actual Work)',
                            style:
                            TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ) : Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 300.0,
                      child: GridView.builder(
                        itemCount: _imageEvidence.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return Stack(
                            children: [
                              Center(
                                child: IsWeb
                                    ? Image.network(_imageEvidence[index].path)
                                    : Image.file(_imageEvidence[index]),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _imageEvidence.removeAt(index);
                                  }),
                                  child: Icon(FontAwesomeIcons.solidCircleXmark, color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        bool result = await taskController.raiseADispute(
                          widget.requestInformation.task_taken_id ?? 0,
                          'Disputed',
                          widget.taskInformation.client?.user?.role ??
                              '',
                          _disputeTypeController.text,
                          _disputeDetailsController.text,
                          _imageEvidence,
                        );

                        if (result) {
                          if (mounted){
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Dispute has been raised. We will resolved it as soon as possible.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.amber,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }else{
                            return;
                          }

                          // Navigator.pushReplacement(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => TaskDisputed(
                          //       taskInformation: widget.taskInformation!,
                          //     ),
                          //   ),
                          // );

                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to raise dispute. Please Try Again.",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e, stackTrace) {
                        debugPrint("Error raising dispute: $e.");
                        debugPrintStack(stackTrace: stackTrace);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Error occurred",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Open a Dispute',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        )
    );
  }
}