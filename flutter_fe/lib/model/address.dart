class AddressModel {
  final int? id;
  final String streetAddress;
  final String? barangay;
  final String city;
  final String province;
  final String postalCode;
  final String country;

  AddressModel({
    this.id,
    required this.streetAddress,
    this.barangay,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.country,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['user_id'] as int?,
      streetAddress: json['street_address'] ?? '',
      barangay: json['barangay'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": id,
      "street_address": streetAddress,
      "barangay": barangay,
      "city": city,
      "province": province,
      "postal_code": postalCode,
      "country": country
    };
  }

  @override
  String toString() {
    return 'AddressModel(streetAddress: $streetAddress, barangay: $barangay, city: $city, province: $province, postalCode: $postalCode, country: $country)';
  }
}
