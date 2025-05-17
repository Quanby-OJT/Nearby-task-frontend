import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_request_controller.dart';
import 'package:flutter_fe/model/task_request.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TaskRequestsScreen extends StatefulWidget {
  const TaskRequestsScreen({super.key});

  @override
  State<TaskRequestsScreen> createState() => _TaskRequestsScreenState();
}

class _TaskRequestsScreenState extends State<TaskRequestsScreen> {
  final TaskRequestController _requestController = TaskRequestController();
  List<TaskRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final requests = await _requestController.getTaskerRequests();
      debugPrint("Loaded ${requests.length} requests");

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error in _loadRequests: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading requests: $e';
      });
    }
  }

  Future<void> _acceptRequest(TaskRequest request) async {
    try {
      final result = await _requestController.acceptRequest(request.requestId!);

      if (result['success'] == true) {
        // Update the local state
        setState(() {
          final index =
              _requests.indexWhere((r) => r.requestId == request.requestId);
          if (index != -1) {
            _requests[index] = request.copyWith(status: 'accepted');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Request accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to accept request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineRequest(TaskRequest request) async {
    try {
      final result =
          await _requestController.declineRequest(request.requestId!);

      if (result['success'] == true) {
        // Update the local state
        setState(() {
          final index =
              _requests.indexWhere((r) => r.requestId == request.requestId);
          if (index != -1) {
            _requests[index] = request.copyWith(status: 'declined');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Request declined successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to decline request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug information
    if (_requests.isNotEmpty) {
      debugPrint("TaskRequestsScreen: Displaying ${_requests.length} requests");
      debugPrint("First request details:");
      debugPrint("ID: ${_requests[0].requestId}");
      debugPrint("Status: ${_requests[0].status}");
      debugPrint("Task ID: ${_requests[0].task.id}");
      debugPrint("Task Title: ${_requests[0].task.title}");
      debugPrint("Client ID: ${_requests[0].client.id}");
    } else {
      debugPrint("TaskRequestsScreen: No requests loaded yet");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Requests (${_requests.length})',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF03045E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF03045E)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No task requests available',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            Text(
              'When clients send you task requests, they will appear here',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03045E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(TaskRequest request) {
    // Convert API status to display status
    final String displayStatus = _getDisplayStatus(request.status);

    // Check if action buttons should be shown
    final bool isPending = request.status.toLowerCase() == 'pending';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF03045E),
                  child: Text(
                    request.client.firstName.isNotEmpty
                        ? request.client.firstName.substring(0, 1)
                        : 'C',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.client.firstName.isNotEmpty ||
                                request.client.lastName.isNotEmpty
                            ? '${request.client.firstName} ${request.client.lastName}'
                            : 'Client #${request.client.id}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (request.createdAt != null)
                        Text(
                          'Request date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(request.createdAt!))}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayStatus.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTaskInfoSection(request),
            const SizedBox(height: 16),
            if (isPending) _buildActionButtons(request),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfoSection(TaskRequest request) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.task.title ?? 'Untitled Task',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF03045E),
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Description', request.task.description ?? 'No description'),
          _buildInfoRow('Price', '\$${request.task.contactPrice ?? 0}'),
          _buildInfoRow('Urgency', request.task.urgency ?? 'Not specified'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TaskRequest request) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _declineRequest(request),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Decline',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _acceptRequest(request),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03045E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Accept',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Get display style status based on API status
  String _getDisplayStatus(String apiStatus) {
    // Convert API status to display status
    switch (apiStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
      case 'in negotiation':
        return 'In Negotiation';
      case 'declined':
        return 'Declined';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return apiStatus;
    }
  }

  // Get status color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'in negotiation':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
