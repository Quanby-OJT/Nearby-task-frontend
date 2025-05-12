// Represents the top-level structure of the fetched data
class MessagesAssignment {
  final List<TaskAssignment> taskAssignments;
  final List<Conversation> conversations;

  MessagesAssignment({
    required this.taskAssignments,
    required this.conversations,
  });

  factory MessagesAssignment.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final taskAssignments = (data[0] as List<dynamic>)
        .map((item) => TaskAssignment.fromJson(item as Map<String, dynamic>))
        .toList();
    final conversations = (data[1] as List<dynamic>)
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList();
    return MessagesAssignment(
      taskAssignments: taskAssignments,
      conversations: conversations,
    );
  }
}

// Represents an individual task assignment
class TaskAssignment {
  final int taskTakenId;
  final String taskStatus;
  final int unreadCount;
  final int taskerId;
  final int clientId;
  final Task task;
  final Client client;
  final Tasker tasker;

  TaskAssignment({
    required this.taskTakenId,
    required this.taskStatus,
    required this.unreadCount,
    required this.taskerId,
    required this.clientId,
    required this.task,
    required this.client,
    required this.tasker,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      taskTakenId: json['task_taken_id'] as int,
      taskStatus: json['task_status'] as String,
      unreadCount: json['unread_count'] as int,
      taskerId: json['tasker_id'] as int,
      clientId: json['client_id'] as int,
      task: Task.fromJson(json['post_task'] as Map<String, dynamic>),
      client: Client.fromJson(json['clients'] as Map<String, dynamic>),
      tasker: Tasker.fromJson(json['tasker'] as Map<String, dynamic>),
    );
  }
}

// Represents task details
class Task {
  final int taskId;
  final String taskTitle;

  Task({
    required this.taskId,
    required this.taskTitle,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id'] as int,
      taskTitle: json['task_title'] as String,
    );
  }
}

// Represents client details
class Client {
  final User user;

  Client({
    required this.user,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

// Represents tasker details
class Tasker {
  final User user;

  Tasker({
    required this.user,
  });

  factory Tasker.fromJson(Map<String, dynamic> json) {
    return Tasker(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

// Represents user details
class User {
  final int userId;
  final String lastName;
  final String firstName;
  final String imageLink;
  final String? middleName;

  User({
    required this.userId,
    required this.lastName,
    required this.firstName,
    required this.imageLink,
    this.middleName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
      imageLink: json['image_link'] as String,
      middleName: json['middle_name'] as String?,
    );
  }
}

// Represents conversation details
class Conversation {
  final int taskTakenId;
  final int userId;
  final DateTime createdAt;

  Conversation({
    required this.taskTakenId,
    required this.userId,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      taskTakenId: json['task_taken_id'] as int,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
