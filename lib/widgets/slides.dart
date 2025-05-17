import 'package:flutter/material.dart';

class SlidePage extends StatelessWidget {
  final String title;
  final String description;
  final String subtitle;
  final String imagePath;

  const SlidePage({
    super.key,
    required this.title,
    required this.description,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Zain',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF139799),),),
          const SizedBox(height: 20),
          Text(description,
            style: const TextStyle(fontFamily: 'Zain', fontSize: 18),
            textAlign: TextAlign.right,),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
                fontFamily: 'Zain', fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Image.asset(imagePath),
          ),
        ],
      ),
    );
  }
}
