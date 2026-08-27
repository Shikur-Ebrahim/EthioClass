import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../widgets/auth_widgets.dart';

class ShareAppScreen extends StatelessWidget {
  const ShareAppScreen({super.key});

  final String appLink = "https://ethioclass.com/download"; // Replace with actual link

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Share Application',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Header Image/Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                size: 48,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Share EthioClass with Friends!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Let them scan this QR code or send them the download link directly.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: appLink,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Share Link',
              onPressed: () {
                Share.share(
                    'Check out EthioClass! Download the app here: $appLink');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
