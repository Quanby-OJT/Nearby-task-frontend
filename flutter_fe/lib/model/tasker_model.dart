class TaskerModel {
  final String gender;
  final String contactNumber;
  final String address;
  final String birthDate;
  final String profilePicture;
  final String bio;
  final String specialization;
  final String skills;
  final bool? availability;
  final String? taskerDocuments;
  final String? socialMediaLinks;
  final String taskerAddress;

  TaskerModel(
      {required this.gender,
      required this.contactNumber,
      required this.address,
      required this.birthDate,
      required this.profilePicture,
      required this.bio,
      required this.specialization,
      required this.skills,
      this.availability,
      required this.wage_per_hour,
      this.tesda_documents_link,
      this.social_media_links});

  //Factory to manage tasker data.
  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    return TaskerModel(
        gender: json["gender"],
        address: json["address"],
        contactNumber: json["contact_number"],
        birthDate: json["birthdate"],
        profilePicture: json["profile_picture"],
        bio: json['bio'],
        specialization: json['specialization'],
        skills: json['skills'],
        availability: json['availability'],
        wage_per_hour: json['wage_per_hour'],
        tesda_documents_link: json['tesda_documents_link'],
        social_media_links: json['social_media_links']);
  }


  Map<String, dynamic> toJson() {
    return {
      "gender": gender,
      "address": address,
      "contact_number": contactNumber,
      "birthdate": birthDate,
      "profile_picture": profilePicture,
      "bio": bio,
      "specialization": specialization,
      "skills": skills,
      "address": taskerAddress,
      "availability": availability,
      "tesda_documents_link": taskerDocuments,
      "social_media_links": socialMediaLinks
    };
  }
}
