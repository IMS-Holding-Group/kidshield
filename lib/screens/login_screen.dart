import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/theme_provider.dart';
import 'child_main_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  
  const LoginScreen({super.key, required this.themeProvider});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  /// وضع الجهاز: ولي أمر يستقبل التنبيهات — طفل يُرسل التحليل من جهازه
  bool _isParentMode = true;
  
  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await ApiService.login(
      _usernameController.text,
      _passwordController.text,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success'] == true) {
      final userId = (result['user_id'] as num).toInt();
      final role = (result['role'] as String?)?.toLowerCase() ?? 'parent';
      final parentId = result['parent_id'];
      final displayName = result['display_name'] as String?;
      if (_isParentMode && role == 'child') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الحساب مسجّل كطفل — اختر «دخول الطفل» أو استخدم حساب ولي الأمر'),
          ),
        );
        return;
      }
      if (!_isParentMode && role != 'child') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الحساب لولي الأمر — اختر «دخول ولي الأمر» أو استخدم حساب الطفل'),
          ),
        );
        return;
      }
      await SessionService.saveSession(
        userId,
        role: role,
        parentId: parentId != null ? (parentId as num).toInt() : null,
        displayName: displayName,
      );
      if (mounted) {
        if (role == 'child') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChildMainScreen(
                userId: userId,
                themeProvider: widget.themeProvider,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                userId: userId,
                themeProvider: widget.themeProvider,
              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'فشل تسجيل الدخول')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KidShield'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => widget.themeProvider.toggleTheme(),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.shield,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'تسجيل الدخول',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نظام حماية الأطفال الرقمية',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'نوع الحساب',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('ولي أمر'),
                      icon: Icon(Icons.supervisor_account),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('طفل'),
                      icon: Icon(Icons.child_care),
                    ),
                  ],
                  selected: {_isParentMode},
                  onSelectionChanged: (s) {
                    setState(() => _isParentMode = s.first);
                  },
                ),
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: _usernameController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'اسم المستخدم',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Material(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _login,
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.1),
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            child: const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
