import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الشروط والأحكام'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSection('1. القبول', [
              'باستخدامك تطبيق KidShield فإنك توافق على هذه الشروط والأحكام. إذا كنت لا توافق، يرجى عدم استخدام التطبيق.',
            ]),
            _buildSection('2. الاستخدام المقبول', [
              'يُستخدم التطبيق لأغراض حماية الأطفال من المخاطر الرقمية فقط.',
              'لا يُسمح باستخدام التطبيق لأي نشاط غير قانوني أو يضر بالآخرين.',
              'أنت مسؤول عن صحة البيانات التي تدخلها.',
            ]),
            _buildSection('3. الخدمة', [
              'نقدم تحليلاً آلياً للمحتوى. النتائج تقديرية وليست حكماً نهائياً.',
              'نحاول الحفاظ على استمرارية الخدمة لكن لا نضمن عدم التوقف.',
              'نحتفظ بحق تعديل أو إيقاف الخدمة.',
            ]),
            _buildSection('4. المسؤولية', [
              'التطبيق أداة مساعدة. القرار النهائي للأهل أو المعلم.',
              'لا نتحمل مسؤولية أي قرار يتخذ بناءً على تحليلات التطبيق.',
              'الحد الأقصى للمسؤولية يقتصر على الخدمة المقدمة.',
            ]),
            _buildSection('5. التعديلات', [
              'قد نحدث هذه الشروط. استمرار الاستخدام بعد التحديث يعني الموافقة.',
            ]),
          ],
        ),
      ),
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(i, style: const TextStyle(height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
