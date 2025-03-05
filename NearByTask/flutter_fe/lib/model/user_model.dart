class UserModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String password;
  final dynamic
      image; // Can be either a String (URL) or Uint8List (binary data)
  final String? imageName; // Store image filename if available
  final String role;


//This is what the controller used
  UserModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.password,
    this.image,
    this.imageName,
    required this.role
  });

  // Factory constructor to handle image as either URL or binary data, this is for the display record part
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      email: json['email'],
      password: json['hashed_password'],
      // Check if the image is a URL (String) or binary data (Uint8List)
      image: json['image_link'] is String
          ? json['image_link']
          : null, // Assuming image is a URL (String)
      imageName: json['image_name'],
      role: json['user_role']
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
