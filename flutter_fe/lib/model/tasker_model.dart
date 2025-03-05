class TaskerModel{
  final String bio;
  final String specialization;
  final String skills;
  final bool? availability;
  final double wage_per_hour;
  final String? tesda_documents_link;
  final String? social_media_links;

  TaskerModel({
    required this.bio,
    required this.specialization,
    required this.skills,
    this.availability,
    required this.wage_per_hour,
    this.tesda_documents_link,
    this.social_media_links
  });

  //Factory to manage tasker data.
  factory TaskerModel.fromJson(Map<String, dynamic> json){
    return TaskerModel(
      bio: json['bio'],
      specialization: json['specialization'],
      skills: json['skills'],
      availability: json['availability'],
      wage_per_hour: json['wage_per_hour'],
      tesda_documents_link: json['tesda_documents_link'],
      social_media_links: json['social_media_links']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "bio": bio,
      "specialization": specialization,
      "skills": skills,
      "availability": availability,
      "wage_per_hour": wage_per_hour,
      "tesda_documents_link": tesda_documents_link,
      "social_media_links": social_media_links
    };
  }
}