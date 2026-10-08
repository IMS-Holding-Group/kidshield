import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import 'faq_support_screen.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';
import 'security_privacy_screen.dart';
import 'user_guide_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  final ThemeProvider themeProvider;
  
  const SettingsScreen({super.key, required this.userId, required this.themeProvider});
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: SwitchListTile(
                title: const Text('الوضع الداكن'),
                subtitle: const Text('تفعيل الوضع الداكن'),
                value: isDark,
                onChanged: (value) => widget.themeProvider.setTheme(value),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('الملف الشخصي'),
                    subtitle: const Text('عرض وتعديل الملف الشخصي'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('إعدادات التنبيهات'),
                    subtitle: const Text('تخصيص التنبيهات والإشعارات'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('الأمان والخصوصية'),
                    subtitle: const Text('إعدادات الأمان والخصوصية'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecurityPrivacyScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('حول التطبيق'),
                    subtitle: const Text('معلومات عن KidShield'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _showAboutDialog(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('المساعدة والدعم'),
                    subtitle: const Text('الأسئلة الشائعة والدعم الفني'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FaqSupportScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('دليل الاستخدام'),
                    subtitle: const Text('كيفية استخدام التطبيق'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserGuideScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('سياسة الخصوصية'),
                    subtitle: const Text('كيف نحمي بياناتك'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('الشروط والأحكام'),
                    subtitle: const Text('شروط استخدام التطبيق'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Material(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حول KidShield'),
          content: const Text(
            'KidShield هو نظام ذكي موجه للأهل والمعلمين يهدف إلى حماية الأطفال من المخاطر الرقمية.\n\n'
            'الإصدار: 1.0.0\n'
            '© 2026 KidShield',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await SessionService.clearSession();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(themeProvider: widget.themeProvider),
                    ),
                  );
                }
              },
              child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
