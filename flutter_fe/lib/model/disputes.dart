import 'package:flutter_fe/model/task_assignment.dart';

class Disputes {
  final TaskAssignment? taskAssignment;
  final String disputeReason;
  final String disputeDetails;
  final String moderatorAction;
  final String moderatorNotes;

  Disputes({
    required this.disputeReason,
    required this.disputeDetails,
    required this.moderatorAction,
    required this.moderatorNotes,
    this.taskAssignment
  });

  factory Disputes.fromJson(Map<String, dynamic> json) {
    return Disputes(
      disputeReason: json['reason_for_dispute'],
      disputeDetails: json['dispute_details'],
      moderatorAction: json['moderator_action'] ?? "No action taken",
      moderatorNotes: json['addl_dispute_notes'] ?? "",
      taskAssignment: TaskAssignment.fromJson(json['task_taken'])
    );
  }
}