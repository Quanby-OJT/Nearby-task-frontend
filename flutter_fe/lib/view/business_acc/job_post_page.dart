import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/business_task_detail.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_fe/view/business_acc/task_details_screen.dart';

class JobPostPage extends StatefulWidget {
  const JobPostPage({super.key});

  @override
  State<JobPostPage> createState() => _JobPostPageState();
}

class _JobPostPageState extends State<JobPostPage> {
  final TaskController controller = TaskController();
  final JobPostService jobPostService = JobPostService();
  String? _message;
  bool _isSuccess = false;

  String? selectedTimePeriod;
  String? selectedUrgency;
  String? selectedSpecialization;
  String? selectedWorkType; // New field for work_type
  List<String> items = ['Day/s', 'Week/s', 'Month/s', 'Year/s'];
  List<String> urgency = ['Non-Urgent', 'Urgent'];
  List<String> workTypes = ['Solo', 'Group']; // Options for work_type dropdown
  List<String> specialization = [];
  List<TaskModel?> clientTasks = [];
  Map<String, String> _errors = {};

  String? _selectedSkill;
  List<String> _skills = [];
  final storage = GetStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSpecialization();
    _loadSkills();
    fetchCreatedTasks();
  }

  Future<void> fetchSpecialization() async {
    try {
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();
      setState(() {
        specialization =
            fetchedSpecializations.map((spec) => spec.specialization).toList();
      });
    } catch (error) {
      print('Error fetching specializations: $error');
    }
  }

  Future<void> _loadSkills() async {
    try {
      final String response =
          await rootBundle.loadString('assets/tesda_skills.json');
      final data = jsonDecode(response);
      setState(() {
        _skills = List<String>.from(data['tesda_skills']);
      });
    } catch (e) {
      print('Error loading skills: $e');
    }
  }

  Future<void> fetchCreatedTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = storage.read('user_id');
      if (userId != null) {
        final tasks = await controller.getJobsforClient(context, userId);
        setState(() {
          clientTasks = tasks;
        });
      }
    } catch (e) {
      debugPrint("Error fetching created tasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to load your tasks. Please try again."),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => fetchCreatedTasks(),
        ),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _validateAndSubmit() {
    setState(() {
      _errors.clear();

      if (controller.jobTitleController.text.trim().isEmpty) {
        _errors['task_title'] = 'Please Indicate Your Needed Task';
      }
      if (selectedSpecialization == null) {
        _errors['specialization'] = "Please Indicate the Needed Specialization";
      }
      if (controller.jobDescriptionController.text.trim().isEmpty) {
        _errors['task_description'] = 'Please Elaborate Your Task.';
      }
      String contractPrice = controller.contactPriceController.text.trim();
      if (contractPrice.isEmpty) {
        _errors['contact_price'] = 'Indicate the Contract Price';
      } else if (double.tryParse(contractPrice) == null ||
          double.parse(contractPrice) <= 0) {
        _errors['contact_price'] =
            'Contract Price must be a valid positive number';
      }
      if (controller.jobLocationController.text.trim().isEmpty) {
        _errors['location'] =
            'Indicate Your Location where the Task will be held.';
      }
      String jobTime = controller.jobTimeController.text.trim();
      if (jobTime.isEmpty) {
        _errors['num_of_days'] = 'Indicate the Time Needed to Finish the Task';
      } else if (int.tryParse(jobTime) == null || int.parse(jobTime) <= 0) {
        _errors['num_of_days'] = 'Time Needed must be a valid positive number';
      }
      String startDate = controller.jobTaskBeginDateController.text.trim();
      if (startDate.isEmpty) {
        _errors['task_begin_date'] = 'Indicate When to Start Your Task';
      } else {
        try {
          DateTime taskBeginDate = DateTime.parse(startDate);
          if (taskBeginDate.isBefore(DateTime.now())) {
            _errors['task_begin_date'] =
                'Task start date must be in the future';
          }
        } catch (e) {
          _errors['task_begin_date'] = 'Invalid date format';
        }
      }
      if (selectedUrgency == null) {
        _errors['urgency'] =
            'Please Indicate if Your Task Needs to be finished ASAP.';
      }
      if (selectedTimePeriod == null) {
        _errors['time_period'] = "Please Indicate the Time Period.";
      }
      if (selectedWorkType == null) {
        _errors['work_type'] = "Please Indicate the Work Type (Solo or Group).";
      }

      debugPrint(_errors.toString());

      if (_errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix the errors before submitting'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        _submitJob();
      }
    });
  }

  //Form for Task Creation.
  void _showCreateTaskModal() {
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: Text(
                    "Create a New Task",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 5),
                  child: Text(
                    "* Required Fields",
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.indigo,
                        fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: TextField(
                    cursorColor: Color(0xFF0272B1),
                    controller: controller.jobTitleController,
                    decoration: InputDecoration(
                      label: Text('What is the Task All About? *'),
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Enter title',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                      errorText: _errors['task_title'],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: DropdownButtonFormField<String>(
                    value: selectedSpecialization,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Select Tasker Specialization *',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    items: specialization.map((String spec) {
                      return DropdownMenuItem<String>(
                        value: spec,
                        child: Text(spec, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedSpecialization = newValue;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: TextField(
                    maxLines: 5,
                    cursorColor: Color(0xFF0272B1),
                    controller: controller.jobDescriptionController,
                    decoration: InputDecoration(
                      label: Text('Can you Elaborate About Your Task? *'),
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Enter description...',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                      errorText: _errors['task_description'],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: TextFormField(
                    maxLines: 1,
                    cursorColor: Color(0xFF0272B1),
                    controller: controller.contactPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      label: Text('Contact Price *'),
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Enter price...',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                      errorText: _errors['contact_price'],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: TextField(
                    cursorColor: Color(0xFF0272B1),
                    controller: controller.jobLocationController,
                    decoration: InputDecoration(
                      label: Text('Where Will the Task be Taken? *'),
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Enter location',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                      errorText: _errors['location'],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: DropdownButtonFormField<String>(
                    value: selectedTimePeriod,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Indicate the Time Period',
                      hintStyle: TextStyle(color: Color(0xFF0272B1)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedTimePeriod = newValue;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: TextField(
                    cursorColor: Color(0xFF0272B1),
                    controller: controller.jobTimeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      label: Text('How Long Will the Task Would Take? *'),
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Enter duration',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                      errorText: _errors['num_of_days'],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: TextField(
                    controller: controller.jobTaskBeginDateController,
                    keyboardType: TextInputType.datetime,
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        String formattedDate =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        controller.jobTaskBeginDateController.text =
                            formattedDate;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'When will the task begin? *',
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Select a date',
                      hintStyle: TextStyle(color: Colors.grey),
                      suffixIcon:
                          Icon(Icons.calendar_today, color: Color(0xFF0272B1)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                      errorText: _errors['task_begin_date'],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 40, right: 40, top: 20, bottom: 0),
                  child: DropdownButtonFormField<String>(
                    value: selectedUrgency,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Does your task need be done ASAP? *',
                      hintStyle: TextStyle(color: Color(0xFF0272B1)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    items: urgency.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedUrgency = newValue;
                      });
                    },
                  ),
                ),
                // New work_type dropdown
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: DropdownButtonFormField<String>(
                    value: selectedWorkType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Select Work Type (Solo or Group) *',
                      hintStyle: TextStyle(color: Color(0xFF0272B1)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                      errorText: _errors['work_type'],
                    ),
                    items: workTypes.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedWorkType = newValue;
                      });
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(
                    children: [
                      TextField(
                        maxLines: 3,
                        cursorColor: Color(0xFF0272B1),
                        controller: controller.jobRemarksController,
                        decoration: InputDecoration(
                          labelText: 'Remarks',
                          labelStyle: TextStyle(color: Color(0xFF0272B1)),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Color(0xFFF1F4FF),
                          hintText: 'Enter remarks...',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Color(0xFF0272B1), width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _message ?? '',
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _message = "");
                            _validateAndSubmit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0272B1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Post Job',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _message = "";
                              _errors = {};
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Show My Task List',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitJob() async {
    debugPrint("Submitting job...");
    setState(() {
      _message = "";
      _errors.clear();
      _isSuccess = false;
    });

    selectedUrgency == "Urgent";
    try {
      final result = await controller.postJob(selectedSpecialization,
          selectedUrgency, selectedTimePeriod, selectedWorkType);
      debugPrint(result.toString());

      if (result['success']) {
        setState(() {
          _message = result['message'] ?? "Successfully Posted Task.";
          _isSuccess = true;
        });

        // Refresh the task list to show the newly created task
        await fetchCreatedTasks();

        // Clear form fields after successful submission
        controller.jobTitleController.clear();
        controller.jobDescriptionController.clear();
        controller.jobLocationController.clear();
        controller.jobTimeController.clear();
        controller.contactPriceController.clear();
        controller.jobRemarksController.clear();
        controller.jobTaskBeginDateController.clear();

        setState(() {
          selectedSpecialization = null;
          selectedUrgency = null;
          selectedTimePeriod = null;
          selectedWorkType = null;
        });
      } else {
        setState(() {
          if (result.containsKey('errors') && result['errors'] is List) {
            for (var error in result['errors']) {
              if (error is Map<String, dynamic> &&
                  error.containsKey('path') &&
                  error.containsKey('msg')) {
                _errors[error['path']] = error['msg'];
              }
            }
          } else if (result.containsKey('message')) {
            _message = result['message'];
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_message!),
          backgroundColor: _isSuccess ? Colors.green : Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            textColor: Colors.white,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _navigateToTaskDetail(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessTaskDetail(task: task, taskID: task.id!),
      ),
    );
    if (result == true) {
      // Task was updated or disabled, refresh the task list
      await fetchCreatedTasks();
    }
  }

  //Main Application Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFF0272B1)),
        title: Text(
          'Your Tasks',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (clientTasks.isEmpty)
              ? Center(child: Text("No tasks available"))
              : ListView.builder(
                  itemCount: clientTasks.length,
                  itemBuilder: (context, index) {
                    final task = clientTasks[index];
                    if (task == null) {
                      return SizedBox.shrink(); // Skip null tasks
                    }

                    // Format the price safely
                    String priceDisplay = "N/A";
                    if (task.contactPrice != null) {
                      try {
                        priceDisplay = NumberFormat("#,##0.00", "en_US")
                            .format(task.contactPrice!.roundToDouble());
                      } catch (e) {
                        priceDisplay = task.contactPrice.toString();
                      }
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        title: Text(task.title ?? "Untitled Task",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              "📍 ${task.location ?? 'Location not specified'}",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "• ₱ $priceDisplay",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "• 🛠 ${task.specialization ?? 'No specialization'}",
                              style: TextStyle(fontSize: 14),
                            ),
                            if (task.duration != null)
                              Text(
                                "• ⏱ Duration: ${task.duration}",
                                style: TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                        onTap: () {
                          // Navigate to task details page
                          _navigateToTaskDetail(task);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "refreshBtn",
            mini: true,
            onPressed: fetchCreatedTasks,
            child: Icon(Icons.refresh),
            backgroundColor: Colors.green,
          ),
          SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "addTaskBtn",
            onPressed: _showCreateTaskModal,
            icon: Icon(Icons.add, size: 26),
            label: Text("Had a New Task in Mind?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }
}
