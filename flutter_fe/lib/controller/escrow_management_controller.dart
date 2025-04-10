import 'dart:convert';

import 'package:flutter/cupertino.dart';
import '../service/task_request_service.dart';
import 'package:web_socket_channel/io.dart';

class EscrowManagementController {
  final TaskRequestService _requestService = TaskRequestService();
  final TextEditingController rejectionController = TextEditingController();
  final TextEditingController otherReasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  int tokenRate = 1;
  ValueNotifier<int> tokenCredits = ValueNotifier(0);
  IOWebSocketChannel? _channel;

  EscrowManagementController(){
    amountController.addListener(() {
      calculateTokens();
    });
    fetchTokenBalance();
  }

  void calculateTokens(){
    if(amountController.text.isNotEmpty) {
      try {
        debugPrint("Amount: ${amountController.text}");
        String cleanedAmount = amountController.text.replaceAll("₱", "").replaceAll(",", "");
        debugPrint("Amount: $cleanedAmount");
        double.parse(cleanedAmount);
      } catch (e) {
        return;
      }
      tokenCredits.value = (double.parse(amountController.text.replaceAll("₱", "").replaceAll(",", "")) * tokenRate).toInt();
    }else {
      tokenCredits.value = 0;
    }
  }

  Future<void> fetchTokenBalance() async {
    try {
      var response = await _requestService.getTokenBalance();

      if (response['success'] == true && response.containsKey('token_balance')) {
        debugPrint("Error fetching token balance: ${response["error"]}");
        return;
      }
      tokenCredits.value = response["token_balance"];
    } catch (e) {
      debugPrint("Error fetching token balance: $e");
    }
  }

  Future<Map<String, dynamic>> depositAmountToEscrow() async{
    try{
      // debugPrint("TaskRequestController: Depositing amount to escrow");
      // debugPrint("TaskRequestController: Contract Price: $contractPrice");
      // debugPrint("TaskRequestController: Task Taken ID: $taskTakenId");
      var response = await _requestService.depositEscrowPayment(double.parse(amountController.text.replaceAll("₱", "").replaceAll(",", "")));

      if(response['success']){
        await fetchTokenBalance();
        return {"message": response['message'], "payment_url": response['payment_url']};
      }else{
        return {"error": response['error']};
      }
    }catch(e, st){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      return {"error": 'Error depositing amount to escrow. Please try again.'};
    }
  }

  Future<String> releaseEscrowPayment(int taskTakenId) async{
    try{
      debugPrint("TaskRequestController: Releasing escrow payment for task taken with ID $taskTakenId");
      var response = await _requestService.releaseEscrowPayment(taskTakenId);
      if(response.containsKey("message")){
        return response["message"];
      }else if(response.containsKey("error")){
        return response["error"];
      }else{
        return "Unknown Error";
      }
    }catch(e, stackTrace){
      debugPrint("Error in TaskRequestController.releaseEscrowPayment: $e");
      debugPrintStack(stackTrace: stackTrace);
      return "An Error Occured while releasing your payment. Please Try Again.";
    }
  }

  void connectWebSocket() async {
    _channel = IOWebSocketChannel.connect('ws://10.0.2.2:5000');
    _channel!.stream.listen((message) {
      debugPrint('Received message: $message');

      final data = jsonDecode(message);

      if(data['amount'] != null){
        tokenCredits.value = data['amount'];
      }
    }, onError: (error) {
      debugPrint('WebSocket error: $error');
    }, onDone: () {
      debugPrint('WebSocket connection closed');
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    rejectionController.dispose();
    otherReasonController.dispose();
    tokenCredits.dispose();
  }
}