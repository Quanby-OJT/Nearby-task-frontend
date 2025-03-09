class ClientModel{
  final String preferences;
  final String clientAddress;

  ClientModel({
    required this.preferences,
    required this.clientAddress
  });

  Map<String, dynamic> toJson() {
    return{
      "preferences": preferences,
      "client_address": clientAddress
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json){
    return ClientModel(
        preferences: json['preferences'] as String,
        clientAddress: json['client_address'] as String
    );
  }
}