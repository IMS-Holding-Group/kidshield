import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FalsePositiveDialog extends StatefulWidget {
  final int logId;
  final int userId;
  final Function() onReported;
  
  const FalsePositiveDialog({
    super.key,
    required this.logId,
    required this.userId,
    required this.onReported,
  });
  
  @override
  State<FalsePositiveDialog> createState() => _FalsePositiveDialogState();
}

class _FalsePositiveDialogState extends State<FalsePositiveDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('الإبلاغ عن اكتشاف خاطئ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إذا كان هذا الاكتشاف خاطئاً، يرجى إخبارنا بذلك لتحسين النموذج.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'السبب (اختياري)',
                  hintText: 'لماذا تعتقد أن هذا الاكتشاف خاطئ؟',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _reportFalsePositive,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إبلاغ', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _reportFalsePositive() async {
    setState(() {
      _isSubmitting = true;
    });
    
    final result = await ApiService.reportFalsePositive(
      widget.logId,
      widget.userId,
      _reasonController.text.trim(),
    );
    
    if (mounted) {
      Navigator.pop(context);
      widget.onReported();
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شكراً لك! تم الإبلاغ عن الاكتشاف الخاطئ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل الإبلاغ'),
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
