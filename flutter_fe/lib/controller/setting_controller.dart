import 'package:flutter/material.dart';
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
}
