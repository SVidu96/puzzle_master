import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLink = false, VoidCallback? onTap}) {
    final textWidget = Text(
      value,
      style: TextStyle(
        fontSize: 16,
        color: isLink ? Colors.blue.shade700 : Colors.black87,
        decoration: isLink ? TextDecoration.underline : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          isLink
              ? GestureDetector(onTap: onTap, child: textWidget)
              : textWidget,
        ],
      ),
    );
  }

  Widget _buildSocialButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      color: color,
      iconSize: 32,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade100,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'About Puzzle Master',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.business, 'By', 'SVidu96.dev'),
            _buildInfoRow(Icons.numbers, 'Version', '1.0.1 (Beta)'),
            _buildInfoRow(
              Icons.email,
              'Contact',
              'svidu96.dev@proton.me',
              isLink: true,
              onTap: () => _launchUrl('mailto:svidu96.dev@proton.me'),
            ),
            _buildInfoRow(
              Icons.language,
              'Website',
              'www.SVidu96.dev',
              isLink: true,
              onTap: () => _launchUrl('https://www.SVidu96.dev'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  Icons.facebook,
                  Colors.blue,
                  () => _launchUrl('https://facebook.com/SVidu96.dev'),
                ),
                _buildSocialButton(
                  Icons.telegram,
                  Colors.blue.shade700,
                  () => _launchUrl('https://t.me/SVidu96.dev'),
                ),
                _buildSocialButton(
                  Icons.discord,
                  Colors.indigo,
                  () => _launchUrl('https://discord.gg/SVidu96.dev'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
} 