import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/service/profile_service.dart';
import 'package:flutter_fe/view/address/address.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressList extends StatefulWidget {
  final Function(AddressModel)? onAddressSelected;

  const AddressList({super.key, this.onAddressSelected});

  @override
  State<AddressList> createState() => _AddressListState();
}

class _AddressListState extends State<AddressList> {
  final storage = GetStorage();

  final _addressController = SettingController();

  List<AddressModel> _addresses = [];
  bool _isLoading = true;
  String? _userName;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userId = await ProfileService.getUserId();
      if (userId != null) {
        setState(() {
          _userName = 'Ronnie Estillero';
          _userPhone = '(+63) 950 646 0086';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addressResponse = await _addressController.loadAddresses();

    debugPrint('my addresses is this : $addressResponse');

    try {
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _addresses = addressResponse;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load addresses: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addNewAddress() async {
    try {
      final result = await Navigator.push<AddressModel>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Address(onAddressSelected: widget.onAddressSelected, mode: 'create'),
        ),
      );

      await _loadAddresses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add address: $e')),
      );
    }
  }

  void _selectAddress(AddressModel address) {
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(address);
    }
    Navigator.pop(context, address);
  }

  void _setAsDefault(int index) async{
    //TODO: Create logic for setting an address as default.
    await _addressController.setDefaultAddress(_addresses[index].id);
    //TODO: Implement broadcasting feature of auto-update.
    setState(() {
      _addresses[index].defaultAddress = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Default address updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editAddress(int index) async {
    final result = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Address(onAddressSelected: widget.onAddressSelected, mode: "edit"),
      ),
    );

    if (result != null) {
      setState(() {
        _addresses[index] = result;
      });
    }
  }

  void _deleteAddress(int index) async {
    // Check if it's the default address
    bool wasDefault = _addresses[index].defaultAddress ?? false;
    //TODO: Implement backend API for address deletion.
    await _addressController.deleteAddress(_addresses[index].id);

    setState(() {
      _addresses.removeAt(index);

      // If we deleted the default address and there are other addresses, make the first one default
      if (wasDefault && _addresses.isNotEmpty) {
        _addresses[0] = AddressModel(
          id: _addresses[0].id,
          streetAddress: _addresses[0].streetAddress,
          barangay: _addresses[0].barangay,
          city: _addresses[0].city,
          province: _addresses[0].province,
          postalCode: _addresses[0].postalCode,
          country: _addresses[0].country,
          latitude: _addresses[0].latitude,
          longitude: _addresses[0].longitude,
          defaultAddress: true,
          formattedAddress: _addresses[0].formattedAddress,
          regionName: _addresses[0].regionName,
        );
      }
    });

    // In a real app, you would delete this from your backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'My Addresses',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No addresses found',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addNewAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71A4A),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text('Add New Address'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address = _addresses[index];
                      // Build a readable address string, skipping empty or null fields
                      final addressParts = [
                        if (address.streetAddress.isNotEmpty)
                          address.streetAddress,
                        if (address.barangay?.isNotEmpty ?? false)
                          address.barangay,
                        if (address.city.isNotEmpty) address.city,
                        if (address.province.isNotEmpty) address.province,
                        if (address.postalCode.isNotEmpty) address.postalCode,
                        if (address.country.isNotEmpty) address.country,
                      ];
                      final displayAddress = addressParts.isNotEmpty
                          ? addressParts.join(', ')
                          : address.formattedAddress?.isNotEmpty ?? false
                              ? address.formattedAddress!
                              : 'Address details incomplete';

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _selectAddress(address),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (address.defaultAddress == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFB71A4A),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Default',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    if (address.defaultAddress == false)
                                      Row(
                                        children: [
                                          if (address.defaultAddress != true)
                                            TextButton(
                                              onPressed: () =>
                                                  _setAsDefault(index),
                                              child: Text(
                                                'Set as Default',
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFFB71A4A),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                )
                                              ),
                                            ),
                                        ],
                                      ),
                                    SizedBox(
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(FontAwesomeIcons.pencil),
                                            onPressed: () =>
                                                _editAddress(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(FontAwesomeIcons.trash,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deleteAddress(index),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  displayAddress,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.grey[800]),
                                ),
                                if (address.latitude != null &&
                                    address.longitude != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Lat: ${address.latitude}, Lng: ${address.longitude}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAddress,
        backgroundColor: Color(0xFFB71A4A),
        tooltip: 'Add a new address',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
