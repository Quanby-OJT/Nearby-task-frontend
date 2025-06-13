import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// Placeholder imports (replace with actual imports)
import 'package:flutter_fe/view/profile/payment_processing.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/model/transactions.dart';
import 'package:flutter_fe/view/task/task_details_screen.dart';
import 'package:flutter_fe/controller/task_controller.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with TickerProviderStateMixin {
  final _escrowManagementController = EscrowManagementController();
  final TaskController taskController = TaskController();
  late AnimationController loadingController;
  List<Transactions> _transactionHistory = [];
  List<Transactions> _filteredTransactions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  int _displayLimit = 5;

  @override
  void initState() {
    super.initState();
    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _searchController.addListener(_filterTransactions);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    loadingController.repeat(reverse: true);

    try {
      await _escrowManagementController.fetchTokenBalance();
      await getTransactionHistory();
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
    final imageUrl =
        transaction.taskAssignment.tasker?.user?.image ?? 'Unknown';
    final hasValidImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'Unknown';

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
            ),
            child: hasValidImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 24,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.grey, size: 24),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Summary Card
            Container(
              width: double.infinity,
              height: 150,
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                          // Show deposit dialog
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return PaymentProcessingPage(
                                transferMethod: "deposit",
                              );
                            },
                          ));
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
                      style:
                          GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
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
                                  physics: const NeverScrollableScrollPhysics(),
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
                                      child: _buildTransactionCard(transaction),
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    loadingController.dispose();
    super.dispose();
  }
}
