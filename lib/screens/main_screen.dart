import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/parent_notification_service.dart';
import '../theme/theme_provider.dart';
import 'dashboard_screen.dart';
import 'analyze_text_screen.dart';
import 'alerts_screen.dart';
import 'monitoring_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final int userId;
  final ThemeProvider themeProvider;
  
  const MainScreen({super.key, required this.userId, required this.themeProvider});
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int? _analyzeInitialTab;
  Timer? _alertsPoll;
  int _knownAlertCount = 0;

  @override
  void initState() {
    super.initState();
    // محاكاة وصول «إشعار» لحساب ولي الأمر عبر شريط إشعارات النظام
    ParentNotificationService.instance.init();
    _refreshAlertBaseline();
    _alertsPoll = Timer.periodic(const Duration(seconds: 14), (_) => _checkNewParentAlerts());
  }

  @override
  void dispose() {
    _alertsPoll?.cancel();
    super.dispose();
  }

  Future<void> _refreshAlertBaseline() async {
    final r = await ApiService.getAlerts(widget.userId);
    if (r['success'] == true && mounted) {
      final list = r['alerts'] as List<dynamic>? ?? [];
      setState(() => _knownAlertCount = list.length);
    }
  }

  Future<void> _checkNewParentAlerts() async {
    final r = await ApiService.getAlerts(widget.userId);
    if (r['success'] != true || !mounted) return;
    final list = r['alerts'] as List<dynamic>? ?? [];
    if (list.length > _knownAlertCount) {
      setState(() => _knownAlertCount = list.length);
      final a = list.first as Map<String, dynamic>;
      final app = a['source_app']?.toString() ?? 'غير محدد';
      final aid = a['id'];
      final notifId = aid is int
          ? aid
          : aid is num
              ? aid.toInt()
              : list.length;
      final childName = a['child_name']?.toString();
      if (!mounted) return;
      // إشعار نظام = محاكاة وصوله لتطبيق/حساب الأب
      ParentNotificationService.instance.showParentAlert(
        notificationId: notifId,
        reason: a['reason']?.toString() ?? 'تنبيه',
        sourceApp: app == 'غير محدد' ? null : app,
        childName: (childName != null && childName.isNotEmpty) ? childName : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تنبيه جديد: ${a['reason'] ?? ''} (المصدر: $app) — اطّلع في «التنبيهات»',
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'عرض',
            onPressed: () {
              setState(() => _currentIndex = 3);
            },
          ),
        ),
      );
    } else {
      setState(() => _knownAlertCount = list.length);
    }
  }

  void _goToAnalyzeTab(int tabIndex) {
    setState(() {
      _currentIndex = 2;
      _analyzeInitialTab = tabIndex;
    });
  }

  void _clearAnalyzeInitialTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _analyzeInitialTab = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardScreen(userId: widget.userId, themeProvider: widget.themeProvider),
            MonitoringScreen(
              userId: widget.userId,
              onAnalyzeVideo: () => _goToAnalyzeTab(1),
              onAnalyzeGame: () => _goToAnalyzeTab(2),
            ),
            AnalyzeTextScreen(
              userId: widget.userId,
              initialTabIndex: _analyzeInitialTab,
              onInitialTabConsumed: _clearAnalyzeInitialTab,
            ),
            AlertsScreen(userId: widget.userId),
            SettingsScreen(userId: widget.userId, themeProvider: widget.themeProvider),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_outlined),
              selectedIcon: Icon(Icons.monitor),
              label: 'المراقبة',
            ),
            NavigationDestination(
              icon: Icon(Icons.text_fields_outlined),
              selectedIcon: Icon(Icons.text_fields),
              label: 'تحليل',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'التنبيهات',
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
}
