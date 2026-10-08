import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// شاشة التحليل - نص، فيديو، ألعاب
class AnalyzeTextScreen extends StatefulWidget {
  final int userId;
  final int? initialTabIndex;
  final VoidCallback? onInitialTabConsumed;
  /// وضع جهاز الطفل: تبويب نص فقط + اختيار التطبيق المصدر للتجربة الحقيقية
  final bool childMode;

  const AnalyzeTextScreen({
    super.key,
    required this.userId,
    this.initialTabIndex,
    this.onInitialTabConsumed,
    this.childMode = false,
  });

  @override
  State<AnalyzeTextScreen> createState() => _AnalyzeTextScreenState();
}

class _AnalyzeTextScreenState extends State<AnalyzeTextScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  final _childNameController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String _sourceApp = 'واتساب';
  static const _sourceApps = [
    'واتساب',
    'تيليجرام',
    'سناب شات',
    'انستقرام',
    'تيك توك',
    'رسائل',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.childMode ? 1 : 3, vsync: this);
    _textController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AnalyzeTextScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.childMode &&
        widget.initialTabIndex != null &&
        widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex! >= 0 &&
        widget.initialTabIndex! < 3) {
      _tabController.animateTo(widget.initialTabIndex!);
      widget.onInitialTabConsumed?.call();
    }
  }

  String? get _childName {
    final name = _childNameController.text.trim();
    return name.isEmpty ? null : name;
  }

  Future<void> _analyzeText({bool saveOnly = false}) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال النص للتحليل')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _result = null;
    });
    final response = await ApiService.analyzeText(
      text,
      widget.userId,
      childName: _childName,
      saveOnly: saveOnly,
      sourceApp: widget.childMode ? _sourceApp : null,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      _handleResponse(response, saveOnly, 'تم حفظ النص بنجاح');
    }
  }

  Future<void> _analyzeMedia({bool saveOnly = false}) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رابط الفيديو أو اللعبة')),
      );
      return;
    }
    final mediaType = _tabController.index == 1 ? 'video' : 'game';
    setState(() {
      _isLoading = true;
      _result = null;
    });
    final response = await ApiService.analyzeMedia(
      url,
      widget.userId,
      mediaType: mediaType,
      childName: _childName,
      saveOnly: saveOnly,
      sourceApp: widget.childMode ? _sourceApp : null,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      _handleResponse(
        response,
        saveOnly,
        mediaType == 'video' ? 'تم حفظ الفيديو بنجاح' : 'تم حفظ اللعبة بنجاح',
      );
    }
  }

  void _handleResponse(Map<String, dynamic> response, bool saveOnly, String saveMsg) {
    if (response['success'] == true) {
      setState(() => _result = response['result']);
      if (!saveOnly && _result?['risk_level'] != null && _result!['risk_level'] != 'low' && _result!['risk_level'] != 'safe') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.childMode
                  ? 'أُرسل تنبيه لولي الأمر: ${_getRiskLevelText(_result!['risk_level'])} — ${_result?['reason']}'
                  : 'تم اكتشاف محتوى ${_getRiskLevelText(_result!['risk_level'])}: ${_result?['reason']}',
            ),
            backgroundColor: _result!['risk_level'] == 'high' ? Colors.red : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (saveOnly) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(saveMsg), backgroundColor: Colors.green),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'فشل التحليل')),
      );
    }
  }

  String _getRiskLevelText(String? riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'خطورة عالية';
      case 'medium':
        return 'خطورة متوسطة';
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
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: widget.childMode
            ? null
            : AppBar(
                title: const Text('التحليل'),
                centerTitle: true,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.text_fields), text: 'نص'),
                    Tab(icon: Icon(Icons.video_library), text: 'فيديو'),
                    Tab(icon: Icon(Icons.sports_esports), text: 'ألعاب'),
                  ],
                ),
              ),
        body: widget.childMode
            ? _buildTextTab()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTextTab(),
                  _buildMediaTab('فيديو', 'رابط فيديو يوتيوب', Icons.video_library),
                  _buildMediaTab('لعبة', 'رابط اللعبة (جوجل بلاي، آب ستور، ستيم...)', Icons.sports_esports),
                ],
              ),
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.childMode) ...[
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'التطبيق / المصدر (للتقرير لولي الأمر)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _sourceApp,
                  items: _sourceApps
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _sourceApp = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!widget.childMode)
            TextField(
              controller: _childNameController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'اسم الطفل (اختياري)',
                hintText: 'أدخل اسم الطفل',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
          if (!widget.childMode) const SizedBox(height: 16),
          Text(
            'أدخل النص للتحليل',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            textDirection: TextDirection.rtl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'اكتب النص هنا...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'عدد الأحرف: ${_textController.text.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(() => _analyzeText(saveOnly: true), () => _analyzeText(saveOnly: false)),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaTab(String label, String hint, IconData icon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _childNameController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'اسم الطفل (اختياري)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تحليل $label',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            textDirection: TextDirection.rtl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(icon),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(() => _analyzeMedia(saveOnly: true), () => _analyzeMedia(saveOnly: false)),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(VoidCallback onSave, VoidCallback onAnalyze) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('حفظ فقط'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onAnalyze,
            icon: const Icon(Icons.analytics),
            label: const Text('تحليل وحفظ'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    final riskLevel = r['risk_level'] ?? 'low';
    final color = _getRiskLevelColor(riskLevel);
    return Card(
      color: color.withOpacity(0.1),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  riskLevel == 'high' ? Icons.dangerous : riskLevel == 'medium' ? Icons.warning : Icons.check_circle,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'النتيجة: ${_getRiskLevelText(riskLevel)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            if (r['source_url'] != null) ...[
              const SizedBox(height: 8),
              Text('الرابط: ${r['source_url']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (r['extracted_text'] != null && r['extracted_text'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'النص المستخرج: ${r['extracted_text']}...',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (r['category'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('الفئة: ${r['category']}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ),
            const SizedBox(height: 12),
            Text('السبب: ${r['reason'] ?? 'غير محدد'}', style: const TextStyle(fontSize: 16)),
            if (r['explanation'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('التفسير:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(r['explanation']),
                  ],
                ),
              ),
            ],
            if (r['key_words'] != null && (r['key_words'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('الكلمات المؤثرة:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (r['key_words'] as List).map((w) => Chip(label: Text(w.toString()), backgroundColor: Colors.purple.shade100)).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('مستوى الثقة: '),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (r['confidence'] as num?)?.toDouble() ?? 0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(((r['confidence'] as num?) ?? 0) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _urlController.dispose();
    _childNameController.dispose();
    super.dispose();
  }
}
