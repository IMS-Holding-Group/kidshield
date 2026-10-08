import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../theme/theme_provider.dart';
import 'analyze_text_screen.dart';
import 'login_screen.dart';

/// واجهة جهاز الطفل: دردشات/نشاط (عروض توضيحية) + مراقبة نصية ترسل لولي الأمر
class ChildMainScreen extends StatefulWidget {
  final int userId;
  final ThemeProvider themeProvider;

  const ChildMainScreen({
    super.key,
    required this.userId,
    required this.themeProvider,
  });

  @override
  State<ChildMainScreen> createState() => _ChildMainScreenState();
}

class _ChildMainScreenState extends State<ChildMainScreen> {
  int _index = 0;

  Future<void> _logout() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(themeProvider: widget.themeProvider),
      ),
    );
  }

  String get _title {
    switch (_index) {
      case 0:
        return 'KidShield — الدردشات';
      case 1:
        return 'KidShield — النشاط';
      case 2:
        return 'KidShield — مراقبة النص';
      default:
        return 'KidShield — الطفل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          centerTitle: true,
        ),
        body: IndexedStack(
          index: _index,
          children: [
            _placeholderTab(
              'الدردشات (عرض)',
              'هنا تُربط لاحقاً بمراقبة التطبيقات بصلاحيات النظام.\nللمناقشة: جرّب لصق نص في تبويب «المراقبة».',
              Icons.forum,
            ),
            _placeholderTab(
              'آخر المشاهدات / المكالمات',
              'يمكن لاحقاً عرض نبذة من النشاط من دون تخزين تفاصيل تنتهك الخصوصية — حسب سياستكم.',
              Icons.history,
            ),
            AnalyzeTextScreen(
              userId: widget.userId,
              childMode: true,
            ),
            _settingsTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'دردشات',
            ),
            NavigationDestination(
              icon: Icon(Icons.visibility_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'النشاط',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'المراقبة',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderTab(String title, String body, IconData icon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _settingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('هذا تطبيق الطفل'),
          subtitle: const Text('التحليل يُنقل إلى خادم ولي الأمر فور اكتشاف خطر.'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('تسجيل الخروج'),
          onTap: _logout,
        ),
      ],
    );
  }
}
