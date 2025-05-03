import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';

class SetUpAddressScreen extends StatefulWidget {
  const SetUpAddressScreen({super.key});

  @override
  State<SetUpAddressScreen> createState() => _SetUpAddressScreenState();
}

class _SetUpAddressScreenState extends State<SetUpAddressScreen>
    with SingleTickerProviderStateMixin {
  final SettingController _settingController = SettingController();
  bool _isDescriptionVisible = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  String _locationMessage = "Tap to get location";
  double? _latitude;
  double? _longitude;
  String? _cityName;
  String? _province;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _locationMessage = "Getting location...";
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Permission status: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('Requested permission: $permission');
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          setState(() {
            _isLoading = false;
            _locationMessage = "Location permission denied";
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        setState(() {
          _isLoading = false;
          _locationMessage =
              "Location permission permanently denied, please enable in settings";
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _locationMessage = "Getting location...";
      });
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      debugPrint('Location: ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? city = placemarks.isNotEmpty
          ? placemarks[0].locality ?? placemarks[0].subAdministrativeArea
          : null;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _cityName = city ?? "Unknown city";
        _province = placemarks.isNotEmpty
            ? placemarks[0].subAdministrativeArea ?? "Unknown province"
            : "Unknown province";
        _locationMessage = city != null
            ? "Location: $city, $_province"
            : "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";

        _isLoading = false;
      });

      if (_latitude != null && _longitude != null) {
        await _saveLocation();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoading = false;
        _locationMessage = "Error getting location: $e";
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_latitude == null || _longitude == null) {
      debugPrint('Cannot save location: latitude or longitude is null');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('Saving location: $_latitude, $_longitude');
    try {
      await _settingController.setLocation(_latitude!, _longitude!);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving location: $e');
      setState(() {
        _isLoading = false;
        _locationMessage = "Error saving location: $e";
      });
    }
  }

  void _toggleDescription() {
    setState(() {
      _isDescriptionVisible = !_isDescriptionVisible;
      if (_isDescriptionVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.pink,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isDescriptionVisible)
                      Container(
                        padding: const EdgeInsets.only(top: 30, bottom: 16),
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'So, are you from around here?',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFB71A4A),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'Set your location to see who\'s in your neighborhood or beyond. You won\'t be able to match with people otherwise.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _getLocation,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFE0E0E0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.pink)
                                        : const Icon(
                                            Icons.location_on,
                                            size: 60,
                                            color: Colors.pink,
                                          ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Text(
                                        _locationMessage,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: ElevatedButton(
                                    onPressed: _getLocation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFB71A4A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Allow',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: ElevatedButton(
                                    onPressed: _toggleDescription,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'How Is My Location Used?',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF03045E),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          _isDescriptionVisible
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: const Color(0xFF03045E),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_isDescriptionVisible)
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: const EdgeInsets.only(top: 30, bottom: 16),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: ElevatedButton(
                                  onPressed: _getLocation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB71A4A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Allow',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: ElevatedButton(
                                  onPressed: _toggleDescription,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'How Is My Location Used?',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF03045E),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        _isDescriptionVisible
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: const Color(0xFF03045E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Don\'t worry—',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        color: const Color(0xFFB71A4A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Your location helps us show potential matches nearby or slightly further away. Your exact location is never shared.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
