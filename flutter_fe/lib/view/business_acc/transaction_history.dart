import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/view/components/modals/modal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

// Placeholder imports (replace with actual imports)
import 'package:flutter_fe/view/profile/payment_processing.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/model/transactions.dart';
import 'package:flutter_fe/view/task/task_details_screen.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../verification/verification_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with TickerProviderStateMixin {
  final _escrowManagementController = EscrowManagementController();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  late AnimationController loadingController;
  List<Transactions> _transactionHistory = [];
  List<Transactions> _filteredTransactions = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  int _displayLimit = 5;
  AuthenticatedUser? user;
  final storage = GetStorage();
  bool _isUploadDialogShown = false;
  late SharedPreferences _prefs;
  final Connectivity _connectivity = Connectivity();

  // Profile image caching
  final Map<int, String> _taskerProfileImages = {};
  final Map<int, String> _clientProfileImages = {};

  @override
  void initState() {
    super.initState();
    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _searchController.addListener(_filterTransactions);
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _connectivity.checkConnectivity();

    if (result.contains(ConnectivityResult.mobile) == true ||
        result.contains(ConnectivityResult.wifi) == true) {
      setState(() {
        _isLoading = false;
        _isOfflineMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Internet connection is available",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
      _loadData();
    } else {
      setState(() {
        _isOfflineMode = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              "Using offline mode",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: Color(0xFFB71A4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
      _loadCachedData();
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedTransactions = _prefs.getString('cached_transactions');
      final cachedBalance = _prefs.getString('cached_balance');

      if (cachedTransactions != null) {
        final List<dynamic> decodedTransactions =
            json.decode(cachedTransactions);
        setState(() {
          _transactionHistory = decodedTransactions
              .map((json) => Transactions.fromJson(json))
              .toList();
          _filteredTransactions = _transactionHistory;
        });
        debugPrint(
            "Loaded ${_transactionHistory.length} transactions from cache");
      }

      if (cachedBalance != null) {
        _escrowManagementController.tokenCredits.value =
            double.parse(cachedBalance).toInt();
      }

      // Load cached profile images
      final cachedTaskerImages =
          _prefs.getString('cached_tasker_profile_images');
      if (cachedTaskerImages != null) {
        final Map<String, dynamic> taskerImageData =
            json.decode(cachedTaskerImages);
        setState(() {
          _taskerProfileImages.clear();
          taskerImageData.forEach((key, value) {
            _taskerProfileImages[int.parse(key)] = value.toString();
          });
          debugPrint(
              "Loaded ${_taskerProfileImages.length} tasker profile images from cache");
        });
      }

      final cachedClientImages =
          _prefs.getString('cached_client_profile_images');
      if (cachedClientImages != null) {
        final Map<String, dynamic> clientImageData =
            json.decode(cachedClientImages);
        setState(() {
          _clientProfileImages.clear();
          clientImageData.forEach((key, value) {
            _clientProfileImages[int.parse(key)] = value.toString();
          });
          debugPrint(
              "Loaded ${_clientProfileImages.length} client profile images from cache");
        });
      }
    } catch (e) {
      debugPrint("Error loading cached data: $e");
    }
  }

  Future<void> _saveDataToCache() async {
    try {
      if (_transactionHistory.isNotEmpty) {
        final transactionsJson = _transactionHistory
            .map((transaction) => transaction.toJson())
            .toList();
        await _prefs.setString(
            'cached_transactions', json.encode(transactionsJson));
        debugPrint("Saved ${_transactionHistory.length} transactions to cache");
      }

      await _prefs.setString(
        'cached_balance',
        _escrowManagementController.tokenCredits.value.toString(),
      );
      debugPrint("Saved balance to cache");

      // Save profile images to cache
      if (_taskerProfileImages.isNotEmpty) {
        await _prefs.setString(
            'cached_tasker_profile_images', json.encode(_taskerProfileImages));
        debugPrint(
            "Saved ${_taskerProfileImages.length} tasker profile images to cache");
      }

      if (_clientProfileImages.isNotEmpty) {
        await _prefs.setString(
            'cached_client_profile_images', json.encode(_clientProfileImages));
        debugPrint(
            "Saved ${_clientProfileImages.length} client profile images to cache");
      }
    } catch (e) {
      debugPrint("Error saving data to cache: $e");
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    loadingController.repeat(reverse: true);

    try {
      await Future.wait([
        _escrowManagementController.fetchTokenBalance(),
        getTransactionHistory(),
        _fetchUserData(),
      ]);
      await _fetchAllProfileImages();
      await _saveDataToCache();
    } finally {
      if (mounted) {
        loadingController.stop();
        loadingController.value = 0;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> getTransactionHistory() async {
    final transactionData = await taskController.getAllTransactions();
    setState(() {
      _transactionHistory = transactionData;
      _filteredTransactions = transactionData;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final dynamic userId = storage.read("user_id");

      if (userId == null) return;

      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);

      debugPrint("Current User Status: ${user?.user.accStatus}");

      setState(() {
        this.user = user;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching user data: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Fetch profile images for all taskers and clients in transactions
  Future<void> _fetchAllProfileImages() async {
    try {
      debugPrint("Starting to fetch profile images for transactions");
      final Set<int> taskerIds = {};
      final Set<int> clientIds = {};

      // Collect unique tasker and client IDs from transactions
      for (final transaction in _transactionHistory) {
        // Collect tasker IDs
        if (transaction.taskAssignment.tasker?.user?.id != null) {
          taskerIds.add(transaction.taskAssignment.tasker!.user!.id!);
        }

        // Collect client IDs
        if (transaction.taskAssignment.client?.user?.id != null) {
          clientIds.add(transaction.taskAssignment.client!.user!.id!);
        }
      }

      debugPrint(
          "Found ${taskerIds.length} unique taskers and ${clientIds.length} unique clients");

      // Fetch tasker profile images
      for (final taskerId in taskerIds) {
        if (_taskerProfileImages.containsKey(taskerId)) continue;

        try {
          final taskerService = TaskerService();
          final result = await taskerService.getTaskerImages(taskerId);

          if (result.containsKey('images') && result['images'] is List) {
            final List<dynamic> images = result['images'];
            if (images.isNotEmpty) {
              final firstImage = images.first;
              if (firstImage is Map && firstImage['image_link'] != null) {
                if (mounted) {
                  setState(() {
                    _taskerProfileImages[taskerId] = firstImage['image_link'];
                  });
                }
                debugPrint("✅ Cached tasker profile image for ID $taskerId");
              }
            }
          }
        } catch (e) {
          debugPrint(
              "❌ Error fetching tasker profile image for ID $taskerId: $e");
        }
      }

      // Fetch client profile images
      for (final clientId in clientIds) {
        if (_clientProfileImages.containsKey(clientId)) continue;

        try {
          final clientService = ClientServices();
          final result = await clientService.getClientImages(clientId);

          if (result.containsKey('images') && result['images'] is List) {
            final List<dynamic> images = result['images'];
            if (images.isNotEmpty) {
              final firstImage = images.first;
              if (firstImage is Map && firstImage['image_link'] != null) {
                if (mounted) {
                  setState(() {
                    _clientProfileImages[clientId] = firstImage['image_link'];
                  });
                }
                debugPrint("✅ Cached client profile image for ID $clientId");
              }
            }
          }
        } catch (e) {
          debugPrint(
              "❌ Error fetching client profile image for ID $clientId: $e");
        }
      }

      debugPrint(
          "Profile image caching complete. Taskers: ${_taskerProfileImages.length}, Clients: ${_clientProfileImages.length}");
    } catch (e) {
      debugPrint("Error in _fetchAllProfileImages: $e");
    }
  }

  // Get tasker profile image decoration with priority logic
  DecorationImage? _getTaskerProfileImageDecoration(Transactions transaction) {
    final taskerId = transaction.taskAssignment.tasker?.user?.id;

    // Priority 1: Profile image from tasker_images table
    if (taskerId != null && _taskerProfileImages.containsKey(taskerId)) {
      final profileImageUrl = _taskerProfileImages[taskerId];
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        return DecorationImage(
          image: NetworkImage(profileImageUrl),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            debugPrint('Error loading tasker profile image: $exception');
            if (mounted) {
              setState(() {
                _taskerProfileImages.remove(taskerId); // Clear the failed URL
              });
            }
          },
        );
      }
    }

    // Priority 2: Default user image from user.image field
    final userImage = transaction.taskAssignment.tasker?.user?.image ??
        transaction.taskAssignment.tasker?.user?.imageName;
    if (userImage != null && userImage.isNotEmpty && userImage != "Unknown") {
      return DecorationImage(
        image: NetworkImage(userImage),
        fit: BoxFit.cover,
        onError: (exception, stackTrace) {
          debugPrint('Error loading default tasker image: $exception');
        },
      );
    }

    return null;
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTransactions = _transactionHistory.where((transaction) {
        final title =
            transaction.taskAssignment.task?.title.toLowerCase() ?? '';
        final taskerName =
            '${transaction.taskAssignment.tasker?.user?.firstName ?? ''} ${transaction.taskAssignment.tasker?.user?.lastName ?? ''}'
                .toLowerCase();
        final clientName =
            '${transaction.taskAssignment.client?.user?.firstName ?? ''} ${transaction.taskAssignment.client?.user?.middleName ?? ''} ${transaction.taskAssignment.client?.user?.lastName ?? ''}'
                .toLowerCase();
        final matchesQuery = title.contains(query) ||
            taskerName.contains(query) ||
            clientName.contains(query);
        final matchesStatus = _selectedStatus == null ||
            transaction.recordStatus == _selectedStatus;
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _loadMore() {
    setState(() {
      _displayLimit += 5;
    });
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return format.format(amount);
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFE7A335);
      case 'Confirmed':
        return const Color(0xFF7BC0F5);
      case 'Rejected':
        return const Color(0xFFD43D4D);
      case 'Cancelled':
        return const Color(0xFFD43D4D);
      case 'Ongoing':
        return const Color(0xFF3E9FE5);
      case 'Review':
        return const Color(0xFFD6932A);
      case 'Disputed':
        return const Color(0xFFD43D4D);
      case 'Completed':
        return const Color(0xFF4DBF66);
      case 'Reworking':
        return const Color(0xFF3E9FE5);
      case 'Expired':
        return const Color(0xFFD43D4D);
      case 'Declined':
        return const Color(0xFFD43D4D);
      default:
        return const Color(0xFF4A4A68);
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: const Color(0xFFB71A4A),
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          prefixIcon: const Icon(
            FontAwesomeIcons.magnifyingGlass,
            color: Color(0xFFB71A4A),
            size: 18,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFFB71A4A),
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterTransactions();
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => _filterTransactions(),
      ),
    );
  }

  Widget _buildTransactionCard(Transactions transaction) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskAssignment: transaction.taskAssignment,
              taskStatus: transaction.recordStatus,
              transactionDate: DateTime.parse(transaction.date),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTransactionReceived(transaction),
                  _buildTransactionStatusColor(transaction),
                ],
              ),
              const SizedBox(height: 8),
              _buildTransactionInfo(transaction),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionStatusColor(Transactions transaction) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: statusColor(transaction.recordStatus),
      ),
      child: Text(
        transaction.recordStatus,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTransactionReceived(Transactions transaction) {
    final updatedDateTime = DateTime.parse(transaction.date);
    final formattedDate = DateFormat('MMM d, yyyy').format(updatedDateTime);
    final difference = DateTime.now().toUtc().difference(updatedDateTime);
    final timeAgo = difference.inMinutes < 60
        ? '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago'
        : difference.inHours < 24
            ? '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago'
            : formattedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formattedDate, style: GoogleFonts.poppins(fontSize: 14)),
        Text(
          timeAgo,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTransactionInfo(Transactions transaction, {double size = 40.0}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              image: _getTaskerProfileImageDecoration(transaction),
            ),
            child: _getTaskerProfileImageDecoration(transaction) == null
                ? const Icon(Icons.person, color: Colors.grey, size: 24)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (transaction.taskAssignment.task?.title.length ?? 0) > 20
                    ? '${transaction.taskAssignment.task?.title.substring(0, 20)}...'
                    : transaction.taskAssignment.task?.title ?? 'Untitled Task',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                semanticsLabel:
                    transaction.taskAssignment.task?.title ?? 'Untitled Task',
              ),
              Text(
                "${transaction.taskAssignment.tasker?.user?.firstName ?? 'Unknown'} ${transaction.taskAssignment.tasker?.user?.lastName ?? 'Unknown'}",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB71A4A),
                  fontSize: 10,
                ),
              ),
              Text(
                'Client: ${transaction.taskAssignment.client?.user?.firstName ?? ''} ${transaction.taskAssignment.client?.user?.middleName ?? ''} ${transaction.taskAssignment.client?.user?.lastName ?? ''}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      null, // For "All" option
      'Pending',
      'Confirmed',
      'Rejected',
      'Cancelled',
      'Ongoing',
      'Review',
      'Disputed',
      'Completed',
      'Reworking',
      'Expired',
      'Declined'
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Wallet',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB71A4A),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _checkInternetConnection,
        color: Color(0xFFB71A4A),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isOfflineMode)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  color: Color(0xFFB71A4A),
                  child: Center(
                    child: Text(
                      "Offline Mode",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              // Financial Summary Card
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: const Color(0xFFB71A4A),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Your Total Earnings',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isLoading
                            ? LinearProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFE23670),
                                ),
                                backgroundColor: const Color(0xFFF5A1BB),
                              )
                            : Text(
                                formatCurrency(
                                  _escrowManagementController.tokenCredits.value
                                      .toDouble(),
                                ),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Income Card changed to Deposit Card
                    Expanded(
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (user?.user.accStatus == "Pending") {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => Modal(
                                  modalTitle: "Account Verification",
                                  description:
                                      "You Haven't fully verified your Account yet. Please Verify first in order to deposit.",
                                  buttonText: "Verify Now",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const VerificationPage()),
                                    ).then((value) async {
                                      await _loadData();
                                    });
                                    if (result == true) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      await _loadData();
                                    } else {
                                      setState(() {
                                        _isUploadDialogShown = false;
                                      });
                                    }
                                  },
                                ),
                              );
                            } else if (user?.user.accStatus == null) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => Modal(
                                  modalTitle: "No Internet Connection",
                                  description:
                                      "Please Check Your Connection and Try Again.",
                                  buttonText: "Okay",
                                  onPressed: () {
                                    _loadData();
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            } else {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) {
                                  return PaymentProcessingPage(
                                    transferMethod: "deposit",
                                  );
                                },
                              ));
                            }
                            // Show deposit dialog
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.green[50],
                                      child: Icon(
                                        Icons.arrow_downward,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Deposit',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to deposit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Withdraw Button
                    Expanded(
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (user?.user.accStatus == "Pending") {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => Modal(
                                  modalTitle: "Account Verification",
                                  description:
                                      "You Haven't fully verified your Account yet. Please Verify first in order to deposit.",
                                  buttonText: "Verify Now",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const VerificationPage()),
                                    ).then((value) async {
                                      await _loadData();
                                    });
                                    if (result == true) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      await _loadData();
                                    } else {
                                      setState(() {
                                        _isUploadDialogShown = false;
                                      });
                                    }
                                  },
                                ),
                              );
                              return;
                            } else if (user?.user.accStatus == null) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => Modal(
                                  modalTitle: "No Internet Connection",
                                  description:
                                      "Please Check Your Connection and Try Again.",
                                  buttonText: "Okay",
                                  onPressed: () {
                                    _loadData();
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                              return;
                            }

                            // Show withdraw dialog
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PaymentProcessingPage(
                                        transferMethod: "withdraw")));
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.red[50],
                                      child: Icon(
                                        Icons.arrow_upward,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Withdraw',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to withdraw',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction History
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction History',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    DropdownButton<String?>(
                      value: _selectedStatus,
                      hint: Text(
                        'Filter by status',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey),
                      ),
                      isExpanded: true,
                      items: statusOptions.map((status) {
                        return DropdownMenuItem<String?>(
                          value: status,
                          child: Text(
                            status ?? 'All',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                          _filterTransactions();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _isLoading
                        ? Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.1),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color(0xFFE23670),
                                          ),
                                          backgroundColor:
                                              const Color(0xFFF5A1BB),
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color(0xFFE23670),
                                          ),
                                          backgroundColor:
                                              const Color(0xFFF5A1BB),
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color(0xFFE23670),
                                          ),
                                          backgroundColor:
                                              const Color(0xFFF5A1BB),
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color(0xFFE23670),
                                          ),
                                          backgroundColor:
                                              const Color(0xFFF5A1BB),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _filteredTransactions.isEmpty
                            ? Text(
                                "No transactions match your criteria",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.black,
                                ),
                              )
                            : Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredTransactions.length >=
                                            _displayLimit
                                        ? _displayLimit
                                        : _filteredTransactions.length,
                                    itemBuilder: (context, index) {
                                      final transaction =
                                          _filteredTransactions[index];
                                      return Semantics(
                                        label:
                                            'Transaction: ${transaction.taskAssignment.task?.title ?? 'Untitled'}, ${transaction.recordStatus}, ${DateFormat('MMM d, yyyy').format(DateTime.parse(transaction.date))}',
                                        child:
                                            _buildTransactionCard(transaction),
                                      );
                                    },
                                  ),
                                  if (_filteredTransactions.length >
                                      _displayLimit)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: ElevatedButton(
                                        onPressed: _loadMore,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFB71A4A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          'Load More',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    loadingController.dispose();
    super.dispose();
  }
}
