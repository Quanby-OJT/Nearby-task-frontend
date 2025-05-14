import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressModel {
  final int id;
  final double? latitude;
  final double? longitude;
  final String streetAddress;
  final String? barangay;
  final String city;
  final String province;
  final String postalCode;
  final String country;
  final bool? defaultAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? formattedAddress;
  final String? regionName;

  AddressModel({
    required this.id,
    this.latitude,
    this.longitude,
    required this.streetAddress,
    this.barangay,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.country,
    this.defaultAddress,
    this.createdAt,
    this.updatedAt,
    this.formattedAddress,
    this.regionName,
  });

  // Operator overloading to allow map-like access
  dynamic operator [](String key) {
    switch (key) {
      case 'user_id':
      case 'id':
        return id;
      case 'latitude':
        return latitude;
      case 'longitude':
        return longitude;
      case 'street':
      case 'street_address':
        return streetAddress;
      case 'barangay':
        return barangay;
      case 'city':
        return city;
      case 'province':
        return province;
      case 'postal_code':
        return postalCode;
      case 'country':
        return country;
      case 'default':
        return defaultAddress;
      case 'created_at':
        return createdAt;
      case 'updated_at':
        return updatedAt;
      case 'formatted_address':
        return formattedAddress;
      case 'region_name':
        return regionName;
      default:
        return null;
    }
  }

  // To support map-like operations in the codebase
  bool get isNotEmpty => true;

  // To support values access in the codebase
  Iterable<dynamic> get values => [
        id,
        streetAddress,
        barangay,
        city,
        province,
        postalCode,
        country,
        latitude,
        longitude,
        defaultAddress,
        createdAt,
        updatedAt,
        formattedAddress,
        regionName,
      ];

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? json['user_id'] as String?,
      streetAddress: json['street'] ?? json['street_address'] ?? '',
      barangay: json['barangay'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      defaultAddress: json['default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      formattedAddress: json['formatted_address'] ?? '',
      regionName: json['region_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'street_address': streetAddress,
      'barangay': barangay,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'default': defaultAddress,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'formatted_address': formattedAddress,
      'region_name': regionName,
    };
  }

  @override
  String toString() {
    return 'AddressModel(streetAddress: $streetAddress, barangay: $barangay, city: $city, province: $province, postalCode: $postalCode, country: $country, latitude: $latitude, longitude: $longitude, default: $defaultAddress, createdAt: $createdAt, updatedAt: $updatedAt, formattedAddress: $formattedAddress, regionName: $regionName)';
  }

  // Helper method to get LatLng for Google Maps
  LatLng? getLatLng() {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  // Create a new instance from map data
  factory AddressModel.fromMapData(Map<String, dynamic> mapData) {
    return AddressModel(
      streetAddress: mapData['street_address'] ?? '',
      barangay: mapData['barangay'],
      city: mapData['city'] ?? '',
      province: mapData['province'] ?? '',
      postalCode: mapData['postal_code'] ?? '',
      country: mapData['country'] ?? 'Philippines',
      latitude: mapData['latitude'],
      longitude: mapData['longitude'],
      formattedAddress: mapData['formattedAddress'],
      regionName: mapData['region'],
    );
  }
}
