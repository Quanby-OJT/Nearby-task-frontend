import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressModel {
  final String? id;
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
  final String? remarks;

  AddressModel({
    this.id,
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
    this.remarks,
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
      case 'formatted_Address':
        return formattedAddress;
      case 'region':
      case 'region_name':
        return regionName;
      case 'remarks':
        return remarks;
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
        remarks,
      ];

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? json['id'] as String?,
      streetAddress: json['street']?.toString() ??
          json['street_address']?.toString() ??
          '',
      barangay: json['barangay']?.toString(),
      city: json['city']?.toString() ?? 'Unknown City',
      province: json['province']?.toString() ?? 'Unknown Province',
      postalCode: json['postal_code']?.toString() ?? '',
      country: json['country']?.toString() ?? 'Philippines',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString()) ?? 0.0
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString()) ?? 0.0
          : null,
      defaultAddress: json['default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : null,
      formattedAddress: json['formatted_address']?.toString() ??
          json['formatted_Address']?.toString() ??
          '',
      regionName:
          json['region']?.toString() ?? json['region_name']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
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
      'remarks': remarks,
    };
  }

  @override
  String toString() {
    return 'AddressModel(streetAddress: $streetAddress, barangay: $barangay, city: $city, province: $province, postalCode: $postalCode, country: $country, latitude: $latitude, longitude: $longitude, default: $defaultAddress, createdAt: $createdAt, updatedAt: $updatedAt, formattedAddress: $formattedAddress, regionName: $regionName, remarks: $remarks)';
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
      id: mapData['id']?.toString(),
      streetAddress: mapData['street_address']?.toString() ?? '',
      barangay: mapData['barangay']?.toString(),
      city: mapData['city']?.toString() ?? 'Unknown City',
      province: mapData['province']?.toString() ?? 'Unknown Province',
      postalCode: mapData['postal_code']?.toString() ?? '',
      country: mapData['country']?.toString() ?? 'Philippines',
      latitude: mapData['latitude'] != null
          ? double.tryParse(mapData['latitude'].toString()) ?? 0.0
          : null,
      longitude: mapData['longitude'] != null
          ? double.tryParse(mapData['longitude'].toString()) ?? 0.0
          : null,
      formattedAddress: mapData['formattedAddress']?.toString() ?? '',
      regionName: mapData['region']?.toString() ?? '',
      remarks: mapData['remarks']?.toString() ?? '',
    );
  }
}
