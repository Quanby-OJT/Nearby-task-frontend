import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/report_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/conversation.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../controller/conversation_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<TaskAssignment> taskAssignments = [];
  List<Conversation> conversation = [];
  List<TaskAssignment?> filteredTaskAssignments = [];
  final GetStorage storage = GetStorage();
  final TaskController _taskController = TaskController();
  final ReportController reportController = ReportController();
  final ConversationController conversationController =
      ConversationController();
  final ProfileController _profileController = ProfileController();
  final ClientServices _clientServices = ClientServices();
  final TaskerService _taskerService = TaskerService();
  List<UserModel> tasker = [];
  int? cardNumber = 0;
  bool _isUploadDialogShown = false;
  bool _isLoading = true;
  IO.Socket? socket;
  AuthenticatedUser? _user;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;
  bool _isModalOpen = false;
  String? _selectedReportCategory;
  bool _isOfflineMode = false;
  late SharedPreferences _prefs;
  final Connectivity _connectivity = Connectivity();

  // Profile image caching
  Map<int, String> _taskerProfileImages = {};
  Map<int, String> _clientProfileImages = {};

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();

    conversationController.searchConversation.addListener(filterMessages);

    socket = IO.io('http://192.168.1.12:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.on('new_message', (data) {
      if (data['user_id'] != storage.read('user_id')) {
        _fetchTaskAssignments();
      }
    });

    socket?.on('message_read', (data) {
      _fetchTaskAssignments();
    });
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkInternetConnection();
  }

  void loadAll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _fetchTaskAssignments(),
      _fetchTaskers(),
      _fetchUserIDImage(),
      _fetchReportHistory(),
    ]);

    // Fetch all profile images after task assignments are loaded
    await _fetchAllProfileImages();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    reportController.reasonController.dispose();
    conversationController.searchConversation.dispose();
    _selectedReportCategory = null;
    socket?.disconnect();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final result = await _connectivity.checkConnectivity();

    if (result.contains(ConnectivityResult.mobile) == true ||
        result.contains(ConnectivityResult.wifi) == true) {
      if (!mounted) return;
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
      loadAll();
    } else {
      if (!mounted) return;
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

  Future<void> _saveDataToCache() async {
    try {
      if (taskAssignments.isNotEmpty) {
        final taskAssignmentsJson =
            taskAssignments.map((task) => task.toJson()).toList();
        await _prefs.setString(
            'cached_task_assignments', json.encode(taskAssignmentsJson));
        debugPrint("Saved ${taskAssignments.length} task assignments to cache");
      }

      if (conversation.isNotEmpty) {
        final conversationsJson =
            conversation.map((conv) => conv.toJson()).toList();
        await _prefs.setString(
            'cached_conversations', json.encode(conversationsJson));
        debugPrint("Saved ${conversation.length} conversations to cache");
      }
    } catch (e) {
      debugPrint("Error saving data to cache: $e");
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedTaskAssignments = _prefs.getString('cached_task_assignments');
      final cachedConversations = _prefs.getString('cached_conversations');
      final cachedTaskerImages =
          _prefs.getString('cached_tasker_profile_images');
      final cachedClientImages =
          _prefs.getString('cached_client_profile_images');

      if (cachedTaskAssignments != null) {
        final List<dynamic> decodedTaskAssignments =
            json.decode(cachedTaskAssignments);
        if (!mounted) return;
        setState(() {
          taskAssignments = decodedTaskAssignments
              .map((json) => TaskAssignment.fromJson(json))
              .toList();
          filteredTaskAssignments = taskAssignments;
        });
        debugPrint(
            "Loaded ${taskAssignments.length} task assignments from cache");
      }

      if (cachedConversations != null) {
        final List<dynamic> decodedConversations =
            json.decode(cachedConversations);
        if (!mounted) return;
        setState(() {
          conversation = decodedConversations
              .map((json) => Conversation.fromJson(json))
              .toList();
        });
        debugPrint("Loaded ${conversation.length} conversations from cache");
      }

      // Load cached profile images
      if (cachedTaskerImages != null) {
        final Map<String, dynamic> decodedTaskerImages =
            json.decode(cachedTaskerImages);
        _taskerProfileImages = decodedTaskerImages
            .map((key, value) => MapEntry(int.parse(key), value.toString()));
        debugPrint(
            "Loaded ${_taskerProfileImages.length} tasker profile images from cache");
      }

      if (cachedClientImages != null) {
        final Map<String, dynamic> decodedClientImages =
            json.decode(cachedClientImages);
        _clientProfileImages = decodedClientImages
            .map((key, value) => MapEntry(int.parse(key), value.toString()));
        debugPrint(
            "Loaded ${_clientProfileImages.length} client profile images from cache");
      }
    } catch (e) {
      debugPrint("Error loading cached data: $e");
    }
  }

  void filterMessages() {
    String query = conversationController.searchConversation.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      filteredTaskAssignments = taskAssignments.where((taskTaken) {
        return (taskTaken.task?.title.toLowerCase().contains(query) ?? false) ||
            (taskTaken.tasker?.user?.firstName.toLowerCase().contains(query) ??
                false) ||
            (taskTaken.tasker?.user?.middleName
                    ?.toLowerCase()
                    .contains(query) ??
                false) ||
            (taskTaken.tasker?.user?.lastName.toLowerCase().contains(query) ??
                false);
      }).toList();
    });
  }

  Future<void> readMessages(int taskTakenId) async {
    // Use the instance member directly
    await conversationController.readMessage(taskTakenId);
  }

  Future<void> _fetchTaskAssignments() async {
    try {
      if (!mounted) return;
      setState(() {
        taskAssignments = [];
        filteredTaskAssignments = [];
        conversation = [];
        _isLoading = true;
      });

      final taskAndConversationResult =
          await _taskController.fetchTasksAndConversations();
      final tasks = taskAndConversationResult.taskAssignments;
      final convs = taskAndConversationResult.conversations;

      debugPrint("Raw Conversations: $convs");
      debugPrint("Task Assignments: $tasks");

      if (!mounted) return;
      setState(() {
        taskAssignments = tasks;
        conversation = convs;
        filteredTaskAssignments = tasks;
        _isLoading = false;
      });

      // Save data to cache after successful fetch
      await _saveDataToCache();
    } catch (e, st) {
      debugPrint("Error fetching task assignments: $e");
      debugPrint(st.toString());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load messages")),
        );
      }
    }
  }

  Future<void> _fetchTaskers() async {
    await reportController.fetchTaskers();
    debugPrint("Taskers loaded in ChatScreen: ${reportController.taskers}");
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _fetchReportHistory() async {
    int userId = storage.read('user_id');
    await reportController.fetchReportHistory(userId);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        if (!mounted) return;
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
    }
  }

  Future<void> _fetchAllProfileImages() async {
    try {
      // Get unique tasker and client IDs from task assignments
      Set<int> taskerIds = {};
      Set<int> clientIds = {};

      for (var taskAssignment in taskAssignments) {
        if (taskAssignment.tasker?.user?.id != null) {
          taskerIds.add(taskAssignment.tasker!.user!.id!);
        }
        if (taskAssignment.client?.user?.id != null) {
          clientIds.add(taskAssignment.client!.user!.id!);
        }
      }

      debugPrint(
          "Fetching profile images for ${taskerIds.length} taskers and ${clientIds.length} clients");

      // Fetch tasker profile images
      await Future.wait(taskerIds.map((id) => _fetchTaskerProfileImage(id)));

      // Fetch client profile images
      await Future.wait(clientIds.map((id) => _fetchClientProfileImage(id)));

      // Save profile images to cache
      await _saveProfileImagesToCache();

      debugPrint(
          "Profile images fetched: ${_taskerProfileImages.length} tasker images, ${_clientProfileImages.length} client images");
    } catch (e) {
      debugPrint("Error fetching profile images: $e");
    }
  }

  Future<void> _fetchTaskerProfileImage(int userId) async {
    try {
      final result = await _taskerService.getTaskerImages(userId);
      if (result.containsKey('images') && result['images'] is List) {
        final List<dynamic> images = result['images'];
        if (images.isNotEmpty) {
          final firstImage = images.first;
          if (firstImage is Map && firstImage['image_link'] != null) {
            _taskerProfileImages[userId] = firstImage['image_link'];
            debugPrint(
                "Fetched tasker profile image for user $userId: ${firstImage['image_link']}");
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching tasker profile image for user $userId: $e");
      // Clear any failed URLs
      _taskerProfileImages.remove(userId);
    }
  }

  Future<void> _fetchClientProfileImage(int userId) async {
    try {
      final result = await _clientServices.getClientImages(userId);
      if (result.containsKey('images') && result['images'] is List) {
        final List<dynamic> images = result['images'];
        if (images.isNotEmpty) {
          final firstImage = images.first;
          if (firstImage is Map && firstImage['image_link'] != null) {
            _clientProfileImages[userId] = firstImage['image_link'];
            debugPrint(
                "Fetched client profile image for user $userId: ${firstImage['image_link']}");
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching client profile image for user $userId: $e");
      // Clear any failed URLs
      _clientProfileImages.remove(userId);
    }
  }

  Future<void> _saveProfileImagesToCache() async {
    try {
      // Save tasker profile images to cache
      final taskerImagesJson = _taskerProfileImages
          .map((key, value) => MapEntry(key.toString(), value));
      await _prefs.setString(
          'cached_tasker_profile_images', json.encode(taskerImagesJson));

      // Save client profile images to cache
      final clientImagesJson = _clientProfileImages
          .map((key, value) => MapEntry(key.toString(), value));
      await _prefs.setString(
          'cached_client_profile_images', json.encode(clientImagesJson));

      debugPrint(
          "Saved profile images to cache: ${_taskerProfileImages.length} tasker images, ${_clientProfileImages.length} client images");
    } catch (e) {
      debugPrint("Error saving profile images to cache: $e");
    }
  }

  DecorationImage? _getProfileImageDecoration(
      UserModel? user, String userRole) {
    try {
      String? profileImageUrl;

      // Priority 1: Profile image from database table
      if (user?.id != null) {
        if (userRole.toLowerCase() == 'tasker') {
          profileImageUrl = _taskerProfileImages[user!.id!];
        } else if (userRole.toLowerCase() == 'client') {
          profileImageUrl = _clientProfileImages[user!.id!];
        }
      }

      // Priority 2: Default user image
      profileImageUrl ??= user?.imageName ?? user?.image;

      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        return DecorationImage(
          image: CachedNetworkImageProvider(profileImageUrl),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            debugPrint("Error loading profile image: $exception");
          },
        );
      }
    } catch (e) {
      debugPrint("Error getting profile image decoration: $e");
    }

    return null;
  }

  void _showReportModal() {
    setState(() {
      _isModalOpen = true;
    });
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Report User",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB71A4A),
                                    fontSize: 24,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Please fill in the details below",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: DropdownSearch<Map<String, dynamic>>(
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search users...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              items: reportController.taskers,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Report User *',
                                  labelStyle:
                                      TextStyle(color: Color(0xFFB71A4A)),
                                  filled: true,
                                  fillColor: Color(0xFFF1F4FF),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Color(0xFFB71A4A), width: 2),
                                  ),
                                ),
                              ),
                              itemAsString: (Map<String, dynamic> tasker) =>
                                  "${tasker['first_name']} ${tasker['middle_name'] ?? ''} ${tasker['last_name']}",
                              onChanged: (Map<String, dynamic>? newValue) {
                                setModalState(() {
                                  _selectedReportCategory = newValue != null
                                      ? newValue['user_id'].toString()
                                      : null;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select a User' : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: TextField(
                              controller: reportController.reasonController,
                              maxLines: 5,
                              cursorColor: Color(0xFFB71A4A),
                              decoration: InputDecoration(
                                label: Text('Report Description *'),
                                labelStyle: TextStyle(color: Color(0xFFB71A4A)),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Color(0xFFF1F4FF),
                                hintText: 'Enter description...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: Color(0xFFB71A4A), width: 2),
                                ),
                                errorText: reportController.errors['reason'],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload Proof (Max 5 images)',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFB71A4A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await reportController
                                        .pickImages(modalContext);
                                    setModalState(() {});
                                  },
                                  icon: Icon(Icons.upload_file,
                                      color: Colors.white),
                                  label: Text(
                                    'Upload Images',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFB71A4A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                ),
                                if (reportController.imageUploadError !=
                                    null) ...[
                                  SizedBox(height: 5),
                                  Text(
                                    reportController.imageUploadError!,
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  ),
                                ],
                                if (reportController
                                    .selectedImages.isNotEmpty) ...[
                                  SizedBox(height: 10),
                                  SizedBox(
                                    height: 120,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: reportController
                                          .selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: Column(
                                            children: [
                                              Stack(
                                                children: [
                                                  FutureBuilder<Uint8List>(
                                                    future: reportController
                                                        .selectedImages[index]
                                                        .readAsBytes(),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return SizedBox(
                                                          height: 80,
                                                          width: 80,
                                                          child: Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        );
                                                      }
                                                      if (snapshot.hasError) {
                                                        return SizedBox(
                                                          height: 80,
                                                          width: 80,
                                                          child: Center(
                                                              child: Text(
                                                                  'Error')),
                                                        );
                                                      }
                                                      return Image.memory(
                                                        snapshot.data!,
                                                        height: 80,
                                                        width: 80,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setModalState(() {
                                                          reportController
                                                              .removeImage(
                                                                  index);
                                                        });
                                                      },
                                                      child: Container(
                                                        color: Colors.red,
                                                        child: Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'Image ${index + 1}',
                                                style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            reportController.clearForm();
                            setState(() {
                              _isModalOpen = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            int userId = storage.read('user_id');
                            int? reportedWhom = _selectedReportCategory != null
                                ? int.tryParse(_selectedReportCategory!)
                                : null;
                            if (_existingProfileImageUrl == null ||
                                _existingIDImageUrl == null ||
                                _existingProfileImageUrl!.isEmpty ||
                                _existingIDImageUrl!.isEmpty ||
                                !_documentValid) {
                              _showWarningDialog();
                              return;
                            }
                            reportController.validateAndSubmit(
                                context, setModalState, userId, reportedWhom);
                            setState(() {
                              _isModalOpen = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFB71A4A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'Submit',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _isModalOpen = false;
      });
    });
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "Account Verification",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Upload your Profile and ID images to complete your account. Verification will follow.",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FillUpClient()),
              );
              if (result == true) {
                setState(() {
                  _isLoading = true;
                });
                await _fetchUserIDImage();
              } else {
                setState(() {
                  _isUploadDialogShown = false;
                });
              }
            },
            child: Text(
              "Verify Account",
              style: GoogleFonts.poppins(color: Color(0xFFB71A4A)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isUploadDialogShown = false;
              });
            },
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportHistoryModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Report History",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB71A4A),
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: reportController.reportHistory.isEmpty
                    ? Center(
                        child: Text(
                          "No report history available yet.",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: reportController.reportHistory.length,
                        itemBuilder: (context, index) {
                          final report = reportController.reportHistory[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              title: Text(
                                "Report #${report.reportId ?? 'N/A'}",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB71A4A),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Reason: ${report.reason ?? 'No reason provided'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Reported By: ${report.reportedByName ?? 'Unknown'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Reported Whom: ${report.reportedWhomName ?? 'Unknown'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Created At: ${report.createdAt ?? 'N/A'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Status: ${report.status != null ? (report.status! ? 'Resolved' : 'Pending') : 'N/A'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          "Messages",
          style: GoogleFonts.montserrat(
            color: Color(0xFFB71A4A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report_user') {
                _showReportModal();
              } else if (value == 'report_history') {
                _showReportHistoryModal();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'report_user',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Report User', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'report_history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF0272B1)),
                    SizedBox(width: 8),
                    Text('Report History', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, color: Color(0xFFB71A4A)),
          ),
        ],
      ),
      body: Column(
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: conversationController.searchConversation,
                cursorColor: const Color(0xFFB71A4A),
                decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Color(0xFFB71A4A),
                      size: 18,
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable:
                          conversationController.searchConversation,
                      builder: (context, value, child) {
                        return value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFFB71A4A),
                                  size: 18,
                                ),
                                onPressed: () {
                                  conversationController.searchConversation
                                      .clear();
                                },
                              )
                            : const SizedBox.shrink();
                      },
                    )),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFFB71A4A)),
                  )
                : taskAssignments.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _initializeSharedPreferences,
                        color: Color(0xFFB71A4A),
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.commentSlash,
                                    size: 80,
                                    color: Color(0xFFB71A4A),
                                  ),
                                  SizedBox(height: 16),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      "No messages yet. Accept a tasker or wait for your task to be accepted.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _initializeSharedPreferences,
                        color: Color(0xFFB71A4A),
                        child: ListView.builder(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredTaskAssignments.length,
                          itemBuilder: (context, index) {
                            final taskAssignment =
                                filteredTaskAssignments[index];
                            if (taskAssignment == null) {
                              return SizedBox.shrink();
                            }
                            final conversation =
                                this.conversation.firstWhereOrNull(
                                      (conv) =>
                                          conv.taskTakenId ==
                                          taskAssignment.taskTakenId,
                                    );
                            return conversationCard(
                                taskAssignment, conversation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void showMessageOptions(BuildContext context, int taskTakenId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Conversation',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete this conversation? This cannot be undone.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onPressed: () {
                conversationController.deleteMessage(context, taskTakenId);
                Navigator.of(context).pop();
                _fetchTaskAssignments();
              },
            ),
          ],
        );
      },
    );
  }

  Widget conversationCard(
      TaskAssignment taskTaken, Conversation? conversation) {
    final currentUserId = storage.read('user_id');
    final role = storage.read('role');
    final senderId = conversation?.userId ??
        (role == 'Tasker'
            ? taskTaken.client?.user?.id
            : taskTaken.tasker?.user?.id) ??
        0;
    final bool isReceiver = senderId != currentUserId;
    final bool isUnread = taskTaken.unreadCount > 0;
    final user =
        role == 'Tasker' ? taskTaken.client?.user : taskTaken.tasker?.user;
    final userRole = role == 'Tasker' ? 'client' : 'tasker';
    final timestamp = conversation?.createdAt != null
        ? DateFormat('h:mm a').format(conversation!.createdAt!)
        : '';

    debugPrint("Role: $role");
    debugPrint("Current User ID: $currentUserId");
    debugPrint("Sender ID: $senderId");
    debugPrint("Is Receiver: $isReceiver");
    debugPrint("Is Unread: $isUnread");

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
        border: isUnread && isReceiver
            ? Border.all(color: Color(0xFFB71A4A).withOpacity(0.2), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualChatScreen(
                  taskAssignment: taskTaken,
                  user: user ??
                      UserModel(
                        firstName: '',
                        middleName: '',
                        lastName: '',
                        email: '',
                        role: '',
                        accStatus: '',
                      ),
                ),
              ),
            ).then((_) {
              _fetchTaskAssignments();
              conversationController.readMessage(taskTaken.taskTakenId);
            });
          },
          onLongPress: () => showMessageOptions(context, taskTaken.taskTakenId),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnread && isReceiver
                              ? Color(0xFFB71A4A).withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF0272B1),
                        backgroundImage:
                            _getProfileImageDecoration(user, userRole)?.image,
                        child:
                            _getProfileImageDecoration(user, userRole) == null
                                ? Text(
                                    user?.firstName.isNotEmpty == true
                                        ? user!.firstName[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    if (isUnread && isReceiver)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color(0xFFB71A4A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFB71A4A).withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            taskTaken.unreadCount > 99
                                ? '99+'
                                : taskTaken.unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  taskTaken.task?.title ?? 'No Title',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0272B1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Task Chat',
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFF0272B1),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timestamp,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isUnread && isReceiver)
                                Container(
                                  margin: EdgeInsets.only(top: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFB71A4A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              isUnread
                                  ? Icons.check_circle_outline
                                  : Icons.check_circle,
                              color: isUnread
                                  ? Colors.grey[400]
                                  : Color(0xFF4CAF50),
                              size: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${user?.firstName ?? ''} ${user?.middleName ?? ''} ${user?.lastName ?? ''}"
                                  .trim(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isUnread && isReceiver
                                    ? Color(0xFF1A1A1A)
                                    : Colors.grey[600],
                                fontWeight: isUnread && isReceiver
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (conversation?.conversationMessage != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUnread && isReceiver
                                ? Color(0xFFB71A4A).withOpacity(0.05)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUnread && isReceiver
                                  ? Color(0xFFB71A4A).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  conversation!.conversationMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: isUnread && isReceiver
                                        ? Color(0xFF1A1A1A)
                                        : Colors.grey[600],
                                    fontWeight: isUnread && isReceiver
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
