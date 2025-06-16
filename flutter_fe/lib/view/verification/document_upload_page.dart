import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/model/verification_model.dart';

class DocumentUploadPage extends StatefulWidget {
  final Function(File? documentFile) onDocumentUploaded;

  const DocumentUploadPage({super.key, required this.onDocumentUploaded});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final storage = GetStorage();

  File? _documentFile;
  String? _documentFileName;
  String? _documentUrl; // Add this field to track existing document
  bool _isLoading = false;
  String? _uploadMethod;

  @override
  void initState() {
    super.initState();
    _checkExistingDocument();
  }

  // Add method to check for existing documents
  Future<void> _checkExistingDocument() async {
    try {
      setState(() => _isLoading = true);

      final userId = storage.read('user_id');
      debugPrint(
          'DocumentUpload: Checking for existing documents for user: $userId');

      if (userId != null) {
        final result = await ApiService.getTaskerVerificationStatus(
            int.parse(userId.toString()));

        debugPrint('DocumentUpload: API response: ${result.toString()}');

        if (result['success'] == true) {
          String? documentUrl;
          String? documentFileName;

          // Check verification data first
          if (result['exists'] == true && result['verification'] != null) {
            final verificationData =
                VerificationModel.fromJson(result['verification']);

            if (verificationData.documentUrl != null &&
                verificationData.documentUrl!.isNotEmpty) {
              documentUrl = verificationData.documentUrl;
              documentFileName = 'Verification Document';
              debugPrint(
                  'DocumentUpload: Found document in verification data: $documentUrl');
            }
          }

          // Check user documents from additional data (this is the main source now)
          if (result['userDocuments'] != null &&
              result['userDocuments']['user_document_link'] != null &&
              result['userDocuments']['user_document_link']
                  .toString()
                  .isNotEmpty) {
            documentUrl = result['userDocuments']['user_document_link'];
            documentFileName = _getDocumentFileName(documentUrl);
            debugPrint(
                'DocumentUpload: ✅ Found document in userDocuments: $documentUrl');
          }

          if (documentUrl != null && documentUrl.isNotEmpty) {
            setState(() {
              _documentUrl = documentUrl;
              _documentFileName = documentFileName ?? 'Existing Document';
            });

            debugPrint(
                'DocumentUpload: Set existing document URL: $_documentUrl');

            // Show success message to inform user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Existing document found! You can keep it or upload a new one.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.blue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } else {
            debugPrint('DocumentUpload: No existing document found');
          }
        }
      }
    } catch (e) {
      debugPrint('DocumentUpload: Error checking existing document: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to extract filename from URL
  String _getDocumentFileName(String? url) {
    if (url == null || url.isEmpty) return 'Document';

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        // Remove any query parameters or fragments
        return fileName.split('?').first.split('#').first;
      }
    } catch (e) {
      debugPrint('Error parsing document URL: $e');
    }

    return 'Existing Document';
  }

  // Helper method to get appropriate icon for document type
  IconData _getDocumentIcon(String? fileName) {
    if (fileName == null || fileName.isEmpty) return Icons.insert_drive_file;

    final lowerFileName = fileName.toLowerCase();

    if (lowerFileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerFileName.endsWith('.doc') ||
        lowerFileName.endsWith('.docx')) {
      return Icons.description;
    } else if (lowerFileName.endsWith('.jpg') ||
        lowerFileName.endsWith('.jpeg') ||
        lowerFileName.endsWith('.png') ||
        lowerFileName.endsWith('.gif')) {
      return Icons.image;
    } else if (lowerFileName.endsWith('.txt')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  // Helper method to view/open document
  void _viewDocument(String documentUrl) {
    try {
      // Show a dialog with document info since we can't directly open URLs in Flutter without url_launcher
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Document Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB71A4A),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Name:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _documentFileName ?? 'Document',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Document URL:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    documentUrl,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This document was previously uploaded and is available for your verification.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB71A4A),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error viewing document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to view document details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureDocumentImage() async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _documentFile = File(photo.path);
          _documentFileName = photo.name;
          _uploadMethod = 'camera';
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document photo captured successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing document image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          setState(() {
            _documentFile = file;
            _documentFileName = result.files.single.name;
            _uploadMethod = 'file';
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document selected successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected file does not exist'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _completeVerification() {
    if (_documentFile != null) {
      // Only pass the file if it exists
      if (_documentFile!.existsSync()) {
        debugPrint("Document file exists, proceeding with upload");
        widget.onDocumentUploaded(_documentFile);
      } else {
        debugPrint("Document file doesn't exist, proceeding without document");
        widget.onDocumentUploaded(null);

        // Show informative message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proceeding without document upload'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else if (_documentUrl != null) {
      // If there's an existing document URL, proceed with that
      debugPrint("Existing document found, proceeding with existing document");
      widget.onDocumentUploaded(null); // Pass null as no new file to upload
    } else {
      // If no document was selected, proceed without it
      debugPrint("No document selected, proceeding without document");
      widget.onDocumentUploaded(null);
    }
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
                            'Document Upload',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB71A4A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload additional documents (Optional)',
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

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFB71A4A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFB71A4A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFFB71A4A)),
                              const SizedBox(width: 8),
                              Text(
                                'This step is optional',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB71A4A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can upload additional documents to enhance your profile, such as:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Certifications or diplomas'),
                          _buildBulletPoint('Skills training certificates'),
                          _buildBulletPoint('Previous work documentation'),
                          _buildBulletPoint('Character references'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Show existing document if available
                    if (_documentUrl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with status indicator
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Existing Document Found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You already have a document on file. You can keep using this document or upload a new one.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Document display container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Document preview section
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _getDocumentIcon(_documentFileName),
                                          size: 36,
                                          color: const Color(0xFFB71A4A),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _documentFileName ?? 'Document',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.verified,
                                                  size: 14,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Previously uploaded',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // View document button
                                      IconButton(
                                        onPressed: () =>
                                            _viewDocument(_documentUrl!),
                                        icon: Icon(
                                          Icons.open_in_new,
                                          color: const Color(0xFFB71A4A),
                                          size: 20,
                                        ),
                                        tooltip: 'View document',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Action buttons
                                Row(
                                  children: [
                                    // Keep existing document button
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // User chooses to keep existing document
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Using existing document for verification.',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 10),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          _completeVerification();
                                        },
                                        icon: Icon(Icons.check,
                                            size: 16, color: Colors.white),
                                        label: Text(
                                          'Keep This',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Replace document button
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickDocument,
                                        icon: Icon(Icons.upload_file, size: 16),
                                        label: Text(
                                          'Replace',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFB71A4A),
                                          side: BorderSide(
                                              color: const Color(0xFFB71A4A),
                                              width: 2),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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

                    // Upload Actions
                    if (_documentFile == null && _documentUrl == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File Upload Option
                          GestureDetector(
                            onTap: _pickDocument,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.upload_file,
                                      size: 28,
                                      color: const Color(0xFFB71A4A),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Upload Document File',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF, Images, or Word Documents',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Selected Document Display
                    if (_documentFile != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uploaded Document',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (_uploadMethod == 'camera')
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.file(
                                        _documentFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                                spreadRadius: 1,
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _documentFileName
                                                        ?.endsWith('.pdf') ??
                                                    false
                                                ? Icons.picture_as_pdf
                                                : (_documentFileName?.endsWith(
                                                                '.doc') ??
                                                            false) ||
                                                        (_documentFileName
                                                                ?.endsWith(
                                                                    '.docx') ??
                                                            false)
                                                    ? Icons.description
                                                    : Icons.insert_drive_file,
                                            size: 36,
                                            color: const Color(0xFFB71A4A),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _documentFileName ?? 'Document',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[800],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Document uploaded successfully',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _uploadMethod == 'camera'
                                        ? _captureDocumentImage
                                        : _pickDocument,
                                    icon: Icon(
                                      _uploadMethod == 'camera'
                                          ? Icons.camera_alt
                                          : Icons.upload_file,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _uploadMethod == 'camera'
                                          ? 'Retake photo'
                                          : 'Replace file',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                      side:
                                          BorderSide(color: Colors.grey[400]!),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 40),
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
                color: Color(0xFFB71A4A),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFB71A4A),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
