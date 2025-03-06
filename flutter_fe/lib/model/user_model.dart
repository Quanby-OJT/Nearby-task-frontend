class UserModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String? birthdate;
  final String? password;
  final dynamic
  image; // Can be either a String (URL) or Uint8List (binary data)
  final String? imageName; // Store image filename if available
  final String role;
  final String accStatus;


//This is what the controller used
  UserModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    this.password,
    this.image,
    this.imageName,
    required this.role,
    this.birthdate,
    required this.accStatus
  });

  // Factory constructor to handle image as either URL or binary data, this is for the display record part
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['first_name'] ?? '', // Default to empty string
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      birthdate: json['birthdate'] as String?, // Allow null values
      email: json['email'] ?? '',
      password: json['hashed_password'] as String?, // Allow null values
      image: json['image_link'] ?? '', // Ensure it's not null
      imageName: json['image_name'] as String?, // Allow null values
      role: json['user_role'] ?? '',
      accStatus: json['acc_status'] ?? '',
    );
  }


// Returns whith these datas
  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "email": email,
      "hashed_password": password,
      "user_role": role
      // Store the image as a URL (String) or handle binary data (Uint8List) if needed
    };
  }
}
