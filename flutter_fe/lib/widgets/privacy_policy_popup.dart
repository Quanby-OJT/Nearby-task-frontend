import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPopup extends StatefulWidget {
  final String?
      context; // 'task_assignment' or null for default account creation
  const PrivacyPolicyPopup({Key? key, this.context}) : super(key: key);

  @override
  State<PrivacyPolicyPopup> createState() => _PrivacyPolicyPopupState();
}

class _PrivacyPolicyPopupState extends State<PrivacyPolicyPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isChecked = false;

  String get _title => widget.context == 'task_assignment'
      ? 'Task Assignment Policy'
      : widget.context == 'task_creation'
          ? 'Task Application Policy'
          : 'Privacy Policy';

  IconData get _icon => widget.context == 'task_assignment'
      ? Icons.assignment_outlined
      : widget.context == 'task_creation'
          ? Icons.add_task_outlined
          : Icons.privacy_tip_outlined;

  String get _checkboxText => widget.context == 'task_assignment'
      ? 'I agree to the Task Assignment Policy'
      : widget.context == 'task_creation'
          ? 'I agree to the Task Application Policy'
          : 'I agree to the Privacy Policy';

  List<Map<String, String>> get _sections {
    if (widget.context == 'task_assignment') {
      return [
        {
          'title': 'Task Assignment Terms',
          'content':
              'By assigning a task, you agree to the terms and conditions of task assignment and acknowledge your responsibilities as a task creator. You must ensure all task details are accurate and complete.'
        },
        {
          'title': 'Tasker Selection & Matching',
          'content':
              'You are responsible for selecting appropriate taskers based on their skills, experience, and availability. Ensure the task requirements match the tasker\'s capabilities and qualifications.'
        },
        {
          'title': 'Communication & Coordination',
          'content':
              'Maintain clear and professional communication with assigned taskers. Provide all necessary information, respond promptly to queries, and ensure smooth coordination throughout the task duration.'
        },
        {
          'title': 'Task Requirements & Deadlines',
          'content':
              'Clearly specify all task details, requirements, deadlines, and deliverables. Any changes must be communicated promptly to all parties involved and documented appropriately.'
        },
        {
          'title': 'Privacy & Confidentiality',
          'content':
              'Respect the privacy and confidentiality of taskers. Do not share personal information or task details with unauthorized parties. Maintain professional boundaries and data protection standards.'
        },
        {
          'title': 'Quality & Standards',
          'content':
              'Ensure all assigned tasks meet our platform\'s quality standards and guidelines. Monitor task progress and provide necessary support to maintain service excellence.'
        }
      ];
    } else if (widget.context == 'task_creation') {
      return [
        {
          'title': 'Task Application Guidelines',
          'content':
              'By applying for a task, you agree to provide accurate and complete information. All task details must be clear, specific, and aligned with our platform\'s guidelines and standards.'
        },
        {
          'title': 'Task Description & Requirements',
          'content':
              'Provide detailed descriptions of your task, including all necessary requirements, skills needed, and expected outcomes. Be specific about deliverables and any special conditions.'
        },
        {
          'title': 'Budget & Timeline',
          'content':
              'Set realistic budgets and timelines for your tasks. Consider the complexity and scope of work when determining the price and duration. Be clear about payment terms and milestones.'
        },
        {
          'title': 'Location & Accessibility',
          'content':
              'Specify accurate task locations and any accessibility requirements. Ensure the location is accessible and safe for taskers. Include any relevant travel or accommodation details.'
        },
        {
          'title': 'Photos & Documentation',
          'content':
              'Upload clear and relevant photos that help taskers understand the work. Ensure all documentation is accurate and complies with our platform\'s content guidelines.'
        },
        {
          'title': 'Quality Assurance',
          'content':
              'Commit to maintaining high standards for task quality. Be prepared to provide feedback and work with taskers to ensure successful task completion.'
        }
      ];
    } else {
      return [
        {
          'title': 'Information Collection',
          'content':
              'We collect information that you provide directly to us, including your name, email address, and other contact information.'
        },
        {
          'title': 'Information Usage',
          'content':
              'We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to protect our users.'
        },
        {
          'title': 'Information Sharing',
          'content':
              'We do not share your personal information with third parties except as described in this privacy policy.'
        },
        {
          'title': 'Data Security',
          'content':
              'We take reasonable measures to help protect your personal information from loss, theft, misuse, and unauthorized access.'
        },
        {
          'title': 'Your Rights',
          'content':
              'You have the right to access, correct, or delete your personal information. Contact us to exercise these rights.'
        }
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xFFB71A4A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _icon,
                    color: Color(0xFFB71A4A),
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB71A4A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Container(
                  height: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _sections
                          .map((section) => _buildSection(
                                section['title']!,
                                section['content']!,
                              ))
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isChecked = value ?? false;
                        });
                      },
                      activeColor: Color(0xFFB71A4A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _checkboxText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                        maxLines: null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isChecked
                        ? () {
                            _controller.reverse().then((_) {
                              Navigator.of(context).pop();
                            });
                          }
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: _isChecked
                          ? Color(0xFFB71A4A)
                          : Color(0xFFB71A4A).withOpacity(0.5),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'I Understand',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB71A4A),
            ),
          ),
          SizedBox(height: 5),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
