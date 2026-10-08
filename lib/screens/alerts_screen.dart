import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  final int userId;

  const AlertsScreen({super.key, required this.userId});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getAlerts(widget.userId);

    if (result['success'] == true) {
      setState(() {
        _alerts = List<Map<String, dynamic>>.from(result['alerts'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAlertStatus(int alertId, String status) async {
    final result = await ApiService.updateAlertStatus(alertId, status);

    if (result['success'] == true) {
      _loadAlerts();
      String message = '';
      if (status == 'reviewed') {
        message = 'تم تحديد التنبيه كمقروء';
      } else if (status == 'ignored') {
        message = 'تم تجاهل التنبيه';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'فشل تحديث الحالة')),
        );
      }
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

  String _getStatusText(String? status) {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'reviewed':
        return 'تمت المراجعة';
      case 'ignored':
        return 'تم التجاهل';
      default:
        return 'جديد';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'new':
        return Colors.red;
      case 'reviewed':
        return Colors.green;
      case 'ignored':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التنبيهات'), centerTitle: true),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alerts.isEmpty
            ? const Center(child: Text('لا توجد تنبيهات'))
            : RefreshIndicator(
                onRefresh: _loadAlerts,
                child: ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    final riskLevel = alert['risk_level'] ?? 'high';
                    final status = alert['status'] ?? 'new';
                    final isRead = alert['is_read'] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: isRead ? 2 : 4,
                      color: _getRiskLevelColor(riskLevel).withOpacity(0.1),
                      child: ExpansionTile(
                        leading: Icon(
                          riskLevel == 'high'
                              ? Icons.dangerous
                              : riskLevel == 'medium'
                              ? Icons.warning
                              : Icons.info,
                          color: _getRiskLevelColor(riskLevel),
                          size: 30,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert['text'] ?? '',
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (status == 'new')
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRiskLevelColor(
                                        riskLevel,
                                      ).withOpacity(0.3),
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
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'السبب: ${alert['reason'] ?? 'غير محدد'}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                                if (alert['source_app'] != null &&
                                    (alert['source_app'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'التطبيق: ${alert['source_app']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Text(
                                  'الوقت: ${alert['date'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'النص الكامل:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  alert['text'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                if (alert['explanation'] != null) ...[
                                  const Text(
                                    'التفسير:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert['explanation'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (status == 'new')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Material(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: InkWell(
                                            onTap: () => _updateAlertStatus(
                                              alert['id'],
                                              'reviewed',
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            splashColor: Colors.white
                                                .withOpacity(0.2),
                                            highlightColor: Colors.white
                                                .withOpacity(0.1),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              alignment: Alignment.center,
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'تمت المراجعة',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _updateAlertStatus(
                                              alert['id'],
                                              'ignored',
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            splashColor: Colors.grey
                                                .withOpacity(0.2),
                                            highlightColor: Colors.grey
                                                .withOpacity(0.1),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.close,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'تجاهل',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
