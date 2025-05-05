class UserAddressModel {
  final String? id;
  final double latitude;
  final double longitude;
  final String street;
  final String? barangay;
  final String city;
  final String province;
  final String postalCode;
  final String country;
  final bool? defaultAddress;

  UserAddressModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.street,
    this.barangay,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.country,
    this.defaultAddress,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: json['user_id'] as String?,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      street: json['street'] ?? '',
      barangay: json['barangay'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      defaultAddress: json['default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": id ?? "",
      "latitude": latitude,
      "longitude": longitude,
      "street": street,
      "barangay": barangay ?? "",
      "city": city,
      "province": province ?? "",
      "postal_code": postalCode ?? "",
      "country": country ?? "",
      "default": defaultAddress,
    };
  }

  @override
  String toString() {
    return 'UserAddressModel(street: $street, barangay: $barangay, city: $city, province: $province, postalCode: $postalCode, country: $country, defaultAddress: $defaultAddress)';
  }
}
