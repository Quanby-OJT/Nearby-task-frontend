import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';

class LikeScreen extends StatefulWidget {
  const LikeScreen({Key? key}) : super(key: key);

  @override
  State<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen> {
  final JobPostService _jobService = JobPostService();
  bool _isLoading = true;
  List<TaskModel> _likedJobs = [];
  String? _errorMessage;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Liked Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLikedJobs,
          ),
        ],
      ),
      body: _buildBody(),
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
    // Format date string if it exists
    // String formattedDate = '';
    // if (task.title != null) {
    //   try {
    //     final date = DateTime.parse(task.created_at!);
    //     formattedDate = '${date.day}/${date.month}/${date.year}';
    //   } catch (e) {
    //     formattedDate = job.created_at ?? '';
    //   }
    // }

    return Card(
      color: Color(0xFF0272B1),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title ?? 'No Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    // Option to unlike job
                    _unlikeJob(task);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (task.location != null && task.location!.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: Colors.white,
                  ),
                  Text(
                    task.location!,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (task.contactPrice != null)
                  Chip(
                    label: Text('\$${task.contactPrice}'),
                    backgroundColor: Colors.green[50],
                  ),
                // if (formattedDate.isNotEmpty)
                //   Text(
                //     'Posted: $formattedDate',
                //     style: TextStyle(color: Colors.grey[600], fontSize: 12),
                //   ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Navigate to job details page
                _viewJobDetails(task);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text(
                'View Details',
                style: TextStyle(color: Colors.black),
              ),
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
