import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/service/philippines_location_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EditAddress extends StatefulWidget {
  final AddressModel address;
  const EditAddress({super.key, required this.address});

  @override
  State<EditAddress> createState() => _EditAddressState();
}

class _EditAddressState extends State<EditAddress> {
  final _locationService = PhilippineLocationService();
  final SettingController _settingController = SettingController();

  // Selected values
  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedCity;
  Map<String, dynamic>? _selectedBarangay;

  // Lists for dropdowns
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _barangays = [];

  bool _isLoadingRegions = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isLoadingBarangays = false;
  bool _isLoadingMap = false;

  // Map-related variables
  GoogleMapController? _mapController;
  LatLng? _markerPosition;
  Map<String, dynamic>? _finalLocationData;
  bool _mapInitialized = false;
  String selectedAddress = '';

  // Form controllers
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  // Storage
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();
    // Pre-populate fields from the provided AddressModel
    _streetAddressController.text = widget.address.streetAddress;
    _postalCodeController.text = widget.address.postalCode;
    selectedAddress = widget.address.formattedAddress ?? '';
    _markerPosition = widget.address.getLatLng();
    _mapInitialized = _markerPosition != null;
    _finalLocationData = widget.address.toJson();
    _remarksController.text = widget.address.remarks ?? '';
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final regions = await _locationService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
        if (widget.address.regionName != null) {
          _selectedRegion = _regions.firstWhere(
            (region) =>
                _locationService.getRegionDisplayName(region) ==
                widget.address.regionName,
            orElse: () => _regions.first,
          );
          _loadProvinces(_selectedRegion!['code']);
        }
      });
    } catch (e) {
      setState(() => _isLoadingRegions = false);
      _showError('Failed to load regions: ${e.toString()}');
    }
  }

  Future<void> _loadProvinces(String regionCode) async {
    setState(() {
      _isLoadingProvinces = true;
      _provinces = [];
      _cities = [];
      _barangays = [];
      _selectedProvince = null;
      _selectedCity = null;
      _selectedBarangay = null;
      _markerPosition = null;
      _finalLocationData = null;
      _mapInitialized = false;
    });
    try {
      final provinces = await _locationService.getProvincesByRegion(regionCode);
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
        _selectedProvince = _provinces.firstWhere(
          (province) => province['name'] == widget.address.province,
          orElse: () => _provinces.first,
        );
        _loadCities(_selectedProvince!['code']);
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
      _showError('Failed to load provinces: ${e.toString()}');
    }
  }

  Future<void> _loadCities(String provinceCode) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _barangays = [];
      _selectedCity = null;
      _selectedBarangay = null;
      _markerPosition = null;
      _finalLocationData = null;
      _mapInitialized = false;
    });
    try {
      final cities = await _locationService.getCitiesByProvince(provinceCode);
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
        _selectedCity = _cities.firstWhere(
          (city) => city['name'] == widget.address.city,
          orElse: () => _cities.first,
        );
        _loadBarangays(_selectedCity!['code']);
      });
    } catch (e) {
      setState(() => _isLoadingCities = false);
      _showError('Failed to load cities: ${e.toString()}');
    }
  }

  Future<void> _loadBarangays(String cityCode) async {
    setState(() {
      _isLoadingBarangays = true;
      _barangays = [];
      _selectedBarangay = null;
      _markerPosition = null;
      _finalLocationData = null;
      _mapInitialized = false;
    });
    try {
      final barangays = await _locationService.getBarangaysByCity(cityCode);
      setState(() {
        _barangays = barangays;
        _isLoadingBarangays = false;
        if (widget.address.barangay != null) {
          _selectedBarangay = _barangays.firstWhere(
            (barangay) => barangay['name'] == widget.address.barangay,
            orElse: () => _barangays.first,
          );
          _updateCoordinates();
        }
      });
    } catch (e) {
      setState(() => _isLoadingBarangays = false);
      _showError('Failed to load barangays: ${e.toString()}');
    }
  }

  Future<void> _updateCoordinates() async {
    if (_selectedBarangay == null ||
        _selectedCity == null ||
        _selectedProvince == null ||
        _selectedRegion == null) {
      return;
    }

    setState(() => _isLoadingMap = true);
    try {
      double latitude = 14.5995; // Default to Manila
      double longitude = 120.9842;

      // Use existing coordinates if available and still valid
      if (widget.address.latitude != null &&
          widget.address.longitude != null &&
          _isAddressUnchanged()) {
        latitude = widget.address.latitude!;
        longitude = widget.address.longitude!;
      } else {
        // Geocode the address
        final address = '${_selectedBarangay!['name']}, '
            '${_selectedCity!['name']}, '
            '${_selectedProvince!['name']}, '
            '${_locationService.getRegionDisplayName(_selectedRegion!)}, Philippines';

        print('Geocoding address: $address');
        try {
          final locations = await locationFromAddress(address);
          if (locations.isNotEmpty) {
            final location = locations.first;
            latitude = location.latitude;
            longitude = location.longitude;
            print('Found coordinates: $latitude, $longitude');
          } else {
            print('No coordinates found for address');
          }
        } catch (e) {
          print('Error geocoding address: ${e.toString()}');
        }
      }

      final newPosition = LatLng(latitude, longitude);
      setState(() {
        _markerPosition = newPosition;
        _isLoadingMap = false;
        _mapInitialized = true;
      });

      // Update map camera position
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingMap = false);
      _showError('Failed to update map coordinates: ${e.toString()}');
    }
  }

  bool _isAddressUnchanged() {
    return widget.address.barangay == _selectedBarangay?['name'] &&
        widget.address.city == _selectedCity?['name'] &&
        widget.address.province == _selectedProvince?['name'] &&
        widget.address.regionName ==
            _locationService.getRegionDisplayName(_selectedRegion!);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingMap = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingMap = false);
          _showError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingMap = false);
        _showError('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _markerPosition = LatLng(position.latitude, position.longitude);
        _isLoadingMap = false;
        _mapInitialized = true;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _markerPosition!,
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingMap = false);
      _showError('Failed to get current location: ${e.toString()}');
    }
  }

  void _updateMarkerPosition(LatLng position) {
    setState(() {
      _markerPosition = position;
    });
  }

  Future<void> _updateLocation() async {
    if (_markerPosition == null) {
      _showError('Please select a location on the map');
      return;
    }

    // Validate required fields
    if (_streetAddressController.text.trim().isEmpty) {
      _showError('Street address is required');
      return;
    }

    if (_postalCodeController.text.trim().isEmpty) {
      _showError('Postal code is required');
      return;
    }

    if (_selectedBarangay == null) {
      _showError('Barangay is required');
      return;
    }

    if (_selectedCity == null) {
      _showError('City is required');
      return;
    }

    if (_selectedProvince == null) {
      _showError('Province is required');
      return;
    }

    try {
      setState(() => _isLoadingMap = true);

      selectedAddress =
          '${_streetAddressController.text.isNotEmpty ? '${_streetAddressController.text}, ' : ''}'
          '${_selectedBarangay!['name']}, '
          '${_selectedCity!['name']}, '
          '${_selectedProvince!['name']}, '
          '${_locationService.getRegionDisplayName(_selectedRegion!)}';

      final placemarks = await placemarkFromCoordinates(
        _markerPosition!.latitude,
        _markerPosition!.longitude,
      );

      final placemark = placemarks.first;
      final formattedAddress = [
        placemark.street,
        placemark.subLocality,
        placemark.locality,
        placemark.administrativeArea,
        placemark.country
      ].where((element) => element != null && element.isNotEmpty).join(', ');

      setState(() {
        _finalLocationData = {
          'id': widget.address.id,
          'latitude': _markerPosition!.latitude,
          'longitude': _markerPosition!.longitude,
          'formattedAddress': formattedAddress,
          'region': _locationService.getRegionDisplayName(_selectedRegion!),
          'province': _selectedProvince!['name'],
          'city': _selectedCity!['name'],
          'barangay': _selectedBarangay!['name'],
          'street_address': _streetAddressController.text,
          'postal_code': _postalCodeController.text,
          'country': 'Philippines',
          'default': widget.address.defaultAddress,
          'remarks': _remarksController.text,
          'updated_at': DateTime.now().toIso8601String(),
        };
        _isLoadingMap = false;
      });

      await _settingController.updateAddress(
        widget.address.id,
        _markerPosition!.latitude,
        _markerPosition!.longitude,
        selectedAddress,
        _locationService.getRegionDisplayName(_selectedRegion!),
        _selectedProvince!['name'],
        _selectedCity!['name'],
        _selectedBarangay!['name'],
        _streetAddressController.text,
        _postalCodeController.text,
        'Philippines',
        _remarksController.text,
      );

      final addressModel = AddressModel.fromMapData(_finalLocationData!);
      Navigator.pop(context, addressModel);
    } catch (e) {
      setState(() => _isLoadingMap = false);
      _showError('Failed to save location: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) displayText,
    required Function(T?)? onChanged,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(displayText(item)),
              );
            }).toList(),
            onChanged: isLoading || onChanged == null ? null : onChanged,
            isExpanded: true,
            hint: isLoading
                ? const Text('Loading...')
                : const Text('Select an option'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Edit Address',
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
      body: _isLoadingRegions
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdown<Map<String, dynamic>>(
                    label: 'Region',
                    value: _selectedRegion,
                    items: _regions,
                    displayText: _locationService.getRegionDisplayName,
                    isLoading: _isLoadingRegions,
                    onChanged: (value) {
                      setState(() => _selectedRegion = value);
                      if (value != null) {
                        _loadProvinces(value['code']);
                      }
                    },
                  ),
                  _buildDropdown<Map<String, dynamic>>(
                    label: 'Province',
                    value: _selectedProvince,
                    items: _provinces,
                    displayText: (item) => item['name'],
                    isLoading: _isLoadingProvinces,
                    onChanged: _provinces.isEmpty
                        ? null
                        : (value) {
                            setState(() => _selectedProvince = value);
                            if (value != null) {
                              _loadCities(value['code']);
                            }
                          },
                  ),
                  _buildDropdown<Map<String, dynamic>>(
                    label: 'City/Municipality',
                    value: _selectedCity,
                    items: _cities,
                    displayText: (item) => item['name'],
                    isLoading: _isLoadingCities,
                    onChanged: _cities.isEmpty
                        ? null
                        : (value) {
                            setState(() => _selectedCity = value);
                            if (value != null) {
                              _loadBarangays(value['code']);
                            }
                          },
                  ),
                  _buildDropdown<Map<String, dynamic>>(
                    label: 'Barangay',
                    value: _selectedBarangay,
                    items: _barangays,
                    displayText: (item) => item['name'],
                    isLoading: _isLoadingBarangays,
                    onChanged: _barangays.isEmpty
                        ? null
                        : (value) {
                            setState(() => _selectedBarangay = value);
                            if (value != null) {
                              _updateCoordinates();
                            }
                          },
                  ),
                  if (_selectedBarangay != null)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _streetAddressController,
                          decoration: InputDecoration(
                            labelText: 'Street Address *',
                            hintText: 'Enter your street address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _postalCodeController,
                          decoration: InputDecoration(
                            labelText: 'Postal Code *',
                            hintText: 'Enter postal code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _remarksController,
                          decoration: InputDecoration(
                            labelText: 'Remarks',
                            hintText: 'Enter remarks',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (_selectedRegion != null &&
                      _selectedProvince != null &&
                      _selectedCity != null &&
                      _selectedBarangay != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Address:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_streetAddressController.text.isNotEmpty ? '${_streetAddressController.text}, ' : ''}'
                              '${_selectedBarangay!['name']}, '
                              '${_selectedCity!['name']}, '
                              '${_selectedProvince!['name']}, '
                              '${_locationService.getRegionDisplayName(_selectedRegion!)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_selectedBarangay != null)
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Center(
                                  child: Text(
                                    'Pin Your Exact Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 300,
                            child: _isLoadingMap
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _markerPosition == null
                                    ? Center(
                                        child: ElevatedButton(
                                          onPressed: _updateCoordinates,
                                          child: const Text('Load Map'),
                                        ),
                                      )
                                    : (!kIsWeb && Platform.isWindows)
                                        ? const Center(
                                            child: Text(
                                              'Maps are not supported on Windows desktop.\nPlease use coordinates to specify location.',
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : GoogleMap(
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: _markerPosition!,
                                              zoom: 15,
                                            ),
                                            markers: {
                                              Marker(
                                                markerId:
                                                    const MarkerId('location'),
                                                position: _markerPosition!,
                                                draggable: true,
                                                onDragEnd: (newPosition) {
                                                  _updateMarkerPosition(
                                                      newPosition);
                                                },
                                              ),
                                            },
                                            onMapCreated: (controller) {
                                              _mapController = controller;
                                            },
                                            myLocationEnabled: true,
                                            myLocationButtonEnabled: true,
                                            zoomControlsEnabled: true,
                                            mapToolbarEnabled: true,
                                            onTap: (position) {
                                              _updateMarkerPosition(position);
                                            },
                                          ),
                          ),
                          if (_markerPosition != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Coordinates: ${_markerPosition!.latitude.toStringAsFixed(6)}, ${_markerPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _markerPosition == null ? null : _updateLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71A4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
