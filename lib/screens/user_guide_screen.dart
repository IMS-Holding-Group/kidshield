import 'package:flutter/material.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دليل الاستخدام'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSection('البداية', [
              '1. سجّل الدخول باسم المستخدم وكلمة المرور.',
              '2. من الشاشة الرئيسية يمكنك عرض السجلات والإحصائيات.',
              '3. استخدم تبويب "تحليل" لتحليل النصوص أو روابط الفيديوهات والألعاب.',
            ]),
            _buildSection('تحليل النص', [
              'أدخل النص في الحقل المخصص واضغط "تحليل وحفظ".',
              'يمكنك اختيار اسم الطفل لربط التحليل به.',
              'ستظهر النتيجة مع مستوى الخطورة والتفسير.',
            ]),
            _buildSection('تحليل الفيديو', [
              'انتقل لتبويب "فيديو" والصق رابط فيديو يوتيوب.',
              'يتم جلب العنوان والوصف وتحليلهما تلقائياً.',
              'اضغط "تحليل وحفظ" لعرض النتيجة.',
            ]),
            _buildSection('تحليل الألعاب', [
              'انتقل لتبويب "ألعاب" والصق رابط اللعبة.',
              'يدعم: جوجل بلاي، آب ستور، ستيم، إيبك، روبلوكس.',
              'يتم تحليل وصف اللعبة وتصنيفها.',
            ]),
            _buildSection('التنبيهات', [
              'عند اكتشاف محتوى ضار يظهر تنبيه تلقائياً.',
              'يمكنك مراجعة التنبيهات أو تجاهلها من تبويب "التنبيهات".',
            ]),
            _buildSection('إدارة الأطفال', [
              'من الشاشة الرئيسية اضغط أيقونة الأطفال.',
              'أضف أسماء الأطفال لربط التحليلات بهم.',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(p, style: const TextStyle(height: 1.5)),
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
