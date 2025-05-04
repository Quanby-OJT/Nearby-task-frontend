class SpecializationModel {
  final int? id;
  final String specialization;

  SpecializationModel({this.id, this.specialization = ""});

  Map<String, dynamic> toJson() {
    return {"id": id, "specialization": specialization};
  }

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: json['spec_id'] != null ? json['spec_id'] as int : null,
      specialization: json['specialization'] as String,
    );
  }
}
