import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_request_controller.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/view/chat/payment.dart';

import '../service_acc/legal_terms_and_conditions.dart';

class TaskDetailsScreen extends StatefulWidget{
  final int taskTakenId;

  const TaskDetailsScreen({super.key, required this.taskTakenId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

//Main Application Page
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final TaskRequestController taskRequestController = TaskRequestController();
  TaskAssignment? taskAssignment;
  bool _isLoading = true;
  String role = "";
  final storage = GetStorage();
  List<String> taskTaskerStatus = ['Interested', 'Confirmed', 'Rejected', 'Ongoing', 'Completed', 'Cancelled', 'Pending'];//For Tasker Only
  List<String> taskClientStatus = ['Negotiate with them', 'Confirm Tasker', 'Reject Tasker', 'Cancel the Task'];//For Client Only
  List<String> rejectionReasons = [
    'Tasker is not available',
    'I had other concerns that needed more attention',
    'Tasker is not willing to work with me',
    'Tasker does not have the required skills',
    'Others (please specify)'
  ];
  bool rejectFormField = false;
  final rejectTasker = GlobalKey<FormState>();
  String rejectionReason = "";
  bool processingData = false;
  List<String> skills = [];
  String selectedTaskStatus = "";
  String address = "";
  bool agreed = false;



  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
    setState(() {
      agreed = false;
    });
  }

  Future<void> _fetchTaskDetails() async {
    role = await storage.read('role');
    debugPrint(widget.taskTakenId.toString());
    try {
      final response = await _jobPostService.fetchAssignedTaskInformation(widget.taskTakenId);
      debugPrint("Response: $response");
      setState(() {
        taskAssignment = response;
        selectedTaskStatus = taskStatus();
        skills = taskAssignment?.tasker?.skills.split(',') ?? [];
        _isLoading = false;

        // Check if address exists and format it
        if (taskAssignment?.tasker?.address != null) {
          final addressMap = taskAssignment?.tasker?.address!;

          // Format the address string using map key access
          address = [
            addressMap?["street"] ?? "",
            addressMap?["barangay"] ?? "",
            addressMap?["city"] ?? "",
            addressMap?["province"] ?? "",
            addressMap?["country"] ?? "",
            addressMap?["postal_code"] ?? ""
          ].where((element) => element.isNotEmpty).join(", ");
        } else {
          address = "N/A";
        }
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String taskStatus() {
    switch(taskAssignment?.taskStatus){
      case "Rejected":
        return "Reject the Tasker";
      case "Cancelled":
        return "Cancel the Task";
        case "Confirmed":
        return "Confirm Tasker";
      case "Ongoing":
        return "Ongoing";
      case "Completed":
        return "Completed";
      case "Pending":
        return "Waiting for Client";
      default:
        return "Unknown";
    }
  }


  //Main Application
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Details',
          style:
          TextStyle(color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Color(0xFF0272B1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskAssignment == null
          ? const Center(child: Text('Error Loading Task Information. Please Try Again.'))
          : role == "Tasker" ? _buildClientDetails() : _buildTaskerDetails()
    );
  }

  //To be viewed by Client
  Widget _buildTaskerDetails(){
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "About the Tasker",
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0272B1),
                ),
              )
            ),
            Divider(height:30),
            _buildInfoRow(FontAwesomeIcons.user, Colors.black, "${taskAssignment?.tasker?.user?.firstName} ${taskAssignment?.tasker?.user?.middleName ?? ''} ${taskAssignment?.tasker?.user?.lastName}" ?? "N/A"),
            _buildInfoRow(FontAwesomeIcons.phone, Colors.blue, taskAssignment?.tasker?.user?.contact.toString() ?? "N/A"),
            _buildInfoRow(FontAwesomeIcons.envelope, Color(0XFFE04556), taskAssignment?.tasker?.user?.email ?? "N/A"),
            _buildInfoRow(FontAwesomeIcons.locationPin, Color(0XFFE04556), address ?? "N/A"),
            Divider(height: 30),
            Text(
              "About Me",
              style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF03045E)
              ),
            ),
            Text(
              taskAssignment?.tasker?.bio ?? "N/A",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            _buildInfoRow(FontAwesomeIcons.toolbox, Color(0XFF3C28CC), taskAssignment?.tasker?.specialization ?? "N/A"),
            Text(
              "Skills",
              style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF03045E)
              ),
            ),
            skills.isEmpty
            ? Text(
                "N/A",
                style: TextStyle(fontSize: 16)
              )
            : Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: skills.map((skill) => Chip(
                label: Text(
                  skill,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Color(0XFF03045E)
              )).toList(),
            ),
            Divider(height: 30),
            Text(
              "What will you do to the tasker?",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0XFF03045E)
              ),
            ),
            // if(taskAssignment?.taskStatus == "Pending") ...[
            //   ElevatedButton(
            //     onPressed: () => acceptTasker(context),
            //     style: ButtonStyle(
            //       backgroundColor: WidgetStateProperty.all(Color(0XFF3E9B52)),
            //     ),
            //     child: Row(
            //       children: [
            //         Icon(
            //           FontAwesomeIcons.check,
            //           color: Colors.white,
            //         ),
            //         SizedBox(width: 10,),
            //         Text(
            //           "Accept Tasker",
            //           style: GoogleFonts.roboto(
            //               fontSize: 16,
            //               color: Colors.white,
            //               fontWeight: FontWeight.bold
            //           ),
            //         )
            //       ],
            //     )
            //   ),
            //   SizedBox(width: 5,),
            //   ElevatedButton(
            //       onPressed: () => showRejectionOrCancellationForm("Reject"),
            //       style: ButtonStyle(
            //         backgroundColor: WidgetStateProperty.all(Color(0XFFD43D4D)),
            //       ),
            //       child: Row(
            //         children: [
            //           Icon(
            //             FontAwesomeIcons.trash,
            //             color: Colors.white,
            //           ),
            //           SizedBox(width: 10,),
            //           Text(
            //             "Reject Tasker",
            //             style: GoogleFonts.roboto(
            //                 fontSize: 16,
            //                 color: Colors.white,
            //                 fontWeight: FontWeight.bold
            //             ),
            //           )
            //         ],
            //       )
            //   ),
            //   ElevatedButton(
            //     onPressed: () => showRejectionOrCancellationForm("Cancel"),
            //     style: ButtonStyle(
            //       backgroundColor: WidgetStateProperty.all(Color(0XFFD43D4D)),
            //     ),
            //     child: Row(
            //       children: [
            //         Icon(
            //           FontAwesomeIcons.ban,
            //           color: Colors.white,
            //         ),
            //         SizedBox(width: 10,),
            //         Text(
            //           "Cancel the Task",
            //           style: GoogleFonts.roboto(
            //               fontSize: 16,
            //               color: Colors.white,
            //               fontWeight: FontWeight.bold
            //           ),
            //         )
            //       ],
            //     )
            //   ),
            // ],
            // const SizedBox(height: 20),
            // ///
            // /// If Tasker finishes the task on time, or the task in itself reaches its dealine, this button must appear.
            // ///
            // /// -Ces
            //
            // if(taskAssignment?.taskStatus == "Completed")...[
            //   Center(
            //     child: ElevatedButton(
            //       style: ButtonStyle(
            //         backgroundColor: WidgetStateProperty.all(Color(0XFF3E9B52)),
            //       ),
            //       onPressed: () => showCompletedTaskPayment(),
            //       child: Text(
            //         "Release Payment",
            //         style: GoogleFonts.roboto(
            //           fontSize: 16,
            //           color: Colors.white,
            //           fontWeight: FontWeight.bold
            //         ),
            //       )
            //     )
            //   )
            // ]
          ]
        ),
      )
    );
  }

  //To be Viewed by Tasker
  Widget _buildClientDetails() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                taskAssignment?.task?.title ?? "Untitled Task",
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0272B1),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Divider(height: 30),
            //About the Task
            Text(
              "About the Task",
              style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0272B1)
              ),
            ),
            Text(
              taskAssignment?.task?.description ?? "N/A",
              style: TextStyle(
                fontSize: 16,
              ),
              softWrap: true,
              textAlign: TextAlign.justify,
            ),
            _buildInfoRow(
                FontAwesomeIcons.locationPin, Colors.red, taskAssignment?.task?.location ?? "N/A"),
            _buildInfoRow(FontAwesomeIcons.gears, Colors.blue, taskAssignment?.task?.specialization ?? "N/A"),
            _buildInfoRow(
                FontAwesomeIcons.moneyBill,
                Colors.green,
                "₱ ${
                    NumberFormat(
                        "#,##0.00", "en_PH").format(
                        taskAssignment?.task?.contactPrice.roundToDouble() ?? 0.00
                    )
                }"
            ),
            Divider(height: 30),
            _buildInfoRow(FontAwesomeIcons.calendar, Colors.red, "${taskAssignment?.task?.duration} ${taskAssignment?.task?.period}"),
            _buildInfoRow(FontAwesomeIcons.clock, Colors.redAccent, taskAssignment?.task?.urgency ?? "N/A"),
            _buildInfoRow(FontAwesomeIcons.userGroup, Colors.black45, taskAssignment?.task?.workType ?? "N/A"),
            _buildInfoRow(FontAwesomeIcons.calendarDay, Colors.red, taskAssignment?.task?.taskBeginDate ?? "N/A"),
            if(role == "Tasker") ...[
              _buildInfoRow(
                  FontAwesomeIcons.toolbox, Colors.black, taskAssignment?.task?.status ?? "Unknown Status"),
            ],
            _buildInfoRow(
                FontAwesomeIcons.paperclip, Colors.brown, taskAssignment?.task?.remarks ?? "N/A"),
            Divider(height: 30),
            // _buildInfoRow(
                //     "Tasker Status", taskAssignment?.taskStatus ?? "Unknown Status"),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    "Your Current Application Status: ",
                    style: TextStyle(
                      fontSize: 16)
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor(taskAssignment?.taskStatus ?? "Unknown"), // Example background color
                    borderRadius: BorderRadius.circular(20), // Rounded edges for oblong shape
                  ),
                  child: Text(
                    taskAssignment?.taskStatus ?? "Unknown",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            if(taskAssignment?.taskStatus == "Rejected") ...[
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "Your Client's Reason: ",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Flexible(
                    child: Text(taskAssignment?.taskStatusReason ?? "N/A",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ]
              ),
              const SizedBox(height: 30),
            ]
            else if(taskAssignment?.taskStatus == "Cancelled") ...[
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "Your Client's Reason: ", style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Flexible(
                    child: Text(taskAssignment?.taskStatusReason ?? "N/A",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ]
              ),
            ]
            else if(taskAssignment?.taskStatus == "Confirmed") ...[
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Color(0XFF170A66)),
                  ),
                  onPressed: () => showLegalTermAgreement(context),
                  child: Text(
                    "Proceed to Agreement",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  )
                )
              )
            ]
          ]
        ),
      ),
    );
  }
  
  Color badgeColor(String status){
    switch(status){
      case "Rejected":
        return Color(0XFFD43D4D);
      case "Cancelled":
        return Color(0XFFD43D4D);
      case "Confirmed":
        return Color(0XFF4DBF66);
        case "Ongoing":
        return Color(0XFF3C28CC);
      case "Completed":
        return Color(0XFF2E763E);
      case "Pending":
        return Color(0XFFE7A335);
      default:
        return Colors.grey;
    } 
  }

  void showLegalTermAgreement(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Terms and Conditions"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            child: Column(
              children: [
                Text("Please Read the Legal Terms and Conditions Before Proceeding with Engaging with Your Task."),
                SizedBox(height: 10),
                InkWell(
                    onTap: () => {Navigator.of(context).push(MaterialPageRoute(builder: (context) => LegalTermsAndConditionsScreen()))},
                    child: Text(
                      "NearByTask Legal Terms and Conditions",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline
                      ),
                    )
                ),
              ]
            )
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                  "I agree"
              )
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Close"),
            ),
          ],
        );
      }
    );
  }

  Widget _buildInfoRow(IconData? label, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            label,
            size: 24,
            color: color,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true
            ),
          ),
        ],
      ),
    );
  }

  // String _handleTaskStatusChange(String newStatus) {
  //   // setState(() {
  //   //   taskAssignment?.taskStatus = newStatus;
  //   // });
  //   switch (newStatus) {
  //     case "Reject Tasker":
  //       showRejectionOrCancellationForm("Rejected");
  //       return "Rejected";
  //     case "Cancel the Task":
  //       showRejectionOrCancellationForm("Cancelled");
  //       return "Cancelled";
  //     case "Confirm Tasker":
  //       showEscrowPayment(context);
  //       return "Confirmed";
  //     case "Completed":
  //       //TODO: implement this later for Client
  //
  //       return "Completed";
  //   }
  //   return "";
  // }

  // void acceptTasker(BuildContext parentContext) {  // Add parentContext parameter
  //   showDialog(
  //     context: parentContext,  // Use parentContext here
  //     builder: (BuildContext dialogContext) {  // Rename the inner context
  //       return AlertDialog(
  //         title: Text(
  //           "Are You Sure You Want to Accept This Tasker?",
  //           style: GoogleFonts.roboto(
  //             fontSize: 30,
  //             fontWeight: FontWeight.bold,
  //             color: Color(0xFF0272B1),
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         content: Text(
  //           "Once you accept this tasker, the task will be taken and it will not be available to other Taskers.",
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () async {
  //               debugPrint("Hi");
  //             },
  //             child: Padding(
  //               padding: const EdgeInsets.all(10.0),
  //               child: Row(
  //                 children: [
  //                   Icon(FontAwesomeIcons.moneyBillTransfer, color: Colors.green, size: 20),
  //                   SizedBox(width: 20),
  //                   Text(
  //                     "I Accept the Tasker",
  //                     style: GoogleFonts.roboto(fontSize: 14, color: Colors.green),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.of(dialogContext).pop(),  // Use dialogContext here
  //             child: Padding(
  //               padding: const EdgeInsets.all(10.0),
  //               child: Row(
  //                 children: [
  //                   Icon(FontAwesomeIcons.ban, color: Colors.red, size: 20),
  //                   SizedBox(width: 20),
  //                   Text(
  //                     "Cancel",
  //                     style: GoogleFonts.roboto(fontSize: 14, color: Colors.red),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  // void showCompletedTaskPayment() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //           "Does your Tasker Finished Your Task?",
  //           style: GoogleFonts.roboto(
  //             fontSize: 30,
  //             fontWeight: FontWeight.bold,
  //             color: Color(0xFF0272B1),
  //           ),
  //         ),
  //         content: Text(
  //           "If your tasker had finished your task, check first the following: \n 1. Work Quality \n 2. Tasker's Attitude \n"
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(), //A function where the escrow payment will be released to the tasker and they will provide a feedback of their work.
  //             child: Row(
  //               children: [
  //                 Icon(
  //                   FontAwesomeIcons.moneyBillTransfer,
  //                   color: Colors.green.shade900,
  //                   size: 20,
  //                 ),
  //                 SizedBox(
  //                   width: 20,
  //                 ),
  //                 Text(
  //                   "Release Funds",
  //                   style: GoogleFonts.roboto(
  //                     fontSize: 14,
  //                     color: Colors.green.shade900,
  //                   )
  //                 )
  //               ]
  //             )
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Row(
  //               children: [
  //                 Icon(
  //                   FontAwesomeIcons.ban,
  //                   color: Colors.red.shade900,
  //                   size: 20,
  //                 ),
  //                 SizedBox(
  //                   width: 20,
  //                 ),
  //                 Text(
  //                   "Cancel",
  //                   style: GoogleFonts.roboto(
  //                     fontSize: 14,
  //                     color: Colors.red.shade900
  //                   ),
  //                 )
  //               ]
  //             )
  //           )
  //         ],
  //       );
  //     }
  //   );
  // }
  // void showRejectionOrCancellationForm(String status){
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context){
  //       return AlertDialog(
  //         title: Text(
  //           "You are going to ${status == "Rejected" ? "Reject a Tasker" : "Cancel your Task."}",
  //           style: GoogleFonts.roboto(
  //               fontSize: 30,
  //               fontWeight: FontWeight.bold,
  //               color: Color(0xFF0272B1)
  //           ),
  //         ),
  //         content: SizedBox(
  //           height: MediaQuery.of(context).size.height * 0.3,
  //           width: 250,
  //           child: Column(
  //             children: <Widget>[
  //               SizedBox(height: 10),
  //               Text("Why are you rejecting a Tasker/Cancelling a Task?"),
  //               SizedBox(height: 10),
  //               DropdownMenu(
  //                 hintText: "Please select a reason",
  //                 dropdownMenuEntries: rejectionReasons.map((rejectionReason) {
  //                   return DropdownMenuEntry(
  //                     value: rejectionReason,
  //                     label: rejectionReason,
  //                   );
  //                 }).toList(),
  //                 onSelected: (String? value) {
  //                   debugPrint(value);
  //                   if (value == 'Others (please specify)') {
  //                     setState(() {
  //                       rejectFormField = true;
  //                     });
  //                   }else{
  //                     setState(() {
  //                       rejectFormField = false;
  //                     });
  //                   }
  //                 },
  //                 controller: taskRequestController.rejectionController,
  //               ),
  //               SizedBox(height: 10),
  //               TextField(
  //                 maxLines: 4,
  //                 enabled: rejectFormField,
  //                 decoration: InputDecoration(
  //                   labelText: "Others (please specify)",
  //                   border: OutlineInputBorder(),
  //                   ),
  //                 controller: taskRequestController.otherReasonController,
  //               ),
  //             ]
  //           )
  //         ),
  //         actions: <Widget> [
  //           StatefulBuilder(
  //             builder: (BuildContext context, StateSetter setState) {
  //               return TextButton(
  //                 onPressed: processingData ? null : () async{
  //                   setState(() => processingData = true);
  //                   String rejectOrCancel = await taskRequestController.rejectTasker(widget.taskTakenId, status);
  //                   setState(() => processingData = false);
  //
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     SnackBar(
  //                       content: Text(rejectOrCancel),
  //                     ),
  //                   );
  //                 },
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(10.0),
  //                   child: Row(
  //                     children: [
  //                       Icon(
  //                         FontAwesomeIcons.share,
  //                         color: Colors.green,
  //                         size: 20,
  //                       ),
  //                       SizedBox(width: 20,),
  //                       Text(
  //                         processingData ? "Please Wait..." : status == "Rejected" ? "Send Rejection Notice" : "Send Cancellation Notice",
  //                         style: GoogleFonts.roboto(
  //                             fontSize: 14,
  //                             fontWeight: FontWeight.bold,
  //                             color: processingData ? Colors.black38 : Colors.green
  //                         ),
  //                       )
  //                     ]
  //                   )
  //                 )
  //               );
  //             }
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Padding(
  //               padding: const EdgeInsets.all(10.0),
  //               child: Row(
  //                 children: [
  //                   Icon(
  //                     FontAwesomeIcons.ban,
  //                     color: Colors.red,
  //                     size: 20,
  //                   ),
  //                   SizedBox(width: 20,),
  //                   Text(
  //                     "Cancel",
  //                     style: GoogleFonts.roboto(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.red
  //                     ),
  //                   )
  //                 ]
  //               )
  //             )
  //           ),
  //         ]
  //       );
  //     }
  //   );
  // }
}