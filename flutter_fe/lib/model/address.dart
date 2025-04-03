class AddressModel {
  final int? id;
  final String streetAddress;
  final String? barangay;
  final String city;
  final String province;
  final String postalCode;
  final String country;

//This is what the controller used
  AddressModel({
    this.id,
    required this.streetAddress,
    this.barangay,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.country,
  });

  // Factory constructor to handle image as either URL or binary data, this is for the display record part
  // This is for the display record part
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['user_id'] as int?, // Allow null values
      streetAddress: json['street_address'] ?? '', // Default to empty string
      barangay: json['barangay'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
    );
  }

// Returns whith these datas
// This is for the display record part
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

  // This is for the display record part
  String toString() {
    return 'AddressModel(streetAddress: $streetAddress, barangay: $barangay, city: $city, province: $province, postalCode: $postalCode, country: $country)';
  }
}
