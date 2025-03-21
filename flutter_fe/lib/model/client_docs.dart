class ClientDocsModel {
  final dynamic image;

//This is what the controller used
  ClientDocsModel({
    this.image,
  });
  factory ClientDocsModel.fromJson(Map<String, dynamic> json) {
    return ClientDocsModel(
      image: json['document_url'] ?? '', // Ensure it's not null
    );
  }

  Map<String, dynamic> toJson() {
    return {"document_url": image};
  }

  @override
  String toString() {
    return 'UserClientDocsModel(image: $image)';
  }
}
