import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class PreviewTask extends StatefulWidget {
  final TaskController controller;
  final String? selectedSpecialization;
  final String? selectedUrgency;
  final String? selectedWorkType;
  final String? selectedScope;
  final List<String> relatedSpecializations;
  final List<File> photos;
  final Function() onSubmit;
  final String? method;
  final List<dynamic>? taskImages;
  final List<int>? imagesToDelete;

  const PreviewTask({
    super.key,
    required this.controller,
    required this.selectedSpecialization,
    required this.selectedUrgency,
    required this.selectedWorkType,
    required this.selectedScope,
    required this.relatedSpecializations,
    required this.photos,
    required this.onSubmit,
    this.method,
    this.taskImages,
    this.imagesToDelete,
  });

  @override
  State<PreviewTask> createState() => _PreviewTaskState();
}

class _PreviewTaskState extends State<PreviewTask> {
  bool isLoading = false;

  Widget _buildPreviewSection(String title, List<Map<String, String?>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item['label']}: ${item['value']}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.microtask(() => widget.onSubmit());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'Preview Task',
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
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewSection('Task Basics', [
                  {
                    'label': 'Title',
                    'value': widget.controller.jobTitleController.text
                  },
                  {
                    'label': 'Location',
                    'value': widget.controller.jobLocationController.text
                  },
                  {
                    'label': 'Description',
                    'value': widget.controller.jobDescriptionController.text
                  },
                ]),
                _buildPreviewSection('Task Details', [
                  {
                    'label': 'Specialization',
                    'value': widget.selectedSpecialization
                  },
                  {
                    'label': 'Related Specializations',
                    'value': widget.relatedSpecializations.join(', ')
                  },
                  {'label': 'Work Type', 'value': widget.selectedWorkType},
                ]),
                _buildPreviewSection('Task Timeline', [
                  {'label': 'Scope', 'value': widget.selectedScope},
                  {
                    'label': 'Start Date',
                    'value': widget.controller.jobStartDateController.text
                  },
                ]),
                _buildPreviewSection('Budget & Urgency', [
                  {
                    'label': 'Price',
                    'value': widget.controller.contactPriceController.text
                  },
                  {'label': 'Urgency', 'value': widget.selectedUrgency},
                ]),
                _buildPreviewSection('Additional Info', [
                  {
                    'label': 'Remarks',
                    'value': widget.controller.jobRemarksController.text.isEmpty
                        ? 'None'
                        : widget.controller.jobRemarksController.text
                  },
                  {
                    'label': 'Photos',
                    'value': widget.photos.isNotEmpty ||
                            (widget.taskImages != null &&
                                widget.taskImages!.isNotEmpty)
                        ? '${widget.photos.length + (widget.taskImages?.length ?? 0)} photo(s) uploaded'
                        : 'None'
                  },
                ]),
                if (widget.photos.isNotEmpty ||
                    (widget.taskImages != null &&
                        widget.taskImages!.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.taskImages != null)
                        ...widget.taskImages!
                            .where((image) =>
                                !widget.imagesToDelete!.contains(image.id))
                            .map((image) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                image.image_url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                          );
                        }),
                      ...widget.photos.map((photo) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              photo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: isLoading ? Colors.grey : Colors.red[400],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71A4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.method == 'add_task' ? 'Post Task' : 'Update Task',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB71A4A)),
              ),
            ),
          ),
      ],
    );
  }
}
