import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سياسة الخصوصية'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildParagraph(
              'نحن في KidShield نلتزم بحماية خصوصيتك وبياناتك. تحدد سياسة الخصوصية هذه كيفية جمعنا واستخدامنا وحمايتنا لمعلوماتك.',
            ),
            _buildSection('البيانات التي نجمعها', [
              '• بيانات تسجيل الدخول (اسم المستخدم وكلمة المرور)',
              '• النصوص والتحليلات التي تقوم بإدخالها',
              '• روابط الفيديوهات والألعاب المُراجعة',
              '• بيانات الأطفال المضافة (الاسم والعمر)',
            ]),
            _buildSection('كيف نستخدم البيانات', [
              '• تحليل المحتوى لاكتشاف المخاطر الرقمية',
              '• تحسين دقة النموذج التحليلي',
              '• عرض الإحصائيات والتقارير لك',
              '• إرسال التنبيهات عند اكتشاف محتوى ضار',
            ]),
            _buildSection('حماية البيانات', [
              '• البيانات محفوظة بشكل آمن على جهازك والخادم',
              '• لا نشارك بياناتك مع أطراف ثالثة لأغراض تسويقية',
              '• الاتصال بالخادم مشفّر (HTTPS)',
            ]),
            _buildSection('حقوقك', [
              '• يمكنك حذف حسابك وبياناتك في أي وقت',
              '• يمكنك تصدير بياناتك عند الطلب',
              '• للاستفسارات: support@kidshield.app',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: const TextStyle(height: 1.6, fontSize: 15)),
    );
  }

  Widget _buildSection(String title, List<String> items) {
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
            ...items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(i, style: const TextStyle(height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
