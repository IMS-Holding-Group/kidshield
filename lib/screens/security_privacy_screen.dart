import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة الأمان والخصوصية
class SecurityPrivacyScreen extends StatefulWidget {
  final int userId;

  const SecurityPrivacyScreen({super.key, required this.userId});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  bool _requirePin = false;
  bool _biometricEnabled = false;
  int _dataRetentionDays = 90;
  bool _analyticsEnabled = true;
  bool _isLoading = true;

  static const _keyRequirePin = 'security_require_pin';
  static const _keyBiometric = 'security_biometric';
  static const _keyRetention = 'privacy_data_retention_days';
  static const _keyAnalytics = 'privacy_analytics_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _requirePin = prefs.getBool(_keyRequirePin) ?? false;
      _biometricEnabled = prefs.getBool(_keyBiometric) ?? false;
      _dataRetentionDays = prefs.getInt(_keyRetention) ?? 90;
      _analyticsEnabled = prefs.getBool(_keyAnalytics) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأمان والخصوصية'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'الأمان',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('طلب PIN عند فتح التطبيق'),
                          subtitle: const Text('حماية إضافية لحسابك'),
                          value: _requirePin,
                          onChanged: (v) {
                            setState(() => _requirePin = v);
                            _saveBool(_keyRequirePin, v);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('البصمة أو التعرف على الوجه'),
                          subtitle: const Text('فتح التطبيق بالبصمة'),
                          value: _biometricEnabled,
                          onChanged: (v) {
                            setState(() => _biometricEnabled = v);
                            _saveBool(_keyBiometric, v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'الخصوصية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('احتفاظ البيانات'),
                          subtitle: Text(
                            'حذف السجلات القديمة بعد $_dataRetentionDays يوم',
                          ),
                          trailing: DropdownButton<int>(
                            value: _dataRetentionDays,
                            items: const [
                              DropdownMenuItem(
                                value: 30,
                                child: Text('30 يوم'),
                              ),
                              DropdownMenuItem(
                                value: 90,
                                child: Text('90 يوم'),
                              ),
                              DropdownMenuItem(
                                value: 180,
                                child: Text('6 أشهر'),
                              ),
                              DropdownMenuItem(value: 365, child: Text('سنة')),
                              DropdownMenuItem(
                                value: 0,
                                child: Text('بدون حد'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _dataRetentionDays = v);
                                _saveInt(_keyRetention, v);
                              }
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('تحسين التطبيق'),
                          subtitle: const Text(
                            'مشاركة إحصائيات مجهولة لتحسين التحليل',
                          ),
                          value: _analyticsEnabled,
                          onChanged: (v) {
                            setState(() => _analyticsEnabled = v);
                            _saveBool(_keyAnalytics, v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'بياناتك محفوظة محلياً ولا يتم مشاركتها مع أطراف ثالثة.',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
