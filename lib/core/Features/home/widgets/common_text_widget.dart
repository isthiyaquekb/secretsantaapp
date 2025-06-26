import 'package:flutter/material.dart';

class CommonTextWidget extends StatelessWidget {
  final String title;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  const CommonTextWidget({
    required this.title,
    required this.fontSize,
    required this.color,
    this.fontWeight=FontWeight.normal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: fontSize, color: color,fontWeight: fontWeight),
      textAlign: TextAlign.center,
    );
  }
}