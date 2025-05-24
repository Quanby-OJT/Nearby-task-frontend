import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/config/url_strategy.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/task_request.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class TaskRequestService {
  static String url = apiUrl ?? "https://192.168.1.10:5000/connect";
  static final storage = GetStorage();

  Future<String?> getUserId() async => storage.read('user_id')?.toString();

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      debugPrint("Response body: ${response.body}");

      // First check if response body is empty
      if (response.body.isEmpty) {
        return {"error": "Empty response from server"};
      }

      // Try to parse as JSON
      final dynamic responseBody = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if responseBody is a Map, if not wrap it
        if (responseBody is Map<String, dynamic>) {
          return responseBody;
        } else if (responseBody is Map) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          return Map<String, dynamic>.from(responseBody);
        } else if (responseBody is List) {
          return {"data": responseBody};
        } else {
          return {"data": responseBody};
        }
      } else {
        debugPrint("API Error Response: $responseBody");
        if (responseBody is Map && responseBody.containsKey("error")) {
          final error = responseBody["error"];
          return {"error": error?.toString() ?? "Unknown error"};
        } else {
          return {
            "error": "Unknown error with status code: ${response.statusCode}"
          };
        }
      }
    } catch (e) {
      debugPrint("Error parsing response: $e");
      debugPrint("Response body was: ${response.body}");

      // If we can't parse as JSON, return the raw body as a message
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"message": response.body};
      } else {
        return {"error": "Failed to parse response: $e"};
      }
    }
  }

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    final token = await AuthService.getSessionToken();
    try {
      String formattedEndpoint =
          endpoint.startsWith('/') ? endpoint : '/$endpoint';
      debugPrint('Making GET request to: $url$formattedEndpoint');

      final response = await http.get(
        Uri.parse('$url$formattedEndpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response for $endpoint: ${response.body}");
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint("API Request Error: $e");
      debugPrint(stackTrace.toString());
      return {"error": "Request failed: $e"};
    }
  }

  Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    try {
      String formattedEndpoint =
          endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final response = await http.post(
        Uri.parse('$url$formattedEndpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response for $endpoint: ${response.body}");
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint("API Request Error: $e");
      debugPrint(stackTrace.toString());
      return {"error": "Request failed: $e"};
    }
  }

  Future<Map<String, dynamic>> _putRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    try {
      final response = await http.put(
        Uri.parse('$url$endpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "Request failed. Please Try Again."};
    }
  }

  // Get all task requests for the tasker from task_taken table
  Future<List<TaskRequest>> getTaskerRequests() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        debugPrint("User ID is null, cannot fetch tasker requests");
        return [];
      }

      // Use the endpoint that matches the backend route
      final response = await _getRequest('/task-taken/tasker/$userId');
      debugPrint("Response from task-taken/tasker: $response");

      if (response.containsKey("error")) {
        debugPrint("Error fetching task requests: ${response["error"]}");
        return []; // Don't use mock data in case of actual API errors
      }

      // Check for 'tasks' array as per your backend response structure
      if (response.containsKey("tasks") && response["tasks"] is List) {
        debugPrint(
            "Found tasks array in response with ${response["tasks"].length} items");
        final List<dynamic> tasksData = response["tasks"];
        final requests = _mapTaskTakenToRequests(tasksData);

        debugPrint("Mapped ${requests.length} requests from tasks data");
        return requests;
      }
      // Also check for success flag in the response
      else if (response.containsKey("success") && response["success"] == true) {
        if (response.containsKey("data") && response["data"] is List) {
          final List<dynamic> tasksData = response["data"];
          final requests = _mapTaskTakenToRequests(tasksData);
          debugPrint("Mapped ${requests.length} requests from data array");
          return requests;
        }
      }

      // Log what keys were actually in the response to help with debugging
      debugPrint(
          "No task requests found in response. Response keys: ${response.keys.join(', ')}");

      // If response doesn't match expected format but isn't an error, return empty list
      return [];
    } catch (e, st) {
      debugPrint("Exception fetching tasker requests: $e");
      debugPrint(st.toString());

      // Return empty list instead of mock data in case of error
      return [];
    }
  }

  // Helper method to map task_taken data to TaskRequest objects
  List<TaskRequest> _mapTaskTakenToRequests(List<dynamic> data) {
    return data
        .map((item) {
          try {
            // Print the first 200 chars of the item for debugging
            final itemStr = item.toString();
            debugPrint(
                "Mapping task_taken item: ${itemStr.length > 200 ? '${itemStr.substring(0, 200)}...' : itemStr}");

            // Extract task_taken_id - this is the primary key we need for updates
            final int taskTakenId = item['id'] ?? item['task_taken_id'] ?? 0;
            debugPrint("Task taken ID: $taskTakenId");

            // Check if we have at least taskId and clientId
            final int taskId = _extractTaskId(item);
            final int clientId = _extractClientId(item);

            if (taskId == 0 || clientId == 0) {
              debugPrint(
                  "Missing required task_id or client_id, skipping item");
              return null;
            }

            // Extract task info
            final TaskModel task = _extractTaskModel(item, taskId);

            // Extract client info
            final UserModel client = _extractClientModel(item, clientId);

            // Extract tasker info
            final int taskerId = item['tasker_id'] ?? 0;
            final UserModel tasker = UserModel(
              id: taskerId,
              firstName: '', // Will be filled from user profile
              lastName: '', // Will be filled from user profile
              email: '', // Will be filled from user profile
              role: 'tasker',
            );

            // Get status - could be "status", "task_status", or "taskStatus"
            final String status = item['task_status'] ??
                item['taskStatus'] ??
                item['status'] ??
                'pending';

            // Create TaskRequest object using the taskTakenId as the requestId
            return TaskRequest(
              requestId:
                  taskTakenId, // *** Using task_taken.id as the requestId ***
              task: task,
              client: client,
              tasker: tasker,
              status: status,
              createdAt: item['created_at'] ?? DateTime.now().toIso8601String(),
            );
          } catch (e, st) {
            debugPrint("Error mapping task_taken item to TaskRequest: $e");
            debugPrint("Stack trace: $st");
            // Return null for failed mappings
            return null;
          }
        })
        .whereType<TaskRequest>()
        .toList(); // Filter out nulls
  }

  // Helper methods to extract data from different formats

  int _extractTaskId(dynamic item) {
    try {
      // In your backend response, task_id is at the root level
      // and task data is nested under 'task' which references post_task table
      return item['task_id'] ?? 0;
    } catch (e) {
      debugPrint("Error extracting task_id: $e");
      return 0;
    }
  }

  int _extractClientId(dynamic item) {
    try {
      // In your backend response, client_id is at the root level
      return item['client_id'] ?? 0;
    } catch (e) {
      debugPrint("Error extracting client_id: $e");
      return 0;
    }
  }

  TaskModel _extractTaskModel(dynamic item, int taskId) {
    try {
      // According to your backend, task details are under the 'task' field
      // which references the post_task table
      if (item.containsKey('task') && item['task'] is Map) {
        final taskData = item['task'];
        debugPrint("Task data: $taskData");

        return TaskModel(
            id: taskId, // Use the task_id from the root level
            title: taskData['task_title'] ?? '',
            description: taskData['task_description'] ?? '',
            contactPrice: taskData['proposed_price'] ?? 0,
            urgency: taskData['urgent'] == true ? 'Urgent' : 'Non-Urgent',
            specialization: taskData['specialization'],
            addressID: taskData['address_id'] ?? '',
            status: taskData['status'],
            scope: taskData['scope'],
            workType: '');
      }

      // Fallback if task data is not found
      return TaskModel(
          id: taskId,
          title: "Task #$taskId",
          description: "No details available",
          addressID: "",
          contactPrice: 0,
          urgency: "Unknown",
          specialization: '',
          status: '',
          scope: '',
          workType: '');
    } catch (e, stackTrace) {
      debugPrint("Error creating TaskModel: $e");
      debugPrintStack(stackTrace: stackTrace);
      // Return minimal task model
      return TaskModel(
          id: taskId,
          title: "Task #$taskId",
          description: "No details available",
          addressID: "",
          contactPrice: 0,
          urgency: "Unknown",
          specialization: '',
          status: '',
          scope: '',
          workType: '');
    }
  }

  UserModel _extractClientModel(dynamic item, int clientId) {
    try {
      // According to your backend, client details are under the 'client' field
      // which references the clients table
      if (item.containsKey('client') && item['client'] is Map) {
        final clientData = item['client'];

        // We need to fetch user details separately since your backend only returns
        // client_id, user_id, and client_address
        return UserModel(
          id: clientId,
          firstName: "Client", // We'll need to fetch these from the user table
          lastName: "#${clientData['user_id'] ?? clientId}",
          email: "",
          role: "client",
        );
      }

      // Fallback
      return UserModel(
        id: clientId,
        firstName: "Client",
        lastName: "#$clientId",
        email: "",
        role: "client",
      );
    } catch (e) {
      debugPrint("Error creating ClientModel: $e");
      // Return minimal client model
      return UserModel(
        id: clientId,
        firstName: "Client",
        lastName: "#$clientId",
        email: "",
        role: "client",
      );
    }
  }

  // Accept a task request from task_taken table
  Future<Map<String, dynamic>> acceptTaskRequest(int requestId) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'Please log in to accept requests',
        };
      }

      debugPrint("Accepting task with ID: $requestId and tasker ID: $userId");
      return await _postRequest(
        endpoint: '/update-status-tasker',
        body: {
          'task_taken_id': requestId,
          'tasker_id': int.parse(userId),
          'status': 'Confirmed'
        },
      );
    } catch (e) {
      debugPrint("Error accepting task request: $e");
      return {
        'success': false,
        'message': 'Failed to accept request: $e',
      };
    }
  }

  Future<Map<String, dynamic>> depositEscrowPayment(
      double depositAmount, String paymentMethod) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'Please log in to deposit payments.',
        };
      }
      debugPrint("Depositing escrow payment with price: $depositAmount");

      return await _postRequest(
        endpoint: '/deposit-escrow-payment',
        body: {
          'client_id': int.parse(userId),
          'amount': depositAmount,
          'payment_method': paymentMethod,
        },
      );
    } catch (e) {
      debugPrint("Error accepting task request: $e");
      return {
        'success': false,
        'error': 'Failed to accept request: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getTokenBalance() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'Please log in to check balance.',
        };
      }
      debugPrint("Checking token balance for user with ID: $userId");
      return await _getRequest('/get-token-balance/$userId');
    } catch (e) {
      debugPrint("Error checking token balance: $e");
      return {
        'success': false,
        'error': 'Failed to check balance: $e',
      };
    }
  }

  Future<Map<String, dynamic>> releaseEscrowPayment(int taskerId, double amount,
      String paymentMethod, String acctNumber) async {
    try {
      debugPrint("Releasing escrow payment with tasker ID: $taskerId");
      final String role = storage.read("role");
      return await _postRequest(
        endpoint: '/withdraw-escrow-amount/$taskerId',
        body: {
          'amount': amount,
          'payment_method': paymentMethod,
          'account_number': acctNumber,
          'role': role
        },
      );
    } catch (e, stackTrace) {
      debugPrint("Error releasing escrow payment: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        'success': false,
        'error': 'Failed to release the payment. Please Try Again.'
      };
    }
  }

  //Confirmation of Authorized Payment
  Future<Map<String, dynamic>> confirmPayment(
      int userId, double amount, bool success, String transactionId) async {
    try {
      return await _putRequest(
          endpoint: "/webhook/paymongo/$userId/$transactionId",
          body: {
            "amount": amount,
            "success": success,
          });
    } catch (error, stackTrace) {
      debugPrint("Error confirming payment: $error");
      debugPrintStack(stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to confirm payment. Please Try Again',
      };
    }
  }

  // Decline a task request from task_taken table
  Future<Map<String, dynamic>> declineTaskRequest(int requestId) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'Please log in to decline requests',
        };
      }

      debugPrint("Declining task with ID: $requestId and tasker ID: $userId");
      return await _postRequest(
        endpoint: '/update-status-tasker',
        body: {
          'task_taken_id': requestId,
          'tasker_id': int.parse(userId),
          'status': 'Declined'
        },
      );
    } catch (e) {
      debugPrint("Error declining task request: $e");
      return {
        'success': false,
        'message': 'Failed to decline request: $e',
      };
    }
  }

  Future<Map<String, dynamic>> rejectTaskerOrCancelTask(
      int requestId, String rejectOrCancel, String rejectionReason) async {
    try {
      return await _putRequest(
          endpoint: "/update-status-tasker/$requestId",
          body: {
            "task_status": rejectOrCancel,
            "reason_for_rejection_or_cancellation": rejectionReason
          });
    } catch (e, stackTrace) {
      debugPrint("Error rejecting tasker: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to reject the tasker. Please Try Again.'
      };
    }
  }

  // For demo/development: Generate mock task requests
  Future<List<TaskRequest>> getMockTaskRequests() async {
    // This is for testing UI without backend implementation
    try {
      final userId = await getUserId();
      if (userId == null) return [];

      // Create dummy client
      final client = UserModel(
        id: 1,
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        role: "client",
      );

      // Create dummy tasker (current user)
      final tasker = UserModel(
        id: int.parse(userId),
        firstName: "Current",
        lastName: "User",
        email: "current.user@example.com",
        role: "tasker",
      );

      // Create dummy tasks
      List<TaskModel> tasks = [
        TaskModel(
            id: 101,
            clientId: 1,
            title: "Fix Plumbing",
            description: "Need to fix a leaking pipe in the kitchen",
            scope: "123 Main St",
            contactPrice: 120,
            urgency: "Urgent",
            specialization: '',
            status: '',
            workType: ''),
        TaskModel(
            id: 102,
            clientId: 1,
            title: "Install Ceiling Fan",
            description: "Need to install a new ceiling fan in the living room",
            scope: "456 Oak Ave",
            contactPrice: 80,
            urgency: "Non-Urgent",
            specialization: '',
            status: '',
            workType: ''),
        TaskModel(
            id: 103,
            clientId: 1,
            title: "Paint Bedroom",
            description: "Paint the walls of a medium-sized bedroom",
            scope: "789 Pine Blvd",
            contactPrice: 200,
            urgency: "Non-Urgent",
            specialization: '',
            status: '',
            workType: ''),
      ];

      // Create dummy requests
      List<TaskRequest> requests = [];
      for (var i = 0; i < tasks.length; i++) {
        requests.add(
          TaskRequest(
            requestId: 1000 + i,
            task: tasks[i],
            client: client,
            tasker: tasker,
            status: 'pending',
            createdAt:
                DateTime.now().subtract(Duration(days: i)).toIso8601String(),
          ),
        );
      }

      return requests;
    } catch (e) {
      debugPrint("Error generating mock requests: $e");
      return [];
    }
  }
}
