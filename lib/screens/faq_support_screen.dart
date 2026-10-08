import 'package:flutter/material.dart';
import 'user_guide_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

/// صفحة الأسئلة الشائعة والدعم الفني - مع ListView لتجنب overflow
class FaqSupportScreen extends StatelessWidget {
  const FaqSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأسئلة الشائعة والدعم الفني'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('الأسئلة الشائعة'),
            ..._faqItems.map((item) => _buildFaqTile(context, item)),
            const SizedBox(height: 24),
            _buildSectionTitle('الدعم الفني'),
            _buildSupportCard(context),
            const SizedBox(height: 24),
            _buildSectionTitle('روابط مفيدة'),
            _buildLinksCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFaqTile(BuildContext context, Map<String, String> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: Colors.blue),
        title: Text(
          item['question']!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(item['answer']!, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('البريد الإلكتروني'),
              subtitle: Text('support@kidshield.app'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.phone, color: Colors.green),
              title: Text('هاتف الدعم'),
              subtitle: Text('+966 XX XXX XXXX'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange),
              title: const Text('ساعات العمل'),
              subtitle: Text(
                'الأحد - الخميس: 9:00 ص - 5:00 م',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('دليل الاستخدام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserGuideScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('الشروط والأحكام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  static final List<Map<String, String>> _faqItems = [
    {
      'question': 'ما هو KidShield؟',
      'answer':
          'KidShield هو تطبيق ذكي لحماية الأطفال من المخاطر الرقمية. يقوم بتحليل النصوص والفيديوهات والألعاب لاكتشاف المحتوى الضار كالتنمر والكراهية والألفاظ غير اللائقة.',
    },
    {
      'question': 'كيف يعمل التحليل؟',
      'answer':
          'يستخدم KidShield نموذج ذكاء اصطناعي مدرب على اكتشاف المحتوى الضار. يمكنك لصق النص أو رابط فيديو/لعبة وسيتم تحليله تلقائياً مع عرض مستوى الخطورة والتفسير.',
    },
    {
      'question': 'هل يمكن تحليل الفيديوهات والألعاب؟',
      'answer':
          'نعم! يمكنك لصق رابط فيديو من يوتيوب أو رابط لعبة من متجر التطبيقات، وسيقوم النظام بتحليل العنوان والوصف وتصنيف مدى ملاءمة المحتوى للأطفال.',
    },
    {
      'question': 'كيف أضيف طفلي للمراقبة؟',
      'answer':
          'من الشاشة الرئيسية اضغط على أيقونة إدارة الأطفال، ثم أضف اسم الطفل وعمره. عند التحليل يمكنك اختيار الطفل المرتبط بالنص.',
    },
    {
      'question': 'ماذا لو كان التحليل خاطئاً؟',
      'answer':
          'يمكنك الإبلاغ عن اكتشاف خاطئ من خلال تفاصيل السجل. هذا يساعد في تحسين النظام تدريجياً.',
    },
    {
      'question': 'هل بياناتي آمنة؟',
      'answer':
          'نعم، نحن نأخذ الخصوصية على محمل الجد. البيانات محفوظة بشكل آمن ولا تتم مشاركتها مع أطراف ثالثة.',
    },
  ];
}
