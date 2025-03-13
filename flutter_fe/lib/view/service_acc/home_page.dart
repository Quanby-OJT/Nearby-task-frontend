import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CardSwiperController controller = CardSwiperController();
  List<TaskModel> tasks = [];
  List<String> searchCategories = [
    'All',
    'Cleaning',
    'Delivery',
    'Repair',
    'Moving'
  ];
  List<String> selectedCategories = [];
  bool _isLoading = true;
  void initState() {
    super.initState();
    _fetchTasks();
  }

//For Displaying the record (record functionality)
  Future<void> _fetchTasks() async {
    try {
      JobPostService jobPostService = JobPostService();
      List<TaskModel> fetchedTasks = await jobPostService.fetchAllJobs();

      print("Raw API Response: ${fetchedTasks}"); // Print entire response
      print(
          "Parsed tasks count: ${fetchedTasks.length}"); // Check if tasks are parsed

      setState(() {
        tasks = fetchedTasks;
        print(tasks);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching tasks: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLikedJob(TaskModel task) async {
    try {
      debugPrint("Printing..." + task.id.toString());
      // Check if task ID is null
      if (task.id == null) {
        print("Cannot like job: Task ID is null for task: ${task.title}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cannot like job: Invalid job ID"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      JobPostService jobPostService = JobPostService();

      // Call the service method to save the liked job - now passing an int
      final result = await jobPostService.saveLikedJob(task.id!);

      if (result.containsKey('message')) {
        // Show success indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("$e");
      debugPrintStack();

      // Show error indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save like. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0272B1),
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   title: Center(
      //       child: Text(
      //     'Job Posts',
      //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      //   )),
      //   backgroundColor: Colors.transparent,
      // ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 35, top: 20),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: 200,
                      // child: DropdownSearch<String>.multiSelection(
                      //   items: searchCategories,
                      //   selectedItems: selectedCategories,
                      //   dropdownDecoratorProps: DropDownDecoratorProps(
                      //     dropdownSearchDecoration: InputDecoration(
                      //       prefixIcon: Icon(Icons.search),
                      //       filled: true,
                      //       fillColor: Color(0xFFF1F4FF),
                      //       hintText: 'Search...',
                      //       hintStyle: TextStyle(color: Colors.grey),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(
                      //             color: Colors.transparent, width: 0),
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //       focusedBorder: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(10),
                      //         borderSide: BorderSide(
                      //             color: Color(0xFF0272B1), width: 2),
                      //       ),
                      //     ),
                      //   ),
                      //   popupProps: PopupPropsMultiSelection.menu(
                      //     scrollbarProps: ScrollbarProps(
                      //       thickness: 8,
                      //       radius: Radius.circular(10),
                      //     ),
                      //
                      //     showSelectedItems:
                      //         false, // This hides selected items from search field
                      //     showSearchBox: true,
                      //     fit: FlexFit.loose,
                      //
                      //     itemBuilder: (context, item, isSelected) {
                      //       return Container(
                      //         padding: EdgeInsets.symmetric(
                      //             horizontal: 16, vertical: 8),
                      //         child: Row(
                      //           children: [
                      //             Checkbox(
                      //               value: isSelected,
                      //               hoverColor: Color(0xFF0272B1),
                      //               activeColor: Color(0xFF0272B1),
                      //               onChanged: null,
                      //             ),
                      //             SizedBox(width: 8),
                      //             Text(
                      //               item,
                      //               style: TextStyle(
                      //                 fontWeight: isSelected
                      //                     ? FontWeight.bold
                      //                     : FontWeight.normal,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       );
                      //     },
                      //   ),
                      //   onChanged: (List<String> selectedItems) {
                      //     setState(() {
                      //       selectedCategories = selectedItems;
                      //     });
                      //   },
                      // ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )

              ///
              /// This code, if the backend data contains only one data, it must display the data and the card swipe must work regardless.
              ///
              /// -Ces
              ///
              else if (tasks.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No Jobs Available",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Check back later for new opportunities",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchTasks,
                          icon: Icon(Icons.refresh),
                          label: Text("Refresh"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF0272B1),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: CardSwiper(
                    allowedSwipeDirection: AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                    ),
                    controller: controller,
                    cardsCount: tasks.length,
                    onSwipe: (previousIndex, targetIndex, swipeDirection) {
                      if (swipeDirection == CardSwiperDirection.left) {
                        print("Swiped Left (Disliked)");
                      } else if (swipeDirection == CardSwiperDirection.right) {
                        print("Swiped Right (Liked)");
                        _saveLikedJob(tasks[previousIndex]);
                      }
                      return true;
                    },
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      final task = tasks[index];
                      return Center(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16.0, bottom: 60),
                            child: Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₱${task.contactPrice ?? "--"}',
                                  style: GoogleFonts.openSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  task.title ?? 'No Title',
                                  style: GoogleFonts.openSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  task.description ?? 'No Description',
                                  style: GoogleFonts.openSans(
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  spacing: 5,
                                  children: [
                                    Icon(
                                      Icons.location_pin,
                                      size: 20,
                                    ),
                                    Text(
                                      task.location ?? "Location",
                                      style: GoogleFonts.openSans(),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          if (!_isLoading && tasks.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        controller.swipe(CardSwiperDirection.left);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: CircleBorder(),
                          fixedSize: Size(60, 60),
                          padding: EdgeInsets.zero),
                      child: Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          weight: 4,
                          size: 30,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        controller.swipe(CardSwiperDirection.right);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: CircleBorder(),
                        fixedSize: Size(60, 60),
                        padding: EdgeInsets.zero, // Remove default padding
                      ),
                      child: Center(
                        // Use Center instead of Align
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
