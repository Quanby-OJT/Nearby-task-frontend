class SpecializationModel{
  final String specialization;

  SpecializationModel({
    this.specialization = ""
  });

  Map<String, dynamic> toJson() {
    return{
      "specialization": specialization
    };
  }

  factory SpecializationModel.fromJson(Map<String, dynamic> json){
    return SpecializationModel(
      specialization: json['specialization'] as String
    );
  }
}