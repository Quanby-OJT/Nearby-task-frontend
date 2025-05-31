import 'package:flutter/material.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/setting_service.dart';

class SettingController {
  final SettingService settingService = SettingService();
  GetStorage storage = GetStorage();

  Future setLocation(
      double latitude, double longitude, String city, String province) async {
    debugPrint('Setting location: $latitude, $longitude');
    final taskerId = storage.read('user_id');

    if (taskerId == null) {
      debugPrint('Error: tasker_id is null in storage');
      throw Exception('User ID not found. Please login again.');
    }

    return settingService.setLocation(
        taskerId, latitude, longitude, city, province);
  }

  Future<SettingModel> getLocation() async {
    final taskerId = storage.read('user_id');

    if (taskerId == null) {
      debugPrint('Error: tasker_id is null in storage');
      throw Exception('User ID not found. Please login again.');
    }

    return settingService.getLocation(taskerId);
  }

  Future<void> updateSpecialization(List<String> specialization) async {
    final taskerId = storage.read('user_id');

    if (taskerId == null) {
      debugPrint('Error: tasker_id is null in storage');
      throw Exception('User ID not found. Please login again.');
    }

    debugPrint('Updating specialization: $specialization');

    return settingService.updateSpecialization(taskerId, specialization);
  }

  Future<void> updateDistance(
      double distance, RangeValues ageRange, bool showFurtherAway) async {
    final taskerId = storage.read('user_id');

    debugPrint('Updating distance: $distance, age range: $ageRange');

    if (taskerId == null) {
      debugPrint('Error: tasker_id is null in storage');
      throw Exception('User ID not found. Please login again.');
    }

    debugPrint('Updating distance: $distance, age range: $ageRange');

    return settingService.updateDistance(
        taskerId, distance, ageRange, showFurtherAway);
  }

  Future<List<AddressModel>> loadAddresses() async {
    final userId = storage.read('user_id');
    final addresses = await settingService.getAddresses(userId as int);

    debugPrint('my addresses is this post: $addresses');
    return addresses;
  }

  Future setAddress(
    double latitude,
    double longitude,
    String formattedAddress,
    String region,
    String province,
    String city,
    String barangay,
    String street,
    String postalCode,
    String country,
    String remarks,
  ) async {
    final userId = storage.read('user_id');

    if (userId == null) {
      debugPrint('Error: user_id is null in storage');
      throw Exception('User ID not found. Please login again.');
    }

    return settingService.setAddress(
      userId,
      latitude,
      longitude,
      formattedAddress,
      region,
      province,
      city,
      barangay,
      street,
      postalCode,
      country,
      remarks,
    );
  }

  Future updateAddress(
    String addressId,
    double latitude,
    double longitude,
    String formattedAddress,
    String region,
    String province,
    String city,
    String barangay,
    String street,
    String postalCode,
    String country,
    String remarks,
  ) async {
    try {
      return settingService.updateAddress(
        addressId,
        latitude,
        longitude,
        formattedAddress,
        region,
        province,
        city,
        barangay,
        street,
        postalCode,
        country,
        remarks,
      );
    } catch (e) {
      debugPrint('Error updating address: $e');
      throw Exception('Failed to update address. Please try again.');
    }
  }

  Future<dynamic> deleteAddress(String addressId) async {
    try {
      return settingService.deleteAddress(addressId);
    } catch (e) {
      debugPrint('Error deleting address: $e');
      throw Exception('Failed to delete address. Please try again.');
    }
  }
}
