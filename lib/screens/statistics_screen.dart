import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  final int userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getStatistics(widget.userId);

    if (result['success'] == true) {
      setState(() {
        _statistics = result['statistics'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإحصائيات'), centerTitle: true),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _statistics == null
            ? const Center(child: Text('لا توجد إحصائيات'))
            : RefreshIndicator(
                onRefresh: _loadStatistics,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatCard(
                        'إجمالي التحليلات',
                        _statistics!['total_logs'].toString(),
                        Icons.analytics,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'محتوى آمن',
                              '${_statistics!['safe_count']} (${_statistics!['safe_percentage']}%)',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'تحذير',
                              '${_statistics!['warning_count'] ?? 0} (${_statistics!['warning_percentage'] ?? 0}%)',
                              Icons.warning,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'محتوى ضار',
                              '${_statistics!['harmful_count']} (${_statistics!['harmful_percentage']}%)',
                              Icons.dangerous,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'عدد التنبيهات',
                              _statistics!['alerts_count'].toString(),
                              Icons.notifications_active,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'غير مقروء',
                              '${_statistics!['unread_alerts'] ?? 0}',
                              Icons.mark_email_unread,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        'متوسط الثقة',
                        '${_statistics!['avg_confidence']}%',
                        Icons.trending_up,
                        Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        'المحتويات الضارة (7 أيام)',
                        '${_statistics!['last_7_days_harmful'] ?? 0}',
                        Icons.calendar_today,
                        Colors.deepOrange,
                      ),
                      const SizedBox(height: 16),
                        if (_statistics!['most_common_risk'] != null)
                          _buildStatCard(
                            'أكثر مستوى خطورة',
                            _statistics!['most_common_risk'] == 'harmful' 
                                ? 'ضار'
                                : _statistics!['most_common_risk'] == 'warning'
                                    ? 'تحذير'
                                    : 'آمن',
                            Icons.priority_high,
                            _statistics!['most_common_risk'] == 'harmful'
                                ? Colors.red
                                : _statistics!['most_common_risk'] == 'warning'
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        if (_statistics!['weekly_report'] != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            'تقرير أسبوعي (7 أيام)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildReportSummary(_statistics!['weekly_report'] as Map<String, dynamic>?),
                        ],
                        if (_statistics!['monthly_report'] != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'تقرير شهري (30 يوماً)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildReportSummary(_statistics!['monthly_report'] as Map<String, dynamic>?),
                        ],
                        if (_statistics!['top_reasons'] != null &&
                          (_statistics!['top_reasons'] as List).isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'أهم أسباب التنبيهات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_statistics!['top_reasons'] as List).map((reason) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.warning,
                                color: Colors.red,
                              ),
                              title: Text(reason['reason'] ?? 'غير محدد'),
                              trailing: Chip(
                                label: Text('${reason['count']}'),
                                backgroundColor: Colors.red.shade100,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildReportSummary(Map<String, dynamic>? r) {
    if (r == null) return const SizedBox.shrink();
    final total = r['total_logs'] ?? 0;
    final harm = r['harmful_logs'] ?? 0;
    final usage = r['top_apps_by_usage'] as List<dynamic>? ?? [];
    final risk = r['top_apps_by_risk'] as List<dynamic>? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('سجلات: $total — مشبوهة/ضارة: $harm'),
            const SizedBox(height: 8),
            if (usage.isNotEmpty) ...[
              const Text('أكثر التطبيقات (بالسجلات):', style: TextStyle(fontWeight: FontWeight.w600)),
              ...usage.take(4).map((e) {
                final m = e as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(m['app']?.toString() ?? ''),
                  trailing: Text('${m['count']}'),
                );
              }),
            ],
            if (risk.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Text('أكثرها مشاكل: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
              ...risk.take(4).map((e) {
                final m = e as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(m['app']?.toString() ?? ''),
                  trailing: Text('${m['count']}'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
