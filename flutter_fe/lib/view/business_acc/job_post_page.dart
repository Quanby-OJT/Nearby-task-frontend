import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

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
  List<String> items = ['Day/s', 'Week/s', 'Month/s', 'Year/s'];
  List<String> urgency = ['Non-Urgent', 'Urgent'];
  List<String> specialization = [];
  List<TaskModel?> clientTasks = [];
  Map<String, String> _errors = {};
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();
    fetchSpecialization();
    getAllJobsforClient();
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

  Future<void> getAllJobsforClient() async {
    try {
      List<TaskModel?>? fetchedTasks =
          await controller.getJobsforClient(context, storage.read('user_id'));

      if (fetchedTasks != null) {
        setState(() {
          clientTasks = fetchedTasks;
        });
      }
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
    }
  }

  void _validateAndSubmit() {
    setState(() {
      _errors.clear(); // Clear previous errors

      if (controller.jobTitleController.text.trim().isEmpty) {
        _errors['task_title'] = 'Please Indicate Your Needed Task';
      }
      if (selectedSpecialization == null) {
        _errors['specialization'] = "Please Indicate the Needed Specialization";
      }
      if (controller.jobDescriptionController.text.trim().isEmpty) {
        _errors['task_description'] = 'Please Elaborate Your Task.';
      }

      // Ensure contract price is a valid number
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

      // Ensure job time is a valid number
      String jobTime = controller.jobTimeController.text.trim();
      if (jobTime.isEmpty) {
        _errors['num_of_days'] = 'Indicate the Time Needed to Finish the Task';
      } else if (int.tryParse(jobTime) == null || int.parse(jobTime) <= 0) {
        _errors['num_of_days'] = 'Time Needed must be a valid positive number';
      }

      // Validate date format and future date
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

      debugPrint(_errors.toString());

      // Show error messages in UI
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

  void _showCreateTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
                    child: Text(
                      "Create a New Task",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40, top: 5),
                    child: Text(
                      "* Required Fields",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.indigo,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
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
                              borderSide: BorderSide(
                                  color: Colors.transparent, width: 0),
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF0272B1), width: 2)),
                          errorText: _errors['task_title']),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
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
                          child: Text(
                            spec,
                            overflow: TextOverflow
                                .ellipsis, // Ensures text does not overflow
                          ),
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
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
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
                              borderSide: BorderSide(
                                  color: Colors.transparent, width: 0),
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF0272B1), width: 2)),
                          errorText: _errors['task_description']),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
                    child: TextFormField(
                      maxLines: 1, // Single line for numbers
                      cursorColor: Color(0xFF0272B1),
                      controller: controller.contactPriceController,
                      keyboardType:
                          TextInputType.number, // Ensures numeric input
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Restricts to numbers only
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
                          errorText: _errors['contract_price']),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
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
                              borderSide: BorderSide(
                                  color: Colors.transparent, width: 0),
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF0272B1), width: 2)),
                          errorText: _errors['location']),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
                    child: DropdownButtonFormField<String>(
                      value: selectedTimePeriod,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFF1F4FF),
                          //labelText: 'Select an option',
                          hintText: 'Indicate the Time Priod',
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
                          )),
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
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
                    child: TextField(
                      cursorColor: Color(0xFF0272B1),
                      controller: controller.jobTimeController,
                      keyboardType: TextInputType.number, // Numeric keyboard
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Only numbers allowed
                      decoration: InputDecoration(
                          label: Text('How Long Will the Task Would Take? *'),
                          labelStyle: TextStyle(color: Color(0xFF0272B1)),
                          filled: true,
                          fillColor: Color(0xFFF1F4FF),
                          hintText: 'Enter title',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent, width: 0),
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF0272B1), width: 2)),
                          errorText: _errors['num_of_days']),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, top: 20),
                    child: TextField(
                      controller: controller.jobTaskBeginDateController,
                      keyboardType:
                          TextInputType.datetime, // Opens date keyboard
                      readOnly: true, // Prevents manual input
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000), // Adjust as needed
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          // Format date as YYYY-MM-DD
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
                          suffixIcon: Icon(Icons.calendar_today,
                              color: Color(0xFF0272B1)), // Calendar icon
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
                          errorText: _errors['task_begin_date']),
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
                          //labelText: 'Select an option',
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
                          )),
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
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 40, right: 40, top: 20, bottom: 20),
                    child: TextField(
                      maxLines: 3,
                      cursorColor: Color(0xFF0272B1),
                      controller: controller.jobRemarksController,
                      decoration: InputDecoration(
                          label: Text('Remarks'),
                          labelStyle: TextStyle(color: Color(0xFF0272B1)),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Color(0xFFF1F4FF),
                          hintText: 'Enter remarks...',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent, width: 0),
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF0272B1), width: 2))),
                    ),
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  Container(
                    height: 50,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                        onPressed: () {
                          _message = "";
                          _validateAndSubmit();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0272B1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text(
                          'Post Job',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 50,
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 40), // Match padding
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _message = "";
                        _errors = {};
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
            ));
      },
    );
  }

  Future<void> _submitJob() async {
    debugPrint("Submitting job...");
    setState(() {
      _message = "";
      _errors.clear(); // Clears previous errors
      _isSuccess = false;
    });

    bool urgent = false;
    if (selectedUrgency == "Urgent") {
      urgent = true;
    } else if (selectedUrgency == "Non-Urgent") urgent = false;
    final result = await controller.postJob(
        selectedSpecialization, urgent, selectedTimePeriod);
    debugPrint(result.toString());

    if (result['success']) {
      setState(() {
        _message = result['message'] ?? "Successfully Posted Task.";
        _isSuccess = true;
      });
    } else {
      setState(() {
        if (result.containsKey('errors') && result['errors'] is List) {
          for (var error in result['errors']) {
            if (error is Map<String, dynamic> &&
                error.containsKey('path') &&
                error.containsKey('msg')) {
              _errors[error['path']] =
                  error['msg']; // Store field-specific errors
            }
          }
        } else if (result.containsKey('message')) {
          _message = result['message'];
        }
      });
    }

    if (_isSuccess) {
      getAllJobsforClient();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Tasks',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
        ),
      ),
      body: clientTasks.isEmpty
          ? Center(child: Text("No tasks available"))
          : ListView.builder(
              itemCount: clientTasks.length,
              itemBuilder: (context, index) {
                final task = clientTasks[index];
                return ListTile(
                  title: Text(task?.title ?? "Untitled Task",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "📍 ${task!.location} \n • "
                    "₱ ${NumberFormat("#,##0.00", "en_US").format(task.contactPrice!.roundToDouble())} \n • "
                    "🛠 ${task.specialization}",
                    style: TextStyle(fontSize: 14), // Optional styling
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () {
                    // Open task details (if needed)
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskModal,
        icon: Icon(Icons.add, size: 26), // Larger icon for better visibility
        label: Text(
          "Had a New Task in Mind?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent, // Adjust color as needed
        foregroundColor: Colors.white, // Ensures text/icon are visible
        elevation: 4, // Adds slight shadow for depth
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Slightly rounded corners
        ),
      ),
    );
  }
}
