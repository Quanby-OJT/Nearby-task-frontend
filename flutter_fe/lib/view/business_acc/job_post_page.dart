import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/controller/task_controller.dart';

class JobPostPage extends StatefulWidget {
  const JobPostPage({super.key});

  @override
  State<JobPostPage> createState() => _JobPostPageState();
}

class _JobPostPageState extends State<JobPostPage> {
  final TaskController controller = TaskController();
  String? _message;
  bool _isSuccess = false;

  String? selectedValue; // Stores selected dropdown value
  String? selectedUrgency; // Stores selected dropdown value
  String? selectedSpecialization;
  List<String> items = ['Day', 'Week', 'Month'];
  List<String> urgency = ['Non-Urgent', 'Urgent'];
  List<String> specializtion = ['Tech Support', 'Cleaning', 'Plumbing'];

  Future<void> _submitJob() async {
    controller.jobTitleController.text = controller.jobTitleController.text;
    controller.jobSpecializationController.text = selectedSpecialization ?? "";
    controller.jobDescriptionController.text =
        controller.jobDescriptionController.text;
    controller.jobLocationController.text =
        controller.jobLocationController.text;
    controller.jobDurationController.text = selectedValue ?? "";
    controller.jobDaysController.text = controller.jobDaysController.text;
    controller.jobUrgencyController.text = selectedUrgency ?? "";

    final result = await controller.postJob();
    setState(() {
      _message = result['message'];
      _isSuccess = result['success'];
    });

    controller.postJob();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'Create a new task',
            style: TextStyle(
                color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
              child: TextField(
                cursorColor: Color(0xFF0272B1),
                controller: controller.jobTitleController,
                decoration: InputDecoration(
                    label: Text('Job Title'),
                    labelStyle: TextStyle(color: Color(0xFF0272B1)),
                    filled: true,
                    fillColor: Color(0xFFF1F4FF),
                    hintText: 'Enter title',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
              child: DropdownButtonFormField<String>(
                value: selectedSpecialization,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF1F4FF),
                    //labelText: 'Select an option',
                    hintText: 'Specialization...',
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
                items: specializtion.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSpecialization = newValue;
                    controller.jobSpecializationController.text =
                        newValue ?? "";
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
                    label: Text('Job Description'),
                    labelStyle: TextStyle(color: Color(0xFF0272B1)),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Color(0xFFF1F4FF),
                    hintText: 'Enter description...',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
              child: TextFormField(
                maxLines: 1, // Single line for numbers
                cursorColor: Color(0xFF0272B1),
                controller: controller.contactPriceController,
                keyboardType: TextInputType.number, // Ensures numeric input
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ], // Restricts to numbers only
                decoration: InputDecoration(
                  label: Text('Contact Price'),
                  labelStyle: TextStyle(color: Color(0xFF0272B1)),
                  filled: true,
                  fillColor: Color(0xFFF1F4FF),
                  hintText: 'Enter price...',
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
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
              child: TextField(
                cursorColor: Color(0xFF0272B1),
                controller: controller.jobLocationController,
                decoration: InputDecoration(
                    label: Text('Location'),
                    labelStyle: TextStyle(color: Color(0xFF0272B1)),
                    filled: true,
                    fillColor: Color(0xFFF1F4FF),
                    hintText: 'Enter location',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
              child: DropdownButtonFormField<String>(
                value: selectedValue,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF1F4FF),
                    //labelText: 'Select an option',
                    hintText: 'Duration...',
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
                    selectedValue = newValue;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
              child: TextField(
                cursorColor: Color(0xFF0272B1),
                controller: controller.jobDaysController,
                keyboardType: TextInputType.number, // Numeric keyboard
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ], // Only numbers allowed
                decoration: InputDecoration(
                    label: Text('Number of days'),
                    labelStyle: TextStyle(color: Color(0xFF0272B1)),
                    filled: true,
                    fillColor: Color(0xFFF1F4FF),
                    hintText: 'Enter title',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
              child: TextField(
                controller: controller.jobTaskBeginDateController,
                keyboardType: TextInputType.datetime, // Opens date keyboard
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
                    controller.jobTaskBeginDateController.text = formattedDate;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Task Begin Date',
                  labelStyle: TextStyle(color: Color(0xFF0272B1)),
                  filled: true,
                  fillColor: Color(0xFFF1F4FF),
                  hintText: 'Select a date',
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: Icon(Icons.calendar_today,
                      color: Color(0xFF0272B1)), // Calendar icon
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
            Padding(
              padding: const EdgeInsets.only(
                  left: 40, right: 40, top: 20, bottom: 0),
              child: DropdownButtonFormField<String>(
                value: selectedUrgency,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF1F4FF),
                    //labelText: 'Select an option',
                    hintText: 'Urgency...',
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
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2))),
              ),
            ),
            if (_message != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
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
                    _submitJob();
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
            TextButton(
                onPressed: () {
                  showModalList(context);
                },
                child: Text(
                  'Task list',
                  style: TextStyle(color: Colors.black),
                ))
          ],
        ),
      ),
    );
  }

  void showModalList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        List<String> items = ['items1', 'items2', 'items3', 'items4'];

        return Container(
          padding: EdgeInsets.all(16.0),
          height: 600, // Set height for modal
          child: Column(
            children: [
              Text('List of tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(items[index]),
                      onTap: () {
                        Navigator.pop(
                            context, items[index]); // Close modal on selection
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
