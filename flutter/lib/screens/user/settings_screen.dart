import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_settings.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  late UserSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.instance.getSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(UserSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    // In background, save to API
    await SettingsService.instance.updateSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Preferences'),
                _buildCard([
                  _buildDropdownRow(
                    icon: Icons.language,
                    title: 'Language',
                    value: _settings.language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'am', child: Text('Amharic')),
                    ],
                    onChanged: (val) {
                      if (val != null) _updateSetting(_settings.copyWith(language: val));
                    },
                  ),
                  const Divider(height: 1),
                  _buildDropdownRow(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    value: _settings.theme,
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System Default')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (val) {
                      if (val != null) _updateSetting(_settings.copyWith(theme: val));
                    },
                  ),
                  const Divider(height: 1),
                  _buildDropdownRow(
                    icon: Icons.hd_outlined,
                    title: 'Download Quality',
                    value: _settings.downloadQuality,
                    items: const [
                      DropdownMenuItem(value: '1080p', child: Text('High (1080p)')),
                      DropdownMenuItem(value: '720p', child: Text('Medium (720p)')),
                      DropdownMenuItem(value: '480p', child: Text('Low (480p)')),
                    ],
                    onChanged: (val) {
                      if (val != null) _updateSetting(_settings.copyWith(downloadQuality: val));
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader('Notifications'),
                _buildCard([
                  _buildSwitchRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Push Notifications',
                    value: _settings.pushNotifications,
                    onChanged: (val) {
                      _updateSetting(_settings.copyWith(pushNotifications: val));
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchRow(
                    icon: Icons.email_outlined,
                    title: 'Email Notifications',
                    value: _settings.emailNotifications,
                    onChanged: (val) {
                      _updateSetting(_settings.copyWith(emailNotifications: val));
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader('About'),
                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.textMedium),
                    title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textMedium)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.textMedium),
                    title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textMedium),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
                    onTap: () {},
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMedium,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdownRow({
    required IconData icon,
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMedium, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark),
            ),
          ),
          DropdownButton<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more_rounded, color: AppColors.grey),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: AppColors.textMedium),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
