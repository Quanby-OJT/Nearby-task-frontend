import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadFileIndicator extends StatelessWidget {
  const UploadFileIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0XFFE23670);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: CircularProgressIndicator(
                strokeWidth: 10,
                color: color,
              ),
            ),
            Icon(
              Icons.cloud_upload_outlined,
              size: 70,
              color: color,
            )
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Uploading Task...',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class DownloadFileIndicator extends StatelessWidget {
  const DownloadFileIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    Color color = Color(0XFFE23670);
    return SizedBox(
        width: 100,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        strokeWidth: 10,
                        color: color,
                      )),
                  Icon(Icons.cloud_download_outlined, size: 70, color: color)
                ],
              ),
              SizedBox(height: 10),
              Text('Downloading Task...',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ]));
  }
}
