import 'package:flutter/material.dart';

class SubFabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool showLabel; 

  const SubFabButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.showLabel = true, 
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showLabel) 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: label, 
          mini: true, 
          onPressed: onTap,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          child: Icon(icon),
        ),
      ],
    );
  }
}