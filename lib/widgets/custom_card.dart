import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? splashColor;
  final Color? highlightColor;
  
  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.splashColor,
    this.highlightColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultSplashColor = isDark 
        ? Colors.blue.withOpacity(0.3) 
        : Colors.blue.withOpacity(0.2);
    final defaultHighlightColor = isDark
        ? Colors.blue.withOpacity(0.2)
        : Colors.blue.withOpacity(0.1);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: splashColor ?? defaultSplashColor,
          highlightColor: highlightColor ?? defaultHighlightColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
