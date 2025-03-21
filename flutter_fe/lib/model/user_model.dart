class UserModel {
  final int? id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String? birthdate;
  final String? password;
  final dynamic image;
  final String? imageName;
  final String role;
  final String accStatus;
  final String? gender;

//This is what the controller used
  UserModel(
    {
      this.id,
      required this.firstName,
      required this.middleName,
      required this.lastName,
      required this.email,
      this.password,
      this.image,
      this.imageName,
      required this.role,
      this.birthdate,
      required this.accStatus,
      this.gender,
    }
  );

  // Factory constructor to handle image as either URL or binary data, this is for the display record part
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] as int?, // Allow null values
      firstName: json['first_name'] ?? '', // Default to empty string
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      birthdate: json['birthdate'] as String?, // Allow null values
      email: json['email'] ?? '',
      password: json['hashed_password'] as String?, // Allow null values
      image: json['image_link'] ?? '', // Ensure it's not null
      imageName: json['image_link'] as String?, // Allow null values
      role: json['user_role'] ?? '',
      accStatus: json['acc_status'] ?? '',
      gender: json['gender'] as String?, // Allow null values
    );
  }

// Returns whith these datas
  Map<String, dynamic> toJson() {
    return {
      "user_id": id,
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "email": email,
      "password": password,
      "user_role": role,
      "acc_status": accStatus,
      "gender": gender
    };
  }

  @override
  String toString() {
    return 'UserModel(firstName: $firstName, middleName: $middleName, lastName: $lastName, email: $email, password: ${password != null ? "****" : "null"}, role: $role, accStatus: $accStatus)';
  }
}
