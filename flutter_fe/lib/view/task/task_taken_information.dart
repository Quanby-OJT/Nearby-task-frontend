// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_fe/model/task_assignment.dart';
//
// class TaskTakenInformation extends StatefulWidget{
//   final TaskAssignment taskInformation;
//   final String taskStatus;
//
//   const TaskTakenInformation({super.key, required this.taskInformation, required this.taskStatus});
//
//   @override
//   State<TaskTakenInformation> createState() => _TaskTakenInformationState();
// }
//
// class _TaskTakenInformationState extends State<TaskTakenInformation> {
//   @override
//   Widget build(BuildContext context) {
//     final String _role = GetStorage().read("role") ?? 'Unknown';
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text(
//           'Task Information',
//           style: GoogleFonts.poppins(
//             color: const Color(0xFFB71A4A),
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.grey[100],
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios,
//             color: Color(0xFFB71A4A),
//             size: 20,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.black))
//           : SingleChildScrollView(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildStatusSection(),
//                   const SizedBox(height: 16),
//                   _buildTaskCard(constraints),
//                   const SizedBox(height: 16),
//                   if (_role == "Tasker") _buildClientProfileCard(),
//                   if (_role == "Client") _buildTaskerProfileCard(),
//                   const SizedBox(height: 16),
//                   _buildActionButton(),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<void> _fetchTaskDetails() async {
//     try {
//       final int userId = storage.read("user_id") ?? 0;
//       final response = await _jobPostService
//           .fetchTaskInformation(_requestInformation!.task_id as int);
//
//       AuthenticatedUser? user =
//       await _profileController.getAuthenticatedUser(context, userId);
//
//       setState(() {
//         _role = user?.user.role ?? 'Unknown';
//       });
//       setState(() {
//         widget.taskInformation.task = response.task;
//       });
//     } catch (e) {
//       debugPrint("Error fetching task details: $e");
//     }
//   }
//
//   Widget _buildTaskCard(BoxConstraints constraints) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: Theme.of(context).colorScheme.surfaceContainer,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color:
//                     Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(Icons.task,
//                       color: Theme.of(context).colorScheme.primary, size: 24),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     widget.taskInformation.task?.title ?? 'Task',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Theme.of(context).colorScheme.onSurface,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildTaskInfoRow(
//               icon: FontAwesomeIcons.locationDot,
//               label: 'Description',
//               value: widget.taskInformation.task!.description ?? 'N/A',
//             ),
//             const SizedBox(height: 16),
//             _buildTaskInfoRow(
//               icon: FontAwesomeIcons.briefcase,
//               label: 'Work Type',
//               value: widget.taskInformation.task!.workType ?? 'N/A',
//             ),
//             _buildTaskInfoRow(
//               icon: FontAwesomeIcons.star,
//               label: 'Specialization',
//               value: widget.taskInformation.task!.taskerSpecialization?.specialization ??
//                   'N/A',
//             ),
//             _buildTaskInfoRow(
//               icon: FontAwesomeIcons.dollarSign,
//               label: 'Contract Price',
//               value: widget.taskInformation.task!.contactPrice.toString() ?? 'N/A',
//             ),
//             _buildTaskInfoRow(
//               icon: FontAwesomeIcons.info,
//               label: 'Status',
//               value: widget.taskStatus,
//             ),
//             _buildTaskInfoRow(
//               icon: FontAwesomeIcons.calendar,
//               label: 'Start Date',
//               value: _requestInformation?.task?.taskBeginDate != null
//                   ? DateFormat('MMM dd, yyyy HH:mm a').format(DateTime.parse(
//                   _requestInformation?.task?.taskBeginDate ?? ''))
//                   : 'N/A',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTaskInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           FaIcon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
//           const SizedBox(width: 12),
//           Text(
//             '$label: ',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Theme.of(context).colorScheme.onSurfaceVariant,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Theme.of(context).colorScheme.onSurface,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildClientProfileCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundColor: Color(0xFF03045E).withOpacity(0.1),
//                   child: Icon(
//                     Icons.person,
//                     color: Color(0xFF03045E),
//                     size: 28,
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.taskInformation?.taskDetails?.client?.user?.role ==
//                           "Tasker"
//                           ? "Tasker Profile"
//                           : "Client Profile",
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF03045E),
//                       ),
//                     ),
//                     Text(
//                       'Details',
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             _buildProfileInfoRow(
//               'Name',
//               (widget.taskInformation?.taskDetails?.client?.user != null)
//                   ? '${widget.taskInformation!.taskDetails!.client!.user!.firstName ?? ''} ${widget.taskInformation!.taskDetails!.client!.user!.lastName ?? ''}'
//                   .trim()
//                   : 'Not available',
//             ),
//             SizedBox(height: 8),
//             _buildProfileInfoRow(
//                 'Email',
//                 widget.taskInformation?.taskDetails?.client?.user?.email ??
//                     'Not available'),
//             SizedBox(height: 8),
//             _buildProfileInfoRow(
//                 'Phone',
//                 widget.taskInformation?.taskDetails?.client?.user?.contact ??
//                     'Not available'),
//             SizedBox(height: 8),
//             _buildProfileInfoRow(
//                 'Status',
//                 widget.taskInformation?.taskDetails?.client?.user?.accStatus ??
//                     'Not available'),
//             SizedBox(height: 8),
//             _buildProfileInfoRow('Account', 'Verified', isVerified: true),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTaskerProfileCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundColor: Color(0xFF03045E).withOpacity(0.1),
//                   child: Icon(
//                     Icons.person,
//                     color: Color(0xFF03045E),
//                     size: 28,
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.taskInformation?.taskDetails?.client?.user?.role ==
//                           "Client"
//                           ? "Client Profile"
//                           : "Tasker Profile",
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF03045E),
//                       ),
//                     ),
//                     Text(
//                       'Details',
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             _buildProfileInfoRow(
//               'Name',
//               (widget.taskInformation?.tasker?.user != null)
//                   ? '${widget.taskInformation!.tasker!.user!.firstName ?? ''} ${widget.taskInformation!.tasker!.user!.lastName ?? ''}'
//                   .trim()
//                   : 'Not available',
//             ),
//             SizedBox(height: 8),
//             _buildProfileInfoRow('Email',
//                 widget.taskInformation?.tasker?.user?.email ?? 'Not available'),
//             SizedBox(height: 8),
//             _buildProfileInfoRow(
//                 'Phone',
//                 widget.taskInformation?.tasker?.user?.contact ??
//                     'Not available'),
//             SizedBox(height: 8),
//             _buildProfileInfoRow(
//                 'Status',
//                 widget.taskInformation?.tasker?.user?.accStatus ??
//                     'Not available'),
//             SizedBox(height: 8),
//             _buildProfileInfoRow('Account', 'Verified', isVerified: true),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusSection() {
//     final status = widget.taskStatus;
//     final isExpired = status.toLowerCase() == 'expired';
//
//     if (_requestInformation?.start_date == null) {
//       return SizedBox(
//         width: double.infinity,
//         child: Column(
//           children: [
//             Icon(
//               statusIcon(status),
//               color: statusColor(status),
//               size: 36,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               status,
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: statusColor(status),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               statusMessage(status),
//               textAlign: TextAlign.center,
//               style: GoogleFonts.poppins(
//                 fontSize: 12,
//                 color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Task Expired',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Theme.of(context).colorScheme.error,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.red[50]!, Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.red[100]!.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue[100]!.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               statusIcon(status),
//               color: statusColor(status),
//               size: 36,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             status,
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.red,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             statusMessage(status),
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 12,
//               color: Colors.red,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: () {
//           Navigator.pop(context);
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFFB71A4A),
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 2,
//         ),
//         child: Text(
//           'Back to Tasks',
//           style: GoogleFonts.poppins(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProfileInfoRow(String label, String value,
//       {bool isVerified = false}) {
//     return Row(
//       children: [
//         Text(
//           '$label: ',
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[600],
//           ),
//         ),
//         Expanded(
//           child: Row(
//             children: [
//               Flexible(
//                 child: Text(
//                   value,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               if (isVerified)
//                 Padding(
//                   padding: const EdgeInsets.only(left: 8),
//                   child: Icon(
//                     Icons.verified,
//                     color: Colors.green[400],
//                     size: 18,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// Color statusColor(String status) {
//   switch (status.toLowerCase()) {
//     case 'completed':
//       return Colors.green;
//     case 'confirmed':
//       return Colors.blue;
//     case 'expired':
//       return Colors.red;
//     default:
//       return Colors.grey;
//   }
// }
//
// IconData statusIcon(String status) {
//   switch (status.toLowerCase()) {
//     case 'completed':
//       return Icons.check_circle;
//     case 'confirmed':
//       return Icons.check;
//     case 'expired':
//       return Icons.warning;
//     default:
//       return Icons.info;
//   }
// }
//
// String statusMessage(String status) {
//   switch (status.toLowerCase()) {
//     case 'completed':
//       return 'The task is completed.';
//     case 'confirmed':
//       return 'The task has been confirmed.';
//     case 'expired':
//       return 'The task has expired.';
//     default:
//       return 'Task status is unknown.';
//   }
// }
