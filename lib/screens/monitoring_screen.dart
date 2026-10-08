import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MonitoringScreen extends StatefulWidget {
  final int userId;
  final VoidCallback? onAnalyzeVideo;
  final VoidCallback? onAnalyzeGame;

  const MonitoringScreen({
    super.key,
    required this.userId,
    this.onAnalyzeVideo,
    this.onAnalyzeGame,
  });
  
  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool _isMonitoring = false;
  bool _isLoading = false;
  Map<String, dynamic>? _monitoringStatus;
  
  @override
  void initState() {
    super.initState();
    _loadMonitoringStatus();
  }
  
  Future<void> _loadMonitoringStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    final result = await ApiService.getMonitoringStatus(widget.userId);
    
    if (result['success'] == true) {
      setState(() {
        _isMonitoring = result['is_active'] ?? false;
        _monitoringStatus = result;
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
        appBar: AppBar(
          title: const Text('المراقبة التلقائية'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isMonitoring 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                        ),
                        child: Icon(
                          _isMonitoring ? Icons.security : Icons.security_outlined,
                          size: 50,
                          color: _isMonitoring ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isMonitoring ? 'المراقبة نشطة' : 'المراقبة متوقفة',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMonitoring 
                            ? 'النظام يراقب المحتوى تلقائياً'
                            : 'قم بتفعيل المراقبة التلقائية',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_isMonitoring && _monitoringStatus != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                '${_monitoringStatus!['recent_alerts'] ?? 0} تنبيه خلال الساعة الماضية',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: _isMonitoring ? Colors.red : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () async {
                    if (_isMonitoring) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            title: const Text('إيقاف المراقبة'),
                            content: const Text('هل أنت متأكد من إيقاف المراقبة التلقائية؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('إيقاف', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      );
                      
                      if (confirmed == true) {
                        setState(() {
                          _isMonitoring = false;
                        });
                      }
                    } else {
                      setState(() {
                        _isMonitoring = true;
                      });
                      _loadMonitoringStatus();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMonitoring ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isMonitoring ? 'إيقاف المراقبة' : 'تفعيل المراقبة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'ميزات المراقبة التلقائية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                Icons.text_fields,
                'تحليل النصوص',
                'تحليل تلقائي للنصوص في التطبيقات والرسائل',
              ),
              _buildFeatureCard(
                Icons.video_library,
                'تحليل الفيديوهات',
                'تحليل محتوى فيديوهات يوتيوب - اضغط للانتقال',
                enabled: true,
                onTap: widget.onAnalyzeVideo,
              ),
              _buildFeatureCard(
                Icons.games,
                'تحليل الألعاب',
                'تحليل ألعاب جوجل بلاي وستيم وغيرها - اضغط للانتقال',
                enabled: true,
                onTap: widget.onAnalyzeGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description, {
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: enabled
            ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green)
            : const Icon(Icons.schedule, color: Colors.grey),
        onTap: enabled && onTap != null ? onTap : null,
      ),
    );
  }
}
