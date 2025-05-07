import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/philippines_location_service.dart';

class GeneralInfoPage extends StatefulWidget {
  final Function(Map<String, dynamic> userInfo) onInfoCompleted;

  const GeneralInfoPage({super.key, required this.onInfoCompleted});

  @override
  State<GeneralInfoPage> createState() => _GeneralInfoPageState();
}

class _GeneralInfoPageState extends State<GeneralInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final GetStorage storage = GetStorage();
  final PhilippineLocationService _locationService =
      PhilippineLocationService();

  // Text controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  // Form data
  String? _gender;
  DateTime? _birthdate;
  bool _isLoading = false;

  // Address data
  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedCity;
  Map<String, dynamic>? _selectedBarangay;

  // Location data lists
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _barangays = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRegions();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _postalCodeController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoading = true);
    try {
      final regions = await _locationService.getRegions();
      setState(() {
        _regions = regions;
      });
    } catch (e) {
      debugPrint('Error loading regions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProvinces(String regionCode) async {
    setState(() => _isLoading = true);
    try {
      final provinces = await _locationService.getProvincesByRegion(regionCode);
      setState(() {
        _provinces = provinces;
        _cities = [];
        _barangays = [];
      });
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCities(String provinceCode) async {
    setState(() => _isLoading = true);
    try {
      final cities = await _locationService.getCitiesByProvince(provinceCode);
      setState(() {
        _cities = cities;
        _barangays = [];
      });
    } catch (e) {
      debugPrint('Error loading cities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBarangays(String cityCode) async {
    setState(() => _isLoading = true);
    try {
      final barangays = await _locationService.getBarangaysByCity(cityCode);
      setState(() {
        _barangays = barangays;
      });
    } catch (e) {
      debugPrint('Error loading barangays: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Load data from storage if available
      final String? firstName = storage.read('first_name');
      final String? lastName = storage.read('last_name');
      final String? email = storage.read('email');
      final String? phone = storage.read('phone');

      // Add handling for region data that might be stored
      final dynamic regionData = storage.read('region');
      if (regionData != null) {
        // Handle case where regionData might be a string instead of a map
        if (regionData is String) {
          // Find the region from the loaded regions list once they're available
          _loadRegions().then((_) {
            if (_regions.isNotEmpty) {
              final matchingRegion = _regions.firstWhere(
                (region) =>
                    region['code'] == regionData ||
                    region['name'] == regionData,
                orElse: () => <String, dynamic>{},
              );

              if (matchingRegion.isNotEmpty) {
                setState(() {
                  _selectedRegion = matchingRegion;
                  if (matchingRegion['code'] != null) {
                    _loadProvinces(matchingRegion['code']);
                  }
                });
              }
            }
          });
        } else if (regionData is Map<String, dynamic>) {
          // It's already a map, use it directly
          _selectedRegion = regionData;
          if (regionData['code'] != null) {
            _loadProvinces(regionData['code']);
          }
        }
      }

      if (firstName != null) _firstNameController.text = firstName;
      if (lastName != null) _lastNameController.text = lastName;
      if (email != null) _emailController.text = email;
      if (phone != null) _phoneController.text = phone;
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthdate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 13)), // Minimum age 13 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0272B1),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _birthdate = picked;
        _birthdateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _submitInfo() {
    if (_formKey.currentState!.validate()) {
      // Create userInfo map with all the collected data
      Map<String, dynamic> userInfo = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'middleName': _middleNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': {
          'region': _selectedRegion is Map<String, dynamic>
              ? _selectedRegion!['name']
              : null,
          'regionCode': _selectedRegion is Map<String, dynamic>
              ? _selectedRegion!['code']
              : null,
          'province': _selectedProvince is Map<String, dynamic>
              ? _selectedProvince!['name']
              : null,
          'provinceCode': _selectedProvince is Map<String, dynamic>
              ? _selectedProvince!['code']
              : null,
          'city': _selectedCity is Map<String, dynamic>
              ? _selectedCity!['name']
              : null,
          'cityCode': _selectedCity is Map<String, dynamic>
              ? _selectedCity!['code']
              : null,
          'barangay': _selectedBarangay is Map<String, dynamic>
              ? _selectedBarangay!['name']
              : null,
          'barangayCode': _selectedBarangay is Map<String, dynamic>
              ? _selectedBarangay!['code']
              : null,
          'streetAddress': _streetAddressController.text,
          'postalCode': _postalCodeController.text,
        },
        'fullAddress': _buildFullAddress(),
        'gender': _gender,
        'birthdate': _birthdate != null
            ? DateFormat('yyyy-MM-dd').format(_birthdate!)
            : null,
      };

      // Call the callback function with the map
      widget.onInfoCompleted(userInfo);
    }
  }

  // Build a formatted full address string
  String _buildFullAddress() {
    List<String> addressParts = [];

    if (_streetAddressController.text.isNotEmpty) {
      addressParts.add(_streetAddressController.text);
    }

    if (_selectedBarangay != null &&
        _selectedBarangay is Map<String, dynamic>) {
      addressParts.add('Barangay ${_selectedBarangay!['name']}');
    }

    if (_selectedCity != null && _selectedCity is Map<String, dynamic>) {
      addressParts.add(_selectedCity!['name']);
    }

    if (_selectedProvince != null &&
        _selectedProvince is Map<String, dynamic>) {
      addressParts.add(_selectedProvince!['name']);
    }

    if (_selectedRegion != null && _selectedRegion is Map<String, dynamic>) {
      addressParts.add(_selectedRegion!['name']);
    }

    if (_postalCodeController.text.isNotEmpty) {
      addressParts.add(_postalCodeController.text);
    }

    addressParts.add('Philippines');

    return addressParts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0272B1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please provide your basic information for verification',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Note box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[800]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please ensure that all information provided matches your government-issued ID to avoid verification issues.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Section
                    Text(
                      'Personal Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // First Name
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Middle Name (Optional)
                    _buildTextField(
                      controller: _middleNameController,
                      label: 'Middle Name (Optional)',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    Text(
                      'Gender',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildGenderOption('Male', Icons.male),
                        const SizedBox(width: 16),
                        _buildGenderOption('Female', Icons.female),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Birthdate
                    _buildTextField(
                      controller: _birthdateController,
                      label: 'Date of Birth',
                      icon: Icons.cake,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Contact Information Section
                    Text(
                      'Contact Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        final bool emailValid = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value);

                        if (!emailValid) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone number
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Address Section
                    Text(
                      'Address Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Region
                    Text(
                      'Region',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value: _selectedRegion != null &&
                              _selectedRegion is Map<String, dynamic>
                          ? _selectedRegion!['code']
                          : null,
                      items: _regions,
                      hintText: 'Select Region',
                      icon: Icons.location_on,
                      validator: (value) =>
                          value == null ? 'Please select a region' : null,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          final selectedRegion = _regions.firstWhere(
                              (region) => region['code'] == newValue);
                          setState(() {
                            _selectedRegion = selectedRegion;
                            _selectedProvince = null;
                            _selectedCity = null;
                            _selectedBarangay = null;
                            _loadProvinces(newValue);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Province
                    Text(
                      'Province',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value: _selectedProvince != null
                          ? _selectedProvince!['code']
                          : null,
                      items: _provinces,
                      hintText: 'Select Province',
                      icon: Icons.location_city,
                      validator: (value) =>
                          value == null ? 'Please select a province' : null,
                      onChanged: _selectedRegion == null
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                final selectedProvince = _provinces.firstWhere(
                                    (province) => province['code'] == newValue);
                                setState(() {
                                  _selectedProvince = selectedProvince;
                                  _selectedCity = null;
                                  _selectedBarangay = null;
                                  _loadCities(newValue);
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // City/Municipality
                    Text(
                      'City/Municipality',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value:
                          _selectedCity != null ? _selectedCity!['code'] : null,
                      items: _cities,
                      hintText: 'Select City/Municipality',
                      icon: Icons.location_city,
                      validator: (value) => value == null
                          ? 'Please select a city or municipality'
                          : null,
                      onChanged: _selectedProvince == null
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                final selectedCity = _cities.firstWhere(
                                    (city) => city['code'] == newValue);
                                setState(() {
                                  _selectedCity = selectedCity;
                                  _selectedBarangay = null;
                                  _loadBarangays(newValue);
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Barangay
                    Text(
                      'Barangay',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value: _selectedBarangay != null
                          ? _selectedBarangay!['code']
                          : null,
                      items: _barangays,
                      hintText: 'Select Barangay',
                      icon: Icons.holiday_village,
                      validator: (value) =>
                          value == null ? 'Please select a barangay' : null,
                      onChanged: _selectedCity == null
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                final selectedBarangay = _barangays.firstWhere(
                                    (brgy) => brgy['code'] == newValue);
                                setState(() {
                                  _selectedBarangay = selectedBarangay;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Street Address
                    _buildTextField(
                      controller: _streetAddressController,
                      label: 'Street Address (House/Lot/Blk/Unit No.)',
                      icon: Icons.home,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your street address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Postal Code
                    _buildTextField(
                      controller: _postalCodeController,
                      label: 'Postal/ZIP Code',
                      icon: Icons.markunread_mailbox,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your postal code';
                        }
                        if (value.length < 4) {
                          return 'Please enter a valid postal code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0272B1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Continue to ID Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0272B1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0272B1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[600]!, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown({
    required String? value,
    required List<Map<String, dynamic>> items,
    required String hintText,
    required IconData icon,
    required String? Function(String?)? validator,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0272B1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[800],
      ),
      isExpanded: true,
      hint: Text(
        hintText,
        style: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: 14,
        ),
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
      validator: validator,
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
        return DropdownMenuItem<String>(
          value: item['code'],
          child: Text(item['name']),
        );
      }).toList(),
    );
  }

  Widget _buildGenderOption(String gender, IconData genderIcon) {
    final bool isSelected = _gender == gender;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _gender = gender;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0272B1).withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF0272B1) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                genderIcon,
                color: isSelected ? const Color(0xFF0272B1) : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFF0272B1) : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
