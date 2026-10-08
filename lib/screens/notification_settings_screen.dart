import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة إعدادات التنبيهات
class NotificationSettingsScreen extends StatefulWidget {
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _alertsEnabled = true;
  bool _highRiskOnly = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  static const _keyAlerts = 'notif_alerts_enabled';
  static const _keyHighRiskOnly = 'notif_high_risk_only';
  static const _keySound = 'notif_sound_enabled';
  static const _keyVibration = 'notif_vibration_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alertsEnabled = prefs.getBool(_keyAlerts) ?? true;
      _highRiskOnly = prefs.getBool(_keyHighRiskOnly) ?? false;
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      _vibrationEnabled = prefs.getBool(_keyVibration) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات التنبيهات'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('تفعيل التنبيهات'),
                          subtitle: const Text(
                            'استلام تنبيهات عند اكتشاف محتوى ضار',
                          ),
                          value: _alertsEnabled,
                          onChanged: (v) {
                            setState(() => _alertsEnabled = v);
                            _saveSetting(_keyAlerts, v);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('تنبيهات الخطورة العالية فقط'),
                          subtitle: const Text(
                            'استلام تنبيهات للمحتوى عالي الخطورة فقط',
                          ),
                          value: _highRiskOnly,
                          onChanged: _alertsEnabled
                              ? (v) {
                                  setState(() => _highRiskOnly = v);
                                  _saveSetting(_keyHighRiskOnly, v);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('صوت التنبيه'),
                          subtitle: const Text(
                            'تشغيل صوت عند استلام تنبيه جديد',
                          ),
                          value: _soundEnabled,
                          onChanged: _alertsEnabled
                              ? (v) {
                                  setState(() => _soundEnabled = v);
                                  _saveSetting(_keySound, v);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('اهتزاز'),
                          subtitle: const Text('اهتزاز الجهاز عند التنبيه'),
                          value: _vibrationEnabled,
                          onChanged: _alertsEnabled
                              ? (v) {
                                  setState(() => _vibrationEnabled = v);
                                  _saveSetting(_keyVibration, v);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
