import 'package:flutter/material.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/setting_service.dart';

class SettingController {
  final SettingService settingService = SettingService();
  GetStorage storage = GetStorage();

  Future setLocation(double latitude, double longitude) async {
    debugPrint('Setting location: $latitude, $longitude');
    final taskerId = storage.read('user_id');

    if (taskerId == null) {
      debugPrint('Error: tasker_id is null in storage');
      throw Exception('User ID not found. Please login again.');
    }

    return settingService.setLocation(taskerId, latitude, longitude);
  }

  Future<SettingModel> getLocation() async {
    final taskerId = storage.read('user_id');

    if (taskerId == null) {
      debugPrint('Error: tasker_id is null in storage');
      throw Exception('User ID not found. Please login again.');
    }

    return settingService.getLocation(taskerId);
  }
}
