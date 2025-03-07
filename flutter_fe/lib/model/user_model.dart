class UserModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String password;
  final dynamic
      image; // Can be either a String (URL) or Uint8List (binary data)
  final String? imageName; // Store image filename if available
  final String role; // Ensure role is passed
  final String status;

  UserModel(
      {required this.firstName,
      required this.middleName,
      required this.lastName,
      required this.email,
      required this.password,
      this.image,
      this.imageName,
      required this.role, // Ensure role is required
      required this.status});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        firstName: json['first_name'],
        middleName: json['middle_name'],
        lastName: json['last_name'],
        email: json['email'],
        password: json['hashed_password'],
        image: json['image_link'] is String ? json['image_link'] : null,
        imageName: json['image_name'],
        role: json['user_role'], // Ensure role is parsed
        status: json["acc_status"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "email": email,
      "password": password,
      "user_role": role,
      "acc_status": status
    };
  }
}
