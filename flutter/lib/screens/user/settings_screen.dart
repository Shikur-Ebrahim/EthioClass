import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../models/user_settings.dart';
import '../../services/settings_service.dart';
import 'security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isClearingCache = false;
  String _cacheSize = 'Calculating...';
  late UserSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _calculateCacheSize();
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

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheSize = await _getDirSize(tempDir);
      if (mounted) {
        setState(() {
          _cacheSize = _formatSize(cacheSize);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cacheSize = '0 B');
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (_) {}
    return size;
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
      if (mounted) {
        setState(() {
          _cacheSize = '0 B';
          _isClearingCache = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClearingCache = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear cache.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(UserSettings newSettings) async {
    setState(() => _settings = newSettings);
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
                _buildSectionHeader('Security'),
                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.security_outlined, color: AppColors.textMedium),
                    title: const Text('Security Settings', style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SecurityScreen()),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),
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
                _buildSectionHeader('Storage'),
                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.textMedium),
                    title: const Text('Clear Cache', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Temporary files and cached data', style: TextStyle(fontSize: 12)),
                    trailing: _isClearingCache
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : Text(
                            _cacheSize,
                            style: const TextStyle(
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    onTap: _isClearingCache ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Cache'),
                          content: Text('This will delete $_cacheSize of cached data. Continue?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Clear', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) _clearCache();
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader('About'),
                _buildCard([
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: AppColors.textMedium),
                    title: Text('App Version', style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text('1.0.0', style: TextStyle(color: AppColors.textMedium)),
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
                const SizedBox(height: 32),
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
