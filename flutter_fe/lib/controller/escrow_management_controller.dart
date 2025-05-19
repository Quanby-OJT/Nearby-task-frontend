import 'dart:convert';

import 'package:flutter/cupertino.dart';
import '../service/task_request_service.dart';
import 'package:web_socket_channel/io.dart';

class EscrowManagementController {
  final TaskRequestService _requestService = TaskRequestService();
  final TextEditingController rejectionController = TextEditingController();
  final TextEditingController otherReasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderNameController =
      TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController acctNumberController = TextEditingController();

  int tokenRate = 1;
  ValueNotifier<int> tokenCredits = ValueNotifier(0);
  IOWebSocketChannel? _channel;

  EscrowManagementController() {
    amountController.addListener(() {
      calculateTokens();
    });
    fetchTokenBalance();
  }

  void calculateTokens() {
    if (amountController.text.isNotEmpty) {
      try {
        debugPrint("Amount: ${amountController.text}");
        String cleanedAmount =
            amountController.text.replaceAll("₱", "").replaceAll(",", "");
        debugPrint("Amount: $cleanedAmount");
        double.parse(cleanedAmount);
      } catch (e) {
        return;
      }
      tokenCredits.value = (double.parse(amountController.text
                  .replaceAll("₱", "")
                  .replaceAll(",", "")) *
              tokenRate)
          .toInt();
    } else {
      tokenCredits.value = 0;
    }
  }

  Future<void> fetchTokenBalance() async {
    try {
      var response = await _requestService.getTokenBalance();

      if (response['success'] == false) {
        debugPrint("Error fetching token balance: ${response["error"]}");
        return;
      }
      tokenCredits.value = response["tokens"];
    } catch (e) {
      debugPrint("Error fetching token balance: $e");
    }
  }

  Future<Map<String, dynamic>> depositAmountToEscrow(String paymentMethod) async {
    try {
      debugPrint("TaskRequestController: Depositing amount to escrow");
      debugPrint("TaskRequestController: Contract Price: ${amountController.text}");

      // Make the API call
      var response = await _requestService.depositEscrowPayment(
          double.parse(amountController.text.replaceAll("₱", "").replaceAll(",", "")),
          paymentMethod,
          acctNumberController.text
      );

      // Check for success
      if (response['success'] == true) {
        await fetchTokenBalance();
        return {
          "success": true,
          "payment_url": response['payment_url'] ?? ''
        };
      }
      // Check for known error
      else if (response.containsKey('error')) {
        return {"success": false, "error": response['error'] ?? 'Unknown error occurred'};
      }
      // Fallback for unexpected response structure
      else {
        return {"success": false, "error": 'Unexpected response from server. Please try again.'};
      }
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      return {"success": false, "error": 'Error depositing amount to escrow. Please try again.'};
    }
  }

  Future<String> validatePayment(bool success, int userId, String transactionId, double amount) async{
    final response = await _requestService.confirmPayment(userId, amount, success, transactionId);

    if(response.containsKey('success')){
      if(response.containsKey('message')){
        return response['message'] ?? "Your Payment has been successfully processed.";
      }
      else if(response.containsKey('error')){
        return response['error'] ?? "An Error Occurred while processing your payment.";
      }else{
        return "An Error Occurred while processing your payment.";
      }
    }else{
      return "An Error Occurred while processing your payment.";
    }
  }

  Future<Map<String, dynamic>> releaseEscrowPayment(int taskerId, String paymentMethod) async {
    try {
      debugPrint(
          "TaskRequestController: Releasing escrow payment for task taken with ID $taskerId");
      var response = await _requestService.releaseEscrowPayment(taskerId, double.parse(amountController.text), paymentMethod, acctNumberController.text);
      if (response.containsKey("message")) {
        return {"success": true, "payment_url": response["payment_url"]};
      } else if (response.containsKey("error")) {
        return {"success": false, "error": response["error"] ?? "An Error Occured while releasing escrow payment."};
      } else {
        return {"success": false, "error": "An Error Occured while releasing escrow payment."};
      }
    } catch (e, stackTrace) {
      debugPrint("Error in TaskRequestController.releaseEscrowPayment: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {"success": false, "error": "An Error Occured while releasing escrow payment."};
    }
  }

  void connectWebSocket() async {
    _channel = IOWebSocketChannel.connect('ws://localhost:5000');
    _channel!.stream.listen((message) {
      debugPrint('Received message: $message');

      final data = jsonDecode(message);

      if (data['amount'] != null) {
        tokenCredits.value = data['amount'];
      }
    }, onError: (error) {
      debugPrint('WebSocket error: $error');
    }, onDone: () {
      debugPrint('WebSocket connection closed');
    });
  }

  void dispose() {
    amountController.dispose();
    rejectionController.dispose();
    otherReasonController.dispose();
    tokenCredits.dispose();
  }
}
