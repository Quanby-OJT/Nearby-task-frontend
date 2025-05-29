import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/service/philippines_location_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

class Address extends StatefulWidget {
  final Function(AddressModel)? onAddressSelected;
  final String mode;

  const Address({super.key, this.onAddressSelected, required this.mode});

  @override
  State<Address> createState() => _AddressState();
}

class _AddressState extends State<Address> {
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

  // Form controller for street address
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Storage
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final regions = await _locationService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
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
      });
    } catch (e) {
      setState(() => _isLoadingBarangays = false);
      _showError('Failed to load barangays: ${e.toString()}');
    }
  }

  Future<void> _initializeMap() async {
    if (_selectedBarangay == null) return;

    setState(() => _isLoadingMap = true);
    try {
      double latitude = 14.5995;
      double longitude = 120.9842;

      try {
        final address = '${_selectedBarangay!['name']}, '
            '${_selectedCity!['name']}, '
            '${_selectedProvince!['name']}, '
            '${_locationService.getRegionDisplayName(_selectedRegion!)}, Philippines';

        print('Geocoding address: $address');

        // Get coordinates for the address
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

      setState(() {
        _markerPosition = LatLng(latitude, longitude);
        _isLoadingMap = false;
        _mapInitialized = true;
      });
    } catch (e) {
      print('Error initializing map: ${e.toString()}');
      setState(() => _isLoadingMap = false);
      _showError('Failed to load map: ${e.toString()}');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingMap = true);
    try {
      // Check location permissions
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _markerPosition = LatLng(position.latitude, position.longitude);
        _isLoadingMap = false;
        _mapInitialized = true;
      });

      // Update map camera position
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

  Future<void> _saveLocation() async {
    if (_markerPosition == null) return;

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

      debugPrint('Mode of Data: ${widget.mode}');

      setState(() {
        _finalLocationData = {
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
        };
        _isLoadingMap = false;
      });



      if(widget.mode == 'create'){
        await _settingController.setAddress(
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
        );
      }else if(widget.mode == 'edit'){
        await _settingController.updateAddress(
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
        );
      }


      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoadingMap = false);
      _showError('Failed to save location: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
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
                : const Text('Select Location'),
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
          'Address',
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
                  Text(
                    'Select Your Address',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB71A4A),
                    ),
                  ),
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
                              _initializeMap();
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
                            labelText: 'Street Address',
                            hintText: 'Enter your street address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          onChanged: (value) => setState(() {
                            _streetAddressController.text;
                          }),
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
                                const Text(
                                  'Pin Your Exact Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
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
                                          onPressed: _initializeMap,
                                          child: const Text('Load Map'),
                                        ),
                                      )
                                    : GoogleMap(
                                        initialCameraPosition: CameraPosition(
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
                  // Street Address and Postal Code fields

                  if (_finalLocationData != null)
                    Card(
                      margin: const EdgeInsets.only(top: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Final Location:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // const SizedBox(height: 8),
                            // Text(
                            //     'Address: ${_finalLocationData!['formattedAddress']}'),
                            Text(
                                'Coordinates: ${_finalLocationData!['latitude'].toStringAsFixed(6)}, ${_finalLocationData!['longitude'].toStringAsFixed(6)}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _markerPosition == null ? null : _saveLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71A4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Save Location',
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

                  if (_finalLocationData != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Create AddressModel from the final location data
                                final addressModel = AddressModel.fromMapData(
                                    _finalLocationData!);

                                // Call the callback if provided
                                if (widget.onAddressSelected != null) {
                                  widget.onAddressSelected!(addressModel);
                                }

                                // Return to previous screen
                                Navigator.pop(context, addressModel);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Use This Address',
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
                    ),
                ],
              ),
            ),
    );
  }
}
