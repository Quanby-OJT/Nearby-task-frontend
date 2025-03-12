import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/task_information.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:intl/intl.dart';

class LikeScreen extends StatefulWidget {
  const LikeScreen({Key? key}) : super(key: key);

  @override
  State<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen> {
  final JobPostService _jobService = JobPostService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<TaskModel> _likedJobs = [];
  List<TaskModel> _filteredJobs = [];
  List<int> selectedFilters = [];
  String? _errorMessage;
  int savedJobsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikedJobs();
    _searchController.addListener(_filterTaskFunction);
  }

  void _filterTaskFunction() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredJobs = _likedJobs.where((task) {
        return task.title!.toLowerCase().contains(query) ||
            task.description!.toLowerCase().contains(query);
      }).toList();
    });

    _applyFilters();
    _updateSavedJobs();
  }

  Future<void> _loadLikedJobs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = await _jobService.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in again to view your liked jobs';
        });
        return;
      }

      // Fetch liked jobs
      final likedJobs = await _jobService.fetchUserLikedJobs();
      debugPrint("Liked Jobs ${likedJobs.toString()}");
      setState(() {
        _likedJobs = likedJobs;
        _filteredJobs = List.from(_likedJobs);
        savedJobsCount = _filteredJobs.length;
        _isLoading = false;
      });
    } catch (e, st) {
      setState(() {
        _isLoading = false;
        debugPrint(e.toString());
        debugPrint(st.toString());
        _errorMessage = 'Error loading liked jobs. Please Try Again.';
      });
    }
  }

  // Function to simulate a saved job count update
  void _updateSavedJobs() {
    setState(() {
      savedJobsCount = _filteredJobs.length;
    });
  }

  void _applyFilters() {
    setState(() {
      if (selectedFilters.isNotEmpty) {
        _filteredJobs = _filteredJobs.where((task) {
          int priceFilter = _getPriceFilter(task.contactPrice);
          return selectedFilters.contains(priceFilter);
        }).toList();
      }
      _updateSavedJobs();
    });
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(20),
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Filter by Price",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildFilterChip(500, setModalState),
                      _buildFilterChip(700, setModalState),
                      _buildFilterChip(10000, setModalState),
                      _buildFilterChip(20000, setModalState),
                      _buildFilterChip(30000, setModalState),
                      _buildFilterChip(50000, setModalState),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    child: Text("Apply Filters"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Function to build a filter chip
  Widget _buildFilterChip(int label, Function setModalState) {
    bool isSelected = selectedFilters.contains(label);

    return FilterChip(
      label: Text('\$$label'),
      selected: isSelected,
      onSelected: (bool selected) {
        setModalState(() {
          if (selected) {
            selectedFilters.add(label);
          } else {
            selectedFilters.remove(label);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0), // Added padding
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                    onPressed: () {
                      _openFilterModal();
                    },
                    icon: Icon(
                      Icons.filter_list,
                      color: Colors.grey,
                    )),
                filled: true,
                fillColor: Color(0xFFF1F4FF),
                hintText: 'Search jobs...',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 0),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.blue, width: 2), // Fixed color
                ),
              ),
            ),
          ),
          if (selectedFilters.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 8,
                children: selectedFilters
                    .map((filter) => Chip(
                          label: Text('\$$filter'),
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              selectedFilters.remove(filter);
                              _filterTaskFunction();
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task result: $savedJobsCount",
                  style: GoogleFonts.montserrat(
                      fontSize: 10, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          Expanded(
            // Ensures _buildBody() takes remaining space
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            ElevatedButton(
              onPressed: _loadLikedJobs,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'You haven\'t liked any jobs yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ServiceAccMain()),
                  (route) =>
                      false, // Removes all previous routes from the stack
                );
              },
              child: const Text('Browse Jobs'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLikedJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredJobs.length,
        itemBuilder: (context, index) {
          final job = _filteredJobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  int _getPriceFilter(int? price) {
    if (price == null) return 0;
    if (price <= 500) return 500;
    if (price <= 700) return 700;
    if (price <= 20000) return 20000;
    if (price <= 300000) return 30000;
    return 100000;
  }

  Widget _buildJobCard(TaskModel task) {
    return Card(
      color: Color.fromARGB(255, 239, 254, 255),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Wrap the left content in Expanded
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              image: const DecorationImage(
                                image: AssetImage('assets/images/image1.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width:
                                10), // Replace Padding with SizedBox for consistency
                        Expanded(
                          // Wrap the text column in Expanded to prevent overflow
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title!,
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF03045E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow:
                                    TextOverflow.ellipsis, // Handle long titles
                              ),
                              Row(
                                children: [
                                  if (task.status != null)
                                    Flexible(
                                      // Wrap status text in Flexible
                                      child: Text(
                                        task.status!,
                                        style: GoogleFonts.montserrat(
                                          color:
                                              Color.fromARGB(255, 57, 209, 11),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Color.fromARGB(255, 228, 11, 11),
                    size: 24,
                  ),
                  onPressed: () {
                    _unlikeJob(task);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Wrap the price section in Expanded
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.contactPrice != null)
                          Text(
                            '\₱${NumberFormat("#,##0.00", "en_US").format(task.contactPrice!.roundToDouble())}',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF03045E),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskInformation(taskID: task.id as int),
                        ),
                      );
                      print(task.id);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Minimize the Row size
                      children: [
                        Text(
                          "View Details",
                          style: GoogleFonts.montserrat(
                            color: Color(0xFF03045E),
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward, color: Color(0xFF03045E)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlikeJob(TaskModel job) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Center(
            child: Text(
              'Remove from Saved Jobs?',
              style: GoogleFonts.montserrat(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'This job will be removed from your liked jobs list.',
                    style: GoogleFonts.montserrat(
                        fontSize: 10, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(
                      Icons.cancel,
                      size: 24,
                      color: Colors.green.shade400,
                    )),
                IconButton(
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(
                    Icons.delete,
                    size: 24,
                    color: Colors.red,
                  ),
                )
              ],
            )
          ],
        ),
      );

      if (confirm != true) return;

      // Process the unlike action
      final result = await _jobService.unlikeJob(job.id!);

      if (result['success']) {
        // Remove from local list
        setState(() {
          _filteredJobs.removeWhere((item) => item.id == job.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error in _unlikeJob: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unlike job. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewJobDetails(TaskModel job) {
    // Navigate to a detail page for this job
    // TODO: Replace this with navigation to your detail page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job.title ?? 'Job Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (job.location != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Company: ${job.location}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (job.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Description: ${job.description}'),
                ),
              if (job.contactPrice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Salary: \$${job.contactPrice}'),
                ),
              // Add more job details as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement job application functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Application feature coming soon!')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
