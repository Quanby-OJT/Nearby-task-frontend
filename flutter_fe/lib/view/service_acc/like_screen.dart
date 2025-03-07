import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LikeScreen extends StatefulWidget {
  const LikeScreen({super.key});

  @override
  State<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen> {
  final JobPostService _jobService = JobPostService();
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<TaskModel> _likedJobs = [];
  List<String> selectedFilters = [];
  String? _errorMessage;
  int savedJobsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikedJobs();
  }

  Future<void> _loadLikedJobs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if user is logged in first
      final userId = await _jobService.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to view your liked jobs';
        });
        return;
      }

      // Fetch liked jobs
      final likedJobs = await _jobService.fetchUserLikedJobs();
      setState(() {
        _likedJobs = likedJobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading liked jobs: $e';
      });
    }
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Allows UI update inside modal
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
                      _buildFilterChip("P100", setModalState),
                      _buildFilterChip("P200", setModalState),
                      _buildFilterChip("P300", setModalState),
                      _buildFilterChip("P500+", setModalState),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      setState(() {}); // Update UI
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
  Widget _buildFilterChip(String label, Function setModalState) {
    bool isSelected = selectedFilters.contains(label);

    return FilterChip(
      label: Text(label),
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

  // Function to simulate a saved job count update
  void _updateSavedJobs() {
    setState(() {
      savedJobsCount++; // Increase saved jobs count (for testing)
    });
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
                          label: Text(filter),
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              selectedFilters.remove(filter);
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                Text(
                  "Saved Jobs: $savedJobsCount",
                  style: GoogleFonts.montserrat(
                      fontSize: 14, fontWeight: FontWeight.bold),
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
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLikedJobs,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_likedJobs.isEmpty) {
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
                Navigator.pop(context); // Go back to job listings
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
        itemCount: _likedJobs.length,
        itemBuilder: (context, index) {
          final job = _likedJobs[index];
          return _buildJobCard(job);
        },
      ),
    );
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
                Padding(
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
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task',
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF03045E),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Available tasks',
                                  style: GoogleFonts.montserrat(
                                    color: Color.fromARGB(255, 57, 209, 11),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Color.fromARGB(255, 228, 11, 11),
                        size: 24,
                      ),
                      onPressed: () {
                        // Option to unlike job
                        _unlikeJob(task);
                      },
                    ),
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₱200.00',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF03045E),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Row(
                          children: [
                            Text(
                              "View Details",
                              style: TextStyle(
                                color: Color(0xFF03045E),
                                fontSize: 10,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_forward, color: Color(0xFF03045E)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            // const SizedBox(height: 8),
            // if (task.location != null && task.location!.isNotEmpty)
            //   Row(
            //     children: [
            //       Icon(
            //         Icons.location_city,
            //         color: Colors.white,
            //       ),
            //       Text(
            //         task.location!,
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ],
            //   ),
            // const SizedBox(height: 8),
            // if (task.description != null && task.description!.isNotEmpty)
            //   Text(
            //     task.description!,
            //     maxLines: 3,
            //     overflow: TextOverflow.ellipsis,
            //     style: TextStyle(color: Colors.white),
            //   ),
            // const SizedBox(height: 8),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     if (task.contactPrice != null)
            //       Chip(
            //         label: Text('\$${task.contactPrice}'),
            //         backgroundColor: Colors.green[50],
            //       ),
            //     // if (formattedDate.isNotEmpty)
            //     //   Text(
            //     //     'Posted: $formattedDate',
            //     //     style: TextStyle(color: Colors.grey[600], fontSize: 12),
            //     //   ),
            //   ],
            // ),
            //   const SizedBox(height: 8),
            //   ElevatedButton(
            //     onPressed: () {
            //       // Navigate to job details page
            //       _viewJobDetails(task);
            //     },
            //     style: ElevatedButton.styleFrom(
            //         minimumSize: const Size(double.infinity, 40),
            //         shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(10))),
            //     child: const Text(
            //       'View Details',
            //       style: TextStyle(color: Colors.black),
            //     ),
            //   ),
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
          title: const Text('Remove from Liked Jobs?'),
          content:
              const Text('This job will be removed from your liked jobs list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Process the unlike action
      final result = await _jobService.unlikeJob(job.id!);

      if (result['success']) {
        // Remove from local list
        setState(() {
          _likedJobs.removeWhere((item) => item.id == job.id);
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
