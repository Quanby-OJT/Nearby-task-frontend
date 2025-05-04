import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/address/set-up_address.dart';
import 'package:flutter_fe/view/setting/tasker_specialization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final GetStorage storage = GetStorage();
  final SettingController _settingController = SettingController();
  bool _showFurtherAway = true;
  double _maxDistance = 19;
  RangeValues _ageRange = const RangeValues(18, 24);
  bool _isLoading = false;
  String? _userLocation;
  SettingModel _userPreference = SettingModel();
  String? _cityName;
  String? _province;

  @override
  void initState() {
    super.initState();
    fetchUserPreference();
  }

  Future<void> fetchUserPreference() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userPreference = await _settingController.getLocation();

      setState(() {
        _userPreference = userPreference ?? SettingModel();
        _maxDistance =
            (_userPreference.distance?.toDouble() ?? 19).clamp(1, 100);
        _ageRange = RangeValues(
          (_userPreference.ageStart?.toDouble() ?? 18).clamp(18, 80),
          (_userPreference.ageEnd?.toDouble() ?? 24).clamp(18, 80),
        );

        _showFurtherAway = _userPreference.limit ?? false;
      });

      if (_userPreference.latitude != null &&
          _userPreference.longitude != null) {
        await _decodeLocation(
            _userPreference.latitude!, _userPreference.longitude!);
      } else {
        setState(() {
          _userLocation = "Set location";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user preference: $e');
      setState(() {
        _userPreference = SettingModel();
        _userLocation = "Set location";
        _isLoading = false;
      });
    }
  }

  Future<void> _decodeLocation(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      String? city = placemarks.isNotEmpty
          ? placemarks[0].locality ?? placemarks[0].subAdministrativeArea
          : null;

      setState(() {
        _cityName = city ?? "Unknown city";
        _province = placemarks.isNotEmpty
            ? placemarks[0].subAdministrativeArea ?? "Unknown province"
            : "Unknown province";
        _userLocation = "$_cityName, $_province";
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error decoding location: $e');
      setState(() {
        _userLocation = "Unknown location";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 197, 197, 197),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOCATION',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: Color(0xFFB71A4A),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _userLocation ?? "Set location",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SetUpAddressScreen(),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _showFurtherAway = _userPreference.limit ?? false;
                          });
                          await fetchUserPreference();
                        }
                      },
                      child: Text(
                        'Add a new location',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Text(
                      'Change locations to find matches anywhere.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MAXIMUM DISTANCE',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${_maxDistance.round()}mi.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistance,
                      min: 1,
                      max: 100,
                      onChanged: (value) {
                        setState(() {
                          _maxDistance = value;
                        });
                      },
                      activeColor: const Color(0xFFB71A4A),
                      inactiveColor: Colors.grey[300],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Show people further away if I run out of profiles to see',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Switch(
                          value: _showFurtherAway,
                          onChanged: (value) {
                            setState(() {
                              _showFurtherAway = value;
                            });
                          },
                          activeColor: const Color(0xFFB71A4A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'SPECIALIZATION WITH',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _userPreference.specialization != null &&
                            _userPreference.specialization!.isNotEmpty
                        ? _userPreference.specialization!.join(', ')
                        : 'All',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TaskerSpecializationScreen(),
                      ),
                    ).then((_) => fetchUserPreference());
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AGE RANGE',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 80,
                      onChanged: (RangeValues values) {
                        setState(() {
                          _ageRange = values;
                        });
                      },
                      activeColor: const Color(0xFFB71A4A),
                      inactiveColor: Colors.grey[300],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB71A4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black26,
                  ),
                  child: Text(
                    'Set',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
