import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/theme_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/false_positive_dialog.dart';
import 'analyze_text_screen.dart';
import 'alerts_screen.dart';
import 'statistics_screen.dart';
import 'children_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  final ThemeProvider themeProvider;
  
  const DashboardScreen({super.key, required this.userId, required this.themeProvider});
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _selectedChild;
  List<Map<String, dynamic>> _children = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _loadLogs(),
      _loadStatistics(),
      _loadChildren(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _loadLogs() async {
    final result = await ApiService.getContentLogs(
      widget.userId,
      childName: _selectedChild,
    );
    
    if (result['success'] == true) {
      setState(() {
        _logs = List<Map<String, dynamic>>.from(result['logs'] ?? []);
      });
    }
  }
  
  Future<void> _loadStatistics() async {
    final result = await ApiService.getStatistics(widget.userId);
    
    if (result['success'] == true) {
      setState(() {
        _stats = result['statistics'];
      });
    }
  }
  
  Future<void> _loadChildren() async {
    final result = await ApiService.getChildren(widget.userId);
    
    if (result['success'] == true) {
      setState(() {
        _children = List<Map<String, dynamic>>.from(result['children'] ?? []);
      });
    }
  }
  
  String _getRiskLevelText(String? riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'خطورة عالية';
      case 'medium':
        return 'خطورة متوسطة';
      case 'low':
      default:
        return 'خطورة منخفضة';
    }
  }
  
  Color _getRiskLevelColor(String? riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KidShield'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.child_care),
              tooltip: 'إدارة الأطفال',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChildrenManagementScreen(userId: widget.userId),
                  ),
                ).then((_) => _loadData());
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'الإحصائيات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatisticsScreen(userId: widget.userId),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_children.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<String>(
                          value: _selectedChild,
                          decoration: InputDecoration(
                            labelText: 'فلترة حسب الطفل',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixIcon: const Icon(Icons.filter_list),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('الكل')),
                            ..._children.map((child) => DropdownMenuItem(
                              value: child['name'],
                              child: Text('${child['name']} (${child['count']})'),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedChild = value;
                            });
                            _loadLogs();
                          },
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StatisticsScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              child: _buildStatCardContent(
                                'عدد النصوص المحللة',
                                _stats?['total_logs']?.toString() ?? '0',
                                Icons.analytics,
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AlertsScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              child: _buildStatCardContent(
                                'المحتويات الضارة',
                                _stats?['harmful_count']?.toString() ?? '0',
                                Icons.dangerous,
                                Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlertsScreen(userId: widget.userId),
                            ),
                          );
                        },
                        child: _buildStatCardContent(
                          'آخر تنبيه',
                          _stats?['unread_alerts'] != null && (_stats!['unread_alerts'] as int) > 0
                              ? '${_stats!['unread_alerts']} غير مقروء'
                              : 'لا توجد تنبيهات جديدة',
                          Icons.notifications,
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'سجل المحتوى',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _logs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('لا توجد سجلات')),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final riskLevel = log['risk_level'] ?? log['label'] ?? 'low';
                              return CustomCard(
                                onTap: () {
                                  _showLogDetails(log);
                                },
                                child: ListTile(
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'حذف',
                                    onPressed: () => _confirmDeleteLog(context, log),
                                  ),
                                  leading: Icon(
                                    riskLevel == 'high' 
                                        ? Icons.dangerous 
                                        : riskLevel == 'medium'
                                            ? Icons.warning
                                            : Icons.check_circle,
                                    color: _getRiskLevelColor(riskLevel),
                                  ),
                                  title: Text(
                                    log['text'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getRiskLevelColor(riskLevel).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getRiskLevelText(riskLevel),
                                              style: TextStyle(
                                                color: _getRiskLevelColor(riskLevel),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (log['confidence'] != null)
                                            Chip(
                                              label: Text(
                                                '${((log['confidence'] as num) * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                              backgroundColor: _getRiskLevelColor(riskLevel).withOpacity(0.2),
                                            ),
                                        ],
                                      ),
                                      if (log['reason'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'السبب: ${log['reason']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      if (log['explanation'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'التفسير: ${log['explanation']}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      if (log['child_name'] != null && log['child_name'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'الطفل: ${log['child_name']}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'التاريخ: ${log['date'] ?? ''}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
  
  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تفاصيل التحليل'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('النص:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(log['text'] ?? ''),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRiskLevelColor(log['risk_level']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRiskLevelText(log['risk_level']),
                        style: TextStyle(
                          color: _getRiskLevelColor(log['risk_level']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (log['reason'] != null) ...[
                  const SizedBox(height: 12),
                  Text('السبب:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(log['reason']),
                ],
                if (log['explanation'] != null) ...[
                  const SizedBox(height: 12),
                  Text('التفسير:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(log['explanation']),
                ],
              ],
            ),
          ),
          actions: [
            if (log['risk_level'] != null && log['risk_level'] != 'low')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => FalsePositiveDialog(
                      logId: log['id'],
                      userId: widget.userId,
                      onReported: () => _loadData(),
                    ),
                  );
                },
                child: const Text('إبلاغ عن اكتشاف خاطئ', style: TextStyle(color: Colors.orange)),
              ),
            TextButton(
              onPressed: () => _confirmDeleteLog(context, log),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _confirmDeleteLog(BuildContext context, Map<String, dynamic> log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل تريد حذف هذا السجل نهائياً؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.pop(context);
    final result = await ApiService.deleteContentLog(
      log['id'] as int,
      widget.userId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true ? 'تم الحذف بنجاح' : (result['message'] ?? 'فشل الحذف')),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true) _loadData();
    }
  }
  
  Widget _buildStatCardContent(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
