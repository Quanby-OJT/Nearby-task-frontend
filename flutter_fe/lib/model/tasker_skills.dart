class TaskerSkills {
  final int id;
  final String relevantSkills;

  TaskerSkills({required this.id, required this.relevantSkills});

  factory TaskerSkills.fromJson(Map<String, dynamic> json) {
    return TaskerSkills(
      id: json['id'],
      relevantSkills: json['relevant_skill'],
    );
  }
}
