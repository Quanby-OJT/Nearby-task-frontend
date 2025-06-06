import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/user_model.dart';

class Disputes {
  final TaskAssignment? taskAssignment;
  final String disputeReason;
  final String disputeDetails;
  final String moderatorAction;
  final String moderatorNotes;
  final UserModel? raisedBy;

  Disputes({
    required this.disputeReason,
    required this.disputeDetails,
    required this.moderatorAction,
    required this.moderatorNotes,
    this.raisedBy,
    this.taskAssignment
  });

  factory Disputes.fromJson(Map<String, dynamic> json) {
    return Disputes(
      raisedBy: json['raised_by'] != null ? UserModel.fromJson(json['raised_by']) : null,
      disputeReason: json['reason_for_dispute'],
      disputeDetails: json['dispute_details'],
      moderatorAction: json['moderator_action'] ?? "No action taken",
      moderatorNotes: json['addl_dispute_notes'] ?? "",
      taskAssignment: TaskAssignment.fromJson(json['task_taken'])
    );
  }
}