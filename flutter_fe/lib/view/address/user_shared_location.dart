import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get_storage/get_storage.dart';

class UserSharedLocation extends StatefulWidget {
  final int taskTakenId;
  final UserModel user;

  const UserSharedLocation({
    super.key,
    required this.taskTakenId,
    required this.user,
  });

  @override
  State<UserSharedLocation> createState() => _UserSharedLocationState();
}

class _UserSharedLocationState extends State<UserSharedLocation> {
  static const LatLng _userLocation = LatLng(14.5995, 120.9842);
  final ProfileController _profileController = ProfileController();
  final GetStorage _storage = GetStorage();
  GoogleMapController? _mapController;
  bool _isLocationShared = false;
  bool _isLoading = false;
  AuthenticatedUser? tasker;

  final String _userName = "John Doe";

  @override
  void initState() {
    super.initState();
    Future.wait([_fetchUserDetails()]);
  }

  Future<void> _fetchUserDetails() async {
    try {
      int userId = _storage.read("user_id") ?? 0;
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);

      setState(() {
        tasker = user;
      });
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  void _showLocationShareDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          title: Text(
            'Request Location',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Are you sure you want to request ${widget.user.firstName} location?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB71A4A),
                      )),
                  onPressed: () {
                    setState(() {
                      _isLocationShared = false;
                    });
                    Navigator.of(context).pop(false);
                  },
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: const Color(0xFFB71A4A),
                  ),
                  child: TextButton(
                    child: Text('Request',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                      setState(() => _isLoading = true);
                      await Future.delayed(const Duration(seconds: 2));
                      setState(() {
                        _isLocationShared = true;
                        _isLoading = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _handleToggle(bool value) async {
    if (value) {
      _showLocationShareDialog();
    } else {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isLocationShared = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          tasker?.user.role == 'Tasker' ? 'Client Location' : 'Tasker Location',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _isLocationShared
                          ? Card(
                              elevation: 2,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GoogleMap(
                                  initialCameraPosition: const CameraPosition(
                                    target: _userLocation,
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('user_location'),
                                      position: _userLocation,
                                      infoWindow: InfoWindow(
                                        title: _userName,
                                        snippet: 'Current shared location',
                                      ),
                                    ),
                                  },
                                  onMapCreated:
                                      (GoogleMapController controller) {
                                    _mapController = controller;
                                  },
                                  zoomControlsEnabled: true,
                                  myLocationButtonEnabled: false,
                                  mapToolbarEnabled: true,
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(
                                      height:
                                          8), // Added spacing between icon and text
                                  Text(
                                    tasker?.user.role == 'Tasker'
                                        ? 'Client is not sharing their location'
                                        : 'Tasker is not sharing their location',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.3,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Location Sharing',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Share ${widget.user.firstName} ${widget.user.lastName}\'s Location',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: Colors.black87,
                              ),
                            ),
                            Switch(
                              value: _isLocationShared,
                              onChanged: _handleToggle,
                              activeColor: const Color(0xFFB71A4A),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
