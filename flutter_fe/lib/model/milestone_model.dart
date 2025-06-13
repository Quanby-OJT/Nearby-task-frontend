class MilestoneModel {
  final int? id;
  final int taskId;
  final String title;
  final String description;
  final double amount;
  final DateTime? dueDate;
  final String status; // 'pending', 'in_progress', 'completed', 'overdue'
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int order; // For ordering milestones

  MilestoneModel({
    this.id,
    required this.taskId,
    required this.title,
    required this.description,
    required this.amount,
    this.dueDate,
    this.status = 'pending',
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    required this.order,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'] as int?,
      taskId: json['task_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'description': description,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'order': order,
    };
  }

  MilestoneModel copyWith({
    int? id,
    int? taskId,
    String? title,
    String? description,
    double? amount,
    DateTime? dueDate,
    String? status,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isCompleted;

  @override
  String toString() {
    return 'MilestoneModel(id: $id, taskId: $taskId, title: $title, description: $description, amount: $amount, dueDate: $dueDate, status: $status, order: $order)';
  }
}

// Extension to calculate progress for a list of milestones
extension MilestoneListExtension on List<MilestoneModel> {
  double get progressPercentage {
    if (isEmpty) return 0.0;
    final completed = where((m) => m.isCompleted).length;
    return (completed / length) * 100;
  }

  double get totalAmount =>
      fold(0.0, (sum, milestone) => sum + milestone.amount);

  double get completedAmount => where((m) => m.isCompleted)
      .fold(0.0, (sum, milestone) => sum + milestone.amount);
}
